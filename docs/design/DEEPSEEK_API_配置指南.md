# WanderChina DeepSeek API 配置指南

**创建日期：** 2026-02-25  
**用途：** POI 名称翻译（中文 → 英文/法文/西班牙文）  
**官网：** https://platform.deepseek.com

---

## 1. DeepSeek API 简介

### 1.1 为什么选择 DeepSeek？

```yaml
优势:
  价格:      业界最低（输入 ¥2/百万tokens，输出 ¥3/百万tokens）
  质量:      DeepSeek-V3.2，质量接近 GPT-4
  速度:      响应时间 1-3 秒
  稳定性:    99.9% 可用性
  中文支持:  专门优化中文理解
  上下文:    128K tokens

最新定价（DeepSeek-V3.2）:
  输入 tokens（缓存命中）:    ¥0.2/百万
  输入 tokens（缓存未命中）:  ¥2/百万
  输出 tokens:                ¥3/百万

对比:
  DeepSeek:     ¥2-3/百万 tokens
  GPT-3.5:      ¥10/百万 tokens
  GPT-4:        ¥100/百万 tokens
  Claude:       ¥15/百万 tokens
```

### 1.2 WanderChina 使用场景

```
场景 1: 地图 POI 翻译
  输入: "故宫博物院"
  输出: "Palace Museum"
  频率: 每天约 100-500 次

场景 2: 用户输入内容翻译
  输入: "我想去吃北京烤鸭"
  输出: "I want to eat Peking Duck"
  频率: 每天约 50-200 次
```

---

## 2. 获取 API Key

### 2.1 注册账号

```
1. 访问 https://platform.deepseek.com
2. 点击【注册】或【Sign Up】
3. 使用邮箱注册（支持 Gmail/QQ 邮箱等）
4. 验证邮箱
5. 登录后台
```

### 2.2 创建 API Key

```
1. 登录后台 → 左侧菜单【API Keys】
2. 点击【Create new secret key】
3. 输入名称：wanderchina-production
4. 点击【Create】
5. 复制 API Key（格式：sk-xxxxxxxxxxxxxxxx）

⚠️ 重要：API Key 只显示一次，务必保存！
```

**示例 API Key：**
```
sk-1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p7q8r9s0t1u2v3w4x5y6z
```

### 2.3 账户充值

```
1. 后台 → 【Billing】或【账户余额】
2. 点击【充值】或【Top up】
3. 支持支付方式：
   - 支付宝
   - 微信支付
   - 信用卡

推荐充值金额（基于 V3.2 定价）:
  测试阶段:  ¥50（约 2500 万 tokens，够用数月）
  MVP 阶段:  ¥100（约 5000 万 tokens，够用半年以上）
  正式运营:  ¥500/年（约 2.5 亿 tokens）

注意：
  - DeepSeek 支持缓存，实际消耗会更少
  - 建议从小额开始测试
  - 可以设置余额告警
```

---

## 3. DeepSeek API 详细参数

### 3.1 API 端点

```
基础 URL: https://api.deepseek.com
聊天接口: POST /v1/chat/completions
```

### 3.2 可用模型（2026 年最新）

| 模型名 | 版本 | 用途 | 上下文 | 价格 | 推荐度 |
|--------|------|------|--------|------|--------|
| `deepseek-chat` | V3.2 | 通用对话、翻译 | 128K | 输入¥2/百万，输出¥3/百万 | ⭐️⭐️⭐️⭐️⭐️ |
| `deepseek-reasoner` | V3.2 | 推理任务 | 128K | 输入¥2/百万，输出¥3/百万 | ❌（不适合翻译） |
| `deepseek-coder` | - | 代码生成 | - | - | ❌（不适合翻译） |

**WanderChina 使用：** `deepseek-chat`（V3.2 非思考模式）

**模型特点：**
- ✅ 支持 128K 上下文（足够长）
- ✅ 支持 JSON Output（结构化输出）
- ✅ 支持 Tool Calls（函数调用）
- ✅ 支持缓存（Prompt Caching），可节省 90% 输入成本
- ✅ 输出长度：默认 4K，最大 8K

