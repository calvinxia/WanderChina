# WanderChina — 百度语音 API 配置指南

**用途：** 语音翻译功能的 ASR（语音识别）+ TTS（语音合成）
**更新日期：** 2026-03-02（v2.0，安全架构重构）
**关联文档：** `WANDERCHINA_TENCENT_CLOUD_CONFIG v2.0`

---

## ⚠️ v2.0 重要变更

**v1.0 架构（已废弃）：** Flutter 直接调用百度 API，API Key 存储在 App .env 中
**v2.0 架构（当前）：** Flutter → 云函数 → 百度 API，API Key 仅存在于云端

```
v1.0（安全隐患）:
  Flutter .env 存放 BAIDU_API_KEY + SECRET_KEY
  → 反编译 APK 即可提取密钥
  → 被滥用后无法止血

v2.0（安全架构）:
  Flutter .env 仅存函数 URL（无密钥）
  → 百度密钥在云函数环境变量
  → 泄露时重置环境变量即可
```

---

## 目录

1. [服务概述](#1-服务概述)
2. [账号注册与认证](#2-账号注册与认证)
3. [创建应用获取密钥](#3-创建应用获取密钥)
4. [语音识别 ASR 配置](#4-语音识别-asr-配置)
5. [语音合成 TTS 配置](#5-语音合成-tts-配置)
6. [云函数实现](#6-云函数实现)
7. [Flutter 端集成](#7-flutter-端集成)
8. [错误处理](#8-错误处理)
9. [性能优化](#9-性能优化)
10. [费用说明](#10-费用说明)
11. [测试验证](#11-测试验证)
12. [部署检查清单](#12-部署检查清单)

---

## 1. 服务概述

### 1.1 语音翻译流程

```
用户说话 → Flutter 录音
  → baidu_voice_asr 云函数 → 百度 ASR API → 文本
  → deepseek_translate 云函数 → DeepSeek API → 翻译文本
  → baidu_voice_tts 云函数 → 百度 TTS API → 音频
  → Flutter 播放
```

### 1.2 使用场景

| 场景 | ASR 输入 | TTS 输出 |
|------|---------|---------|
| 外国游客问路 | 英文 → 文本 | 中文语音（给本地人听） |
| 本地人回答 | 中文 → 文本 | 英文语音（给游客听） |
| 餐厅点菜 | 英文 → 中文文本 | 中文语音（服务员听） |

---

## 2. 账号注册与认证

```
访问: https://cloud.baidu.com → 免费注册

实名认证（必需，否则返回错误 110）:
  控制台 → 账户管理 → 实名认证
  方式: 个人认证（身份证 + 人脸）或 企业认证

开通服务:
  控制台 → 产品服务 → 人工智能 → 语音技术
  ✅ 短语音识别标准版
  ✅ 在线语音合成标准版
```

---

## 3. 创建应用获取密钥

```
控制台 → 语音技术 → 应用列表 → 创建应用

  应用名称: WanderChina
  勾选: 短语音识别标准版 + 在线语音合成标准版

创建后获取:
  API Key:     xxxxxxxxxxxxxxxxxxxxxxxx
  Secret Key:  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

⚠️ 密钥只存放在云函数环境变量中，不写入 Flutter 代码或 .env
```

---

## 4. 语音识别 ASR 配置

### 4.1 API 信息

```yaml
接口: POST https://vop.baidu.com/server_api
Content-Type: application/json
认证: Access Token（Token API 获取，30 天有效）
```

### 4.2 音频要求

```yaml
格式:    pcm（推荐）/ wav / amr / m4a
采样率:  16000 Hz
声道:    单声道
时长:    ≤ 60 秒
大小:    ≤ 10 MB
```

### 4.3 语言参数

| 语言 | dev_pid | 说明 |
|------|---------|------|
| 中文普通话 | 1537 | 识别中文 |
| 英语 | 1737 | 识别英文 |
| 法语 | 1837 | 识别法语 |
| 西班牙语 | 1937 | 识别西班牙语 |

### 4.4 请求示例

```json
{
  "format": "pcm",
  "rate": 16000,
  "channel": 1,
  "cuid": "user_device_id",
  "token": "24.xxxxxxxx.xxxxxxxx.xxxxxxxx",
  "dev_pid": 1737,
  "speech": "base64编码的音频数据",
  "len": 12800
}
```

### 4.5 响应

```json
{"err_no": 0, "err_msg": "success.", "result": ["where is the subway"]}
```

---

## 5. 语音合成 TTS 配置

### 5.1 API 信息

```yaml
接口: POST https://tsn.baidu.com/text2audio
Content-Type: application/x-www-form-urlencoded
响应: 成功返回 MP3 二进制流，失败返回 JSON
```

### 5.2 发音人

| 发音人 | per | 用途 |
|--------|-----|------|
| 度小美 | 0 | 中文女声 ✅ |
| 度小宇 | 1 | 中文男声 |
| 英文女声 | 103 | 英文/法文/西文 ✅ |

> **注意：** 百度 TTS 暂无原生法语/西班牙语发音人。MVP 阶段法/西翻译结果使用英文发音人（per=103）朗读英文翻译版本，或仅显示文本不合成语音。

### 5.3 关键参数

```yaml
tex:  文本（UTF-8，URL 编码，≤ 1024 字符）
lan:  语言（zh / en）
per:  发音人（见上表）
spd:  语速（0-15，推荐 5）
pit:  音调（0-15，推荐 5）
vol:  音量（0-15，推荐 9）
aue:  格式（3=MP3）
```

---

## 6. 云函数实现

### 6.1 公网函数：baidu_voice_asr

**基础配置（腾讯云控制台）：**

```yaml
函数名称:   baidu_voice_asr
运行环境:   Python 3.9
内存:       256 MB
超时:       15 秒
VPC:        不启用（公网函数）

环境变量:
  BAIDU_API_KEY:     xxxxxxxx
  BAIDU_SECRET_KEY:  xxxxxxxx

触发器:     函数 URL（免鉴权 + CORS）
```

**函数代码 `index.py`：**

```python
# baidu_voice_asr/index.py
# -*- coding: utf-8 -*-
"""
百度语音识别云函数
- 百度密钥仅在云端，Flutter 不接触
- 自动管理 Access Token（30 天有效）
"""
import json
import os
import time
import requests

# ===== Token 管理（全局缓存）=====
_token_cache = {'token': None, 'expires': 0}

def get_access_token():
    """获取百度 Access Token（自动缓存 + 刷新）"""
    global _token_cache
    now = int(time.time())

    # 提前 1 天刷新
    if _token_cache['token'] and now < _token_cache['expires'] - 86400:
        return _token_cache['token']

    api_key = os.environ.get('BAIDU_API_KEY')
    secret_key = os.environ.get('BAIDU_SECRET_KEY')
    if not api_key or not secret_key:
        raise ValueError('Missing BAIDU_API_KEY or BAIDU_SECRET_KEY')

    url = 'https://aip.baidubce.com/oauth/2.0/token'
    params = {
        'grant_type': 'client_credentials',
        'client_id': api_key,
        'client_secret': secret_key,
    }

    resp = requests.post(url, params=params, timeout=10)
    resp.raise_for_status()
    data = resp.json()

    token = data['access_token']
    expires_in = data.get('expires_in', 2592000)  # 默认 30 天

    _token_cache = {
        'token': token,
        'expires': now + expires_in
    }
    print(f"[TOKEN] 百度 Token 刷新成功，有效期 {expires_in // 86400} 天")
    return token

# ===== 语言配置 =====
DEV_PID_MAP = {
    'zh': 1537,
    'en': 1737,
    'fr': 1837,
    'es': 1937,
}

def json_response(code, body):
    return {
        'statusCode': code,
        'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
        'body': json.dumps(body, ensure_ascii=False)
    }

def main_handler(event, context):
    """
    输入: {"audio_base64": "...", "language": "en", "audio_len": 12800}
    输出: {"text": "where is the subway", "err_no": 0}
    """
    try:
        if isinstance(event, dict) and 'body' in event:
            body = json.loads(event['body'])
        else:
            body = event

        audio_base64 = body.get('audio_base64')
        language = body.get('language', 'zh')
        audio_len = body.get('audio_len')

        if not audio_base64 or not audio_len:
            return json_response(400, {'error': 'Missing audio_base64 or audio_len'})

        if language not in DEV_PID_MAP:
            return json_response(400, {'error': f'Unsupported language: {language}'})

        # 获取 Token
        token = get_access_token()

        # 调用百度 ASR
        resp = requests.post(
            'https://vop.baidu.com/server_api',
            headers={'Content-Type': 'application/json'},
            json={
                'format': 'pcm',
                'rate': 16000,
                'channel': 1,
                'cuid': body.get('device_id', 'wanderchina'),
                'token': token,
                'dev_pid': DEV_PID_MAP[language],
                'speech': audio_base64,
                'len': audio_len,
            },
            timeout=10
        )

        result = resp.json()
        err_no = result.get('err_no', -1)

        if err_no == 0:
            text = result['result'][0] if result.get('result') else ''
            print(f"[ASR] lang={language} | result='{text[:50]}'")
            return json_response(200, {'text': text, 'err_no': 0})
        else:
            print(f"[ASR ERROR] err_no={err_no}, err_msg={result.get('err_msg')}")
            return json_response(200, {
                'text': None,
                'err_no': err_no,
                'err_msg': result.get('err_msg', 'Unknown error')
            })

    except Exception as e:
        print(f"[ASR EXCEPTION] {str(e)}")
        import traceback; traceback.print_exc()
        return json_response(500, {'error': str(e)})
```

### 6.2 公网函数：baidu_voice_tts

**基础配置：** 与 ASR 相同（公网，无 VPC，同环境变量）

```python
# baidu_voice_tts/index.py
# -*- coding: utf-8 -*-
"""
百度语音合成云函数
- 返回 MP3 音频的 Base64 编码（便于 JSON 传输）
- 中文用度小美（per=0），英/法/西用英文女声（per=103）
"""
import json
import os
import time
import base64
import requests
import urllib.parse

_token_cache = {'token': None, 'expires': 0}

def get_access_token():
    global _token_cache
    now = int(time.time())
    if _token_cache['token'] and now < _token_cache['expires'] - 86400:
        return _token_cache['token']

    resp = requests.post(
        'https://aip.baidubce.com/oauth/2.0/token',
        params={
            'grant_type': 'client_credentials',
            'client_id': os.environ['BAIDU_API_KEY'],
            'client_secret': os.environ['BAIDU_SECRET_KEY'],
        },
        timeout=10
    )
    resp.raise_for_status()
    data = resp.json()
    _token_cache = {
        'token': data['access_token'],
        'expires': now + data.get('expires_in', 2592000)
    }
    return _token_cache['token']

# 发音人配置
VOICE_MAP = {
    'zh': {'per': 0, 'lan': 'zh'},    # 度小美
    'en': {'per': 103, 'lan': 'en'},   # 英文女声
    'fr': {'per': 103, 'lan': 'en'},   # 法/西暂用英文发音人
    'es': {'per': 103, 'lan': 'en'},   # 用户听到英文翻译版本
}

def json_response(code, body):
    return {
        'statusCode': code,
        'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
        'body': json.dumps(body, ensure_ascii=False)
    }

def main_handler(event, context):
    """
    输入: {"text": "地铁站在哪里", "language": "zh"}
    输出: {"audio_base64": "...", "format": "mp3"} 或 {"error": "..."}
    """
    try:
        if isinstance(event, dict) and 'body' in event:
            body = json.loads(event['body'])
        else:
            body = event

        text = body.get('text', '').strip()
        language = body.get('language', 'zh')

        if not text:
            return json_response(400, {'error': 'Missing text'})
        if len(text) > 1024:
            return json_response(400, {'error': 'Text exceeds 1024 characters'})

        token = get_access_token()
        voice = VOICE_MAP.get(language, VOICE_MAP['en'])

        # 百度 TTS 要求 URL 编码
        encoded_text = urllib.parse.quote(text)

        resp = requests.post(
            'https://tsn.baidu.com/text2audio',
            data={
                'tex': encoded_text,
                'lan': voice['lan'],
                'cuid': body.get('device_id', 'wanderchina'),
                'ctp': '1',
                'tok': token,
                'per': str(voice['per']),
                'spd': str(body.get('speed', 5)),
                'pit': str(body.get('pitch', 5)),
                'vol': str(body.get('volume', 9)),
                'aue': '3',  # MP3
            },
            timeout=10
        )

        # 判断是否成功（成功返回音频流，失败返回 JSON）
        content_type = resp.headers.get('Content-Type', '')
        if 'audio' in content_type or 'octet-stream' in content_type:
            audio_b64 = base64.b64encode(resp.content).decode('utf-8')
            print(f"[TTS] lang={language} | text='{text[:30]}' | size={len(resp.content)}b")
            return json_response(200, {
                'audio_base64': audio_b64,
                'format': 'mp3',
                'size': len(resp.content)
            })
        else:
            # 失败，返回错误
            error = resp.json() if resp.text else {'err_msg': 'Unknown error'}
            print(f"[TTS ERROR] {error}")
            return json_response(200, {
                'audio_base64': None,
                'error': error.get('err_msg', 'TTS failed')
            })

    except Exception as e:
        print(f"[TTS EXCEPTION] {str(e)}")
        import traceback; traceback.print_exc()
        return json_response(500, {'error': str(e)})
```

**requirements.txt（ASR + TTS 共用）：**
```
requests==2.31.0
```

---

## 7. Flutter 端集成

> **核心原则：Flutter 只调用云函数 URL，不存储百度密钥。**

### 7.1 依赖

```yaml
dependencies:
  http: ^1.1.0
  record: ^5.0.0
  audioplayers: ^5.2.1
  permission_handler: ^11.0.1
  flutter_dotenv: ^5.1.0
```

### 7.2 .env 配置（仅 URL，无密钥）

```env
ASR_URL=https://service-xxx.gz.tencentcs.com/
TTS_URL=https://service-xxx.gz.tencentcs.com/
TRANSLATE_URL=https://service-xxx.gz.tencentcs.com/
```

### 7.3 语音识别服务

```dart
// lib/services/voice/asr_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ASRService {
  static String get _asrUrl => dotenv.env['ASR_URL']!;

  /// 识别音频文件
  static Future<String?> recognize({
    required File audioFile,
    required String language,
  }) async {
    try {
      final bytes = await audioFile.readAsBytes();
      final audioBase64 = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(_asrUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'audio_base64': audioBase64,
          'audio_len': bytes.length,
          'language': language,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['err_no'] == 0) {
          return data['text'];
        }
        print('ASR error: ${data['err_msg']}');
      }
      return null;
    } catch (e) {
      print('ASR failed: $e');
      return null;
    }
  }
}
```

### 7.4 语音合成服务

```dart
// lib/services/voice/tts_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:audioplayers/audioplayers.dart';

class TTSService {
  static String get _ttsUrl => dotenv.env['TTS_URL']!;
  static final AudioPlayer _player = AudioPlayer();

  /// 合成语音，返回 MP3 字节流
  static Future<Uint8List?> synthesize({
    required String text,
    required String language,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_ttsUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'text': text,
          'language': language,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['audio_base64'] != null) {
          return base64Decode(data['audio_base64']);
        }
        print('TTS error: ${data['error']}');
      }
      return null;
    } catch (e) {
      print('TTS failed: $e');
      return null;
    }
  }

  /// 合成并直接播放
  static Future<void> speak({
    required String text,
    required String language,
  }) async {
    final audio = await synthesize(text: text, language: language);
    if (audio != null) {
      await _player.play(BytesSource(audio));
    }
  }
}
```

### 7.5 完整语音翻译流程

```dart
// lib/services/voice/voice_translation_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'asr_service.dart';
import 'tts_service.dart';
import '../api_client.dart';

class VoiceTranslationService {
  /// 完整流程: 录音 → 识别 → 翻译 → 合成
  static Future<VoiceResult?> translate({
    required File audioFile,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    try {
      // ① ASR 识别
      final recognized = await ASRService.recognize(
        audioFile: audioFile,
        language: sourceLanguage,
      );
      if (recognized == null || recognized.isEmpty) {
        throw Exception('语音识别失败');
      }

      // ② DeepSeek 翻译（通过云函数）
      final translateResult = await ApiClient.post(
        ApiClient.translateUrl,
        {'text': recognized, 'target_lang': targetLanguage},
      );
      final translated = translateResult['translated_text'] as String;

      // ③ TTS 合成
      final audio = await TTSService.synthesize(
        text: translated,
        language: targetLanguage,
      );

      return VoiceResult(
        originalText: recognized,
        translatedText: translated,
        audioBytes: audio,
      );
    } catch (e) {
      print('Voice translation failed: $e');
      return null;
    }
  }
}

class VoiceResult {
  final String originalText;
  final String translatedText;
  final Uint8List? audioBytes;

  VoiceResult({
    required this.originalText,
    required this.translatedText,
    this.audioBytes,
  });
}
```

### 7.6 录音配置

```dart
import 'package:record/record.dart';

// 录音参数（适配百度 ASR 要求）
final config = RecordConfig(
  encoder: AudioEncoder.pcm16bits,
  sampleRate: 16000,
  numChannels: 1,
  autoGain: true,
  echoCancel: true,
  noiseSuppress: true,
);

// 限制录音时长 ≤ 60 秒
// 在 UI 层设置计时器，到 60 秒自动停止
```

---

## 8. 错误处理

### 8.1 常见错误码

| 错误码 | 说明 | 解决方法 |
|--------|------|---------|
| 110 | 未实名认证 | 完成百度云实名认证 |
| 111 | Access Token 过期 | 云函数自动刷新 |
| 3300 | 参数不正确 | 检查 dev_pid/rate |
| 3301 | 音频质量过差 | 提高录音质量 |
| 3302 | 鉴权失败 | 检查 Key/Secret |
| 500 | TTS 输入不支持 | 文本含非法字符 |
| 501 | TTS 参数错误 | 检查文本长度 ≤ 1024 |

### 8.2 重试策略

云函数已内置 timeout=10 秒。Flutter 端可额外实现重试：

```dart
Future<String?> recognizeWithRetry(File audio, String lang, {int retries = 2}) async {
  for (int i = 0; i <= retries; i++) {
    final result = await ASRService.recognize(audioFile: audio, language: lang);
    if (result != null) return result;
    if (i < retries) await Future.delayed(Duration(seconds: 1 + i));
  }
  return null;
}
```

---

## 9. 性能优化

### 9.1 TTS 音频客户端缓存

```dart
/// 缓存常用短语的 TTS 音频（内存缓存）
class TTSCache {
  static final Map<String, Uint8List> _cache = {};
  static const int _maxEntries = 100;

  static Future<Uint8List?> getAudio(String text, String lang) async {
    final key = '$lang:$text';
    if (_cache.containsKey(key)) return _cache[key];

    final audio = await TTSService.synthesize(text: text, language: lang);
    if (audio != null) {
      if (_cache.length >= _maxEntries) {
        _cache.remove(_cache.keys.first);  // LRU 简易实现
      }
      _cache[key] = audio;
    }
    return audio;
  }
}
```

### 9.2 并发控制

```dart
/// 避免同时发起过多语音请求
class VoiceRequestQueue {
  static int _active = 0;
  static const int _maxConcurrent = 2;

  static Future<T> enqueue<T>(Future<T> Function() task) async {
    while (_active >= _maxConcurrent) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
    _active++;
    try {
      return await task();
    } finally {
      _active--;
    }
  }
}
```

---

## 10. 费用说明

### 10.1 百度语音定价

```yaml
免费额度（需在百度控制台确认，可能受认证类型和开通时间影响）:
  ASR: 每日 50,000 次（标准版，个人认证）
  TTS: 每日 100,000 次（标准版，个人认证）

超额按量计费:
  ASR: ¥0.0042/次（¥4.2/千次，阶梯定价更低）
  TTS: ¥0.004/次 （¥4.0/千次，阶梯定价更低）

⚠️ 注意:
  - 免费额度可能受认证类型（个人/企业）限制
  - 建议以按量付费价格做预算基准
  - 免费额度作为潜在优惠，不作为成本预算依据
```

### 10.2 WanderChina 费用预估

**以按量付费为基准（保守估算）：**

| 阶段 | MAU | 语音次数/月 | ASR 月费 | TTS 月费 | 合计 |
|------|-----|-----------|---------|---------|------|
| MVP | 500 | 37,500 | ¥158 | ¥150 | **≈¥308** |
| 成长期 | 10K | 750,000 | ¥3,150 | ¥3,000 | ≈¥6,150 |

> 计算: 500 用户 × 30 天 × 2.5 次/天 = 37,500 次/月

**如免费额度有效（乐观场景）：**

| 阶段 | MAU | ASR 月费 | TTS 月费 | 合计 |
|------|-----|---------|---------|------|
| MVP | 500 | ¥0 | ¥0 | **¥0** |
| 成长期 | 10K | ¥0 | ¥0 | **¥0** |

> 37,500 次/月 远低于每日免费额度（150 万次/月），如额度有效则完全免费。

**建议：** MVP 上线前在百度控制台确认实际免费额度，根据结果调整预算。

---

## 11. 测试验证

### 11.1 测试云函数（curl）

```bash
# 测试 ASR（需要一个 Base64 编码的 PCM 音频）
curl -X POST https://service-{asr-id}.gz.tencentcs.com/ \
  -H "Content-Type: application/json" \
  -d '{"audio_base64": "...", "audio_len": 12800, "language": "en"}'

# 测试 TTS
curl -X POST https://service-{tts-id}.gz.tencentcs.com/ \
  -H "Content-Type: application/json" \
  -d '{"text": "Welcome to Beijing", "language": "en"}'
```

### 11.2 Flutter 集成测试

```dart
// 测试 ASR
final text = await ASRService.recognize(
  audioFile: File('test_audio.pcm'),
  language: 'en',
);
print('识别结果: $text');

// 测试 TTS
await TTSService.speak(text: '欢迎来到北京', language: 'zh');

// 测试完整流程
final result = await VoiceTranslationService.translate(
  audioFile: File('test_english.pcm'),
  sourceLanguage: 'en',
  targetLanguage: 'zh',
);
print('原文: ${result?.originalText}');
print('译文: ${result?.translatedText}');
```

---

## 12. 部署检查清单

```
百度云:
  ✅ 账号注册 + 实名认证完成
  ✅ 语音技术应用创建
  ✅ API Key + Secret Key 获取

云函数:
  ✅ baidu_voice_asr 部署（公网，不启用 VPC）
  ✅ baidu_voice_tts 部署（公网，不启用 VPC）
  ✅ 环境变量 BAIDU_API_KEY / BAIDU_SECRET_KEY 配置
  ✅ 函数 URL 启用 + CORS 开启

安全:
  ✅ Flutter .env 中无百度密钥（仅存函数 URL）
  ✅ .gitignore 包含 .env

Flutter:
  ✅ record 包集成 + 麦克风权限配置
  ✅ audioplayers 包集成
  ✅ ASR_URL / TTS_URL 填入 .env
  ✅ 录音参数: 16kHz PCM 单声道

测试:
  ✅ 中英双向语音翻译流程验证
  ✅ 网络超时场景验证
  ✅ 音频录制 ≤ 60 秒限制验证

待确认:
  ⬜ 在百度控制台确认实际免费额度
  ⬜ 法语/西班牙语 ASR 识别准确率测试
```

---

## 附录：Android/iOS 权限

**Android** `android/app/src/main/AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
```

**iOS** `ios/Runner/Info.plist`
```xml
<key>NSMicrophoneUsageDescription</key>
<string>WanderChina needs microphone access for voice translation</string>
```

---

**版本历史：**
- v1.0（2026-02-13）: 初始版本（Flutter 直连百度 API）
- v2.0（2026-03-02）: 安全架构重构
  - 修正: API 密钥从 Flutter .env 移至云函数环境变量
  - 修正: 新增 baidu_voice_asr / baidu_voice_tts 云函数完整代码
  - 修正: 法/西 TTS 从中文发音人（per=0）改为英文发音人（per=103）
  - 修正: 所有 HTTP 请求添加 timeout=10s
  - 修正: 费用说明区分"按量付费基准"和"免费额度乐观场景"
  - 删除: Flutter 端 Token 管理服务（改为云函数端管理）
  - 删除: Flutter 直调百度 API 代码
  - 新增: 音频限制说明（≤ 60 秒，≤ 10MB）
  - 新增: TTS 客户端缓存方案
