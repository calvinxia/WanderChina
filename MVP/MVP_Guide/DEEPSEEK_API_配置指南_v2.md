# WanderChina DeepSeek API 配置指南

**创建日期：** 2026-02-25
**更新日期：** 2026-03-02（v2.0，对齐腾讯云配置文档）
**用途：** POI 名称翻译 + AI 行程生成
**官网：** https://platform.deepseek.com

---

## 1. DeepSeek API 简介

### 1.1 为什么选择 DeepSeek？

```yaml
优势:
  价格:      业界最低
  质量:      DeepSeek-V3.2，质量接近 GPT-4
  速度:      响应时间 1-3 秒
  稳定性:    99.9% 可用性
  中文支持:  专门优化中文理解
  上下文:    128K tokens

最新定价（DeepSeek-V3.2，USD 计价）:
  输入 tokens（缓存命中）:    $0.028/百万  → ≈¥0.20/百万
  输入 tokens（缓存未命中）:  $0.28/百万   → ≈¥2.02/百万
  输出 tokens:                $0.42/百万   → ≈¥3.02/百万

⚠️ 注意: DeepSeek 官方以 USD 计价，上述 ¥ 值按 1 USD = 7.2 CNY 换算
  汇率波动会影响实际 RMB 成本

对比（折算 RMB）:
  DeepSeek:     ≈¥2-3/百万 tokens
  GPT-3.5:      ≈¥10/百万 tokens
  GPT-4:        ≈¥100/百万 tokens
  Claude:       ≈¥15/百万 tokens
```

### 1.2 WanderChina 使用场景

```
场景 1: 地图 POI 翻译（核心功能）
  输入: "故宫博物院"
  输出: "Palace Museum"
  频率: 每天约 100-500 次（MVP）

场景 2: AI 行程生成
  输入: 用户偏好 + 城市 + 天数
  输出: 完整行程 JSON
  频率: 每天约 20-50 次（MVP）
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

### 2.3 账户充值

```
推荐充值金额（基于 V3.2 定价）:
  测试阶段:  ¥50（够用数月）
  MVP 阶段:  ¥100（够用半年以上）
  正式运营:  ¥500/年

注意：
  - DeepSeek 支持缓存，实际消耗会更少
  - 建议从小额开始测试
  - 后台 → 设置余额告警（推荐余额 < ¥10 时提醒）
```

---

## 3. DeepSeek API 详细参数

### 3.1 API 端点

```
基础 URL: https://api.deepseek.com
聊天接口: POST /v1/chat/completions
```

### 3.2 可用模型

| 模型名 | 用途 | 推荐度 |
|--------|------|--------|
| `deepseek-chat` | 通用对话、翻译、行程生成 | ⭐️⭐️⭐️⭐️⭐️ |
| `deepseek-reasoner` | 推理任务 | ❌（不适合翻译） |

**WanderChina 使用：** `deepseek-chat`

### 3.3 请求参数

```json
{
  "model": "deepseek-chat",
  "messages": [
    {
      "role": "system",
      "content": "Translate the following Chinese text to English. Output only the translation, no explanations."
    },
    {
      "role": "user",
      "content": "故宫博物院"
    }
  ],
  "temperature": 0.3,
  "max_tokens": 100,
  "top_p": 0.9
}
```

### 3.4 响应格式

```json
{
  "choices": [{
    "message": {
      "role": "assistant",
      "content": "Palace Museum"
    },
    "finish_reason": "stop"
  }],
  "usage": {
    "prompt_tokens": 25,
    "completion_tokens": 3,
    "total_tokens": 28,
    "prompt_tokens_details": {
      "cached_tokens": 20
    }
  }
}
```

---

## 4. 云函数配置

### 4.1 环境变量

```yaml
腾讯云控制台 → 云函数 → deepseek_translate → 函数配置 → 环境变量

添加:
  Key:    DEEPSEEK_KEY
  Value:  sk-xxxxxxxxxx

⚠️ 安全:
  - 绝对不要将 API Key 硬编码在代码中
  - 不要提交到 Git 仓库
  - 只通过云函数环境变量传递
  - Flutter App 中不存放 API Key
```

### 4.2 完整云函数代码

**文件：** `deepseek_translate/index.py`

```python
# -*- coding: utf-8 -*-
"""
DeepSeek 翻译云函数（v2.0）
- 支持 Prompt Caching（节省 90% 输入成本）
- MVP 仅支持 en/fr/es 三语种
- 成本精确计算（基于 V3.2 USD 定价 × 汇率）
"""
import json
import os
import requests

# ===== DeepSeek V3.2 定价（USD → RMB）=====
USD_TO_CNY = 7.2
PRICE_INPUT_CACHED = 0.028 * USD_TO_CNY / 1_000_000     # $0.028/1M → ≈¥0.20/M
PRICE_INPUT_UNCACHED = 0.28 * USD_TO_CNY / 1_000_000    # $0.28/1M  → ≈¥2.02/M
PRICE_OUTPUT = 0.42 * USD_TO_CNY / 1_000_000             # $0.42/1M  → ≈¥3.02/M