### 3.3 请求参数

```json
{
  "model": "deepseek-chat",
  "messages": [
    {
      "role": "system",
      "content": "你是一个专业的中英翻译。只输出翻译结果，不要解释。"
    },
    {
      "role": "user",
      "content": "故宫博物院"
    }
  ],
  "temperature": 0.3,      // 0-2，越低越确定性（翻译推荐 0.3）
  "max_tokens": 100,       // 限制输出长度
  "top_p": 0.9,           // 可选，控制多样性
  "frequency_penalty": 0,  // 可选，降低重复
  "presence_penalty": 0    // 可选，鼓励新话题
}
```

### 3.4 响应格式

```json
{
  "id": "chatcmpl-abc123",
  "object": "chat.completion",
  "created": 1677652288,
  "model": "deepseek-chat",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Palace Museum"
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 25,      // 输入消耗
    "completion_tokens": 3,   // 输出消耗
    "total_tokens": 28        // 总消耗
  }
}
```

---

## 4. 云函数配置

### 4.1 环境变量配置

```yaml
腾讯云控制台 → 云函数 → deepseek_translate → 函数配置 → 环境变量

添加环境变量:
  Key:    DEEPSEEK_KEY
  Value:  sk-1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p7q8r9s0t1u2v3w4x5y6z

⚠️ 安全提示：
  - 绝对不要将 API Key 硬编码在代码中
  - 不要提交到 Git 仓库
  - 只通过环境变量传递
```

### 4.2 完整云函数代码（优化版 - 带 Prompt Caching + Redis 缓存）

**文件：** `deepseek_translate/index.py`

