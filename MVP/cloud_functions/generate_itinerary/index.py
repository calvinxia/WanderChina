# generate_itinerary/index.py
# -*- coding: utf-8 -*-
"""
行程生成 + AI 对话编辑云函数（公网函数）
- action: generate — 生成新行程
- action: modify — 用自然语言修改已有行程
调用 DeepSeek，不访问数据库

带完整时间戳日志，用于定位性能瓶颈。
"""
import os
import json
import time

def _call_deepseek(prompt, max_tokens=16384, temperature=0.3, label='generate'):
    """统一的 DeepSeek API 调用（带计时）"""
    import requests

    DEEPSEEK_API_KEY = os.environ.get('DEEPSEEK_API_KEY')
    if not DEEPSEEK_API_KEY:
        raise Exception('DEEPSEEK_API_KEY not configured')

    # 计算 prompt token 大小（粗略估算）
    prompt_len = len(prompt)
    print(f"[TIMING][{label}] prompt_chars={prompt_len}")

    for attempt in range(3):
        try:
            t_req_start = time.time()
            resp = requests.post(
                'https://api.deepseek.com/v1/chat/completions',
                headers={
                    'Authorization': f'Bearer {DEEPSEEK_API_KEY}',
                    'Content-Type': 'application/json',
                },
                json={
                    'model': 'deepseek-v4-flash',
                    'messages': [{'role': 'user', 'content': prompt}],
                    'temperature': temperature, # 注：thinking 模式下被忽略，保留以备未来切换 non-thinking
                    'max_tokens': max_tokens,
                },
                timeout=60,
            )
            t_req_end = time.time()
            resp.raise_for_status()
            print(f"[TIMING][{label}] deepseek_api_call: {(t_req_end - t_req_start)*1000:.0f}ms")
            break
        except Exception as e:
            if attempt < 2:
                print(f"[DEEPSEEK] Retry {attempt + 1}/3: {e}")
                time.sleep(2)
            else:
                raise

    # 解析响应
    t_parse_start = time.time()
    response_json = resp.json()
    message = response_json['choices'][0]['message']
    content = message['content']
    reasoning = message.get('reasoning_content', '')

    # 记录 token 使用量
    usage = response_json.get('usage', {})
    prompt_tokens = usage.get('prompt_tokens', 0)
    completion_tokens = usage.get('completion_tokens', 0)
    total_tokens = usage.get('total_tokens', 0)
    print(f"[TIMING][{label}] tokens: prompt={prompt_tokens}, "
          f"completion={completion_tokens}, total={total_tokens}")
    
    # 记录 thinking 模式的 reasoning 信息（V4 thinking 模式下才有）
    if reasoning:
        print(f"[TIMING][{label}] reasoning_chars={len(reasoning)}")

    # 清理 markdown 包裹
    if '```json' in content:
        content = content.split('```json')[1].split('```')[0]
    elif '```' in content:
        content = content.split('```')[1].split('```')[0]

    result = json.loads(content.strip())
    t_parse_end = time.time()
    print(f"[TIMING][{label}] json_parse: {(t_parse_end - t_parse_start)*1000:.0f}ms")

    return result


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
          "category": "sightseeing",
          "imageKeyword": "descriptive photo search term",
          "description": "Brief description"
        }}
      ]
    }}
  ]
}}

Rules:
- Use real, specific venue names (e.g. "Dim sum at Dian Du De 点都德" not "Lunch at a local dim sum restaurant"). Every activity must reference an actual named place that exists in the city.
- Exactly {days} days, 4-5 activities per day
- Realistic times and costs in CNY
- Each activity must have a category (sightseeing, food, shopping, transport, entertainment) and an imageKeyword for photo search (e.g. "Cantonese dim sum" for a dim sum restaurant, "ancient city wall" for Xi'an Wall)
- Allow at least 30 minutes gap between activities at different locations for transit
- If two activities are in different districts of the city, allow 45-60 minutes for travel
- Bilingual place names (English + Chinese)
- Descriptions in {language}"""

    itinerary = _call_deepseek(prompt, label=f'generate_{days}d')

    if 'days' not in itinerary or not isinstance(itinerary['days'], list):
        raise Exception('DeepSeek response missing days array')

    print(f"[GENERATE] Created {len(itinerary['days'])} days for {city_str}")
    return itinerary


def _modify_itinerary(current_itinerary, instruction, language='english'):
    """用自然语言修改已有行程"""
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
- Maximum 10 activities per day
- Descriptions in {language}
- Realistic times and costs in CNY
- Bilingual place names (English + Chinese)"""

    modified = _call_deepseek(prompt, max_tokens=16384, temperature=0.3, label='modify')

    if 'days' not in modified or not isinstance(modified['days'], list):
        raise Exception('DeepSeek response missing days array')

    print(f"[MODIFY] Applied: '{instruction[:50]}', result: {len(modified['days'])} days")
    return modified


def main_handler(event, context):
    """云函数入口"""
    t_total_start = time.time()
    print(f"[TIMING] ===== REQUEST START =====")

    try:
        t0 = time.time()
        body = event.get('body', '{}')
        if isinstance(body, str):
            body = json.loads(body)
        t1 = time.time()
        print(f"[TIMING] parse_body: {(t1-t0)*1000:.0f}ms")

        action = body.get('action', 'generate')
        print(f"[TIMING] action: {action}")

        # ===== action: modify =====
        if action == 'modify':
            current_itinerary = body.get('itinerary')
            instruction = body.get('instruction', '').strip()
            language = body.get('language', 'english')

            if not current_itinerary:
                return _response(400, {'error': 'Missing itinerary'})
            if not instruction:
                return _response(400, {'error': 'Missing instruction'})

            t2 = time.time()
            modified = _modify_itinerary(
                current_itinerary=current_itinerary,
                instruction=instruction,
                language=language,
            )
            t3 = time.time()
            print(f"[TIMING] modify_itinerary_total: {(t3-t2)*1000:.0f}ms")

            response = _response(200, {
                'itinerary': modified,
                'instruction': instruction,
                'action': 'modify',
            })

            t_end = time.time()
            print(f"[TIMING] ===== TOTAL: {(t_end-t_total_start)*1000:.0f}ms =====")
            return response

        # ===== action: generate =====
        cities = body.get('cities', [])
        days = body.get('days', 1)
        interests = body.get('interests', [])
        budget_level = body.get('budget_level', 'medium')
        language = body.get('language', 'english')

        print(f"[TIMING] params: cities={cities}, days={days}, interests={interests}")

        if not cities:
            return _response(400, {'error': 'Missing cities'})

        t2 = time.time()
        itinerary = _generate_itinerary(
            cities=cities,
            days=days,
            interests=interests,
            budget_level=budget_level,
            language=language,
        )
        t3 = time.time()
        print(f"[TIMING] generate_itinerary_total: {(t3-t2)*1000:.0f}ms")

        city_str = ', '.join(cities)
        interest_str = interests[0] if interests else 'Culture'
        title = f"{city_str} · {days} Days · {interest_str}"

        response = _response(200, {
            'title': title,
            'itinerary': itinerary,
        })

        t_end = time.time()
        print(f"[TIMING] ===== TOTAL: {(t_end-t_total_start)*1000:.0f}ms =====")
        return response

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
