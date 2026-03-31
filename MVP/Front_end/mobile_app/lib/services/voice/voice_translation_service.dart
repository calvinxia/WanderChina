import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, Platform;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import '../../models/poi_translation.dart';
import '../api_client.dart';
import '../analytics_service.dart';

enum TranslationDirection {
  foreignToChinese, // EN/FR/ES → 中文
  chineseToForeign, // 中文 → EN/FR/ES
}

class VoiceTranslationResult {
  final String originalText;
  final String translatedText;
  final TranslationDirection direction;
  final AppLanguage foreignLanguage;
  final Duration processingTime;

  const VoiceTranslationResult({
    required this.originalText,
    required this.translatedText,
    required this.direction,
    required this.foreignLanguage,
    required this.processingTime,
  });
}

enum VoiceServiceState { idle, recording, processing, playing, error }

class VoiceTranslationService extends ChangeNotifier {
  static final VoiceTranslationService _instance =
      VoiceTranslationService._internal();
  factory VoiceTranslationService() => _instance;
  VoiceTranslationService._internal();

  final _analytics = AnalyticsService.instance;
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer   _player   = AudioPlayer();

  VoiceServiceState _state = VoiceServiceState.idle;
  VoiceServiceState get state => _state;

  final List<VoiceTranslationResult> _history = [];
  List<VoiceTranslationResult> get history => List.unmodifiable(_history);

  // ─── 初始化 ───────────────────────────────────────────

  Future<void> initialize() async {
    debugPrint('✅ VoiceTranslationService initialized');
  }

  // ─── 公开接口 ─────────────────────────────────────────

  Future<void> startRecording() async {
    if (_state != VoiceServiceState.idle) return;

    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        debugPrint('⚠️ Microphone permission denied');
        _setState(VoiceServiceState.error);
        throw Exception('麦克风权限未授权');
      }

      final dir = await getTemporaryDirectory();

      // iOS 用 WAV（PCM），兼容性最好；Android 用 AAC
      final String ext = Platform.isIOS ? '.wav' : '.m4a';
      final path = '${dir.path}/wander_voice_${DateTime.now().millisecondsSinceEpoch}$ext';

      final config = Platform.isIOS
          ? const RecordConfig(
              encoder: AudioEncoder.wav,     // iOS: PCM/WAV 最稳定
              sampleRate: 16000,             // 百度 ASR 要求 16kHz
              numChannels: 1,                // 单声道
              bitRate: 256000,
            )
          : const RecordConfig(
              encoder: AudioEncoder.aacLc,   // Android: AAC
              sampleRate: 16000,             // 百度 ASR 要求 16kHz
              numChannels: 1,                // 单声道
              bitRate: 128000,
            );