```python
# -*- coding: utf-8 -*-
"""
DeepSeek 翻译云函数（优化版）
- 支持 Prompt Caching（节省 90% 输入成本）
- 详细的 token 使用日志
- 成本监控
"""
import json
import os
import requests

# 固定的 System Prompt（会被 DeepSeek 缓存）
SYSTEM_PROMPTS = {
    'en': 'Translate the following Chinese text to English. Output only the translation, no explanations.',
    'fr': 'Translate the following Chinese text to French. Output only the translation, no explanations.',
    'es': 'Translate the following Chinese text to Spanish. Output only the translation, no explanations.',
    'de': 'Translate the following Chinese text to German. Output only the translation, no explanations.',
    'ja': 'Translate the following Chinese text to Japanese. Output only the translation, no explanations.',
    'ko': 'Translate the following Chinese text to Korean. Output only the translation, no explanations.',
}

def translate_with_deepseek(text, target_lang):
    """
    调用 DeepSeek API 翻译文本
    
    Args:
        text: 要翻译的中文文本
        target_lang: 目标语言代码
    
    Returns:
        dict: {
            'translated_text': str,
            'usage': dict,
            'cost': float
        }
    """
    url = 'https://api.deepseek.com/v1/chat/completions'
    
    api_key = os.environ.get('DEEPSEEK_KEY')
    if not api_key:
        raise ValueError('Missing DEEPSEEK_KEY in environment variables')
    
    headers = {
        'Authorization': f'Bearer {api_key}',
        'Content-Type': 'application/json'
    }
    
    # 使用固定的 System Prompt（提高缓存命中率）
    system_prompt = SYSTEM_PROMPTS.get(target_lang, SYSTEM_PROMPTS['en'])
    
    payload = {
        'model': 'deepseek-chat',
        'messages': [
            {'role': 'system', 'content': system_prompt},  # 固定内容，会被缓存
            {'role': 'user', 'content': text}
        ],
        'temperature': 0.3,
        'max_tokens': 100,
        'top_p': 0.9
    }
    
    try:
        response = requests.post(url, headers=headers, json=payload, timeout=10)
        response.raise_for_status()
        
        result = response.json()
        translated_text = result['choices'][0]['message']['content'].strip()
        
        # 提取 token 使用量
        usage = result.get('usage', {})
        prompt_tokens = usage.get('prompt_tokens', 0)
        completion_tokens = usage.get('completion_tokens', 0)
        total_tokens = usage.get('total_tokens', 0)
        
        # 提取缓存信息（V3.2 新增）
        prompt_details = usage.get('prompt_tokens_details', {})
        cached_tokens = prompt_details.get('cached_tokens', 0)
        uncached_tokens = prompt_tokens - cached_tokens
        
        # 计算成本（DeepSeek V3.2 定价）
        cost = (
            uncached_tokens * 2 / 1_000_000 +     # 未缓存输入: ¥2/百万
            cached_tokens * 0.2 / 1_000_000 +      # 缓存输入: ¥0.2/百万
            completion_tokens * 3 / 1_000_000      # 输出: ¥3/百万
        )
        
        # 详细日志
        cache_hit_rate = (cached_tokens / prompt_tokens * 100) if prompt_tokens > 0 else 0
        print(f"Translation: '{text[:30]}...' → '{translated_text[:30]}...'")
        print(f"Tokens - Prompt: {prompt_tokens} (cached: {cached_tokens}, uncached: {uncached_tokens}), "
              f"Completion: {completion_tokens}, Total: {total_tokens}")
        print(f"Cache hit rate: {cache_hit_rate:.1f}%")
        print(f"Cost: ¥{cost:.8f}")
        
        return {
            'translated_text': translated_text,
            'usage': {
                'prompt_tokens': prompt_tokens,
                'cached_tokens': cached_tokens,
                'uncached_tokens': uncached_tokens,
                'completion_tokens': completion_tokens,
                'total_tokens': total_tokens,
                'cache_hit_rate': cache_hit_rate
            },
            'cost': cost
        }
        
    except requests.exceptions.Timeout:
        raise Exception('DeepSeek API request timeout')
    except requests.exceptions.HTTPError as e:
        if e.response.status_code == 401:
            raise Exception('Invalid DeepSeek API key')
        elif e.response.status_code == 429:
            raise Exception('DeepSeek rate limit exceeded')
        else:
            raise Exception(f'DeepSeek API error: {e.response.text}')
    except Exception as e:
        raise Exception(f'Translation failed: {str(e)}')

def main_handler(event, context):
    """
    云函数入口
    
    输入格式:
    {
      "text": "故宫博物院",
      "target_lang": "en"
    }
    
    输出格式:
    {
      "translated_text": "Palace Museum",
      "source_text": "故宫博物院",
      "target_lang": "en",
      "usage": {...},
      "cost": 0.000075
    }
    """
    try:
        # 解析请求体
        if isinstance(event, dict) and 'body' in event:
            body = json.loads(event['body'])
        else:
            body = event
        
        text = body.get('text')
        target_lang = body.get('target_lang', 'en')
        
        # 参数验证
        if not text:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': 'Missing required parameter: text'
                }, ensure_ascii=False)
            }
        
        supported_langs = ['en', 'fr', 'es', 'de', 'ja', 'ko']
        if target_lang not in supported_langs:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': f'Unsupported language. Supported: {", ".join(supported_langs)}'
                }, ensure_ascii=False)
            }
        
        # 调用翻译
        result = translate_with_deepseek(text, target_lang)
        
        # 返回结果
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'translated_text': result['translated_text'],
                'source_text': text,
                'target_lang': target_lang,
                'usage': result['usage'],
                'cost': result['cost']
            }, ensure_ascii=False)
        }
        
    except Exception as e:
        print(f'Translation error: {str(e)}')
        import traceback
        traceback.print_exc()
        
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': str(e)
            }, ensure_ascii=False)
        }
```

**文件：** `deepseek_translate/requirements.txt`

```txt
requests==2.31.0
```

**优化说明：**

