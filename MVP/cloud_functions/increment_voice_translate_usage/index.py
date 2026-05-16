# increment_voice_translate_usage/index.py
# -*- coding: utf-8 -*-
"""
语音翻译配额累加云函数（VPC 函数）
翻译成功后由前端调用，UPSERT usage_quota 表
跨日自动重置 used_count
"""
import os
import sys
import json

sys.path.insert(0, os.path.dirname(__file__) or '.')
from shared.db_helper import get_db_connection, json_response, parse_body


def main_handler(event, context):
    try:
        body = parse_body(event)
        user_id = body.get('user_id')

        if not user_id:
            return json_response(400, {'error': 'Missing user_id'})

        conn = get_db_connection()
        cursor = conn.cursor()

        # UPSERT: 首次=1, 同日=+1, 跨日=重置为1
        cursor.execute("""
            INSERT INTO usage_quota (user_id, feature, used_count, last_reset_at)
            VALUES (%s, 'voice_translate', 1, CURRENT_TIMESTAMP)
            ON CONFLICT (user_id, feature) DO UPDATE
            SET used_count = CASE
                    WHEN usage_quota.last_reset_at::date < CURRENT_DATE
                    THEN 1
                    ELSE usage_quota.used_count + 1
                END,
                last_reset_at = CASE
                    WHEN usage_quota.last_reset_at::date < CURRENT_DATE
                    THEN CURRENT_TIMESTAMP
                    ELSE usage_quota.last_reset_at
                END
            RETURNING used_count
        """, (user_id,))

        used_count = cursor.fetchone()[0]
        conn.commit()
        cursor.close()

        print(f"[VOICE_USAGE] user={user_id}, used_today={used_count}")

        return json_response(200, {
            'success': True,
            'used_today': used_count,
        })

    except Exception as e:
        print(f"[VOICE_USAGE ERROR] {str(e)}")
        import traceback
        traceback.print_exc()
        return json_response(500, {'error': str(e)})
