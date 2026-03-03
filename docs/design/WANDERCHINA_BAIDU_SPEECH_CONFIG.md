# WanderChina — 百度语音 API 配置指南

**用途：** 语音翻译功能的 ASR（语音识别）+ TTS（语音合成）  
**更新日期：** 2026-02-13  
**关联文档：** `SCREEN_SPECIFICATIONS_v2.md` · `WANDERCHINA_TENCENT_CLOUD_CONFIG.md`

---

## 目录

1. [服务概述](#1-服务概述)
2. [账号注册与认证](#2-账号注册与认证)
3. [创建应用获取密钥](#3-创建应用获取密钥)
4. [语音识别 ASR 配置](#4-语音识别-asr-配置)
5. [语音合成 TTS 配置](#5-语音合成-tts-配置)
6. [Flutter SDK 集成](#6-flutter-sdk-集成)
7. [Token 管理服务](#7-token-管理服务)
8. [完整代码示例](#8-完整代码示例)
9. [错误处理](#9-错误处理)
10. [性能优化](#10-性能优化)
11. [费用说明](#11-费用说明)
12. [测试验证](#12-测试验证)

---

## 1. 服务概述

### 1.1 功能对应关系

```
语音翻译流程：用户说话 → ASR → DeepSeek 翻译 → TTS → 播放

┌────────────────────────────────────────────────────┐
│  百度 ASR（语音识别）                               │
│  - 输入：音频文件（WAV/PCM/AMR 等）                 │
│  - 输出：文本字符串                                 │
│  - 支持：中文、英文、法语、西班牙语等               │
│  - 延迟：< 1 秒（实时识别）                         │
└────────────────────────────────────────────────────┘
                      ↓
            （DeepSeek 翻译，见其他文档）
                      ↓
┌────────────────────────────────────────────────────┐
│  百度 TTS（语音合成）                               │
│  - 输入：文本字符串（< 1024 字符）                  │
│  - 输出：音频流（MP3）                              │
│  - 支持：中文、英文等多种发音人                     │
│  - 延迟：< 500ms                                    │
└────────────────────────────────────────────────────┘
```

### 1.2 WanderChina 使用场景

| 场景 | ASR 输入语言 | TTS 输出语言 |
|------|-------------|-------------|
| 外国游客问路 | 英文/法文/西文 | 中文（给本地人听） |
| 本地人回答 | 中文 | 英文/法文/西文（给游客听） |
| 餐厅点菜 | 英文 → 中文 | 中文（服务员） |
| 理解菜单 | 中文 → 英文 | 英文（游客） |

---

## 2. 账号注册与认证

### 2.1 注册百度智能云

```
访问: https://cloud.baidu.com
点击: 免费注册 → 手机号验证

实名认证（必需）:
  路径: 控制台 → 账户管理 → 实名认证
  方式: 个人认证（身份证 + 人脸识别）
        或 企业认证（营业执照）
```

> **重要：** 语音服务必须完成实名认证才能调用，否则返回错误码 `110`（未实名）

### 2.2 开通语音服务

```
路径: 控制台 → 产品服务 → 人工智能 → 语音技术

开通服务:
  ✅ 语音识别（短语音识别标准版）
  ✅ 语音合成（在线语音合成标准版）
  
计费方式:
  按量后付费（推荐 MVP 阶段）
  套餐包（后期可购买，更便宜）
```

---

## 3. 创建应用获取密钥

### 3.1 创建应用

```
路径: 控制台 → 语音技术 → 应用列表 → 创建应用

应用信息:
  应用名称: WanderChina
  应用描述: 外国游客中国旅行助手 - 语音翻译功能
  语音识别: 勾选
  语音合成: 勾选
  接口选择: 
    - 短语音识别标准版
    - 在线语音合成标准版
```

### 3.2 获取密钥

创建完成后，进入应用详情页可看到：

```yaml
API Key:        xxxxxxxxxxxxxxxxxxxxxxxx
Secret Key:     xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

> **安全提示：** 不要将密钥硬编码到代码中，使用环境变量管理（见第 6 节）

### 3.3 查看配额

```
免费额度（每个账号）:
  语音识别: 每日 50,000 次调用（≈ 170 万字符）
  语音合成: 每日 100,000 次调用（≈ 500 万字符）

超出后:
  语音识别: ¥1.2/千次
  语音合成: ¥1.2/千次
```

---

## 4. 语音识别 ASR 配置

### 4.1 API 接口信息

```yaml
接口地址: https://vop.baidu.com/server_api

请求方式: POST
Content-Type: application/json

认证方式: Access Token（需先调用 Token API 获取）
```

### 4.2 支持的音频格式

| 格式 | 参数值 | 推荐场景 |
|------|-------|---------|
| PCM (WAV) | `pcm` | 高质量录音 |
| WAV | `wav` | 标准录音文件 |
| AMR | `amr` | 移动端压缩格式 |
| M4A | `m4a` | iOS 默认格式 |

**WanderChina 推荐：** 使用 `pcm`，采样率 16000Hz，单声道

### 4.3 语言参数配置

| 语言 | dev_pid 参数 | 说明 |
|------|-------------|------|
| 中文普通话 | `1537` | 识别中文（含数字、标点） |
| 英语 | `1737` | 识别英文 |
| 法语 | `1837` | 识别法语 |
| 西班牙语 | `1937` | 识别西班牙语 |

### 4.4 请求参数示例

```json
{
  "format": "pcm",
  "rate": 16000,
  "channel": 1,
  "cuid": "user_12345",
  "token": "24.xxxxxxxxxxxxxxxxxxxxxxxx.xxxxxxxx.xxxxxxxx",
  "dev_pid": 1737,
  "speech": "base64编码的音频数据",
  "len": 12800
}
```

**关键参数说明：**

```yaml
format:   音频格式（pcm/wav/amr）
rate:     采样率（8000/16000），推荐 16000
channel:  声道数（1=单声道，2=双声道），必须为 1
cuid:     用户唯一标识（自定义，用于区分用户）
token:    Access Token（每 30 天刷新一次）
dev_pid:  语言模型 ID（见上表）
speech:   音频数据的 Base64 编码
len:      音频数据字节数（非 Base64 后的长度）
```

### 4.5 响应示例

**成功：**
```json
{
  "err_no": 0,
  "err_msg": "success.",
  "corpus_no": "7136717705593707527",
  "sn": "123456789",
  "result": ["where is the subway"]
}
```

**失败：**
```json
{
  "err_no": 3301,
  "err_msg": "音频质量过差"
}
```

---

## 5. 语音合成 TTS 配置

### 5.1 API 接口信息

```yaml
接口地址: https://tsn.baidu.com/text2audio

请求方式: POST
Content-Type: application/x-www-form-urlencoded

认证方式: Access Token
```

### 5.2 支持的发音人

| 发音人 | per 参数 | 音色 | 推荐场景 |
|--------|---------|------|---------|
| 度小宇 | `1` | 男声，沉稳 | 中文导航播报 |
| 度小美 | `0` | 女声，温柔 | 中文翻译结果 ✅ |
| 度逍遥 | `3` | 男声，磁性 | 中文旁白 |
| 度丫丫 | `4` | 女童声 | 儿童场景 |
| 英文女声 | `103` | 女声 | 英文翻译结果 ✅ |

**WanderChina 推荐：**
- 中文合成：使用 `per=0`（度小美）
- 英文合成：使用 `per=103`（英文女声）

### 5.3 请求参数示例

```
tex=地铁站在哪里&
lan=zh&
cuid=user_12345&
ctp=1&
tok=24.xxxxxxxxxxxxxxxxxxxxxxxx.xxxxxxxx.xxxxxxxx&
per=0&
spd=5&
pit=5&
vol=5&
aue=3
```

**关键参数说明：**

```yaml
tex:  要合成的文本（UTF-8，最长 1024 字符）
      需要 URL 编码（中文转 %xx%xx）
lan:  语言（zh=中文，en=英文）
cuid: 用户唯一标识
ctp:  客户端类型（1=Web，固定填 1）
tok:  Access Token
per:  发音人（见上表）
spd:  语速（0-15，默认 5，推荐 5）
pit:  音调（0-15，默认 5，推荐 5）
vol:  音量（0-15，默认 5，推荐 9 偏大）
aue:  音频格式（3=MP3，推荐）
```

### 5.4 响应

**成功：** 直接返回音频二进制流（MP3 格式）

**失败：** 返回 JSON
```json
{
  "err_no": 500,
  "err_msg": "不支持输入",
  "sn": "abcdefgh"
}
```

---

## 6. Flutter SDK 集成

### 6.1 添加依赖

```yaml
# pubspec.yaml
dependencies:
  # HTTP 请求
  http: ^1.1.0
  
  # 音频录制
  record: ^5.0.0
  
  # 音频播放
  audioplayers: ^5.2.1
  
  # 权限管理
  permission_handler: ^11.0.1
  
  # 环境变量
  flutter_dotenv: ^5.1.0
```

### 6.2 环境变量配置

**.env 文件（不提交到 Git）：**

```env
# 百度语音 API
BAIDU_SPEECH_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxx
BAIDU_SPEECH_SECRET_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**.gitignore 添加：**
```
.env
```

**main.dart 加载：**

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const WanderChinaApp());
}
```

### 6.3 创建配置类

```dart
// lib/core/config/baidu_speech_config.dart

class BaiduSpeechConfig {
  /// 从环境变量读取 API Key
  static String get apiKey => 
      dotenv.env['BAIDU_SPEECH_API_KEY'] ?? '';

  /// 从环境变量读取 Secret Key
  static String get secretKey => 
      dotenv.env['BAIDU_SPEECH_SECRET_KEY'] ?? '';

  /// ASR API 地址
  static const String asrUrl = 'https://vop.baidu.com/server_api';

  /// TTS API 地址
  static const String ttsUrl = 'https://tsn.baidu.com/text2audio';

  /// Token API 地址
  static const String tokenUrl =
      'https://aip.baidubce.com/oauth/2.0/token';

  /// 音频配置
  static const int sampleRate = 16000;      // 采样率
  static const String audioFormat = 'pcm';  // 格式
  static const int audioChannel = 1;        // 单声道

  /// 语言模型配置
  static const Map<String, int> devPidMap = {
    'zh': 1537,  // 中文普通话
    'en': 1737,  // 英语
    'fr': 1837,  // 法语
    'es': 1937,  // 西班牙语
  };

  /// TTS 发音人配置
  static const Map<String, int> voicePersonMap = {
    'zh': 0,    // 度小美（中文女声）
    'en': 103,  // 英文女声
    'fr': 0,    // 暂用度小美（百度法语 TTS 支持有限）
    'es': 0,    // 暂用度小美
  };
}
```

---

## 7. Token 管理服务

百度语音 API 需要先获取 Access Token，Token 有效期为 **30 天**。

### 7.1 Token 服务实现

```dart
// lib/services/baidu/baidu_token_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/baidu_speech_config.dart';

class BaiduTokenService {
  static const String _tokenKey = 'baidu_access_token';
  static const String _expiryKey = 'baidu_token_expiry';

  /// 获取有效的 Access Token（自动刷新）
  static Future<String?> getValidToken() async {
    final prefs = await SharedPreferences.getInstance();

    // 检查本地是否有未过期的 Token
    final token = prefs.getString(_tokenKey);
    final expiry = prefs.getInt(_expiryKey);

    if (token != null && expiry != null) {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (now < expiry - 86400) {  // 提前 1 天刷新
        return token;
      }
    }

    // Token 过期或不存在，重新获取
    return await _fetchNewToken();
  }

  /// 从百度服务器获取新 Token
  static Future<String?> _fetchNewToken() async {
    try {
      final response = await http.post(
        Uri.parse(BaiduSpeechConfig.tokenUrl).replace(
          queryParameters: {
            'grant_type': 'client_credentials',
            'client_id': BaiduSpeechConfig.apiKey,
            'client_secret': BaiduSpeechConfig.secretKey,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['access_token'] as String;
        final expiresIn = data['expires_in'] as int;  // 秒数，通常是 2592000（30天）

        // 保存到本地
        final prefs = await SharedPreferences.getInstance();
        final expiry = DateTime.now().millisecondsSinceEpoch ~/ 1000 + expiresIn;
        
        await prefs.setString(_tokenKey, token);
        await prefs.setInt(_expiryKey, expiry);

        print('✅ 百度 Token 刷新成功，有效期至: ${DateTime.fromMillisecondsSinceEpoch(expiry * 1000)}');
        return token;
      }

      print('❌ Token 获取失败: ${response.statusCode}');
      return null;
    } catch (e) {
      print('❌ Token 获取异常: $e');
      return null;
    }
  }

  /// 手动清除 Token（用于调试）
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_expiryKey);
  }
}
```

---

## 8. 完整代码示例

### 8.1 ASR 语音识别服务

```dart
// lib/services/baidu/baidu_asr_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/config/baidu_speech_config.dart';
import 'baidu_token_service.dart';

class BaiduASRService {
  
  /// 识别音频文件，返回文本
  Future<String?> recognize({
    required File audioFile,
    required String language,  // 'zh' / 'en' / 'fr' / 'es'
  }) async {
    try {
      // 1. 获取 Access Token
      final token = await BaiduTokenService.getValidToken();
      if (token == null) {
        throw Exception('Failed to get access token');
      }

      // 2. 读取音频文件并转 Base64
      final audioBytes = await audioFile.readAsBytes();
      final audioBase64 = base64Encode(audioBytes);

      // 3. 获取语言对应的 dev_pid
      final devPid = BaiduSpeechConfig.devPidMap[language] ?? 1537;

      // 4. 构建请求
      final response = await http.post(
        Uri.parse(BaiduSpeechConfig.asrUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'format': BaiduSpeechConfig.audioFormat,
          'rate': BaiduSpeechConfig.sampleRate,
          'channel': BaiduSpeechConfig.audioChannel,
          'cuid': 'wanderchina_${DateTime.now().millisecondsSinceEpoch}',
          'token': token,
          'dev_pid': devPid,
          'speech': audioBase64,
          'len': audioBytes.length,
        }),
      );

      // 5. 解析响应
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['err_no'] == 0) {
          final result = data['result'] as List;
          return result.isNotEmpty ? result.first : null;
        } else {
          print('❌ ASR 识别失败: ${data['err_msg']}');
          return null;
        }
      }

      print('❌ ASR 请求失败: ${response.statusCode}');
      return null;

    } catch (e) {
      print('❌ ASR 异常: $e');
      return null;
    }
  }
}
```

### 8.2 TTS 语音合成服务

```dart
// lib/services/baidu/baidu_tts_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../core/config/baidu_speech_config.dart';
import 'baidu_token_service.dart';

class BaiduTTSService {
  
  /// 合成语音，返回音频字节流
  Future<Uint8List?> synthesize({
    required String text,
    required String language,  // 'zh' / 'en' / 'fr' / 'es'
    int voiceSpeed = 5,        // 语速 0-15
    int voicePitch = 5,        // 音调 0-15
    int voiceVolume = 9,       // 音量 0-15
  }) async {
    try {
      // 1. 获取 Access Token
      final token = await BaiduTokenService.getValidToken();
      if (token == null) {
        throw Exception('Failed to get access token');
      }

      // 2. 获取语言对应的发音人
      final person = BaiduSpeechConfig.voicePersonMap[language] ?? 0;

      // 3. URL 编码文本
      final encodedText = Uri.encodeComponent(text);

      // 4. 构建请求
      final url = Uri.parse(BaiduSpeechConfig.ttsUrl).replace(
        queryParameters: {
          'tex': encodedText,
          'lan': language == 'en' ? 'en' : 'zh',
          'cuid': 'wanderchina_${DateTime.now().millisecondsSinceEpoch}',
          'ctp': '1',
          'tok': token,
          'per': person.toString(),
          'spd': voiceSpeed.toString(),
          'pit': voicePitch.toString(),
          'vol': voiceVolume.toString(),
          'aue': '3',  // MP3 格式
        },
      );

      final response = await http.post(url);

      // 5. 检查响应
      if (response.statusCode == 200) {
        // 如果返回 JSON，说明出错了
        if (response.headers['content-type']?.contains('application/json') ?? false) {
          final error = json.decode(response.body);
          print('❌ TTS 合成失败: ${error['err_msg']}');
          return null;
        }

        // 返回音频流
        return response.bodyBytes;
      }

      print('❌ TTS 请求失败: ${response.statusCode}');
      return null;

    } catch (e) {
      print('❌ TTS 异常: $e');
      return null;
    }
  }

  /// 直接播放合成的语音
  Future<void> speakText({
    required String text,
    required String language,
  }) async {
    final audioBytes = await synthesize(
      text: text,
      language: language,
    );

    if (audioBytes != null) {
      // 使用 audioplayers 播放
      final player = AudioPlayer();
      await player.play(BytesSource(audioBytes));
    }
  }
}
```

### 8.3 集成服务（供 UI 调用）

```dart
// lib/services/voice/voice_translation_service.dart

import 'dart:io';
import 'dart:typed_data';
import '../baidu/baidu_asr_service.dart';
import '../baidu/baidu_tts_service.dart';
import '../deepseek/deepseek_service.dart';

class VoiceTranslationService {
  final BaiduASRService _asr = BaiduASRService();
  final BaiduTTSService _tts = BaiduTTSService();
  final DeepSeekService _translator = DeepSeekService();

  /// 完整的语音翻译流程
  /// 
  /// [audioFile] 录制的音频文件
  /// [sourceLanguage] 源语言 'zh' / 'en' / 'fr' / 'es'
  /// [targetLanguage] 目标语言
  /// 
  /// 返回：(识别文本, 翻译文本, 语音字节流)
  Future<VoiceTranslationResult?> translate({
    required File audioFile,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    try {
      // ① ASR 识别
      print('🎤 开始语音识别...');
      final recognizedText = await _asr.recognize(
        audioFile: audioFile,
        language: sourceLanguage,
      );

      if (recognizedText == null || recognizedText.isEmpty) {
        throw Exception('语音识别失败');
      }
      print('✅ 识别结果: $recognizedText');

      // ② DeepSeek 翻译
      print('🌐 开始翻译...');
      final translatedText = await _translator.translate(
        text: recognizedText,
        from: sourceLanguage,
        to: targetLanguage,
      );
      print('✅ 翻译结果: $translatedText');

      // ③ TTS 合成
      print('🔊 开始语音合成...');
      final audioBytes = await _tts.synthesize(
        text: translatedText,
        language: targetLanguage,
      );

      if (audioBytes == null) {
        throw Exception('语音合成失败');
      }
      print('✅ 合成完成，音频大小: ${audioBytes.length} bytes');

      return VoiceTranslationResult(
        originalText: recognizedText,
        translatedText: translatedText,
        audioBytes: audioBytes,
        processingTime: DateTime.now().millisecondsSinceEpoch,
      );

    } catch (e) {
      print('❌ 语音翻译失败: $e');
      return null;
    }
  }
}

/// 翻译结果模型
class VoiceTranslationResult {
  final String originalText;
  final String translatedText;
  final Uint8List audioBytes;
  final int processingTime;

  VoiceTranslationResult({
    required this.originalText,
    required this.translatedText,
    required this.audioBytes,
    required this.processingTime,
  });
}
```

---

## 9. 错误处理

### 9.1 常见错误码

| 错误码 | 说明 | 解决方法 |
|--------|------|---------|
| `110` | 未实名认证 | 完成百度云实名认证 |
| `111` | Access Token 过期 | 调用 Token 刷新接口 |
| `3300` | 输入参数不正确 | 检查 `dev_pid`、`rate` 等参数 |
| `3301` | 音频质量过差 | 提高录音质量，使用降噪 |
| `3302` | 鉴权失败 | 检查 API Key / Secret Key |
| `3303` | 语音服务器后端问题 | 稍后重试 |
| `500` | 不支持输入（TTS） | 文本包含非法字符 |
| `501` | 输入参数不正确 | 检查文本长度（< 1024） |
| `502` | Token 验证失败 | 重新获取 Token |

### 9.2 错误处理示例

```dart
Future<String?> recognizeWithRetry({
  required File audioFile,
  required String language,
  int maxRetries = 3,
}) async {
  for (int i = 0; i < maxRetries; i++) {
    try {
      final result = await _asr.recognize(
        audioFile: audioFile,
        language: language,
      );

      if (result != null) return result;

      // 失败后等待 1 秒重试
      await Future.delayed(const Duration(seconds: 1));

    } catch (e) {
      if (i == maxRetries - 1) {
        // 最后一次重试失败，抛出异常
        rethrow;
      }
    }
  }
  return null;
}
```

---

## 10. 性能优化

### 10.1 音频质量优化

```dart
// 录音时使用优化参数
final config = RecordConfig(
  encoder: AudioEncoder.pcm16bits,  // 16-bit PCM
  sampleRate: 16000,                // 16kHz
  numChannels: 1,                   // 单声道
  autoGain: true,                   // 自动增益
  echoCancel: true,                 // 回声消除
  noiseSuppress: true,              // 降噪
);

await record.start(config, path: audioPath);
```

### 10.2 缓存策略

```dart
// 缓存常用短语的 TTS 音频
class TTSCacheService {
  static final Map<String, Uint8List> _cache = {};

  static Future<Uint8List?> getCachedAudio(String text, String lang) async {
    final key = '$lang:$text';
    
    if (_cache.containsKey(key)) {
      return _cache[key];
    }

    // 未缓存，合成并缓存
    final tts = BaiduTTSService();
    final audio = await tts.synthesize(text: text, language: lang);
    
    if (audio != null) {
      _cache[key] = audio;
    }
    
    return audio;
  }
}
```

### 10.3 并发限制

```dart
// 使用队列避免同时发起过多请求
class RequestQueue {
  final int maxConcurrent = 3;
  int _activeRequests = 0;
  final List<Future Function()> _queue = [];

  Future<T> enqueue<T>(Future<T> Function() task) async {
    while (_activeRequests >= maxConcurrent) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _activeRequests++;
    try {
      return await task();
    } finally {
      _activeRequests--;
    }
  }
}
```

---

## 11. 费用说明

### 11.1 免费额度

```
语音识别（ASR）:
  每日免费: 50,000 次调用
  每月免费: 约 150 万次（按 30 天计）

语音合成（TTS）:
  每日免费: 100,000 次调用
  每月免费: 约 300 万次

免费期限: 永久（个人/企业认证后）
```

### 11.2 超额计费

```
语音识别: ¥1.2/千次
语音合成: ¥1.2/千次

计费周期: 按月结算
```

### 11.3 WanderChina 预估（1000 MAU）

```
假设每用户每天使用 5 次语音翻译:
  ASR 调用: 1000 用户 × 30 天 × 5 次 = 150,000 次/月
  TTS 调用: 150,000 次/月

费用:
  ASR: 免费（< 150万/月）
  TTS: 免费（< 300万/月）

结论: MVP 阶段完全免费
```

### 11.4 成长阶段（10,000 MAU）

```
ASR: 1,500,000 次/月
TTS: 1,500,000 次/月

费用:
  ASR: (1,500,000 - 1,500,000) × ¥1.2/1000 = ¥0（刚好在免费额度内）
  TTS: (1,500,000 - 3,000,000) × ¥1.2/1000 = ¥0（在额度内）

结论: 1 万月活仍然免费
```

> 百度的免费额度非常慷慨，对于 MVP 和早期增长阶段基本无需付费

---

## 12. 测试验证

### 12.1 Token 获取测试

```dart
void testTokenService() async {
  final token = await BaiduTokenService.getValidToken();
  
  if (token != null) {
    print('✅ Token 获取成功: ${token.substring(0, 20)}...');
  } else {
    print('❌ Token 获取失败');
  }
}
```

### 12.2 ASR 测试

```dart
void testASR() async {
  final asr = BaiduASRService();
  
  // 准备一个测试音频文件（16kHz PCM）
  final audioFile = File('test_audio.pcm');
  
  final result = await asr.recognize(
    audioFile: audioFile,
    language: 'en',
  );
  
  print('识别结果: $result');
}
```

### 12.3 TTS 测试

```dart
void testTTS() async {
  final tts = BaiduTTSService();
  
  await tts.speakText(
    text: '欢迎使用 WanderChina',
    language: 'zh',
  );
}
```

### 12.4 完整流程测试

```dart
void testFullPipeline() async {
  final service = VoiceTranslationService();
  
  final audioFile = File('test_english.pcm');
  
  final result = await service.translate(
    audioFile: audioFile,
    sourceLanguage: 'en',
    targetLanguage: 'zh',
  );
  
  if (result != null) {
    print('原文: ${result.originalText}');
    print('译文: ${result.translatedText}');
    print('音频大小: ${result.audioBytes.length} bytes');
    
    // 播放翻译结果
    final player = AudioPlayer();
    await player.play(BytesSource(result.audioBytes));
  }
}
```

---

## 附录 A：权限配置

### Android (android/app/src/main/AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### iOS (ios/Runner/Info.plist)

```xml
<key>NSMicrophoneUsageDescription</key>
<string>WanderChina 需要访问麦克风以提供语音翻译功能</string>
```

---

## 附录 B：依赖包完整列表

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter

  # HTTP 请求
  http: ^1.1.0

  # 本地存储（缓存 Token）
  shared_preferences: ^2.2.2

  # 环境变量
  flutter_dotenv: ^5.1.0

  # 音频录制
  record: ^5.0.0

  # 音频播放
  audioplayers: ^5.2.1

  # 权限请求
  permission_handler: ^11.0.1
```

---

**文档版本：** 1.0  
**关联服务：** DeepSeek 翻译（文本翻译）  
**下一步：** 集成 DeepSeek API 完成翻译链路