# 固定 System Prompt（提高缓存命中率）—— MVP 仅 3 语种
SYSTEM_PROMPTS = {
    'en': 'Translate the following Chinese text to English. Output only the translation, no explanations.',
    'fr': 'Translate the following Chinese text to French. Output only the translation, no explanations.',
    'es': 'Translate the following Chinese text to Spanish. Output only the translation, no explanations.',
}

SUPPORTED_LANGS = list(SYSTEM_PROMPTS.keys())  # ['en', 'fr', 'es']

# 输入安全限制
MAX_TEXT_LENGTH = 200

def translate_with_deepseek(text, target_lang):
    url = 'https://api.deepseek.com/v1/chat/completions'
    api_key = os.environ.get('DEEPSEEK_KEY')
    if not api_key:
        raise ValueError('Missing DEEPSEEK_KEY')

    headers = {
        'Authorization': f'Bearer {api_key}',
        'Content-Type': 'application/json'
    }

    payload = {
        'model': 'deepseek-chat',
        'messages': [
            {'role': 'system', 'content': SYSTEM_PROMPTS[target_lang]},
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

        usage = result.get('usage', {})
        prompt_tokens = usage.get('prompt_tokens', 0)
        completion_tokens = usage.get('completion_tokens', 0)
        prompt_details = usage.get('prompt_tokens_details', {})
        cached_tokens = prompt_details.get('cached_tokens', 0)
        uncached_tokens = prompt_tokens - cached_tokens

        cost = (
            uncached_tokens * PRICE_INPUT_UNCACHED +
            cached_tokens * PRICE_INPUT_CACHED +
            completion_tokens * PRICE_OUTPUT
        )

        cache_hit_rate = (cached_tokens / prompt_tokens * 100) if prompt_tokens > 0 else 0
        print(f"[TRANSLATE] '{text[:30]}' → '{translated_text[:30]}' | "
              f"tokens={prompt_tokens}(cached:{cached_tokens})+{completion_tokens} | "
              f"cache={cache_hit_rate:.0f}% | cost=¥{cost:.6f}")

        return {
            'translated_text': translated_text,
            'usage': {
                'prompt_tokens': prompt_tokens,
                'cached_tokens': cached_tokens,
                'completion_tokens': completion_tokens,
                'cache_hit_rate': cache_hit_rate
            },
            'cost': cost
        }

    except requests.exceptions.Timeout:
        raise Exception('DeepSeek API timeout')
    except requests.exceptions.HTTPError as e:
        if e.response.status_code == 401:
            raise Exception('Invalid DeepSeek API key')
        elif e.response.status_code == 429:
            raise Exception('DeepSeek rate limit exceeded')
        else:
            raise Exception(f'DeepSeek API error: {e.response.status_code}')

def main_handler(event, context):
    try:
        if isinstance(event, dict) and 'body' in event:
            body = json.loads(event['body'])
        else:
            body = event

        text = body.get('text')
        target_lang = body.get('target_lang', 'en')

        if not text:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'Missing parameter: text'})
            }

        if len(text) > MAX_TEXT_LENGTH:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': f'Text exceeds {MAX_TEXT_LENGTH} chars'})
            }

        if target_lang not in SUPPORTED_LANGS:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': f'Unsupported language. Supported: {SUPPORTED_LANGS}'})
            }

        result = translate_with_deepseek(text, target_lang)

        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({
                'translated_text': result['translated_text'],
                'source_text': text,
                'target_lang': target_lang,
                'usage': result['usage'],
                'cost': result['cost']
            }, ensure_ascii=False)
        }

    except Exception as e:
        print(f'[ERROR] {str(e)}')
        import traceback; traceback.print_exc()
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': str(e)})
        }
```

**requirements.txt：**
```
requests==2.31.0
```

### 4.3 Redis 缓存集成

翻译缓存在内网函数 `translate_db_write` 中完成，详见 `WANDERCHINA_TENCENT_CLOUD_CONFIG v2.0` §7.5。

**缓存 Key 格式（统一规范）：**
```
poi:trans:{gaode_poi_id}:{lang}

示例:
  poi:trans:B000A8UJVW:en → "Palace Museum"
  poi:trans:B000A8UJVW:fr → "Musée du Palais"

TTL: 24 小时（86400 秒）
```

---

## 5. 测试

### 5.1 使用 curl 测试 DeepSeek API

```bash
curl -X POST https://api.deepseek.com/v1/chat/completions \
  -H "Authorization: Bearer sk-your-api-key-here" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "deepseek-chat",
    "messages": [
      {"role": "system", "content": "Translate to English. Output only translation."},
      {"role": "user", "content": "故宫博物院"}
    ],
    "temperature": 0.3
  }'
```

### 5.2 测试云函数（部署后）

```bash
# 函数 URL 格式（从腾讯云控制台获取实际地址）
curl -X POST https://service-{id}-{appid}.gz.tencentcs.com/ \
  -H "Content-Type: application/json" \
  -d '{"text": "故宫博物院", "target_lang": "en"}'
