# get_feature_flags/index.py
# -*- coding: utf-8 -*-
"""
Feature flags 获取云函数.
客户端启动时调用 (PUBLIC, 无 token), 返回所有 active flag.
Redis 缓存 5 分钟.
"""
import os
import sys
import json

sys.path.insert(0, os.path.dirname(__file__) or '.')
from shared.db_helper import get_db_connection, get_redis_client, json_response

CACHE_KEY = 'feature_flags:all'
CACHE_TTL = 300  # 5 分钟


def main_handler(event, context):
    try:
        # 1. 优先查 Redis 缓存
        try:
            r = get_redis_client()
            cached = r.get(CACHE_KEY)
            if cached:
                return json_response(200, {
                    'flags': json.loads(cached),
                    'cached': True
                })
        except Exception:
            r = None  # Redis 不可用不阻塞主流程

        # 2. 缓存未命中, 查数据库
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute(
            "SELECT flag_key, flag_value FROM feature_flags"
        )
        flags = {row[0]: row[1] for row in cursor.fetchall()}
        cursor.close()

        # 3. 写入缓存
        if r:
            try:
                r.setex(CACHE_KEY, CACHE_TTL, json.dumps(flags))
            except Exception:
                pass

        return json_response(200, {
            'flags': flags,
            'cached': False
        })

    except Exception as e:
        print(f"[GET_FLAGS ERROR] {str(e)}")
        import traceback
        traceback.print_exc()
        return json_response(500, {'error': str(e)})
