# user_auth/index.py
# -*- coding: utf-8 -*-
"""
用户认证云函数 (v2 — 正式版优化)
支持: 匿名注册、邮箱注册/登录、Apple Sign-In、
      忘记密码、重置密码、删除账号(软删除)
优化: 速率限制、输入校验、Redis 缓存
"""
import os
import sys
import hashlib
import hmac
import time
import base64
import uuid
import json
import random

sys.path.insert(0, os.path.dirname(__file__) or '.')
from shared.db_helper import get_db_connection, get_redis_client, json_response, parse_body
from shared.email_helper import send_reset_email, send_verification_email, send_account_exists_email
from shared.rate_limit import check_rate_limit
from shared.validators import validate_required, validate_email, validate_password

# ===== JWT =====

def create_jwt(user_id, expires_hours=168):
    secret = os.environ['JWT_SECRET']
    header = base64.urlsafe_b64encode(json.dumps(
        {"alg": "HS256", "typ": "JWT"}).encode()).decode().rstrip('=')
    now = int(time.time())
    payload_data = {
        "sub": str(user_id),
        "iat": now,
        "exp": now + expires_hours * 3600
    }
    payload = base64.urlsafe_b64encode(
        json.dumps(payload_data).encode()).decode().rstrip('=')
    sig_input = f"{header}.{payload}"
    signature = base64.urlsafe_b64encode(
        hmac.new(secret.encode(), sig_input.encode(), hashlib.sha256).digest()
    ).decode().rstrip('=')
    return f"{header}.{payload}.{signature}"

def verify_jwt(token):
    try:
        secret = os.environ['JWT_SECRET']
        parts = token.split('.')
        if len(parts) != 3:
            return None
        sig_input = f"{parts[0]}.{parts[1]}"
        expected_sig = base64.urlsafe_b64encode(
            hmac.new(secret.encode(), sig_input.encode(), hashlib.sha256).digest()
        ).decode().rstrip('=')
        if not hmac.compare_digest(parts[2], expected_sig):
            return None
        payload_str = parts[1] + '=' * (4 - len(parts[1]) % 4)
        payload = json.loads(base64.urlsafe_b64decode(payload_str))
        if payload.get('exp', 0) < time.time():
            return None
        return payload
    except Exception:
        return None

# ===== 工具函数 =====

def _hash_token(token):
    return hashlib.sha256(token.encode()).hexdigest()

def _build_user_response(row, token=None):
    data = {
        'user_id': str(row[0]),
        'email': row[1],
        'username': row[2],
        'display_name': row[3],
        'avatar_url': row[4],
        'preferred_lang': row[5],
        'is_premium': row[6],
        'premium_expires_at': row[7].isoformat() if row[7] else None,
        'subscription_product_id': row[8],
        'subscription_platform': row[9],
        'premium_source': row[10],
        'trips_count': row[11],
        'translations_count': row[12],
        'bio': row[13],
        'created_at': str(row[14]),
        'last_login_at': str(row[15]) if row[15] else None,
    }
    if token:
        data['token'] = token
    return data

_USER_SELECT_FIELDS = """
    id, email, username, display_name, avatar_url,
    preferred_lang, is_premium, premium_expires_at,
    subscription_product_id, subscription_platform, premium_source,
    trips_count, translations_count, bio,
    created_at, last_login_at
"""

def _cache_user(redis_client, user_id, user_data):
    """登录成功后缓存用户数据到 Redis（7 天）"""
    try:
        redis_client.setex(f"user:{user_id}", 7 * 86400, json.dumps(user_data))
    except Exception:
        pass

def _get_cached_user(redis_client, user_id):
    """从 Redis 读缓存的用户数据"""
    try:
        cached = redis_client.get(f"user:{user_id}")
        if cached:
            return json.loads(cached)
    except Exception:
        pass
    return None

def _invalidate_user_cache(redis_client, user_id):
    """清除用户缓存（profile 更新 / 删除账号时调用）"""
    try:
        redis_client.delete(f"user:{user_id}")
        redis_client.delete(f"session:{user_id}")
    except Exception:
        pass

# ===== 账号关联辅助函数 =====

def _get_source_ip(event):
    """从 requestContext 取客户端 IP;取不到时返回 None 并记日志。"""
    ip = (event.get('requestContext') or {}).get('sourceIp')
    if not ip:
        print("[AUTH] sourceIp not in requestContext, skipping IP rate limit")
    return ip

def _find_anon_row(cursor, device_id):
    """查找同设备的真正匿名行(同 2.1 条件)。返回行或 None。"""
    cursor.execute("""
        SELECT id, trips_count, trips_created_total, is_premium,
               premium_expires_at, subscription_product_id, subscription_platform
        FROM users
        WHERE device_id = %s
          AND email IS NULL
          AND apple_user_id IS NULL
          AND google_user_id IS NULL
          AND is_active = true
    """, (device_id,))
    return cursor.fetchone()

