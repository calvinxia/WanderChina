# shared/quota_check.py
# -*- coding: utf-8 -*-
"""
配额检查 + 累加共享模块.

设计原则:
1. 所有 check_* 函数纯只读, 不修改任何数据
2. 累加和重置由 increment_* 函数的 UPSERT 处理
3. flag 总开关判断在调用方 (check_user_quota 函数 main_handler) 完成,
   本模块的 check_* 函数仅做"配额是否充足"的具体判断
4. 使用 tuple cursor (与 create_trip 等现有函数一致), 不依赖 RealDictCursor
"""
from datetime import datetime, date


def get_flags(cur, keys):
    """
    批量读取 feature_flags. 一次查询减少开销.
    
    Args:
        cur: psycopg2 cursor (tuple cursor)
        keys: List[str] flag key 列表
    
    Returns:
        Dict[str, Any]: flag_key -> flag_value
        缺失的 key 不会出现在返回值中, 调用方用 .get(key, default) 取
    """
    cur.execute(
        "SELECT flag_key, flag_value FROM feature_flags WHERE flag_key = ANY(%s)",
        (list(keys),)
    )
    return {row[0]: row[1] for row in cur.fetchall()}


def check_itinerary_quota(cur, user_id):
    """
    行程生成配额判断 (纯只读).
    
    设计: 基于 users.trips_count, 不使用 usage_quota 表.
          扣减时机由 create_trip 函数的 INSERT trip + trips_count + 1 同事务保证.
    
    免费阈值: 由 paywall_trigger_itinerary_count flag 控制, 默认 3.
    
    Args:
        cur: psycopg2 cursor
        user_id: UUID
    
    Returns:
        Dict: {'allowed': bool, 'reason': str, ...}
    """
    cur.execute(
        "SELECT is_premium, premium_expires_at, trips_count FROM users WHERE id = %s",
        (user_id,)
    )
    row = cur.fetchone()
    if not row:
        return {'allowed': False, 'reason': 'user_not_found'}
    
    is_premium, premium_expires_at, trips_count = row
    
    # 付费用户: 订阅有效期内无限
    if is_premium and premium_expires_at and premium_expires_at > datetime.now():
        return {'allowed': True, 'reason': 'premium'}
    
    # 读免费阈值 (默认 3, 与 005_feature_flags.sql 的初始值一致)
    flags = get_flags(cur, ['paywall_trigger_itinerary_count'])
    threshold = flags.get('paywall_trigger_itinerary_count', 3)
    
    # 免费用户: trips_count < threshold 表示还有免费额度
    if trips_count < threshold:
        return {
            'allowed': True,
            'reason': 'free_trial',
            'trips_used': trips_count,
            'free_limit': threshold,
        }
    
    # 超出免费额度
    return {
        'allowed': False,
        'reason': 'quota_exceeded',
        'feature': 'itinerary_generate',
        'trips_used': trips_count,
        'free_limit': threshold,
    }


def check_voice_translate_quota(cur, user_id, daily_limit=5):
    """
    语音翻译配额判断 (纯只读).
    
    设计: 基于 usage_quota 表, 按日重置.
          重置不在此函数做! 仅在判断时计算"今天是否已重置过";
          实际 used_count = 0 的写入由 increment_voice_translate_usage 的 UPSERT 处理.
    
    Args:
        cur: psycopg2 cursor
        user_id: UUID
        daily_limit: int, 每日上限 (调用方从 flag 读取后传入)
    
    Returns:
        Dict: {'allowed': bool, 'reason': str, ...}
    """
    cur.execute(
        "SELECT is_premium, premium_expires_at FROM users WHERE id = %s",
        (user_id,)
    )
    row = cur.fetchone()
    if not row:
        return {'allowed': False, 'reason': 'user_not_found'}
    
    is_premium, premium_expires_at = row
    
    # 付费用户: 订阅有效期内无限
    if is_premium and premium_expires_at and premium_expires_at > datetime.now():
        return {'allowed': True, 'reason': 'premium'}
    
    # 读 usage_quota (不存在视为 used=0)
    cur.execute(
        """SELECT used_count, last_reset_at FROM usage_quota
           WHERE user_id = %s AND feature = 'voice_translate'""",
        (user_id,)
    )
    row = cur.fetchone()
    
    if not row:
        # 首次使用, 视为 used=0, 不写入 (保持只读)
        used_today = 0
    else:
        used_count, last_reset_at = row
        # 跨天则视为 0 (实际重置由下一次 increment 写入)
        if last_reset_at and last_reset_at.date() < date.today():
            used_today = 0
        else:
            used_today = used_count
    
    if used_today >= daily_limit:
        return {
            'allowed': False,
            'reason': 'quota_exceeded',
            'feature': 'voice_translate',
            'used_today': used_today,
            'daily_limit': daily_limit,
        }
    
    return {
        'allowed': True,
        'reason': 'within_free_limit',
        'used_today': used_today,
        'daily_limit': daily_limit,
    }


def check_ai_edit_quota(cur, user_id, flags=None):
    """
    AI 编辑配额判断 (纯只读).
    
    设计: AI 编辑不消耗 trips_count 配额, 仅基于:
          - paywall_trigger_ai_edit flag (是否对免费用户限制)
          - users.is_premium (是否为付费用户)
    
    Args:
        cur: psycopg2 cursor
        user_id: UUID
        flags: Dict (可选) 调用方已读的 flag 字典. 不传则本函数自查
    
    Returns:
        Dict: {'allowed': bool, 'reason': str, ...}
    """
    if flags is None:
        flags = get_flags(cur, ['paywall_trigger_ai_edit'])
    
    # flag 关闭: AI 编辑对所有用户免费
    if not flags.get('paywall_trigger_ai_edit', True):
        return {'allowed': True, 'reason': 'ai_edit_free'}
    
    # flag 开启: 仅付费用户可用
    cur.execute(
        "SELECT is_premium, premium_expires_at FROM users WHERE id = %s",
        (user_id,)
    )
    row = cur.fetchone()
    if not row:
        return {'allowed': False, 'reason': 'user_not_found'}
    
    is_premium, premium_expires_at = row
    
    if is_premium and premium_expires_at and premium_expires_at > datetime.now():
        return {'allowed': True, 'reason': 'premium'}
    
    return {
        'allowed': False,
        'reason': 'premium_required',
        'feature': 'ai_edit',
    }


def increment_voice_translate_usage(cur, user_id):
    """
    语音翻译配额累加 (UPSERT, 处理跨日重置).
    
    设计: 一条 SQL 同时处理:
          - 首次使用 (INSERT used_count=1)
          - 同日累加 (used_count + 1)
          - 跨日重置 (检测 last_reset_at < CURRENT_DATE 时归 1, 不是 +1)
    
    Args:
        cur: psycopg2 cursor
        user_id: UUID
    
    Returns:
        int: 累加后的 used_count
    """
    cur.execute("""
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
    
    return cur.fetchone()[0]
