# subscription_sync/index.py
# -*- coding: utf-8 -*-
"""
订阅状态同步云函数（定时触发，VPC）
每日 UTC 16:00（北京时间 0:00）执行
将 premium_expires_at < NOW() 的用户标记为 is_premium = false
幂等：多次执行无副作用
"""
import os
import sys
import json

sys.path.insert(0, os.path.dirname(__file__) or '.')
from shared.db_helper import get_db_connection


def main_handler(event, context):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute("""
            UPDATE users
            SET is_premium = false, updated_at = NOW()
            WHERE is_premium = true AND premium_expires_at < NOW()
            RETURNING id
        """)

        expired_rows = cursor.fetchall()
        expired_count = len(expired_rows)

        conn.commit()
        cursor.close()

        expired_ids = [str(row[0]) for row in expired_rows]

        if expired_count > 0:
            print(f"[SUBSCRIPTION_SYNC] Expired {expired_count} users: {expired_ids[:10]}")
        else:
            print("[SUBSCRIPTION_SYNC] No expired subscriptions found")

        return {
            'success': True,
            'expired_count': expired_count,
            'expired_user_ids': expired_ids,
        }

    except Exception as e:
        print(f"[SUBSCRIPTION_SYNC ERROR] {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'success': False,
            'error': str(e),
        }