1. ✅ **Prompt Caching** - 使用固定 System Prompt 字典，缓存命中时输入成本降低 90%
2. ✅ **详细日志** - 记录缓存命中率、token 使用量、每次调用成本
3. ✅ **精确成本计算** - 区分缓存/非缓存输入，实时计算成本
4. ✅ **完善错误处理** - 超时、鉴权、限流等错误分类处理
5. ✅ **堆栈跟踪** - 生产环境调试更方便

---

### 4.3 Redis 缓存集成（可选但强烈推荐）

为了进一步降低成本和提高响应速度，建议在内网云函数中集成 Redis 缓存。

**优势：**
- 缓存命中时完全不调用 DeepSeek API（成本 ¥0，响应 <50ms）
- 配合 Prompt Caching 可节省总成本的 80-90%

**实现方式：**

参见腾讯云配置文档中的 `translate_db_write` 函数，该函数已集成完整的 Redis 缓存逻辑。

**缓存 Key 设计：**
```
poi:trans:{poi_id}:{target_lang}

示例:
  poi:trans:B000A8UJVW:en → "Palace Museum"
  poi:trans:B000A8UJVW:fr → "Musée du Palais"
```

**过期策略：**
- TTL: 24 小时（86400 秒）
- 热门 POI 可以设置更长时间（7 天或永久）



---

## 5. 测试 DeepSeek API

### 5.1 使用 curl 测试

```bash
# 直接测试 DeepSeek API
curl -X POST https://api.deepseek.com/v1/chat/completions \
  -H "Authorization: Bearer sk-your-api-key-here" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "deepseek-chat",
    "messages": [
      {
        "role": "system",
        "content": "Translate to English. Output only translation."
      },
      {
        "role": "user",
        "content": "故宫博物院"
      }
    ],
    "temperature": 0.3
  }'

# 期望返回:
{
  "choices": [
    {
      "message": {
        "content": "Palace Museum"
      }
    }
  ],
  "usage": {
    "total_tokens": 28
  }
}
```

### 5.2 测试云函数

```bash
# 测试云函数（部署后）
curl -X POST https://service-abc123-1234567.gz.apigw.tencentcs.com/release/deepseek_translate \
  -H "Content-Type: application/json" \
  -d '{
    "text": "故宫博物院",
    "target_lang": "en"
  }'

# 期望返回:
{
  "translated_text": "Palace Museum",
  "source_text": "故宫博物院",
  "target_lang": "en"
}
```

### 5.3 使用 Postman 测试

```
1. 打开 Postman
2. 创建新请求

Method: POST
URL: https://service-abc123.gz.apigw.tencentcs.com/release/deepseek_translate

Headers:
  Content-Type: application/json

Body (raw JSON):
{
  "text": "天安门广场",
  "target_lang": "en"
}

3. 点击 Send

期望响应:
{
  "translated_text": "Tiananmen Square",
  "source_text": "天安门广场",
  "target_lang": "en"
}
```

---

## 6. Flutter 集成

### 6.1 API Service 类

```dart
// lib/services/translation/deepseek_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class DeepSeekService {
  // 云函数 URL（从腾讯云控制台获取）
  static const String _translateUrl = 
      'https://service-abc123-1234567.gz.apigw.tencentcs.com/release/deepseek_translate';
  
  /// 翻译文本
  /// 
  /// [text] 要翻译的中文文本
  /// [targetLang] 目标语言：'en', 'fr', 'es'
  /// 
  /// 返回翻译后的文本，失败返回 null
  static Future<String?> translate({
    required String text,
    String targetLang = 'en',
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_translateUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'text': text,
          'target_lang': targetLang,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Translation timeout');
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['translated_text'];
      } else {
        final error = json.decode(response.body);
        print('Translation error: ${error['error']}');
        return null;
      }
      
    } catch (e) {
      print('Translation failed: $e');
      return null;
    }
  }
  
  /// 批量翻译（并行）
  /// 
  /// [texts] 要翻译的文本列表
  /// [targetLang] 目标语言
  /// 
  /// 返回翻译结果映射
  static Future<Map<String, String>> translateBatch({
    required List<String> texts,
    String targetLang = 'en',
  }) async {
    final futures = texts.map((text) => translate(
      text: text,
      targetLang: targetLang,
    ));
    
    final results = await Future.wait(futures);
    
    final translations = <String, String>{};
    for (var i = 0; i < texts.length; i++) {
      if (results[i] != null) {
        translations[texts[i]] = results[i]!;
      }
    }
    
    return translations;
  }
}
```

