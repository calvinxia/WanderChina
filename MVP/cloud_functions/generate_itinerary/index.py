# generate_itinerary/index.py
# -*- coding: utf-8 -*-
"""
行程生成 + AI 对话编辑云函数（公网函数）
- action: generate — 生成新行程
- action: modify — 用自然语言修改已有行程
调用 DeepSeek，不访问数据库
"""
import os
import json
import time


def _call_deepseek(prompt, max_tokens=4096, temperature=0.3):
    """统一的 DeepSeek API 调用"""
    import requests

    DEEPSEEK_API_KEY = os.environ.get('DEEPSEEK_API_KEY')
    if not DEEPSEEK_API_KEY:
        raise Exception('DEEPSEEK_API_KEY not configured')

    for attempt in range(3):
        try:
            resp = requests.post(
                'https://api.deepseek.com/v1/chat/completions',
                headers={
                    'Authorization': f'Bearer {DEEPSEEK_API_KEY}',
                    'Content-Type': 'application/json',
                },
                json={
                    'model': 'deepseek-chat',
                    'messages': [{'role': 'user', 'content': prompt}],
                    'temperature': temperature,
                    'max_tokens': max_tokens,
                },
                timeout=60,
            )
            resp.raise_for_status()
            break
        except Exception as e:
            if attempt < 2:
                print(f"[DEEPSEEK] Retry {attempt + 1}/3: {e}")
                time.sleep(2)
            else:
                raise

    content = resp.json()['choices'][0]['message']['content']

    # 清理 markdown 包裹
    if '```json' in content:
        content = content.split('```json')[1].split('```')[0]
    elif '```' in content:
        content = content.split('```')[1].split('```')[0]

    return json.loads(content.strip())


def _generate_itinerary(cities, days, interests, budget_level='medium', language='english'):
    """生成新行程"""
    city_str = ', '.join(cities) if cities else 'Beijing'
    interest_str = ', '.join(interests) if interests else 'Culture, Food'

    prompt = f"""Create a {days}-day travel itinerary for {city_str}, China.
Traveler interests: {interest_str}.
Budget level: {budget_level}.

Return ONLY valid JSON, no markdown or explanation:
{{
  "days": [
    {{
      "day_number": 1,
      "title": "Day theme",
      "city": "{cities[0] if cities else 'Beijing'}",
      "summary": "One sentence summary",
      "estimated_cost": 200,
      "activities": [
        {{
          "time": "09:00",
          "name": "Place Name",
          "name_zh": "中文名",
          "duration": "2 hrs",
          "cost": "¥60",
          "description": "Brief description"
        }}
      ]
    }}
  ]
}}

Rules:
- Exactly {days} days, 3-4 activities per day
- Realistic times and costs in CNY
- Bilingual place names (English + Chinese)
- Descriptions in {language}"""

    itinerary = _call_deepseek(prompt)

    if 'days' not in itinerary or not isinstance(itinerary['days'], list):
        raise Exception('DeepSeek response missing days array')

    print(f"[GENERATE] Created {len(itinerary['days'])} days for {city_str}")
    return itinerary


def _modify_itinerary(current_itinerary, instruction, language='english'):
    """用自然语言修改已有行程"""

    # 精简当前行程 JSON（只保留结构关键字段，减少 token 消耗）
    simplified = json.dumps(current_itinerary, ensure_ascii=False, indent=2)

    prompt = f"""You are a travel itinerary editor. Here is the current itinerary:

{simplified}

The user wants to make this change: "{instruction}"

Apply the requested change and return the COMPLETE modified itinerary as valid JSON.
Keep the same JSON structure. Only modify what the user asked for.
All other activities, times, and details should remain unchanged.

Rules:
- Return ONLY valid JSON, no markdown or explanation
- Keep the same structure with "days" array
- Each activity must have: time, name, name_zh, duration, cost, description
- Descriptions in {language}
- Realistic times and costs in CNY
- Bilingual place names (English + Chinese)"""

    modified = _call_deepseek(prompt, max_tokens=4096, temperature=0.3)

    if 'days' not in modified or not isinstance(modified['days'], list):
        raise Exception('DeepSeek response missing days array')

    print(f"[MODIFY] Applied: '{instruction[:50]}', result: {len(modified['days'])} days")
    return modified


def main_handler(event, context):
    """云函数入口"""
    try:
        body = event.get('body', '{}')
        if isinstance(body, str):
            body = json.loads(body)

        action = body.get('action', 'generate')

        # ===== action: modify（AI 对话编辑行程）=====
        if action == 'modify':
            current_itinerary = body.get('itinerary')
            instruction = body.get('instruction', '').strip()
            language = body.get('language', 'english')

            if not current_itinerary:
                return _response(400, {'error': 'Missing itinerary'})
            if not instruction:
                return _response(400, {'error': 'Missing instruction'})

            modified = _modify_itinerary(
                current_itinerary=current_itinerary,
                instruction=instruction,
                language=language,
            )

            return _response(200, {
                'itinerary': modified,
                'instruction': instruction,
                'action': 'modify',
            })

        # ===== action: generate（生成新行程）=====
        cities = body.get('cities', [])
        days = body.get('days', 1)
        interests = body.get('interests', [])
        budget_level = body.get('budget_level', 'medium')
        language = body.get('language', 'english')

        if not cities:
            return _response(400, {'error': 'Missing cities'})

        itinerary = _generate_itinerary(
            cities=cities,
            days=days,
            interests=interests,
            budget_level=budget_level,
            language=language,
        )

        city_str = ', '.join(cities)
        interest_str = interests[0] if interests else 'Culture'
        title = f"{city_str} · {days} Days · {interest_str}"

        return _response(200, {
            'title': title,
            'itinerary': itinerary,
        })

    except json.JSONDecodeError as e:
        print(f"[ERROR] Invalid JSON from DeepSeek: {e}")
        return _response(502, {'error': f'Failed to parse AI response: {e}'})
    except Exception as e:
        print(f"[ERROR] {str(e)}")
        import traceback
        traceback.print_exc()
        return _response(500, {'error': str(e)})


def _response(code, body):
    return {
        'statusCode': code,
        'headers': {'Content-Type': 'application/json'},
        'body': json.dumps(body, ensure_ascii=False)
    }
