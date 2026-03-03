import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import '../../models/poi_translation.dart';
import '../../core/config/backend_config.dart';

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

  static const String _baiduASRUrl   = 'https://vop.baidu.com/server_api';
  static const String _baiduTTSUrl   = 'https://tsn.baidu.com/text2audio';
  static const String _baiduTokenUrl =
      'https://aip.baidubce.com/oauth/2.0/token';

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer   _player   = AudioPlayer();

  VoiceServiceState _state = VoiceServiceState.idle;
  VoiceServiceState get state => _state;

  String?   _baiduAccessToken;
  DateTime? _tokenExpiry;

  final List<VoiceTranslationResult> _history = [];
  List<VoiceTranslationResult> get history => List.unmodifiable(_history);

  // ─── 初始化 ───────────────────────────────────────────

  Future<void> initialize() async {
    await _refreshBaiduToken();
    print('✅ VoiceTranslationService initialized');
  }

  Future<void> _refreshBaiduToken() async {
    try {
      final response = await http.post(
        Uri.parse(_baiduTokenUrl),
        body: {
          'grant_type':    'client_credentials',
          'client_id':     BackendConfig.baiduApiKey,
          'client_secret': BackendConfig.baiduSecretKey,
        },
      );
      if (response.statusCode == 200) {
        final data           = jsonDecode(response.body);
        _baiduAccessToken    = data['access_token'] as String;
        _tokenExpiry         = DateTime.now().add(const Duration(days: 29));
        print('✅ 百度Token获取成功');
      }
    } catch (e) {
      print('⚠️ 百度Token获取失败: $e');
    }
  }

  Future<String?> get _validToken async {
    if (_baiduAccessToken == null ||
        (_tokenExpiry != null && DateTime.now().isAfter(_tokenExpiry!))) {
      await _refreshBaiduToken();
    }
    return _baiduAccessToken;
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

      // Step 1: 百度ASR
      final sourceLang = direction == TranslationDirection.foreignToChinese
          ? foreignLanguage
          : null;
      final recognized = await _baiduASR(audioPath: audioPath, language: sourceLang);
      if (recognized == null || recognized.isEmpty) {
        throw Exception('语音识别失败或无声音');
      }

      // Step 2: DeepSeek翻译
      final translated = await _deepSeekTranslate(
        text:           recognized,
        direction:      direction,
        foreignLanguage: foreignLanguage,
      );

      // Step 3: 百度TTS播放
      await _baiduTTS(
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

  // ─── 百度ASR ──────────────────────────────────────────

  Future<String?> _baiduASR({
    required String audioPath,
    AppLanguage?   language,
  }) async {
    final token = await _validToken;
    if (token == null) throw Exception('百度Token无效');

    final audioBytes  = await File(audioPath).readAsBytes();
    final base64Audio = base64Encode(audioBytes);

    // 百度ASR dev_pid: 1537中文, 1737英文, 1836法文, 1936西班牙文
    final langId = switch (language) {
      AppLanguage.english  => 1737,
      AppLanguage.french   => 1836,
      AppLanguage.spanish  => 1936,
      _                    => 1537,
    };

    try {
      final response = await http.post(
        Uri.parse(_baiduASRUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'format':  'm4a',
          'rate':    16000,
          'channel': 1,
          'cuid':    'wanderchina_app',
          'token':   token,
          'dev_pid': langId,
          'speech':  base64Audio,
          'len':     audioBytes.length,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['err_no'] == 0 && data['result'] != null) {
          final results = data['result'] as List;
          return results.isNotEmpty ? results.first as String : null;
        }
        print('百度ASR错误: ${data['err_msg']}');
      }
    } catch (e) {
      print('⚠️ 百度ASR请求失败: $e');
    }
    return null;
  }

  // ─── DeepSeek翻译 ─────────────────────────────────────

  Future<String> _deepSeekTranslate({
    required String text,
    required TranslationDirection direction,
    required AppLanguage foreignLanguage,
  }) async {
    final targetLangName = switch (foreignLanguage) {
      AppLanguage.english  => 'English',
      AppLanguage.french   => 'French',
      AppLanguage.spanish  => 'Spanish',
    };

    final String systemPrompt;
    final String userPrompt;

    if (direction == TranslationDirection.foreignToChinese) {
      systemPrompt =
          'You are a travel interpreter. Translate to natural spoken Chinese (Mandarin). '
          'Keep it concise for everyday situations. Return ONLY the Chinese translation.';
      userPrompt = 'Translate this $targetLangName to Chinese: "$text"';
    } else {
      systemPrompt =
          'You are a travel interpreter. Translate Chinese to natural $targetLangName. '
          'Add brief cultural context if helpful (e.g., "100块 (¥100 ≈ \$14)"). '
          'Return ONLY the $targetLangName translation.';
      userPrompt = 'Translate this Chinese to $targetLangName: "$text"';
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.deepseek.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${BackendConfig.deepseekApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'temperature': 0.2,
          'max_tokens':  300,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['choices'][0]['message']['content'] as String).trim();
      }
    } catch (e) {
      print('⚠️ DeepSeek翻译失败: $e');
    }
    return text; // 降级：返回原文
  }

  // ─── 百度TTS ──────────────────────────────────────────

  Future<void> _baiduTTS({
    required String text,
    required bool   isChinese,
  }) async {
    final token = await _validToken;
    if (token == null) return;

    // per: 4=中文情感女声, 5=英文女声
    final per = isChinese ? 4 : 5;

    try {
      final uri = Uri.parse(_baiduTTSUrl).replace(queryParameters: {
        'tex': text,
        'tok': token,
        'cuid': 'wanderchina_app',
        'ctp':  '1',
        'lan':  isChinese ? 'zh' : 'en',
        'spd':  '5',
        'pit':  '5',
        'vol':  '10',
        'per':  per.toString(),
        'aue':  '3', // mp3
      });

      final response =
          await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 &&
          response.headers['content-type']?.contains('audio') == true) {
        final dir     = await getTemporaryDirectory();
        final ttsPath =
            '${dir.path}/wander_tts_${DateTime.now().millisecondsSinceEpoch}.mp3';
        await File(ttsPath).writeAsBytes(response.bodyBytes);

        _setState(VoiceServiceState.playing);
        await _player.play(DeviceFileSource(ttsPath));

        _player.onPlayerComplete.first.then((_) {
          try { File(ttsPath).deleteSync(); } catch (_) {}
          _setState(VoiceServiceState.idle);
        });
      }
    } catch (e) {
      print('⚠️ 百度TTS失败: $e');
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