### 6.2 使用示例

```dart
// 示例 1: 单个翻译
void translatePOIName() async {
  final translation = await DeepSeekService.translate(
    text: '故宫博物院',
    targetLang: 'en',
  );
  
  print(translation); // "Palace Museum"
}

// 示例 2: 批量翻译
void translateMultiplePOIs() async {
  final pois = ['故宫博物院', '天安门', '长城'];
  
  final translations = await DeepSeekService.translateBatch(
    texts: pois,
    targetLang: 'en',
  );
  
  translations.forEach((chinese, english) {
    print('$chinese → $english');
  });
  
  // 输出:
  // 故宫博物院 → Palace Museum
  // 天安门 → Tiananmen
  // 长城 → Great Wall
}

// 示例 3: 地图 POI 翻译
void translateMapPOI(String poiId, String nameZh) async {
  // 调用翻译
  final nameEn = await DeepSeekService.translate(
    text: nameZh,
    targetLang: 'en',
  );
  
  if (nameEn != null) {
    // 保存到数据库
    await saveTranslation(poiId, nameZh, nameEn);
    
    // 显示在地图上
    updateMapLabel(poiId, nameEn);
  }
}
```

---

## 7. 费用估算

### 7.1 Token 消耗计算

```
一次翻译示例:
  输入: "故宫博物院" + System Prompt
  Token 数: 约 25-30 tokens

  输出: "Palace Museum"
  Token 数: 约 3-5 tokens

  总计: 约 30-35 tokens
```

### 7.2 成本计算（最新 V3.2 定价）

```yaml
DeepSeek-V3.2 定价:
  输入 tokens（缓存未命中）: ¥2/百万
  输入 tokens（缓存命中）:   ¥0.2/百万
  输出 tokens:               ¥3/百万

每次翻译成本（假设缓存未命中）:
  输入: 30 tokens × ¥2/1,000,000 = ¥0.00006
  输出: 5 tokens × ¥3/1,000,000  = ¥0.000015
  总计: ¥0.000075/次

每天成本（假设 500 次翻译）:
  500 次 × ¥0.000075 = ¥0.0375/天

每月成本:
  ¥0.0375 × 30 = ¥1.125/月

每年成本:
  ¥1.125 × 12 = ¥13.5/年

注意：
  - 如果命中缓存，输入成本降低 90%
  - 实际成本会更低（很多 POI 重复翻译会命中缓存）
  - 预估实际成本约为计算值的 30-50%
```

### 7.3 不同阶段费用预估

| 阶段 | MAU | 每日翻译 | 每月翻译 | 月费用 | 年费用 |
|------|-----|---------|---------|--------|--------|
| 测试期 | 10 | 50 | 1,500 | ¥0.11 | ¥1.35 |
| MVP | 1,000 | 500 | 15,000 | ¥1.13 | ¥13.5 |
| 成长期 | 10,000 | 5,000 | 150,000 | ¥11.25 | ¥135 |
| 成熟期 | 100,000 | 50,000 | 1,500,000 | ¥112.5 | ¥1,350 |

**计算说明：**
- 单次翻译成本：¥0.000075
- 实际成本可能更低（缓存命中率约 40-60%）
- 缓存命中后，输入成本降低 90%

**优化建议：**
```
使用 Redis 缓存常用翻译:
  - 命中率提升到 60%
  - 月费用降低约 40%
  - MVP 阶段: ¥1.13 → ¥0.68/月
```

