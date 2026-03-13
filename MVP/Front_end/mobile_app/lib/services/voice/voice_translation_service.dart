import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import '../../models/poi_translation.dart';
import '../api_client.dart';

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

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer   _player   = AudioPlayer();

  VoiceServiceState _state = VoiceServiceState.idle;
  VoiceServiceState get state => _state;

  final List<VoiceTranslationResult> _history = [];
  List<VoiceTranslationResult> get history => List.unmodifiable(_history);

  // ─── 初始化 ───────────────────────────────────────────

  Future<void> initialize() async {
    print('✅ VoiceTranslationService initialized');
  }

  // ─── 公开接口 ─────────────────────────────────────────

  Future<void> startRecording() async {
    if (_state != VoiceServiceState.idle) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _setState(VoiceServiceState.error);
      throw Exception('麦克风权限未授权');
    }

    final dir  = await getTemporaryDirectory();
    final path =
        '${dir.path}/wander_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder:    AudioEncoder.aacLc,
        bitRate:    128000,
        sampleRate: 16000, // 百度ASR推荐
      ),
      path: path,
    );
    _setState(VoiceServiceState.recording);
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
      if (audioPath == null) throw Exception('录音文件为空');

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
      await _cloudTTS(
        text:      translated,
        isChinese: direction == TranslationDirection.foreignToChinese,
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

      try { File(audioPath).deleteSync(); } catch (_) {}
      return result;
    } catch (e) {
      print('⚠️ 语音翻译链路失败: $e');
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

  // ─── 云函数ASR ──────────────────────────────────────────

  Future<String?> _cloudASR({
    required String audioPath,
    AppLanguage?   language,
  }) async {
    try {
      final audioBytes  = await File(audioPath).readAsBytes();
      final base64Audio = base64Encode(audioBytes);

      final langStr = switch (language) {
        AppLanguage.english  => 'en',
        AppLanguage.french   => 'fr',
        AppLanguage.spanish  => 'es',
        _                    => 'zh',
      };

      final result = await ApiClient.post(ApiClient.asrUrl, {
        'audio_base64': base64Audio,
        'language': langStr,
        'format': 'm4a',
      });

      if (result['recognized_text'] != null) {
        return result['recognized_text'] as String;
      }
      print('ASR云函数错误: ${result['error']}');
    } catch (e) {
      print('⚠️ ASR云函数请求失败: $e');
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
      final result = await ApiClient.post(ApiClient.translateUrl, {
        'text': text,
        'source_lang': sourceLang,
        'target_lang': targetLangFinal,
        'context': 'voice_travel', // 语音旅行场景
      });

      if (result['translated_text'] != null) {
        return result['translated_text'] as String;
      }
    } catch (e) {
      print('⚠️ 翻译云函数失败: $e');
    }
    return text; // 降级：返回原文
  }

  // ─── 云函数TTS ──────────────────────────────────────────

  Future<void> _cloudTTS({
    required String text,
    required bool   isChinese,
  }) async {
    try {
      final result = await ApiClient.post(ApiClient.ttsUrl, {
        'text': text,
        'language': isChinese ? 'zh' : 'en',
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
      print('⚠️ TTS云函数失败: $e');
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
