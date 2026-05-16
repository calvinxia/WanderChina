# shared/rate_limit.py
# -*- coding: utf-8 -*-
"""
速率限制模块 — 基于 Redis INCR + EXPIRE
"""


def check_rate_limit(redis_client, key, max_attempts, window_seconds):
    """
    检查是否超过速率限制。

    Args:
        redis_client: Redis 连接
        key: 限流 key（如 'rate:login:user@example.com'）
        max_attempts: 窗口内最大允许次数
        window_seconds: 窗口时长（秒）

    Returns:
        True = 允许通过, False = 被限流
    """
    try:
        current = redis_client.get(key)
        if current and int(current) >= max_attempts:
            return False
        pipe = redis_client.pipeline()
        pipe.incr(key)
        pipe.expire(key, window_seconds)
        pipe.execute()
        return True
    except Exception:
        # Redis 不可用时放行（不因缓存故障阻塞主流程）
        return True
