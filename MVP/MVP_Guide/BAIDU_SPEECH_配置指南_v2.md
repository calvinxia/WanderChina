# WanderChina — 百度语音 API 配置指南（v2.0）

**更新日期：** 2026-03-02  
**用途：** 语音翻译功能的 ASR（语音识别）+ TTS（语音合成）  
**关联文档：** WANDERCHINA_TENCENT_CLOUD_CONFIG_v2.md

---

## 目录

1. [服务概述](#1-服务概述)
2. [账号注册与密钥获取](#2-账号注册与密钥获取)
3. [架构设计](#3-架构设计)
4. [云函数：baidu_voice_asr](#4-云函数baidu_voice_asr)
5. [云函数：baidu_voice_tts](#5-云函数baidu_voice_tts)
6. [百度 Token 云端管理](#6-百度-token-云端管理)
7. [Flutter 集成](#7-flutter-集成)
8. [TTS 语言限制与回退策略](#8-tts-语言限制与回退策略)
9. [错误处理](#9-错误处理)
10. [费用说明](#10-费用说明)
11. [部署检查清单](#11-部署检查清单)

---

## 1. 服务概述

### 1.1 语音翻译完整流程

```
用户按住说话（英文）
    ↓ 录音 PCM 16kHz
Flutter 将音频 Base64 POST 到 ASR_URL（云函数）
    ↓
baidu_voice_asr 云函数 → 百度 ASR API
    ↓ 返回识别文本 "where is the subway"
Flutter 将文本 POST 到 TRANSLATE_URL（云函数）
    ↓
deepseek_translate 云函数 → DeepSeek API
    ↓ 返回翻译文本 "地铁站在哪里"
Flutter 将翻译文本 POST 到 TTS_URL（云函数）
    ↓
baidu_voice_tts 云函数 → 百度 TTS API
    ↓ 返回 MP3 音频流
Flutter 播放音频
```

### 1.2 使用场景

| 场景 | ASR 输入语言 | TTS 输出语言 |
|------|-------------|-------------|
| 外国游客问路 | 英文 | 中文（给本地人听） |
| 本地人回答 | 中文 | 英文（给游客听） |
| 餐厅点菜 | 英文 → 翻译 → 中文 | 中文（给服务员） |
| 理解指示 | 中文 → 翻译 → 英文 | 英文（给游客） |

---

## 2. 账号注册与密钥获取

### 2.1 注册开通

```
1. 访问 https://cloud.baidu.com → 注册
2. 实名认证（必需，否则返回错误码 110）
   路径: 控制台 → 账户管理 → 实名认证
3. 开通语音服务:
   控制台 → 产品服务 → 人工智能 → 语音技术
   ✅ 语音识别（短语音识别标准版）
   ✅ 语音合成（在线语音合成标准版）
4. 创建应用:
   控制台 → 语音技术 → 应用列表 → 创建应用
   应用名称: WanderChina
   勾选: 短语音识别标准版 + 在线语音合成标准版
```

### 2.2 获取密钥

```yaml
创建完成后，在应用详情页获取:
  API Key:        xxxxxxxxxxxxxxxxxxxxxxxx
  Secret Key:     xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

⚠️ 安全提示:
  这两个密钥仅存放在云函数环境变量中（BAIDU_API_KEY / BAIDU_SECRET_KEY）
  绝不放入 Flutter .env 或任何客户端代码中
```

---

## 3. 架构设计

### 3.1 安全架构（v2.0）

```
⚠️ v1.0 的问题: Flutter 直接调用百度 API，密钥暴露在客户端
✅ v2.0 的方案: 通过公网云函数代理，密钥只在服务端

Flutter App（无百度密钥）
    ↓ HTTPS POST（音频 Base64 / 文本）
公网云函数 baidu_voice_asr / baidu_voice_tts
    ↓ 环境变量中的 BAIDU_API_KEY + BAIDU_SECRET_KEY
百度语音 API（vop.baidu.com / tsn.baidu.com）
```

### 3.2 密钥隔离

```yaml
Flutter .env（仅函数 URL，无密钥）:
  ASR_URL=https://service-ddd.gz.tencentcs.com/
  TTS_URL=https://service-eee.gz.tencentcs.com/

云函数环境变量（密钥只在云端）:
  BAIDU_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxx
  BAIDU_SECRET_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### 3.3 函数配置共通项

```yaml
运行环境:   Python 3.9
内存:       256 MB
VPC:        不启用（需访问公网百度 API）
触发器:     函数 URL（免鉴权）

环境变量:
  BAIDU_API_KEY:     [百度应用 API Key]
  BAIDU_SECRET_KEY:  [百度应用 Secret Key]
  REDIS_HOST:        172.16.2.x     # （可选）Token 缓存
  REDIS_PORT:        6379
  REDIS_PASSWORD:    [密码]

requirements.txt:
  requests==2.31.0
  redis==5.0.1     # （可选）Token 缓存
```

> 注意：这两个函数是公网函数（不启用 VPC），如需访问 Redis 缓存百度 Token，有两种方案：① 函数本地变量缓存（SCF 实例复用期间有效）；② 如确需 Redis，需启用 VPC + NAT 网关（增加 ¥360/月成本）。**MVP 推荐方案①。**

---

## 4. 云函数：baidu_voice_asr

**功能：** 接收音频 Base64 → 调百度 ASR → 返回识别文本

**超时时间：** 15 秒

```python
# baidu_voice_asr/index.py
# -*- coding: utf-8 -*-
"""
百度语音识别代理云函数
Flutter → 本函数 → 百度 ASR API
密钥仅在环境变量中，客户端无感知
"""
import json
import os
import time
import requests

# ===== 百度 Token 管理（函数级缓存）=====
_token_cache = {'token': None, 'expires_at': 0}

def get_baidu_token():
    """获取百度 Access Token（函数实例内缓存，提前 1 天刷新）"""
    now = int(time.time())
    if _token_cache['token'] and now < _token_cache['expires_at'] - 86400:
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

    _token_cache['token'] = token
    _token_cache['expires_at'] = now + expires_in

    print(f"[BAIDU TOKEN] Refreshed, expires in {expires_in}s")
    return token

# ===== 语言模型映射 =====
DEV_PID_MAP = {
    'zh': 1537,   # 中文普通话
    'en': 1737,   # 英语
    'fr': 1837,   # 法语
    'es': 1937,   # 西班牙语
}

def json_response(code, body):
    return {
        'statusCode': code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
        },
        'body': json.dumps(body, ensure_ascii=False),
    }

def main_handler(event, context):
    try:
        if isinstance(event, dict) and 'body' in event:
            body = json.loads(event['body'])
        else:
            body = event

        audio_base64 = body.get('audio')       # Base64 编码的音频
        audio_len = body.get('audio_len')       # 原始音频字节数
        language = body.get('language', 'en')    # 源语言
        audio_format = body.get('format', 'pcm')
        sample_rate = body.get('rate', 16000)
        user_id = body.get('user_id', 'anonymous')

        if not audio_base64 or not audio_len:
            return json_response(400, {'error': 'Missing audio or audio_len'})

        if language not in DEV_PID_MAP:
            return json_response(400, {
                'error': f'Unsupported language. Supported: {list(DEV_PID_MAP.keys())}'
            })

        # 获取百度 Token
        token = get_baidu_token()

        # 调用百度 ASR
        asr_url = 'https://vop.baidu.com/server_api'
        payload = {
            'format': audio_format,
            'rate': sample_rate,
            'channel': 1,
            'cuid': f'wc_{user_id}',
            'token': token,
            'dev_pid': DEV_PID_MAP[language],
            'speech': audio_base64,
            'len': audio_len,
        }

        start = time.time()
        resp = requests.post(asr_url, json=payload, timeout=12)
        latency = time.time() - start
        resp.raise_for_status()
        result = resp.json()

        if result.get('err_no') != 0:
            print(f"[ASR ERROR] {result.get('err_no')}: {result.get('err_msg')}")
            return json_response(400, {
                'error': result.get('err_msg', 'ASR recognition failed'),
                'err_no': result.get('err_no'),
            })

        recognized_text = result['result'][0] if result.get('result') else ''
        print(f"[ASR] lang={language} | text='{recognized_text[:50]}' | {latency:.1f}s")

        return json_response(200, {
            'text': recognized_text,
            'language': language,
            'latency_ms': int(latency * 1000),
        })

    except Exception as e:
        print(f"[ASR EXCEPTION] {str(e)}")
        import traceback; traceback.print_exc()
        return json_response(500, {'error': str(e)})
```

---

## 5. 云函数：baidu_voice_tts

**功能：** 接收文本 → 调百度 TTS → 返回 Base64 音频

**超时时间：** 10 秒

```python
# baidu_voice_tts/index.py
# -*- coding: utf-8 -*-
"""
百度语音合成代理云函数
Flutter → 本函数 → 百度 TTS API
返回 Base64 编码的 MP3 音频
"""
import json
import os
import time
import base64
import requests
from urllib.parse import quote

# ===== 百度 Token（复用 ASR 同样的逻辑）=====
_token_cache = {'token': None, 'expires_at': 0}

def get_baidu_token():
    now = int(time.time())
    if _token_cache['token'] and now < _token_cache['expires_at'] - 86400:
        return _token_cache['token']

    api_key = os.environ.get('BAIDU_API_KEY')
    secret_key = os.environ.get('BAIDU_SECRET_KEY')
    if not api_key or not secret_key:
        raise ValueError('Missing BAIDU_API_KEY or BAIDU_SECRET_KEY')

    url = 'https://aip.baidubce.com/oauth/2.0/token'
    resp = requests.post(url, params={
        'grant_type': 'client_credentials',
        'client_id': api_key,
        'client_secret': secret_key,
    }, timeout=10)
    resp.raise_for_status()
    data = resp.json()

    _token_cache['token'] = data['access_token']
    _token_cache['expires_at'] = now + data.get('expires_in', 2592000)
    return _token_cache['token']

# ===== TTS 发音人配置 =====
# 百度标准版 TTS 仅完整支持中文和英文发音
# 法语/西班牙语不支持合成，需走回退策略
VOICE_PERSON_MAP = {
    'zh': 0,     # 度小美（中文女声）
    'en': 103,   # 英文女声
}

SUPPORTED_TTS_LANGS = list(VOICE_PERSON_MAP.keys())  # ['zh', 'en']

def json_response(code, body):
    return {
        'statusCode': code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
        },
        'body': json.dumps(body, ensure_ascii=False),
    }

def main_handler(event, context):
    try:
        if isinstance(event, dict) and 'body' in event:
            body = json.loads(event['body'])
        else:
            body = event

        text = body.get('text', '')
        language = body.get('language', 'zh')
        speed = body.get('speed', 5)       # 语速 0-15
        volume = body.get('volume', 9)     # 音量 0-15
        user_id = body.get('user_id', 'anonymous')

        if not text:
            return json_response(400, {'error': 'Missing text'})

        if len(text) > 1024:
            return json_response(400, {'error': 'Text too long (max 1024 chars)'})

        # 检查语言是否支持 TTS
        if language not in SUPPORTED_TTS_LANGS:
            return json_response(200, {
                'audio': None,
                'tts_supported': False,
                'text': text,
                'language': language,
                'message': f'TTS not supported for {language}. Text returned for display.',
            })

        token = get_baidu_token()

        # 调用百度 TTS
        tts_url = 'https://tsn.baidu.com/text2audio'
        params = {
            'tex': quote(text),
            'lan': language,
            'cuid': f'wc_{user_id}',
            'ctp': '1',
            'tok': token,
            'per': str(VOICE_PERSON_MAP[language]),
            'spd': str(speed),
            'pit': '5',
            'vol': str(volume),
            'aue': '3',  # MP3
        }

        start = time.time()
        resp = requests.post(tts_url, params=params, timeout=8)
        latency = time.time() - start

        # 百度 TTS: 成功返回音频流，失败返回 JSON
        content_type = resp.headers.get('Content-Type', '')

        if 'audio' in content_type or 'octet' in content_type:
            # 成功：返回 Base64 编码的音频
            audio_b64 = base64.b64encode(resp.content).decode('utf-8')
            print(f"[TTS] lang={language} | text='{text[:30]}' | "
                  f"audio={len(resp.content)}B | {latency:.1f}s")

            return json_response(200, {
                'audio': audio_b64,
                'tts_supported': True,
                'format': 'mp3',
                'audio_size': len(resp.content),
                'latency_ms': int(latency * 1000),
            })
        else:
            # 失败：百度返回了 JSON 错误
            error_data = resp.json()
            print(f"[TTS ERROR] {error_data.get('err_no')}: {error_data.get('err_msg')}")
            return json_response(400, {
                'error': error_data.get('err_msg', 'TTS synthesis failed'),
                'err_no': error_data.get('err_no'),
            })

    except Exception as e:
        print(f"[TTS EXCEPTION] {str(e)}")
        import traceback; traceback.print_exc()
        return json_response(500, {'error': str(e)})
```

---

## 6. 百度 Token 云端管理

### 6.1 MVP 方案：函数级变量缓存

```python
# 利用 SCF 实例复用机制
# 同一实例在活跃期间共享全局变量，Token 只需获取一次
_token_cache = {'token': None, 'expires_at': 0}
```

**特点：**
- 零额外成本（不需要 VPC/NAT 访问 Redis）
- 实例冷启动时重新获取 Token（~200ms）
- 百度 Token 有效期 30 天，实际每天冷启动几次影响极小

### 6.2 成长阶段方案：Redis 缓存（可选）

如需跨实例共享 Token，可引入 Redis 缓存：

```python
def get_baidu_token_with_redis():
    r = redis.Redis(host=os.environ['REDIS_HOST'], ...)
    cached = r.get('baidu:access_token')
    if cached:
        return cached.decode()

    token = fetch_new_baidu_token()
    r.setex('baidu:access_token', 29 * 86400, token)  # 29 天 TTL
    return token
```

> 注意：公网函数访问 Redis 需要 VPC + NAT 网关（增加 ¥360/月）。MVP 阶段不推荐。

---

## 7. Flutter 集成

### 7.1 环境配置

```env
# .env — 仅函数 URL，无百度密钥
ASR_URL=https://service-ddd.gz.tencentcs.com/
TTS_URL=https://service-eee.gz.tencentcs.com/
TRANSLATE_URL=https://service-xxx.gz.tencentcs.com/
```

### 7.2 录音配置

```dart
// 使用 record 包，16kHz PCM 单声道
final config = RecordConfig(
  encoder: AudioEncoder.pcm16bits,
  sampleRate: 16000,
  numChannels: 1,
  autoGain: true,
  echoCancel: true,
  noiseSuppress: true,
);
```

### 7.3 语音翻译服务

```dart
// lib/services/voice/voice_translation_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:audioplayers/audioplayers.dart';

class VoiceTranslationService {
  static String get _asrUrl => dotenv.env['ASR_URL']!;
  static String get _ttsUrl => dotenv.env['TTS_URL']!;
  static String get _translateUrl => dotenv.env['TRANSLATE_URL']!;

  /// 完整语音翻译流程
  Future<VoiceTranslationResult?> translate({
    required File audioFile,
    required String sourceLanguage,  // 'zh' / 'en' / 'fr' / 'es'
    required String targetLanguage,
  }) async {
    try {
      // ① ASR：音频 → 文本
      final audioBytes = await audioFile.readAsBytes();
      final asrResponse = await http.post(
        Uri.parse(_asrUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'audio': base64Encode(audioBytes),
          'audio_len': audioBytes.length,
          'language': sourceLanguage,
          'format': 'pcm',
          'rate': 16000,
        }),
      ).timeout(const Duration(seconds: 15));

      if (asrResponse.statusCode != 200) {
        throw Exception('ASR failed: ${asrResponse.body}');
      }
      final asrData = json.decode(asrResponse.body);
      final recognizedText = asrData['text'] as String;

      if (recognizedText.isEmpty) {
        throw Exception('ASR returned empty text');
      }

      // ② 翻译：源语言文本 → 目标语言文本
      final translateResponse = await http.post(
        Uri.parse(_translateUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'text': recognizedText,
          'target_lang': targetLanguage,
        }),
      ).timeout(const Duration(seconds: 15));

      if (translateResponse.statusCode != 200) {
        throw Exception('Translation failed: ${translateResponse.body}');
      }
      final translateData = json.decode(translateResponse.body);
      final translatedText = translateData['translated_text'] as String;

      // ③ TTS：翻译文本 → 音频
      Uint8List? audioOutput;
      bool ttsSuppported = true;

      final ttsResponse = await http.post(
        Uri.parse(_ttsUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'text': translatedText,
          'language': targetLanguage,
        }),
      ).timeout(const Duration(seconds: 10));

      if (ttsResponse.statusCode == 200) {
        final ttsData = json.decode(ttsResponse.body);
        if (ttsData['tts_supported'] == true && ttsData['audio'] != null) {
          audioOutput = base64Decode(ttsData['audio']);
        } else {
          ttsSuppported = false;
          // 法语/西班牙语 TTS 不支持，仅显示文本
        }
      }

      return VoiceTranslationResult(
        originalText: recognizedText,
        translatedText: translatedText,
        audioBytes: audioOutput,
        ttsSupported: ttsSuppported,
      );

    } catch (e) {
      print('Voice translation failed: $e');
      return null;
    }
  }
}

class VoiceTranslationResult {
  final String originalText;
  final String translatedText;
  final Uint8List? audioBytes;    // null if TTS not supported
  final bool ttsSupported;

  VoiceTranslationResult({
    required this.originalText,
    required this.translatedText,
    this.audioBytes,
    this.ttsSupported = true,
  });
}
```

### 7.4 权限配置

**Android** (`android/app/src/main/AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
```

**iOS** (`ios/Runner/Info.plist`):

```xml
<key>NSMicrophoneUsageDescription</key>
<string>WanderChina needs microphone access for voice translation</string>
```

---

## 8. TTS 语言限制与回退策略

### 8.1 百度标准版 TTS 支持情况

| 语言 | 支持状态 | 发音人 | 说明 |
|------|---------|--------|------|
| 中文 | ✅ 完整支持 | per=0 度小美 | 高质量 |
| 英文 | ✅ 完整支持 | per=103 英文女声 | 高质量 |
| 法文 | ❌ 标准版不支持 | — | 需精品音库（额外付费） |
| 西班牙文 | ❌ 标准版不支持 | — | 需精品音库（额外付费） |

### 8.2 MVP 回退策略

```
目标语言为中文或英文：
  → 正常 TTS 合成，返回 MP3 音频

目标语言为法文或西班牙文：
  → 返回 tts_supported=false + 翻译文本
  → Flutter 端显示翻译文本（大字体），用户可直接给对方看
  → 不做语音合成（避免中文发音人读法语的糟糕体验）
```

### 8.3 成长阶段升级路径

```
方案 A: 百度精品音库 TTS（付费）
  - 支持更多语言和高质量发音
  - 需额外计费

方案 B: 接入第三方 TTS（如 Google Cloud TTS / Azure TTS）
  - 支持 100+ 语言
  - 需新增对应云函数
```

---

## 9. 错误处理

### 9.1 百度 ASR 错误码

| 错误码 | 说明 | 解决方法 |
|--------|------|---------|
| 110 | 未实名认证 | 完成百度云实名认证 |
| 111 | Access Token 过期 | 清除 Token 缓存，重新获取 |
| 3300 | 输入参数不正确 | 检查 dev_pid、rate 等参数 |
| 3301 | 音频质量过差 | 提高录音质量，启用降噪 |
| 3302 | 鉴权失败 | 检查 API Key / Secret Key |
| 3303 | 语音服务器后端问题 | 稍后重试 |

### 9.2 百度 TTS 错误码

| 错误码 | 说明 | 解决方法 |
|--------|------|---------|
| 500 | 不支持输入 | 文本含非法字符 |
| 501 | 输入参数不正确 | 检查文本长度（< 1024 字符） |
| 502 | Token 验证失败 | 重新获取 Token |

### 9.3 Flutter 端重试

```dart
Future<VoiceTranslationResult?> translateWithRetry({
  required File audioFile,
  required String sourceLanguage,
  required String targetLanguage,
  int maxRetries = 2,
}) async {
  for (int i = 0; i <= maxRetries; i++) {
    final result = await translate(
      audioFile: audioFile,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );
    if (result != null) return result;
    if (i < maxRetries) {
      await Future.delayed(Duration(seconds: i + 1));
    }
  }
  return null;
}
```

---

## 10. 费用说明

### 10.1 百度免费额度

```yaml
⚠️ 免费额度政策可能变化，部署前请在百度控制台确认当前配额

语音识别（ASR 标准版）:
  个人认证: 每日免费 50,000 次（待确认）
  企业认证: 每日免费 50,000 次（待确认）

语音合成（TTS 标准版）:
  个人认证: 每日免费 100,000 次（待确认）
  企业认证: 每日免费 100,000 次（待确认）

超出后:
  ASR: ¥1.2/千次
  TTS: ¥1.2/千次
```

### 10.2 WanderChina 费用估算

**假设：** 每活跃用户每天平均 5 次语音翻译

| 阶段 | MAU | 日调用 | 月调用 | 在免费额度内？ | 月费 |
|------|-----|--------|--------|-------------|------|
| **MVP** | 500 | 2,500 | 75K | ✅ 是（< 150 万） | **¥0** |
| 成长期 | 1 万 | 50K | 150 万 | ⚠️ 接近上限 | ¥0-180 |
| 规模化 | 10 万 | 500K | 1500 万 | ❌ 超出 | ≈ ¥16,200 |

**双轨估算：**

```
如果免费额度仍然有效:
  MVP 阶段: ¥0/月（在额度内）
  成长阶段: ¥0-180/月（接近上限）

如果免费额度已调整或取消:
  MVP 阶段: ≈ ¥90-180/月（ASR ¥90 + TTS ¥90）
  成长阶段: ≈ ¥1,800-3,600/月

→ 建议: 部署前登录百度控制台确认实际免费额度
→ 主配置文档 v2.0 §12.2 按较保守的 ¥102/月（500 活跃用户）估算
```

---

## 11. 部署检查清单

```
百度账号:
  ✅ 百度智能云注册 + 实名认证
  ✅ 语音识别 + 语音合成服务已开通
  ✅ 应用已创建，API Key / Secret Key 已保存

云函数:
  ✅ baidu_voice_asr 部署（公网，无 VPC）
  ✅ baidu_voice_tts 部署（公网，无 VPC）
  ✅ 环境变量 BAIDU_API_KEY / BAIDU_SECRET_KEY 已设置
  ✅ 函数 URL 已启用
  ✅ 百度 Token 获取测试通过

Flutter:
  ✅ .env 中仅有 ASR_URL / TTS_URL（无密钥）
  ✅ 录音权限配置（Android + iOS）
  ✅ 录音参数: PCM 16kHz 单声道
  ✅ TTS 语言回退处理（fr/es 显示文本）

安全:
  ✅ Flutter 代码中无 BAIDU_API_KEY / BAIDU_SECRET_KEY
  ✅ 百度密钥仅在云函数环境变量中
```

---

**版本历史:**
- v1.0（2026-02-13）: 初始版本（Flutter 直调百度 API）
- v2.0（2026-03-02）: 重写为云函数代理架构，移除客户端密钥，新增 ASR/TTS 云函数代码，修正 TTS 语言限制，双轨费用估算