      debugPrint('🎙️ Config: ${config.encoder}, path: $path');
      await _recorder.start(config, path: path);
      debugPrint('🎙️ Recording started, isRecording: ${await _recorder.isRecording()}');
      _setState(VoiceServiceState.recording);
    } catch (e) {
      debugPrint('⚠️ Recording failed: $e');
      _setState(VoiceServiceState.error);
      rethrow;
    }
  }

  Future<VoiceTranslationResult?> stopAndTranslate({
    required TranslationDirection direction,
    required AppLanguage foreignLanguage,
  }) async {
    if (_state != VoiceServiceState.recording) return null;

    _setState(VoiceServiceState.processing);
    final stopwatch = Stopwatch()..start();

    try {
      final audioPath = await _recorder.stop();
      if (audioPath == null) {
        throw Exception('录音文件为空');
      }

      // 检查录音文件大小，防止录音时间太短
      final file = File(audioPath);
      if (!await file.exists()) {
        throw Exception('录音文件不存在');
      }

      final fileSize = await file.length();
      debugPrint('Audio file size: $fileSize bytes');

      if (fileSize < 1000) {
        // 小于 1KB 认为录音太短或无效
        debugPrint('⚠️ Recording too short or empty ($fileSize bytes)');
        _setState(VoiceServiceState.idle);
        try {
          file.deleteSync();
        } catch (_) {}
        throw Exception('录音时间太短，请长按说话');
      }

      // Step 1: 云函数ASR
      final sourceLang = direction == TranslationDirection.foreignToChinese
          ? foreignLanguage
          : null;
      final recognized = await _cloudASR(audioPath: audioPath, language: sourceLang);
      if (recognized == null || recognized.isEmpty) {
        throw Exception('语音识别失败或无声音');
      }

      // Step 2: 云函数翻译
      final translated = await _cloudTranslate(
        text:           recognized,
        direction:      direction,
        foreignLanguage: foreignLanguage,
      );

      // Step 3: 云函数TTS播放
      final ttsLang = direction == TranslationDirection.foreignToChinese
          ? 'zh'
          : (foreignLanguage == AppLanguage.english
              ? 'en'
              : foreignLanguage == AppLanguage.french
                  ? 'fr'
                  : 'es');
      await _cloudTTS(
        text: translated,
        language: ttsLang,
      );

      stopwatch.stop();
      final result = VoiceTranslationResult(
        originalText:    recognized,
        translatedText:  translated,
        direction:       direction,
        foreignLanguage: foreignLanguage,
        processingTime:  stopwatch.elapsed,
      );
      _history.add(result);

      // Analytics tracking
      final directionStr = direction == TranslationDirection.foreignToChinese
          ? 'foreign_to_zh'
          : 'zh_to_foreign';
      _analytics.voiceTranslated(directionStr, recognized);

      try { File(audioPath).deleteSync(); } catch (_) {}
      return result;
    } catch (e) {
      debugPrint('⚠️ 语音翻译链路失败: $e');
      _setState(VoiceServiceState.error);
      await Future.delayed(const Duration(seconds: 2));
      _setState(VoiceServiceState.idle);
      return null;
    }
  }

  Future<void> cancelRecording() async {
    if (_state == VoiceServiceState.recording) {
      await _recorder.cancel();
      _setState(VoiceServiceState.idle);
    }
  }

  Future<void> stopPlaying() async {
    await _player.stop();
    _setState(VoiceServiceState.idle);
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  /// 重播上一条翻译结果的 TTS
  Future<void> replayTTS(String text, String targetLang) async {
    await _cloudTTS(text: text, language: targetLang);
  }

  /// 快捷短语：直接翻译 + 播放，跳过录音步骤
  Future<VoiceTranslationResult?> translateQuickPhrase({
    required String phrase,
    required TranslationDirection direction,
    required AppLanguage foreignLanguage,
  }) async {
    if (_state != VoiceServiceState.idle) return null;

    _setState(VoiceServiceState.processing);
    final stopwatch = Stopwatch()..start();

    try {
      // 直接翻译短语
      final translated = await _cloudTranslate(
        text: phrase,
        direction: direction,
        foreignLanguage: foreignLanguage,
      );

      // TTS播放
      final ttsLang = direction == TranslationDirection.foreignToChinese
          ? 'zh'
          : (foreignLanguage == AppLanguage.english
              ? 'en'
              : foreignLanguage == AppLanguage.french
                  ? 'fr'
                  : 'es');
      await _cloudTTS(text: translated, language: ttsLang);

      stopwatch.stop();
      final result = VoiceTranslationResult(
        originalText: phrase,
        translatedText: translated,
        direction: direction,
        foreignLanguage: foreignLanguage,
        processingTime: stopwatch.elapsed,
      );
      _history.add(result);

      return result;
    } catch (e) {
      debugPrint('⚠️ 快捷短语翻译失败: $e');
      _setState(VoiceServiceState.error);
      await Future.delayed(const Duration(seconds: 2));
      _setState(VoiceServiceState.idle);
      return null;
    }
  }

  // ─── 云函数ASR ──────────────────────────────────────────

  Future<String?> _cloudASR({
    required String audioPath,
    AppLanguage?   language,
  }) async {
    try {
      // 检查音频文件是否存在
      final file = File(audioPath);
      if (!await file.exists()) {
        debugPrint('⚠️ Audio file not found: $audioPath');
        return null;
      }

      final audioBytes  = await file.readAsBytes();
      final base64Audio = base64Encode(audioBytes);

      // 调试信息：音频文件大小
      debugPrint('Audio file size: ${audioBytes.length} bytes');

      final langStr = switch (language) {
        AppLanguage.english  => 'en',
        AppLanguage.french   => 'fr',
        AppLanguage.spanish  => 'es',
        _                    => 'zh',
      };

      // 根据文件扩展名确定格式：iOS 用 wav，Android 用 m4a
      final format = audioPath.endsWith('.wav') ? 'wav' : 'm4a';
      debugPrint('🎤 ASR format: $format, language: $langStr');

      final result = await ApiClient.post(ApiClient.asrUrl, {
        'audio_base64': base64Audio,
        'audio_len': audioBytes.length,
        'language': langStr,
        'format': format,
      });

      if (result['recognized_text'] != null) {
        return result['recognized_text'] as String;
      }
      // 兼容不同的返回字段名
      if (result['text'] != null) {
        return result['text'] as String;
      }
      debugPrint('ASR云函数错误: ${result['error']}');
    } catch (e) {
      debugPrint('⚠️ ASR云函数请求失败: $e');
    }
    return null;
  }

  // ─── 云函数翻译 ─────────────────────────────────────

  Future<String> _cloudTranslate({
    required String text,
    required TranslationDirection direction,
    required AppLanguage foreignLanguage,
  }) async {
    final targetLang = switch (foreignLanguage) {
      AppLanguage.english  => 'en',
      AppLanguage.french   => 'fr',
      AppLanguage.spanish  => 'es',
    };

    final sourceLang = direction == TranslationDirection.foreignToChinese
        ? targetLang
        : 'zh';
    final targetLangFinal = direction == TranslationDirection.foreignToChinese
        ? 'zh'
        : targetLang;

    try {
      debugPrint('Translation input: text=$text, source=$sourceLang, target=$targetLangFinal');

      final result = await ApiClient.post(ApiClient.translateUrl, {
        'text': text,
        'source_lang': sourceLang,
        'target_lang': targetLangFinal,
        'context': 'voice_travel', // 语音旅行场景
      });

      debugPrint('Translation result: $result');

      if (result['translated_text'] != null) {
        return result['translated_text'] as String;
      }
    } catch (e) {
      debugPrint('⚠️ 翻译云函数失败: $e');
    }
    return text; // 降级：返回原文
  }

  // ─── 云函数TTS ──────────────────────────────────────────

  Future<void> _cloudTTS({
    required String text,
    required String language, // 'zh', 'en', 'fr', 'es'
  }) async {
    try {
      final result = await ApiClient.post(ApiClient.ttsUrl, {
        'text': text,
        'language': language,
      });

      if (result['audio_base64'] != null) {
        final audioBytes = base64Decode(result['audio_base64'] as String);
        final dir     = await getTemporaryDirectory();
        final ttsPath =
            '${dir.path}/wander_tts_${DateTime.now().millisecondsSinceEpoch}.mp3';
        await File(ttsPath).writeAsBytes(audioBytes);

        _setState(VoiceServiceState.playing);
        await _player.play(DeviceFileSource(ttsPath));

        _player.onPlayerComplete.first.then((_) {
          try { File(ttsPath).deleteSync(); } catch (_) {}
          _setState(VoiceServiceState.idle);
        });
      }
    } catch (e) {
      debugPrint('⚠️ TTS云函数失败: $e');
      _setState(VoiceServiceState.idle);
    }
  }

  void _setState(VoiceServiceState s) {
    _state = s;
    notifyListeners();
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }
}