```

---

## 6. Flutter 集成

> **注意：** Flutter 端不直接调用 DeepSeek API，而是通过云函数 URL 间接调用。
> 完整 Flutter 客户端代码见 `WANDERCHINA_TENCENT_CLOUD_CONFIG v2.0` §11。

**翻译调用流程：**
```dart
// 调用翻译云函数（非直接调用 DeepSeek）
final result = await ApiClient.post(
  ApiClient.translateUrl,  // 从 .env 读取函数 URL
  {'text': '故宫博物院', 'target_lang': 'en'},
);
print(result['translated_text']);  // "Palace Museum"
```

---

## 7. 费用估算

### 7.1 单次成本（V3.2 USD 定价，按 1 USD = 7.2 CNY）

```yaml
一次 POI 翻译:
  输入: ~30 tokens × $0.28/1M × 7.2 = ¥0.000060
  输出: ~5 tokens × $0.42/1M × 7.2  = ¥0.000015
  合计: ≈ ¥0.000075/次

  缓存命中时:
  输入: ~30 tokens × $0.028/1M × 7.2 = ¥0.000006
  输出: ~5 tokens × $0.42/1M × 7.2   = ¥0.000015
  合计: ≈ ¥0.000021/次（节省 72%）

一次行程生成:
  输入: ~500 tokens × $0.28/1M × 7.2 = ¥0.001008
  输出: ~2000 tokens × $0.42/1M × 7.2 = ¥0.006048
  合计: ≈ ¥0.0071/次
```

### 7.2 各阶段费用

| 阶段 | MAU | POI 翻译/月 | 行程生成/月 | 翻译费 | 行程费 | 月总计 |
|------|-----|-----------|-----------|--------|--------|--------|
| MVP | 1K | 15,000 | 1,500 | ¥1.1 | ¥10.6 | **≈¥12** |
| 成长期 | 10K | 150,000 | 15,000 | ¥11 | ¥106 | **≈¥117** |
| 成熟期 | 100K | 1,500,000 | 150,000 | ¥112 | ¥1,063 | **≈¥1,175** |

> 以上为未命中缓存的最大值。Prompt Caching + Redis 缓存可降低 50-70%。

---

## 8. 最佳实践

### 8.1 System Prompt 优化

```python
# ✅ 固定 Prompt → 缓存命中率高
'Translate the following Chinese text to English. Output only the translation, no explanations.'

# ❌ 每次变化 → 无法缓存
f'Please translate "{text}" to English'  # text 每次不同
```

### 8.2 错误重试

```python
import time

def translate_with_retry(text, target_lang, max_retries=3):
    for attempt in range(max_retries):
        try:
            return translate_with_deepseek(text, target_lang)
        except Exception as e:
            if attempt == max_retries - 1:
                raise
            print(f"Retry {attempt + 1}/{max_retries}: {e}")
            time.sleep(1 * (attempt + 1))
```

### 8.3 翻译缓存预热

```python
def preheat_translations():
    """预热 6 城市核心 POI 翻译"""
    import time
    common_pois = [
        '故宫', '天安门', '长城', '颐和园', '天坛',
        '鸟巢', '水立方', '国家博物馆', '北海公园'
    ]
    for poi in common_pois:
        for lang in ['en', 'fr', 'es']:
            translate_and_cache(poi, lang)
            time.sleep(0.1)  # 避免触发限流
```

---

## 9. 部署检查清单

```
环境配置:
  ✅ DeepSeek 账号注册 + 充值（推荐 ¥50-100）
  ✅ API Key 创建并保存
  ✅ 后台设置余额告警

云函数:
  ✅ deepseek_translate 创建（公网，不启用 VPC）
  ✅ 环境变量 DEEPSEEK_KEY 配置
  ✅ 函数 URL 启用 + CORS 开启
  ✅ 超时设置 15 秒、内存 256MB

测试:
  ✅ curl 直测 DeepSeek API 通过
  ✅ curl 测试云函数 URL 通过
  ✅ en/fr/es 三语种翻译质量验收

监控:
  ✅ DeepSeek 后台查看 token 用量
  ✅ 云函数日志包含成本信息
```

---

**版本历史：**
- v1.0（2026-02-25）: 初始版本
- v1.1（2026-02-25）: 添加 V3.2 定价更新
- v2.0（2026-03-02）: 对齐腾讯云配置文档 v2.0
  - 修正: 定价单位从 ¥ 改为 USD（$0.28/$0.028/$0.42）× 汇率
  - 修正: 支持语种从 6 个缩减为 3 个（en/fr/es）
  - 修正: 测试 URL 从 API 网关格式改为函数 URL 格式
  - 修正: 添加输入长度限制（MAX_TEXT_LENGTH = 200）
  - 删除: Flutter 独立集成代码（统一到 v2.0 §11）
  - 删除: 重复的翻译预热函数
  - 新增: 行程生成费用估算
  - 新增: 缓存 Key 格式统一为 poi:trans:{id}:{lang}
