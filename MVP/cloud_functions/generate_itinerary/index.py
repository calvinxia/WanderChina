# generate_itinerary/index.py
# -*- coding: utf-8 -*-
"""
行程生成云函数（公网函数）
调用 DeepSeek 生成旅行行程 JSON
不访问数据库，纯公网调用
"""
import os
import json
import time


def _generate_itinerary(cities, days, interests, budget_level='medium', language='english'):
    """调用 DeepSeek 生成行程 JSON"""
    import requests

    DEEPSEEK_API_KEY = os.environ.get('DEEPSEEK_API_KEY')
    if not DEEPSEEK_API_KEY:
        raise Exception('DEEPSEEK_API_KEY not configured')

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
                    'temperature': 0.7,
                    'max_tokens': 4096,
                },
                timeout=60,
            )
            resp.raise_for_status()
            break
         except requests.exceptions.RequestException as e:
            if attempt < 2:
                print(f"[GENERATE] Retry {attempt + 1}/3: {e}")
                time.sleep(2)
            else:
                raise

    content = resp.json()['choices'][0]['message']['content']

    if '```json' in content:
        content = content.split('```json')[1].split('```')[0]
    elif '```' in content:
        content = content.split('```')[1].split('```')[0]

    itinerary = json.loads(content.strip())

    if 'days' not in itinerary or not isinstance(itinerary['days'], list):
        raise Exception('DeepSeek response missing days array')

    print(f"[GENERATE] DeepSeek generated {len(itinerary['days'])} days for {city_str}")
    return itinerary


def main_handler(event, context):
    """云函数入口"""
    try:
        body = event.get('body', '{}')
        if isinstance(body, str):
            body = json.loads(body)

        cities = body.get('cities', [])
        days = body.get('days', 1)
        interests = body.get('interests', [])
        budget_level = body.get('budget_level', 'medium')
        language = body.get('language', 'english')

        if not cities:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({'error': 'Missing cities'})
            }

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

        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'title': title,
                'itinerary': itinerary,
            }, ensure_ascii=False)
        }

    except json.JSONDecodeError as e:
        print(f"[GENERATE ERROR] Invalid JSON from DeepSeek: {e}")
        return {
            'statusCode': 502,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'error': f'Failed to parse AI response: {e}'})
        }
    except Exception as e:
        print(f"[GENERATE ERROR] {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'error': str(e)})
        }