**结论：** DeepSeek 的费用仍然几乎可以忽略不计！即使在成熟期，翻译成本也仅约 ¥100/月。

---

## 8. 最佳实践

### 8.1 System Prompt 优化

```python
# ✅ 推荐：简洁明确
system_prompt = 'Translate to English. Output only translation.'

# ❌ 不推荐：过长，浪费 tokens
system_prompt = '''
You are a highly skilled professional translator with expertise in 
Chinese to English translation. Your task is to translate the provided 
Chinese text into English. Please ensure the translation is accurate, 
natural, and maintains the original meaning...
'''
```

### 8.2 Temperature 设置

```python
# 翻译任务
temperature = 0.3  # ✅ 低温度，结果确定性高

# 创意写作
temperature = 0.7  # ❌ 不适合翻译
```

### 8.3 错误重试策略

```python
def translate_with_retry(text, target_lang, max_retries=3):
    """带重试的翻译"""
    for attempt in range(max_retries):
        try:
            return translate_with_deepseek(text, target_lang)
        except Exception as e:
            if attempt == max_retries - 1:
                raise
            print(f"Retry {attempt + 1}/{max_retries}")
            time.sleep(1 * (attempt + 1))  # 指数退避
```

### 8.4 缓存策略

```python
# 先检查 Redis 缓存
cache_key = f"trans:{poi_id}:{target_lang}"
cached = redis_client.get(cache_key)

if cached:
    return cached  # 直接返回缓存
else:
    # 调用 DeepSeek
    translated = translate_with_deepseek(text, target_lang)
    
    # 写入缓存（24小时）
    redis_client.setex(cache_key, 86400, translated)
    
    return translated
```

### 8.5 监控和日志

```python
# 记录关键信息（包括缓存状态）
def main_handler(event, context):
    try:
        result = response.json()
        usage = result.get('usage', {})
        
        # 详细的 token 使用日志
        print(f"Translation request: {text[:50]}... → {target_lang}")
        print(f"Prompt tokens: {usage.get('prompt_tokens', 0)}")
        print(f"Prompt tokens (cached): {usage.get('prompt_tokens_details', {}).get('cached_tokens', 0)}")
        print(f"Completion tokens: {usage.get('completion_tokens', 0)}")
        print(f"Total tokens: {usage.get('total_tokens', 0)}")
        
        # 计算成本（考虑缓存）
        prompt_tokens = usage.get('prompt_tokens', 0)
        cached_tokens = usage.get('prompt_tokens_details', {}).get('cached_tokens', 0)
        uncached_tokens = prompt_tokens - cached_tokens
        completion_tokens = usage.get('completion_tokens', 0)
        
        cost = (
            uncached_tokens * 2 / 1_000_000 +  # 未缓存输入
            cached_tokens * 0.2 / 1_000_000 +   # 缓存输入
            completion_tokens * 3 / 1_000_000    # 输出
        )
        
        print(f"Cost: ¥{cost:.8f}")
        print(f"Cache hit rate: {cached_tokens/prompt_tokens*100:.1f}%")
        
    except Exception as e:
        print(f"Error: {str(e)}")
```

**在 DeepSeek 后台监控：**

```
1. 登录 https://platform.deepseek.com
2. 左侧菜单 → Usage / 使用情况
3. 查看：
   - 每日/每月 token 消耗
   - 缓存命中率
   - 总费用
   - API 调用次数
4. 设置告警：
   - 余额低于 ¥10 时邮件提醒
   - 日消耗超过 ¥5 时提醒
```

---

## 9. 常见问题

### Q1: API Key 泄露怎么办？

**A:** 立即操作：
```
1. 登录 DeepSeek 后台
2. API Keys → 找到泄露的 Key
3. 点击【Delete】删除
4. 点击【Create new secret key】创建新的
5. 更新云函数环境变量
```

### Q2: 翻译质量不好怎么办？

