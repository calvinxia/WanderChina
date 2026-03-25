# create_trip/index.py
# -*- coding: utf-8 -*-
"""
行程创建与管理云函数
操作: create（创建行程）、get（获取行程）、list（列出用户行程）、update（更新行程）
create 时如果前端未传 itinerary，自动调用 DeepSeek 生成行程内容
"""
import os
import sys
import uuid
import json

# 导入共享模块（符合 cloud_functions_order 要求）
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from shared.db_helper import get_db_connection, json_response, parse_body


# ─── DeepSeek 行程生成 ─────────────────────────────────────────────

def _generate_itinerary(cities, days, interests, budget_level, language='english'):
    """调用 DeepSeek 生成行程 JSON

    Args:
        cities: 城市列表，如 ['Beijing']
        days: 天数，如 3
        interests: 兴趣列表，如 ['Culture', 'Food']
        budget_level: 预算等级，如 'medium'
        language: 输出语言，如 'english'

    Returns:
        dict: 行程 JSON，包含 days 数组
    """
    import requests

    DEEPSEEK_API_KEY = os.environ.get('DEEPSEEK_API_KEY')
    if not DEEPSEEK_API_KEY:
        raise Exception('DEEPSEEK_API_KEY not configured')

    city_str = ', '.join(cities) if cities else 'Beijing'
    interest_str = ', '.join(interests) if interests else 'Culture, Food'

    prompt = f"""Create a {days}-day travel itinerary for {city_str}, China.
Traveler interests: {interest_str}.
Budget level: {budget_level}.

Return ONLY valid JSON in this exact format, no explanations or markdown:
{{
  "days": [
    {{
      "day_number": 1,
      "title": "Short day theme title",
      "city": "{cities[0] if cities else 'Beijing'}",
      "summary": "One sentence day summary",
      "estimated_cost": 200,
      "activities": [
        {{
          "time": "09:00",
          "name": "Place Name in English",
          "name_zh": "中文地名",
          "duration": "2-3 hrs",
          "cost": "¥60",
          "description": "Brief description of this activity",
          "latitude": 39.9163,
          "longitude": 116.3972
        }}
      ],
      "transit": [
        {{
          "from_index": 0,
          "to_index": 1,
          "mode": "walk",
          "duration": "10 min",
          "distance": "0.8 km"
        }}
      ]
    }}
  ]
}}

Requirements:
- Each day should have 3-5 activities
- Include realistic times, costs in CNY (¥), and durations
- Include transit info between consecutive activities
- Transit modes: walk, subway, bus, taxi
- Provide real latitude/longitude coordinates for each place
- All place names bilingual (English + Chinese)
- Output language for descriptions: {language}"""

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

        content = resp.json()['choices'][0]['message']['content']

        # DeepSeek 可能用 ```json ``` 包裹输出
        if '```json' in content:
            content = content.split('```json')[1].split('```')[0]
        elif '```' in content:
            content = content.split('```')[1].split('```')[0]

        itinerary = json.loads(content.strip())

        # 基本校验
        if 'days' not in itinerary or not isinstance(itinerary['days'], list):
            raise Exception('DeepSeek response missing days array')

        print(f"[TRIP] DeepSeek generated {len(itinerary['days'])} days for {city_str}")
        return itinerary

    except json.JSONDecodeError as e:
        print(f"[TRIP ERROR] DeepSeek returned invalid JSON: {e}")
        print(f"[TRIP ERROR] Raw content: {content[:500]}")
        raise Exception(f'Failed to parse DeepSeek itinerary: {e}')
    except requests.exceptions.Timeout:
        print("[TRIP ERROR] DeepSeek request timed out")
        raise Exception('Itinerary generation timed out, please try again')
    except Exception as e:
        print(f"[TRIP ERROR] DeepSeek itinerary generation failed: {e}")
        raise


# ─── 云函数入口 ─────────────────────────────────────────────────────

