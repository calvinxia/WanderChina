# check_user_quota/index.py
# -*- coding: utf-8 -*-
"""
配额检查云函数 (薄壳).
核心判断逻辑在 shared/quota_check.py.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__) or '.')
from shared.db_helper import get_db_connection, json_response, parse_body
from shared.quota_check import (
    check_itinerary_quota,
    check_voice_translate_quota,
    check_ai_edit_quota,
    get_flags,
)


def main_handler(event, context):
    conn = None
    cursor = None
    try:
        body = parse_body(event)
        user_id = body.get('user_id')
        quota_type = body.get('quota_type')

        if not user_id:
            return json_response(400, {'error': 'Missing user_id'})
        if quota_type not in ('itinerary', 'voice_translate', 'ai_edit'):
            return json_response(400, {
                'error': f'Invalid quota_type: {quota_type}. '
                         f'Must be one of: itinerary, voice_translate, ai_edit'
            })

        conn = get_db_connection()
        cursor = conn.cursor()
        
         # 总开关检查 (paywall_enabled=false 时所有功能免费, 与 005_feature_flags.sql 设计一致)
        master_flag = get_flags(cursor, ['paywall_enabled'])
        paywall_enabled = master_flag.get('paywall_enabled', True)  # 缺失默认 True 保守

        if not paywall_enabled:
            cursor.close()
            return json_response(200, {
                'allowed': True,
                'reason': 'paywall_disabled',
                'trigger_paywall': False,
            })

        # 按 quota_type 分发
        if quota_type == 'itinerary':
            result = check_itinerary_quota(cursor, user_id)

        elif quota_type == 'voice_translate':
            # 从 feature_flags 读 daily_limit (key 名按 005_feature_flags.sql 设计)
            # JSONB 自动转 Python int, 不需要 parse
            flags = get_flags(cursor, ['paywall_trigger_voice_daily'])
            daily_limit = flags.get('paywall_trigger_voice_daily', 5)
            result = check_voice_translate_quota(cursor, user_id, daily_limit=daily_limit)

        else:  # ai_edit
            # flag_value 是 JSONB, psycopg2 已自动转 Python bool, 直接传
            flags = get_flags(cursor, ['paywall_trigger_ai_edit'])
            result = check_ai_edit_quota(cursor, user_id, flags=flags)

        cursor.close()

        # 标准化响应格式: 加上 trigger_paywall 字段供客户端判断
        result['trigger_paywall'] = (
            not result.get('allowed', False)
            and result.get('reason') in ('quota_exceeded', 'premium_required')
        )

        return json_response(200, result)

    except Exception as e:
        print(f"[QUOTA ERROR] {str(e)}")
        import traceback
        traceback.print_exc()
        if cursor:
            cursor.close()
        return json_response(500, {'error': str(e)})