**A:** 优化 System Prompt：
```python
# 通用翻译
'Translate to English. Output only translation.'

# 景点名称翻译
'Translate this Chinese place name to English. Keep it concise and official.'

# 餐厅名称翻译
'Translate this Chinese restaurant name to English. Preserve brand identity.'
```

### Q3: 如何限制翻译长度？

**A:** 使用 `max_tokens` 参数：
```python
payload = {
    'model': 'deepseek-chat',
    'messages': [...],
    'max_tokens': 50  # 限制最多 50 tokens
}
```

### Q4: 遇到 429 错误（Rate Limit）怎么办？

**A:** DeepSeek 限制：
```
免费额度: 60 请求/分钟
付费用户: 300 请求/分钟

解决方法:
1. 实现请求队列
2. 添加重试逻辑（指数退避）
3. 批量请求间隔 1 秒
```

### Q5: 如何监控 API 使用量？

**A:** DeepSeek 后台查看：
```
1. 登录后台 → Usage
2. 查看每日/每月 token 消耗
3. 查看总费用
4. 设置预算告警（推荐）
```

---

## 10. 部署检查清单

```
环境配置:
  ✅ DeepSeek 账号已注册
  ✅ API Key 已创建并保存
  ✅ 账户已充值（推荐 ¥50-100）
  
云函数配置:
  ✅ deepseek_translate 函数已创建
  ✅ VPC 未启用（公网函数）
  ✅ 环境变量 DEEPSEEK_KEY 已设置
  ✅ requirements.txt 已配置
  ✅ 函数 URL 已创建
  ✅ CORS 已开启
  
测试验证:
  ✅ curl 测试通过
  ✅ Postman 测试通过
  ✅ Flutter 集成测试通过
  ✅ 翻译质量验收通过
  
监控告警:
  ✅ DeepSeek 后台设置预算告警
  ✅ 云函数日志查询正常
  ✅ Token 使用量监控就绪
```

---

## 11. 进阶优化

### 11.1 多语言并行翻译

```python
async def translate_multiple_languages(text):
    """并行翻译成英法西三种语言"""
    tasks = [
        translate_with_deepseek(text, 'en'),
        translate_with_deepseek(text, 'fr'),
        translate_with_deepseek(text, 'es'),
    ]
    
    results = await asyncio.gather(*tasks)
    
    return {
        'en': results[0],
        'fr': results[1],
        'es': results[2]
    }
```

### 11.2 翻译质量评分

```python
def score_translation(source, translation):
    """简单的翻译质量评分"""
    score = 100
    
    # 长度检查
    if len(translation) < 2:
        score -= 30
    
    # 是否包含中文（翻译失败）
    if any('\u4e00' <= c <= '\u9fff' for c in translation):
        score -= 50
    
    # 是否有特殊字符
    if any(c in translation for c in ['【', '】', '（', '）']):
        score -= 20
    
    return score
```

### 11.3 Prompt Caching 优化（节省 90% 成本）

**什么是 Prompt Caching？**

DeepSeek-V3.2 支持 Prompt Caching，重复的 System Prompt 会被缓存，缓存命中时输入成本降低 90%。

```python
# 使用固定的 System Prompt（会被缓存）
SYSTEM_PROMPT = 'Translate to English. Output only translation.'

# 第一次调用
# 输入成本: 30 tokens × ¥2/百万 = ¥0.00006

# 后续调用（命中缓存）
# 输入成本: 30 tokens × ¥0.2/百万 = ¥0.000006（降低 90%）
```

**优化策略：**

```python
# ✅ 推荐：固定 System Prompt
def translate_with_deepseek(text, target_lang):
    # 使用固定的 prompt，便于缓存
    lang_map = {'en': 'English', 'fr': 'French', 'es': 'Spanish'}
    
    payload = {
        'model': 'deepseek-chat',
        'messages': [
            {
                'role': 'system',
                'content': f'Translate to {lang_map[target_lang]}. Output only translation.'
            },
            {'role': 'user', 'content': text}
        ],
        'temperature': 0.3
    }
    # System prompt 会被缓存，后续调用成本降低 90%

# ❌ 不推荐：每次变化 System Prompt
def translate_bad(text, target_lang):
    payload = {
        'messages': [
            {
                'role': 'system',
                'content': f'Please translate "{text}" to {target_lang}'
                # 每次都不同，无法命中缓存
            }
        ]
    }
```