def main_handler(event, context):
    """云函数入口（符合 cloud_functions_order 统一规范）"""
    try:
        # 使用统一的请求体解析
        body = parse_body(event)

        action = body.get('action', 'create')
        conn = get_db_connection()
        cursor = conn.cursor()

        # ===== 创建行程 =====
        if action == 'create':
            trip_id = str(uuid.uuid4())
            user_id = body.get('user_id')         # UUID 或 None
            device_id = body.get('device_id')       # 匿名用户
            title = body.get('title', 'My Trip')
            cities = body.get('cities', [])
            duration_days = body.get('duration_days') or body.get('days', 1)
            itinerary_json = body.get('itinerary')  # 前端可选传入
            interests = body.get('interests', [])
            budget_level = body.get('budget_level', 'medium')
            start_date = body.get('start_date')
            end_date = body.get('end_date')
            language = body.get('language', 'english')

            if not cities:
                cursor.close()
                return json_response(400, {'error': 'Missing cities'})

            # 如果前端没传 itinerary，调 DeepSeek 自动生成
            if not itinerary_json:
                print(f"[TRIP] No itinerary provided, generating via DeepSeek...")
                print(f"[TRIP] cities={cities}, days={duration_days}, interests={interests}")
                itinerary_json = _generate_itinerary(
                    cities=cities,
                    days=duration_days,
                    interests=interests,
                    budget_level=budget_level,
                    language=language,
                )
                # 自动生成标题
                city_str = ', '.join(cities)
                interest_str = interests[0] if interests else 'Culture'
                title = f"{city_str} · {duration_days} Days · {interest_str}"

            cursor.execute("""
                INSERT INTO trips
                (id, user_id, device_id, title, cities, duration_days,
                 itinerary_json, interests, budget_level, start_date, end_date, status)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, 'draft')
                RETURNING id, created_at
            """, (trip_id, user_id, device_id, title, cities, duration_days,
                  json.dumps(itinerary_json) if itinerary_json else None,
                  interests, budget_level, start_date, end_date))

            result = cursor.fetchone()

            # 如果有 itinerary，按天拆分存入 trip_days
            if itinerary_json and isinstance(itinerary_json, dict):
                days = itinerary_json.get('days', [])
                for day in days:
                    day_num = day.get('day_number', 1)
                    cursor.execute("""
                        INSERT INTO trip_days
                        (trip_id, day_number, city, activities, summary, estimated_cost)
                        VALUES (%s, %s, %s, %s, %s, %s)
                    """, (trip_id, day_num,
                          day.get('city', cities[0] if cities else ''),
                          json.dumps(day.get('activities', [])),
                          day.get('summary'),
                          day.get('estimated_cost')))

            # 更新用户行程计数
            if user_id:
                cursor.execute("""
                    UPDATE users SET trips_count = trips_count + 1
                    WHERE id = %s
                """, (user_id,))

            conn.commit()
            cursor.close()

            return json_response(201, {
                'trip_id': trip_id,
                'title': title,
                'created_at': str(result[1]),
                'itinerary': itinerary_json,
            })

        # ===== 获取单个行程 =====
        elif action == 'get':
            trip_id = body.get('trip_id')
            if not trip_id:
                cursor.close()
                return json_response(400, {'error': 'Missing trip_id'})

            cursor.execute("""
                SELECT id, title, cities, duration_days, itinerary_json,
                       budget_level, interests, status, start_date, end_date,
                       created_at, updated_at
                FROM trips WHERE id = %s
            """, (trip_id,))
            row = cursor.fetchone()

            if not row:
                cursor.close()
                return json_response(404, {'error': 'Trip not found'})

            # 获取天数详情
            cursor.execute("""
                SELECT day_number, city, activities, summary, estimated_cost
                FROM trip_days WHERE trip_id = %s ORDER BY day_number
            """, (trip_id,))
            days = []
            for d in cursor.fetchall():
                days.append({
                    'day_number': d[0],
                    'city': d[1],
                    'activities': d[2] if isinstance(d[2], list) else json.loads(d[2] or '[]'),
                    'summary': d[3],
                    'estimated_cost': float(d[4]) if d[4] else None
                })

            cursor.close()
            return json_response(200, {
                'trip_id': str(row[0]),
                'title': row[1],
                'cities': row[2],
                'duration_days': row[3],
                'budget_level': row[5],
                'interests': row[6],
                'status': row[7],
                'start_date': str(row[8]) if row[8] else None,
                'end_date': str(row[9]) if row[9] else None,
                'days': days,
                'created_at': str(row[10]),
                'updated_at': str(row[11])
            })

        # ===== 列出用户行程 =====
        elif action == 'list':
            user_id = body.get('user_id')
            device_id = body.get('device_id')
            limit = min(body.get('limit', 20), 50)

            if user_id:
                cursor.execute("""
                    SELECT id, title, cities, duration_days, status, created_at
                    FROM trips WHERE user_id = %s
                    ORDER BY created_at DESC LIMIT %s
                """, (user_id, limit))
            elif device_id:
                cursor.execute("""
                    SELECT id, title, cities, duration_days, status, created_at
                    FROM trips WHERE device_id = %s
                    ORDER BY created_at DESC LIMIT %s
                """, (device_id, limit))
            else:
                cursor.close()
                return json_response(400, {'error': 'Missing user_id or device_id'})

            trips = []
            for row in cursor.fetchall():
                trips.append({
                    'trip_id': str(row[0]),
                    'title': row[1],
                    'cities': row[2],
                    'duration_days': row[3],
                    'status': row[4],
                    'created_at': str(row[5])
                })

            cursor.close()
            return json_response(200, {'trips': trips, 'count': len(trips)})

        # ===== 更新行程 =====
        elif action == 'update':
            trip_id = body.get('trip_id')
            if not trip_id:
                cursor.close()
                return json_response(400, {'error': 'Missing trip_id'})

            updates = []
            params = []
            for field in ['title', 'status', 'budget_level']:
                if field in body:
                    updates.append(f"{field} = %s")
                    params.append(body[field])

            if body.get('itinerary'):
                updates.append("itinerary_json = %s")
                params.append(json.dumps(body['itinerary']))

            if not updates:
                cursor.close()
                return json_response(400, {'error': 'No fields to update'})

            params.append(trip_id)
            cursor.execute(
                f"UPDATE trips SET {', '.join(updates)}, updated_at = NOW() WHERE id = %s",
                params
            )
            conn.commit()
            cursor.close()

            return json_response(200, {'success': True, 'trip_id': trip_id})

        else:
            cursor.close()
            return json_response(400, {
                'error': f'Unknown action: {action}. '
                         f'Supported: create, get, list, update'
            })

    except Exception as e:
        print(f"[TRIP ERROR] {str(e)}")
        import traceback
        traceback.print_exc()
        return json_response(500, {'error': str(e)})
