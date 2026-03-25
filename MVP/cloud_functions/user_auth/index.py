# user_auth/index.py
# -*- coding: utf-8 -*-
"""
用户认证云函数
支持: 匿名注册（device_id）、邮箱注册/登录、Token 刷新
MVP 阶段以 device_id 匿名认证为主，邮箱注册为可选
密码哈希使用数据库端 pgcrypto bcrypt（001_functions.sql 中定义）
"""
import os
import sys
import hashlib
import hmac
import time
import base64
import uuid
import json

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from shared.db_helper import get_db_connection, get_redis_client, json_response, parse_body

# ===== JWT 简易实现（HMAC-SHA256）=====

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

# ===== 主入口 =====

def main_handler(event, context):
    try:
        body = parse_body(event)
        action = body.get('action')
        conn = get_db_connection()
        cursor = conn.cursor()

        # ===== 匿名认证（device_id）=====
        if action == 'anonymous_auth':
            device_id = body.get('device_id')
            if not device_id:
                return json_response(400, {'error': 'Missing device_id'})

            cursor.execute(
                "SELECT id, preferred_lang FROM users WHERE device_id = %s",
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

            try:
                r = get_redis_client()
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

        # ===== 邮箱注册 =====
        elif action == 'register':
            email = body.get('email', '').strip().lower()
            password = body.get('password')
            username = body.get('username')

            if not email or not password:
                return json_response(400, {'error': 'Missing email or password'})
            if len(password) < 8:
                return json_response(400, {'error': 'Password must be >= 8 chars'})

            cursor.execute("SELECT id FROM users WHERE email = %s", (email,))
            if cursor.fetchone():
                cursor.close()
                return json_response(409, {'error': 'Email already registered'})

            user_id = str(uuid.uuid4())
            device_id = body.get('device_id')
            preferred_lang = body.get('preferred_lang', 'en')

            # 使用数据库 pgcrypto bcrypt 哈希密码
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
            email = body.get('email', '').strip().lower()
            password = body.get('password')

            if not email or not password:
                return json_response(400, {'error': 'Missing email or password'})

            cursor.execute(
                "SELECT id, password_hash FROM users WHERE email = %s AND is_active = true",
                (email,)
            )
            row = cursor.fetchone()
            if not row:
                cursor.close()
                return json_response(401, {'error': 'Invalid credentials'})

            # 使用数据库 pgcrypto 验证密码
            cursor.execute("SELECT verify_password(%s, %s)", (password, row[1]))
            is_valid = cursor.fetchone()[0]
            if not is_valid:
                cursor.close()
                return json_response(401, {'error': 'Invalid credentials'})

            user_id = str(row[0])
            cursor.execute(
                "UPDATE users SET last_login_at = NOW() WHERE id = %s",
                (row[0],)
            )
            conn.commit()
            cursor.close()

            token = create_jwt(user_id)
            return json_response(200, {
                'user_id': user_id,
                'token': token
            })

        # ===== Token 验证 =====
        elif action == 'verify':
            token = body.get('token')
            if not token:
                return json_response(400, {'error': 'Missing token'})

            payload = verify_jwt(token)
            if not payload:
                return json_response(401, {'error': 'Invalid or expired token'})

            return json_response(200, {
                'valid': True,
                'user_id': payload['sub']
            })

        # ===== 获取用户资料 =====
        elif action == 'get_profile':
            user_id = body.get('user_id')
            if not user_id:
                return json_response(400, {'error': 'Missing user_id'})

            cursor.execute("""
                SELECT id, email, username, display_name, avatar_url,
                       preferred_lang, is_premium, premium_expires_at,
                       trips_count, translations_count, bio,
                       created_at, last_login_at
                FROM users WHERE id = %s AND is_active = true
            """, (user_id,))
            row = cursor.fetchone()
            cursor.close()

            if not row:
                return json_response(404, {'error': 'User not found'})

            return json_response(200, {
                'user_id': str(row[0]),
                'email': row[1],
                'username': row[2],
                'display_name': row[3],
                'avatar_url': row[4],
                'preferred_lang': row[5],
                'is_premium': row[6],
                'trips_count': row[8],
                'translations_count': row[9],
                'bio': row[10],
                'created_at': str(row[11]),
                'last_login_at': str(row[12]) if row[12] else None
            })

        # ===== 更新用户资料 =====
        elif action == 'update_profile':
            user_id = body.get('user_id')
            if not user_id:
                return json_response(400, {'error': 'Missing user_id'})

            updates = []
            params = []
            for field in ['username', 'display_name', 'avatar_url', 'preferred_lang','bio']:
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

            return json_response(200, {'success': True, 'user_id': user_id})

        else:
            cursor.close()
            return json_response(400, {
                'error': f'Unknown action: {action}. '
                         f'Supported: anonymous_auth, register, login, verify, '
                         f'get_profile, update_profile'
            })

    except Exception as e:
        print(f"[AUTH ERROR] {str(e)}")
        import traceback
        traceback.print_exc()
        return json_response(500, {'error': str(e)})