def _do_upgrade(cursor, anon_id, email=None, pw_hash=None,
                apple_user_id=None, google_user_id=None):
    """2.3 原地升级:更新匿名行写入认证标识。调用方负责 commit。"""
    if pw_hash:
        cursor.execute("""
            UPDATE users SET
                email = %s, password_hash = %s, email_verified = TRUE,
                last_login_at = NOW(), updated_at = NOW()
            WHERE id = %s
        """, (email, pw_hash, anon_id))
    elif apple_user_id:
        cursor.execute("""
            UPDATE users SET
                apple_user_id = %s, email = %s, email_verified = TRUE,
                last_login_at = NOW(), updated_at = NOW()
            WHERE id = %s
        """, (apple_user_id, email, anon_id))
    elif google_user_id:
        cursor.execute("""
            UPDATE users SET
                google_user_id = %s, email = %s, email_verified = TRUE,
                last_login_at = NOW(), updated_at = NOW()
            WHERE id = %s
        """, (google_user_id, email, anon_id))
    print(f"[MERGE] type=upgrade anon={anon_id} into={anon_id}")

def _do_merge(cursor, anon_id, old_user_id):
    """
    2.4 并入老账号:原子认领匿名行后在同一事务内完成所有迁移。
    调用方负责 commit。返回 True 表示合并发生,False 表示跳过(已被并发认领)。
    """
    # 原子认领:一条 UPDATE 同时标记已合并并取出迁移所需的值
    # 若 is_active 已为 FALSE(并发请求已认领),返回 0 行 → 直接跳过
    cursor.execute("""
        UPDATE users SET
            is_active           = FALSE,
            merged_into_user_id = %s
        WHERE id = %s AND is_active = TRUE
        RETURNING trips_count, trips_created_total, is_premium,
                  premium_expires_at, subscription_product_id, subscription_platform
    """, (old_user_id, anon_id))
    claimed = cursor.fetchone()
    if not claimed:
        return False

    anon_trips_count         = claimed[0]
    anon_trips_created_total = claimed[1]
    anon_is_premium          = claimed[2]
    anon_premium_expires_at  = claimed[3]
    anon_sub_product_id      = claimed[4]
    anon_sub_platform        = claimed[5]

    # 1. 行程改挂
    cursor.execute(
        "UPDATE trips SET user_id = %s WHERE user_id = %s",
        (old_user_id, anon_id)
    )

    # 2. 行程计数合并
    cursor.execute("""
        UPDATE users SET
            trips_created_total = trips_created_total + %s,
            trips_count         = trips_count + %s
        WHERE id = %s
    """, (anon_trips_created_total, anon_trips_count, old_user_id))

    # 3. usage_quota:只合并当前周期(今日)的计数
    #    重置判定依据:last_reset_at::date < CURRENT_DATE 时视为已过期(同 increment_voice_translate_usage)
    #    老账号若已过期则以匿名行计数为准;两者都在今日则相加
    cursor.execute("""
        INSERT INTO usage_quota (user_id, feature, used_count, last_reset_at)
        SELECT %s, feature, used_count, last_reset_at
        FROM usage_quota
        WHERE user_id = %s
          AND last_reset_at::date = CURRENT_DATE
        ON CONFLICT (user_id, feature) DO UPDATE
            SET used_count    = CASE
                    WHEN usage_quota.last_reset_at::date < CURRENT_DATE
                    THEN EXCLUDED.used_count
                    ELSE usage_quota.used_count + EXCLUDED.used_count
                END,
                last_reset_at = GREATEST(usage_quota.last_reset_at, EXCLUDED.last_reset_at)
    """, (old_user_id, anon_id))

    # 4. 订阅权益迁移(仅当匿名行有 premium)
    if anon_is_premium:
        cursor.execute("""
            SELECT premium_expires_at, subscription_product_id, subscription_platform
            FROM users WHERE id = %s
        """, (old_user_id,))
        old_prem     = cursor.fetchone()
        old_expires  = old_prem[0]
        old_product  = old_prem[1]
        old_platform = old_prem[2]

        # NULL 视为最早;anon 到期更晚时连 product/platform 一起带过去
        if old_expires is None or (
            anon_premium_expires_at is not None
            and anon_premium_expires_at > old_expires
        ):
            new_expires  = anon_premium_expires_at
            new_product  = anon_sub_product_id
            new_platform = anon_sub_platform
        else:
            new_expires  = old_expires
            new_product  = old_product
            new_platform = old_platform

        # 仅当合并后的到期时间晚于当前时间才激活 premium
        # 交由数据库比较,避免 Python 侧时区歧义(TIMESTAMPTZ vs naive datetime)
        # new_expires 为 NULL 时 NULL > NOW() = NULL(falsy),is_premium 保持原值
        cursor.execute("""
            UPDATE users SET
                is_premium              = (is_premium OR (%s > NOW())),
                premium_expires_at      = %s,
                subscription_product_id = %s,
                subscription_platform   = %s
            WHERE id = %s
        """, (new_expires, new_expires, new_product, new_platform, old_user_id))

    # 5. 交易记录改挂
    cursor.execute(
        "UPDATE transactions SET user_id = %s WHERE user_id = %s",
        (old_user_id, anon_id)
    )

    print(f"[MERGE] type=merge anon={anon_id} into={old_user_id} trips={anon_trips_count}")
    return True

# ===== 主入口 =====