**成本对比：**

| 场景 | 不使用缓存 | 使用缓存 | 节省 |
|------|-----------|---------|------|
| 单次翻译 | ¥0.000075 | ¥0.000021 | 72% |
| 1000次/月 | ¥1.13 | ¥0.32 | 72% |
| 10万次/月 | ¥112.5 | ¥31.5 | 72% |

**结论：** 通过使用固定的 System Prompt，可以节省约 70% 的成本！

### 11.4 翻译缓存预热

```python
def preheat_translations():
    """预热常用 POI 翻译"""
    common_pois = [
        '故宫', '天安门', '长城', '颐和园', '天坛',
        '鸟巢', '水立方', '国家博物馆', '北海公园'
    ]
    
    for poi in common_pois:
        translate_and_cache(poi, 'en')
        time.sleep(0.1)  # 避免触发限流
```

```python
def preheat_translations():
    """预热常用 POI 翻译"""
    common_pois = [
        '故宫', '天安门', '长城', '颐和园', '天坛',
        '鸟巢', '水立方', '国家博物馆', '北海公园'
    ]
    
    for poi in common_pois:
        translate_and_cache(poi, 'en')
        time.sleep(0.1)  # 避免触发限流
```

---

## 附录：完整示例

### A. 完整的云函数代码（生产级）

参见文档第 4.2 节

### B. Flutter 完整集成代码

参见文档第 6 节

### C. 测试用例

```python
# test_translation.py
test_cases = [
    ('故宫博物院', 'Palace Museum'),
    ('天安门广场', 'Tiananmen Square'),
    ('长城', 'Great Wall'),
    ('北京烤鸭', 'Peking Duck'),
    ('火锅', 'Hot Pot'),
]

for chinese, expected_english in test_cases:
    result = translate_with_deepseek(chinese, 'en')
    print(f'{chinese} → {result}')
    assert result.lower() == expected_english.lower()
```

---

**文档版本：** v1.1  
**最后更新：** 2026-02-25  
**维护者：** WanderChina Team

---

## 📌 最新定价更新（2026-02-25）

DeepSeek 已升级到 **V3.2** 版本，定价结构有所调整：

### 最新定价表（DeepSeek-V3.2）

| 类型 | 价格 | 说明 |
|------|------|------|
| **输入 tokens（缓存命中）** | ¥0.2/百万 | System Prompt 重复使用时 |
| **输入 tokens（缓存未命中）** | ¥2/百万 | 首次或变化的输入 |
| **输出 tokens** | ¥3/百万 | 模型生成的回复 |

### 成本优化建议

```
1. 使用固定的 System Prompt
   → 缓存命中率提升
   → 输入成本降低 90%

2. 结合 Redis 缓存
   → 避免重复翻译
   → 总成本降低 40-60%

3. 批量翻译
   → 共享 System Prompt
   → 提高缓存命中率

优化后 MVP 阶段成本:
  ¥1.13/月 → ¥0.32/月（使用 Prompt Caching）
```

### WanderChina 实际成本预估（优化后）

| 阶段 | MAU | 月翻译量 | 原始成本 | 优化后成本 | 年成本 |
|------|-----|---------|---------|-----------|--------|
| MVP | 1K | 15K | ¥1.13 | **¥0.32** | **¥3.84** |
| 成长期 | 10K | 150K | ¥11.25 | **¥3.15** | **¥37.8** |
| 成熟期 | 100K | 1.5M | ¥112.5 | **¥31.5** | **¥378** |

**结论：** 即使使用最新定价，DeepSeek 仍然是市场上最经济的翻译 API 方案！
