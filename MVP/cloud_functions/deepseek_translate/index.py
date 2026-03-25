# deepseek_translate/index.py
# -*- coding: utf-8 -*-
"""
DeepSeek 翻译云函数
- 支持 Prompt Caching（节省 90% 输入成本）
- MVP 仅支持 en/fr/es 三语种
- 成本精确计算（基于 V3.2 USD 定价 × 汇率）
"""
import os
import sys
import requests

# 导入共享模块（符合 cloud_functions_order 要求）
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from shared.db_helper import json_response, parse_body

# DeepSeek V3.2 定价（USD → RMB）
USD_TO_CNY = 7.2
PRICE_INPUT_CACHED = 0.028 * USD_TO_CNY / 1_000_000     # $0.028/1M → ≈¥0.20/M
PRICE_INPUT_UNCACHED = 0.28 * USD_TO_CNY / 1_000_000    # $0.28/1M  → ≈¥2.02/M
PRICE_OUTPUT = 0.42 * USD_TO_CNY / 1_000_000             # $0.42/1M  → ≈¥3.02/M

# 固定 System Prompt（提高缓存命中率）
SYSTEM_PROMPTS = {
    'en': 'Translate the following Chinese text to English. Output only the translation, no explanations.',
    'fr': 'Translate the following Chinese text to French. Output only the translation, no explanations.',
    'es': 'Translate the following Chinese text to Spanish. Output only the translation, no explanations.',
}

SUPPORTED_LANGS = list(SYSTEM_PROMPTS.keys())

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
        raise Exception(f'DeepSeek API error: {e.response.status_code}')

def main_handler(event, context):
    """云函数入口（符合 cloud_functions_order 统一规范）"""
    try:
        # 使用统一的请求体解析
        body = parse_body(event)

        text = body.get('text')
        target_lang = body.get('target_lang', 'en')

        if not text:
            return json_response(400, {'error': 'Missing parameter: text'})

        if target_lang not in SUPPORTED_LANGS:
            return json_response(400, {
                'error': f'Unsupported language. Supported: {SUPPORTED_LANGS}'
            })

        result = translate_with_deepseek(text, target_lang)

        # 使用统一的响应格式
        return json_response(200, {
            'translated_text': result['translated_text'],
            'source_text': text,
            'target_lang': target_lang,
            'usage': result['usage'],
            'cost': result['cost']
        })

    except Exception as e:
        print(f'[ERROR] {str(e)}')
        import traceback
        traceback.print_exc()
        return json_response(500, {'error': str(e)})