def main_handler(event, context):
    try:
        body = parse_body(event)
        action = body.get('action')
        conn = get_db_connection()
        cursor = conn.cursor()

        # 获取 Redis（可能失败，不阻塞主流程）
        try:
            r = get_redis_client()
        except Exception:
            r = None

        # ===== 匿名认证 =====
        if action == 'anonymous_auth':
            missing = validate_required(body, ['device_id'])
            if missing:
                return json_response(400, {'error': f'Missing {missing}'})

            device_id = body['device_id']

            cursor.execute(
                """SELECT id, preferred_lang FROM users
                   WHERE device_id = %s
                     AND email IS NULL
                     AND apple_user_id IS NULL
                     AND google_user_id IS NULL
                     AND is_active = true""",
                (device_id,)
            )
            row = cursor.fetchone()

            if row:
                user_id = str(row[0])
                cursor.execute(
                    "UPDATE users SET last_login_at = NOW() WHERE id = %s",
                    (row[0],)
                )
            else:
                user_id = str(uuid.uuid4())
                preferred_lang = body.get('preferred_lang', 'en')
                cursor.execute("""
                    INSERT INTO users (id, device_id, preferred_lang, last_login_at)
                    VALUES (%s, %s, %s, NOW())
                """, (user_id, device_id, preferred_lang))

            conn.commit()
            cursor.close()

            token = create_jwt(user_id)

            if r:
                try:
                    r.setex(f"session:{user_id}", 7 * 86400, json.dumps({
                        'device_id': device_id,
                        'login_type': 'anonymous'
                    }))
                except Exception:
                    pass

            return json_response(200, {
                'user_id': user_id,
                'token': token,
                'is_new_user': row is None
            })

        # ===== 邮箱注册(两步:第一步发验证码)=====
        elif action == 'register_start':
            missing = validate_required(body, ['email'])
            if missing:
                return json_response(400, {'error': f'Missing {missing}'})

            email = body['email'].strip().lower()

            if not validate_email(email):
                return json_response(400, {'error': 'Invalid email format'})

            # 按邮箱限流:10 分钟 3 次
            if r and not check_rate_limit(r, f"rate:register:{email}", 3, 600):
                return json_response(429, {'error': 'Too many attempts, try again later'})

            # 按 IP 限流:1 小时 20 次
            ip = _get_source_ip(event)
            if r and ip and not check_rate_limit(r, f"rate:ip:register_start:{ip}", 20, 3600):
                return json_response(429, {'error': 'Too many attempts, try again later'})

            cursor.execute(
                "SELECT id, apple_user_id, google_user_id FROM users WHERE email = %s AND is_active = true",
                (email,)
            )
            existing = cursor.fetchone()

            if existing:
                login_methods = ['email']
                if existing[1]:
                    login_methods.append('apple')
                if existing[2]:
                    login_methods.append('google')
                cursor.close()
                try:
                    send_account_exists_email(email, login_methods)
                except Exception as e:
                    print(f"[EMAIL ERROR] register_start (exists) {email}: {e}")
            else:
                code = ''.join(random.choices('0123456789', k=6))
                code_hash = _hash_token(code)
                cursor.execute("DELETE FROM email_verifications WHERE email = %s", (email,))
                cursor.execute("""
                    INSERT INTO email_verifications (email, code_hash, expires_at)
                    VALUES (%s, %s, NOW() + INTERVAL '10 minutes')
                """, (email, code_hash))
                conn.commit()
                cursor.close()
                try:
                    send_verification_email(email, code)
                except Exception as e:
                    print(f"[EMAIL ERROR] register_start {email}: {e}")

            return json_response(200, {'success': True, 'message': 'Verification code sent'})

        # ===== 邮箱注册(两步:第二步验证码 + 密码)=====
        elif action == 'register_verify':
            missing = validate_required(body, ['email', 'code', 'password'])
            if missing:
                return json_response(400, {'error': f'Missing {missing}'})

            email     = body['email'].strip().lower()
            code      = body['code'].strip()
            password  = body['password']
            device_id = body.get('device_id')

            # 按 IP 限流:1 小时 20 次
            ip = _get_source_ip(event)
            if r and ip and not check_rate_limit(r, f"rate:ip:register_verify:{ip}", 20, 3600):
                return json_response(429, {'error': 'Too many attempts, try again later'})

            code_hash = _hash_token(code)

            cursor.execute("""
                SELECT id, code_hash, attempts FROM email_verifications
                WHERE email = %s AND expires_at > NOW()
                ORDER BY created_at DESC LIMIT 1
            """, (email,))
            verif_row = cursor.fetchone()

            if not verif_row:
                cursor.close()
                return json_response(400, {'error': 'Invalid or expired code'})

            verif_id, stored_hash, attempts = verif_row

            if not hmac.compare_digest(code_hash, stored_hash):
                new_attempts = attempts + 1
                if new_attempts >= 5:
                    cursor.execute("DELETE FROM email_verifications WHERE id = %s", (verif_id,))
                else:
                    cursor.execute(
                        "UPDATE email_verifications SET attempts = %s WHERE id = %s",
                        (new_attempts, verif_id)
                    )
                conn.commit()
                cursor.close()
                return json_response(400, {'error': 'Invalid or expired code'})

            err = validate_password(password)
            if err:
                cursor.close()
                return json_response(400, {'error': err})

            # 删除验证记录
            cursor.execute("DELETE FROM email_verifications WHERE id = %s", (verif_id,))

            cursor.execute("SELECT hash_password(%s)", (password,))
            pw_hash = cursor.fetchone()[0]

            preferred_lang = body.get('preferred_lang', 'en')
            username       = body.get('username')

            # 2.3 原地升级
            upgraded = False
            if device_id:
                anon_row = _find_anon_row(cursor, device_id)
                if anon_row:
                    user_id = str(anon_row[0])
                    _do_upgrade(cursor, anon_row[0], email=email, pw_hash=pw_hash)
                    upgraded = True
                else:
                    user_id = str(uuid.uuid4())
                    cursor.execute("""
                        INSERT INTO users (id, email, password_hash, email_verified,
                            username, device_id, preferred_lang, last_login_at)
                        VALUES (%s, %s, %s, TRUE, %s, %s, %s, NOW())
                    """, (user_id, email, pw_hash, username, device_id, preferred_lang))
            else:
                user_id = str(uuid.uuid4())
                cursor.execute("""
                    INSERT INTO users (id, email, password_hash, email_verified,
                        username, preferred_lang, last_login_at)
                    VALUES (%s, %s, %s, TRUE, %s, %s, NOW())
                """, (user_id, email, pw_hash, username, preferred_lang))

            conn.commit()

            if upgraded and r:
                _invalidate_user_cache(r, user_id)   # 清匿名 session,下一行再写入注册后的缓存

            cursor.execute(f"""
                SELECT {_USER_SELECT_FIELDS}
                FROM users WHERE id = %s
            """, (user_id,))
            user_row = cursor.fetchone()
            cursor.close()

            token = create_jwt(user_id)
            response_data = _build_user_response(user_row, token=token)

            if r:
                _cache_user(r, user_id, response_data)
                try:
                    r.setex(f"session:{user_id}", 7 * 86400, json.dumps({'login_type': 'email'}))
                except Exception:
                    pass

            return json_response(201, response_data)

        # ===== 邮箱注册(旧接口,过渡期保留)=====
        elif action == 'register':
            print(f"[DEPRECATED] register called for {body.get('email', '?')}")
            missing = validate_required(body, ['email', 'password'])
            if missing:
                return json_response(400, {'error': f'Missing {missing}'})

            email = body['email'].strip().lower()
            password = body['password']

            if not validate_email(email):
                return json_response(400, {'error': 'Invalid email format'})

            err = validate_password(password)
            if err:
                return json_response(400, {'error': err})

            # 速率限制：同一邮箱 10 分钟内最多注册 3 次
            if r and not check_rate_limit(r, f"rate:register:{email}", 3, 600):
                return json_response(429, {'error': 'Too many attempts, try again later'})

            cursor.execute("SELECT id FROM users WHERE email = %s", (email,))
            if cursor.fetchone():
                cursor.close()
                return json_response(409, {'error': 'Email already registered'})

            user_id = str(uuid.uuid4())
            device_id = body.get('device_id')
            preferred_lang = body.get('preferred_lang', 'en')
            username = body.get('username')

            cursor.execute("SELECT hash_password(%s)", (password,))
            pw_hash = cursor.fetchone()[0]

            cursor.execute("""
                INSERT INTO users (id, email, password_hash, username,
                    device_id, preferred_lang, last_login_at)
                VALUES (%s, %s, %s, %s, %s, %s, NOW())
            """, (user_id, email, pw_hash, username, device_id, preferred_lang))

            conn.commit()
            cursor.close()

            token = create_jwt(user_id)
            return json_response(201, {
                'user_id': user_id,
                'token': token
            })

        # ===== 邮箱登录 =====
        elif action == 'login':
            missing = validate_required(body, ['email', 'password'])
            if missing:
                return json_response(400, {'error': f'Missing {missing}'})

            email = body['email'].strip().lower()
            password = body['password']

            # 按邮箱限流:10 分钟 10 次
            if r and not check_rate_limit(r, f"rate:login:{email}", 10, 600):
                return json_response(429, {'error': 'Too many login attempts, try again later'})

            # 按 IP 限流:1 小时 30 次
            ip = _get_source_ip(event)
            if r and ip and not check_rate_limit(r, f"rate:ip:login:{ip}", 30, 3600):
                return json_response(429, {'error': 'Too many login attempts, try again later'})

            cursor.execute(
                "SELECT id, password_hash FROM users WHERE email = %s AND is_active = true",
                (email,)
            )
            auth_row = cursor.fetchone()
            if not auth_row:
                cursor.close()
                return json_response(401, {'error': 'Invalid credentials'})

            cursor.execute("SELECT verify_password(%s, %s)", (password, auth_row[1]))
            is_valid = cursor.fetchone()[0]
            if not is_valid:
                cursor.close()
                return json_response(401, {'error': 'Invalid credentials'})

            user_id = str(auth_row[0])

            # 2.4 并入老账号(仅在密码校验通过之后,保证 401 统一性)
            device_id = body.get('device_id')
            anon_merged = None
            if device_id:
                anon_row = _find_anon_row(cursor, device_id)
                if anon_row and str(anon_row[0]) != user_id:
                    if _do_merge(cursor, str(anon_row[0]), user_id):
                        anon_merged = str(anon_row[0])

            cursor.execute(
                "UPDATE users SET last_login_at = NOW() WHERE id = %s",
                (auth_row[0],)
            )
            conn.commit()

            if anon_merged and r:
                _invalidate_user_cache(r, anon_merged)   # 匿名 UUID
                _invalidate_user_cache(r, user_id)       # 老账号过期缓存

            cursor.execute(f"""
                SELECT {_USER_SELECT_FIELDS}
                FROM users WHERE id = %s
            """, (auth_row[0],))
            user_row = cursor.fetchone()
            cursor.close()

            token = create_jwt(user_id)
            response_data = _build_user_response(user_row, token=token)

            # 缓存用户数据
            if r:
                _cache_user(r, user_id, response_data)
                try:
                    r.setex(f"session:{user_id}", 7 * 86400, json.dumps({
                        'login_type': 'email'
                    }))
                except Exception:
                    pass

            return json_response(200, response_data)

        # ===== Token 验证 =====
        elif action == 'verify':
            missing = validate_required(body, ['token'])
            if missing:
                return json_response(400, {'error': f'Missing {missing}'})

            payload = verify_jwt(body['token'])
            if not payload:
                return json_response(401, {'error': 'Invalid or expired token'})

            return json_response(200, {
                'valid': True,
                'user_id': payload['sub']
            })

        # ===== 恢复会话（优先查 Redis 缓存）=====
        elif action == 'restore_session':
            missing = validate_required(body, ['token'])
            if missing:
                return json_response(400, {'error': f'Missing {missing}'})

            payload = verify_jwt(body['token'])
            if not payload:
                return json_response(401, {'error': 'Invalid or expired token'})

            user_id = payload['sub']

            # 先查 Redis 缓存
            if r:
                cached = _get_cached_user(r, user_id)
                if cached:
                    cached['token'] = body['token']
                    return json_response(200, cached)

            # 缓存未命中，查 DB
            cursor.execute(f"""
                SELECT {_USER_SELECT_FIELDS}
                FROM users WHERE id = %s AND is_active = true
            """, (user_id,))
            user_row = cursor.fetchone()
            cursor.close()

            if not user_row:
                return json_response(404, {'error': 'User not found'})

            response_data = _build_user_response(user_row, token=body['token'])

            # 写入缓存供下次使用
            if r:
                _cache_user(r, user_id, response_data)

            return json_response(200, response_data)

        # ===== 获取用户资料 =====
        elif action == 'get_profile':
            missing = validate_required(body, ['user_id'])
            if missing:
                return json_response(400, {'error': f'Missing {missing}'})

            cursor.execute(f"""
                SELECT {_USER_SELECT_FIELDS}
                FROM users WHERE id = %s AND is_active = true
            """, (body['user_id'],))
            row = cursor.fetchone()
            cursor.close()

            if not row:
                return json_response(404, {'error': 'User not found'})

            return json_response(200, _build_user_response(row))

        # ===== 更新用户资料 =====
        elif action == 'update_profile':
            missing = validate_required(body, ['user_id'])
            if missing:
                return json_response(400, {'error': f'Missing {missing}'})

            user_id = body['user_id']
            updates = []
            params = []
            for field in ['username', 'display_name', 'avatar_url', 'preferred_lang', 'bio']:
                if field in body:
                    updates.append(f"{field} = %s")
                    params.append(body[field])

            if not updates:
                cursor.close()
                return json_response(400, {'error': 'No fields to update'})

            params.append(user_id)
            cursor.execute(
                f"UPDATE users SET {', '.join(updates)}, updated_at = NOW() "
                f"WHERE id = %s AND is_active = true",
                params
            )
            conn.commit()
            cursor.close()

            # 清缓存（下次 restore_session 会重新查 DB）
            if r:
                _invalidate_user_cache(r, user_id)

            return json_response(200, {'success': True, 'user_id': user_id})

        # ===== 忘记密码 =====
        elif action == 'forgot_password':
            missing = validate_required(body, ['email'])
            if missing:
                return json_response(400, {'error': f'Missing {missing}'})

            email = body['email'].strip().lower()

            if not validate_email(email):
                return json_response(400, {'error': 'Invalid email format'})

            # 按邮箱限流:5 分钟 3 次
            if r and not check_rate_limit(r, f"rate:forgot:{email}", 3, 300):
                return json_response(429, {'error': 'Too many attempts, try again in 5 minutes'})

            # 按 IP 限流:1 小时 20 次
            ip = _get_source_ip(event)
            if r and ip and not check_rate_limit(r, f"rate:ip:forgot_password:{ip}", 20, 3600):
                return json_response(429, {'error': 'Too many attempts, try again later'})

            cursor.execute(
                "SELECT id FROM users WHERE email = %s AND is_active = true",
                (email,)
            )
            user_exists = cursor.fetchone() is not None

            if user_exists:
                reset_token = ''.join(random.choices('0123456789', k=6))
                token_hash = _hash_token(reset_token)

                cursor.execute(
                    "DELETE FROM password_resets WHERE email = %s",
                    (email,)
                )

                cursor.execute("""
                    INSERT INTO password_resets (email, token, expires_at)
                    VALUES (%s, %s, NOW() + INTERVAL '10 minutes')
                """, (email, token_hash))

                conn.commit()
                send_reset_email(email, reset_token)
            else:
                print(f"[AUTH] forgot_password for non-existent email: {email}")

            cursor.close()
            return json_response(200, {
                'success': True,
                'message': 'If the email exists, a reset code has been sent'
            })

        # ===== 重置密码 =====
        elif action == 'reset_password':
            missing = validate_required(body, ['email', 'token', 'new_password'])
            if missing:
                return json_response(400, {'error': f'Missing {missing}'})

            email        = body['email'].strip().lower()
            token        = body['token'].strip()
            new_password = body['new_password']

            # 按 IP 限流:1 小时 20 次
            ip = _get_source_ip(event)
            if r and ip and not check_rate_limit(r, f"rate:ip:reset_password:{ip}", 20, 3600):
                return json_response(429, {'error': 'Too many attempts, try again later'})

            err = validate_password(new_password)
            if err:
                return json_response(400, {'error': err})

            token_hash = _hash_token(token)

            # 先按邮箱查记录(不在 SQL 内校验 token,以便做 attempts 计数)
            cursor.execute("""
                SELECT id, token, attempts FROM password_resets
                WHERE email = %s AND expires_at > NOW()
            """, (email,))
            reset_row = cursor.fetchone()

            if not reset_row:
                cursor.close()
                return json_response(400, {'error': 'Invalid or expired reset code'})

            record_id, stored_hash, current_attempts = reset_row

            if not hmac.compare_digest(token_hash, stored_hash):
                new_attempts = current_attempts + 1
                if new_attempts >= 5:
                    cursor.execute("DELETE FROM password_resets WHERE id = %s", (record_id,))
                else:
                    cursor.execute(
                        "UPDATE password_resets SET attempts = %s WHERE id = %s",
                        (new_attempts, record_id)
                    )
                conn.commit()
                cursor.close()
                return json_response(400, {'error': 'Invalid or expired reset code'})

            cursor.execute("SELECT hash_password(%s)", (new_password,))
            pw_hash = cursor.fetchone()[0]

            cursor.execute(
                "UPDATE users SET password_hash = %s, updated_at = NOW() WHERE email = %s AND is_active = true",
                (pw_hash, email)
            )

            cursor.execute("DELETE FROM password_resets WHERE email = %s", (email,))

            conn.commit()
            cursor.close()

            print(f"[AUTH] Password reset successful for: {email}")
            return json_response(200, {'success': True})

        # ===== Apple Sign-In =====
        elif action == 'apple_sign_in':
            from oauth_verify import verify_apple_id_token

            missing = validate_required(body, ['id_token'])
            if missing:
                return json_response(400, {'error': f'Missing {missing}'})

            try:
                decoded = verify_apple_id_token(body['id_token'])
            except Exception as e:
                print(f"[AUTH] Apple token verification failed: {e}")
                return json_response(401, {'error': f'Invalid Apple token: {e}'})

            apple_user_id = decoded['sub']
            email         = decoded.get('email')
            device_id     = body.get('device_id')

            cursor.execute(
                "SELECT id FROM users WHERE apple_user_id = %s AND is_active = true",
                (apple_user_id,)
            )
            row = cursor.fetchone()

            anon_merged = None
            upgraded    = False

            if row:
                # 找到老账号 → 2.4 并入
                user_id = str(row[0])
                if device_id:
                    anon_row = _find_anon_row(cursor, device_id)
                    if anon_row and str(anon_row[0]) != user_id:
                        if _do_merge(cursor, str(anon_row[0]), user_id):
                            anon_merged = str(anon_row[0])
            elif email:
                cursor.execute(
                    "SELECT id FROM users WHERE email = %s AND apple_user_id IS NULL AND is_active = true",
                    (email,)
                )
                existing = cursor.fetchone()
                if existing:
                    # 找到老账号(绑定 Apple) → 2.4 并入
                    cursor.execute(
                        "UPDATE users SET apple_user_id = %s WHERE id = %s",
                        (apple_user_id, existing[0])
                    )
                    user_id = str(existing[0])
                    if device_id:
                        anon_row = _find_anon_row(cursor, device_id)
                        if anon_row and str(anon_row[0]) != user_id:
                            if _do_merge(cursor, str(anon_row[0]), user_id):
                                anon_merged = str(anon_row[0])
                else:
                    # 新用户 → 2.3 原地升级
                    if device_id:
                        anon_row = _find_anon_row(cursor, device_id)
                        if anon_row:
                            user_id = str(anon_row[0])
                            _do_upgrade(cursor, anon_row[0], apple_user_id=apple_user_id, email=email)
                            upgraded = True
                        else:
                            user_id = str(uuid.uuid4())
                            cursor.execute("""
                                INSERT INTO users (id, apple_user_id, email, email_verified, device_id, last_login_at)
                                VALUES (%s, %s, %s, TRUE, %s, NOW())
                            """, (user_id, apple_user_id, email, device_id))
                    else:
                        user_id = str(uuid.uuid4())
                        cursor.execute("""
                            INSERT INTO users (id, apple_user_id, email, email_verified, last_login_at)
                            VALUES (%s, %s, %s, TRUE, NOW())
                        """, (user_id, apple_user_id, email))
            else:
                cursor.close()
                return json_response(400, {'error': 'Invalid Apple token: no email on first login'})

            cursor.execute(
                "UPDATE users SET last_login_at = NOW() WHERE id = %s",
                (user_id,)
            )
            conn.commit()

            if anon_merged and r:
                _invalidate_user_cache(r, anon_merged)   # 匿名 UUID
                _invalidate_user_cache(r, user_id)       # 老账号过期缓存
            elif upgraded and r:
                _invalidate_user_cache(r, user_id)       # 升级前的匿名 session

            cursor.execute(f"""
                SELECT {_USER_SELECT_FIELDS}
                FROM users WHERE id = %s
            """, (user_id,))
            user_row = cursor.fetchone()
            cursor.close()

            token = create_jwt(user_id)
            response_data = _build_user_response(user_row, token=token)

            if r:
                _cache_user(r, user_id, response_data)
                try:
                    r.setex(f"session:{user_id}", 7 * 86400, json.dumps({
                        'login_type': 'apple',
                        'apple_user_id': apple_user_id,
                    }))
                except Exception:
                    pass

            print(f"[AUTH] Apple Sign-In success: {user_id}")
            return json_response(200, response_data)

        elif action == 'google_sign_in':
            from oauth_verify import verify_google_id_token

            missing = validate_required(body, ['id_token'])
            if missing:
                return json_response(400, {'error': f'Missing {missing}'})

            try:
                decoded = verify_google_id_token(body['id_token'])
            except Exception as e:
                print(f"[AUTH] Google token verification failed: {e}")
                return json_response(401, {'error': f'Invalid Google token: {e}'})

            google_user_id = decoded['sub']
            email          = decoded.get('email')
            device_id      = body.get('device_id')

            cursor.execute(
                "SELECT id FROM users WHERE google_user_id = %s AND is_active = true",
                (google_user_id,)
            )
            row = cursor.fetchone()

            anon_merged = None
            upgraded    = False

            if row:
                # 找到老账号 → 2.4 并入
                user_id = str(row[0])
                if device_id:
                    anon_row = _find_anon_row(cursor, device_id)
                    if anon_row and str(anon_row[0]) != user_id:
                        if _do_merge(cursor, str(anon_row[0]), user_id):
                            anon_merged = str(anon_row[0])
            elif email:
                cursor.execute(
                    "SELECT id FROM users WHERE email = %s AND google_user_id IS NULL AND is_active = true",
                    (email,)
                )
                existing = cursor.fetchone()
                if existing:
                    # 找到老账号(绑定 Google) → 2.4 并入
                    cursor.execute(
                        "UPDATE users SET google_user_id = %s WHERE id = %s",
                        (google_user_id, existing[0])
                    )
                    user_id = str(existing[0])
                    if device_id:
                        anon_row = _find_anon_row(cursor, device_id)
                        if anon_row and str(anon_row[0]) != user_id:
                            if _do_merge(cursor, str(anon_row[0]), user_id):
                                anon_merged = str(anon_row[0])
                else:
                    # 新用户 → 2.3 原地升级
                    if device_id:
                        anon_row = _find_anon_row(cursor, device_id)
                        if anon_row:
                            user_id = str(anon_row[0])
                            _do_upgrade(cursor, anon_row[0], google_user_id=google_user_id, email=email)
                            upgraded = True
                        else:
                            user_id = str(uuid.uuid4())
                            cursor.execute("""
                                INSERT INTO users (id, google_user_id, email, email_verified, device_id, last_login_at)
                                VALUES (%s, %s, %s, TRUE, %s, NOW())
                            """, (user_id, google_user_id, email, device_id))
                    else:
                        user_id = str(uuid.uuid4())
                        cursor.execute("""
                            INSERT INTO users (id, google_user_id, email, email_verified, last_login_at)
                            VALUES (%s, %s, %s, TRUE, NOW())
                        """, (user_id, google_user_id, email))
            else:
                cursor.close()
                return json_response(400, {'error': 'Invalid Google token: no email'})

            cursor.execute(
                "UPDATE users SET last_login_at = NOW() WHERE id = %s",
                (user_id,)
            )
            conn.commit()

            if anon_merged and r:
                _invalidate_user_cache(r, anon_merged)   # 匿名 UUID
                _invalidate_user_cache(r, user_id)       # 老账号过期缓存
            elif upgraded and r:
                _invalidate_user_cache(r, user_id)       # 升级前的匿名 session

            cursor.execute(f"""
                SELECT {_USER_SELECT_FIELDS}
                FROM users WHERE id = %s
            """, (user_id,))
            user_row = cursor.fetchone()
            cursor.close()

            token = create_jwt(user_id)
            response_data = _build_user_response(user_row, token=token)

            if r:
                _cache_user(r, user_id, response_data)
                try:
                    r.setex(f"session:{user_id}", 7 * 86400, json.dumps({
                        'login_type': 'google',
                        'google_user_id': google_user_id,
                    }))
                except Exception:
                    pass

            print(f"[AUTH] Google Sign-In success: {user_id}")
            return json_response(200, response_data)

        # ===== 删除账号（软删除）=====
        elif action == 'delete_account':
            missing = validate_required(body, ['user_id'])
            if missing:
                return json_response(400, {'error': f'Missing {missing}'})

            user_id = body['user_id']

            try:
                cursor.execute(
                    "SELECT id FROM users WHERE id = %s AND is_active = true",
                    (user_id,)
                )
                if not cursor.fetchone():
                    cursor.close()
                    return json_response(404, {'error': 'User not found'})

                # 1. trips 匿名化（断开用户关联，保留行程数据供 AI 训练）
                # trip_days 通过 trip_id 关联，无用户信息，不需要动
                cursor.execute("""
                    UPDATE trips SET 
                        user_id = NULL,
                        device_id = NULL,
                        description = NULL,
                        edit_history = '[]',
                        itinerary_json = NULL,
                        updated_at = NOW()
                    WHERE user_id = %s
                """, (user_id,))

                # 2. 删 user_sessions
                cursor.execute(
                    "DELETE FROM user_sessions WHERE user_id = %s",
                    (user_id,)
                )

                # 3. 删 usage_quota
                cursor.execute(
                    "DELETE FROM usage_quota WHERE user_id = %s",
                    (user_id,)
                )

                # 4. 软删除用户：脱敏 PII，保留记录
                # transactions.user_id ON DELETE SET NULL 不触发（因为不 DELETE）
                # 如需清理 transactions，单独 UPDATE
                cursor.execute("""
                    UPDATE users SET
                        is_active = FALSE,
                        email = NULL,
                        password_hash = NULL,
                        apple_user_id = NULL,
                        google_user_id = NULL,
                        device_id = NULL,
                        username = NULL,
                        display_name = NULL,
                        avatar_url = NULL,
                        bio = NULL,
                        deleted_at = NOW(),
                        updated_at = NOW()
                    WHERE id = %s
                """, (user_id,))

                conn.commit()

                # 清 Redis
                if r:
                    _invalidate_user_cache(r, user_id)

                print(f"[AUTH] Account soft-deleted: {user_id}")
                cursor.close()
                return json_response(200, {'success': True})

            except Exception as e:
                conn.rollback()
                print(f"[AUTH ERROR] delete_account: {e}")
                import traceback
                traceback.print_exc()
                cursor.close()
                return json_response(500, {'error': str(e)})

        # ===== 网络诊断 (保留供未来重新评估 Google Sign-In 时使用) =====
        elif action == 'test_apple_jwks':
            cursor.close()
            import requests
            try:
                start = time.time()
                resp = requests.get('https://appleid.apple.com/auth/keys', timeout=10)
                return json_response(200, {
                    'service': 'apple',
                    'status': resp.status_code,
                    'duration_ms': int((time.time() - start) * 1000),
                    'keys_count': len(resp.json().get('keys', []))
                })
            except Exception as e:
                return json_response(200, {
                    'service': 'apple',
                    'error': type(e).__name__ + ': ' + str(e)[:200]
                })

        elif action == 'test_google_jwks':
            cursor.close()
            import requests
            try:
                start = time.time()
                resp = requests.get('https://www.googleapis.com/oauth2/v3/certs', timeout=10)
                return json_response(200, {
                    'service': 'google',
                    'status': resp.status_code,
                    'duration_ms': int((time.time() - start) * 1000),
                    'keys_count': len(resp.json().get('keys', []))
                })
            except Exception as e:
                return json_response(200, {
                    'service': 'google',
                    'error': type(e).__name__ + ': ' + str(e)[:200]
                })
        
        elif action == 'test_apple_iap':
            cursor.close()
            import requests
            results = {}
            for env_name, url in [
                ('sandbox', 'https://sandbox.itunes.apple.com/verifyReceipt'),
                ('production', 'https://buy.itunes.apple.com/verifyReceipt')
            ]:
                try:
                    start = time.time()
                    resp = requests.post(url, json={'receipt-data': 'invalid'}, timeout=10)
                    results[env_name] = {
                        'status': resp.status_code,
                        'duration_ms': int((time.time() - start) * 1000),
                        'body_preview': resp.text[:150]
                    }
                except Exception as e:
                    results[env_name] = {'error': type(e).__name__ + ': ' + str(e)[:200]}
            return json_response(200, results)
        
        elif action == 'mark_ai_disclosure_shown':
            user_id = body.get('user_id')
            if not user_id:
                cursor.close()
                return json_response(400, {'error': 'Missing user_id'})

            cursor.execute("""
                UPDATE users SET
                    ai_disclosure_shown = TRUE,
                    ai_disclosure_shown_at = NOW(),
                    updated_at = NOW()
                WHERE id = %s AND is_active = true
            """, (user_id,))
            conn.commit()
            cursor.close()
            return json_response(200, {'success': True})

        else:
            cursor.close()
            return json_response(400, {
                'error': f'Unknown action: {action}. '
                         f'Supported: anonymous_auth, register_start, register_verify, register, '
                         f'login, verify, mark_ai_disclosure_shown, restore_session, '
                         f'get_profile, update_profile, forgot_password, reset_password, '
                         f'delete_account, apple_sign_in, google_sign_in'
            })

    except Exception as e:
        print(f"[AUTH ERROR] {str(e)}")
        import traceback
        traceback.print_exc()
        return json_response(500, {'error': str(e)})
