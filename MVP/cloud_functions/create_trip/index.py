# create_trip/index.py
# -*- coding: utf-8 -*-
"""
行程创建与管理云函数
操作: create（创建行程）、get（获取行程）、list（列出用户行程）、update（更新行程）
Flutter 端负责调用 DeepSeek 生成行程 JSON，本函数仅负责持久化存储
"""
import os
import sys
import uuid
import json
import time

# 导入共享模块（符合 cloud_functions_order 要求）
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from shared.db_helper import get_db_connection, json_response, parse_body

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
            description = body.get('description')
            cities = body.get('cities', [])
            duration_days = body.get('duration_days', 1)
            itinerary_json = body.get('itinerary')  # DeepSeek 生成的完整行程
            interests = body.get('interests', [])
            budget_level = body.get('budget_level', 'medium')
            start_date = body.get('start_date')
            end_date = body.get('end_date')

            if not cities:
                cursor.close()
                return json_response(400, {'error': 'Missing cities'})

            cursor.execute("""
                INSERT INTO trips
                (id, user_id, device_id, title, description, cities, duration_days,
                 itinerary_json, interests, budget_level, start_date, end_date, status)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, 'draft')
                RETURNING id, created_at
            """, (trip_id, user_id, device_id, title, description, cities, duration_days,
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
                'created_at': str(result[1])
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

            if body.get('instruction'):
                cursor.execute("""
                    UPDATE trips SET edit_history = COALESCE(edit_history, '[]'::jsonb) || %s::jsonb
                    WHERE id = %s
                """, (json.dumps([{'instruction': body['instruction'], 'ts': time.strftime('%Y-%m-%d %H:%M:%S')}]), trip_id))

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
