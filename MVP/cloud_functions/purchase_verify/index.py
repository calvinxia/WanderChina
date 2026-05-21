# purchase_verify/index.py
# -*- coding: utf-8 -*-
"""
Apple IAP receipt 验证 + 订阅状态更新.

流程:
1. 接收 user_id + receipt_data + product_id
2. 调 Apple verifyReceipt API (production first, fallback sandbox)
3. 解析 receipt.in_app, 提取 transaction_id
4. 调 process_purchase SQL function (写 transactions + 更新 users)
5. 返回新的 premium_expires_at

v2.1: 新增 is_sandbox 标记，区分沙盒和生产交易
"""
import os
import sys
import json
import psycopg2.errors
import requests

sys.path.insert(0, os.path.dirname(__file__) or '.')
from shared.db_helper import get_db_connection, get_redis_client, json_response, parse_body

SANDBOX_URL = 'https://sandbox.itunes.apple.com/verifyReceipt'
PRODUCTION_URL = 'https://buy.itunes.apple.com/verifyReceipt'
APP_STORE_SHARED_SECRET = os.environ.get('APP_STORE_SHARED_SECRET', '')

VALID_PRODUCT_IDS = {'wanderchina.trip_pass.7d', 'wanderchina.trip_pass.14d', 'wanderchina.trip_pass.30d'}


def verify_receipt_with_apple(receipt_data):
    """
    Verify receipt with Apple, handling sandbox/production switch.

    Apple 推荐流程: 总是先试 production, 看 status code 决定:
      - status=0: 成功
      - status=21007: receipt 来自 sandbox, 用 sandbox endpoint 重试
      - status=21008: receipt 来自 production, 用 production endpoint 重试

    Returns:
        tuple: (parsed receipt response, is_sandbox bool)
    Raises:
        ValueError: if receipt invalid after both endpoints tried
    """
    if not APP_STORE_SHARED_SECRET:
        raise RuntimeError("APP_STORE_SHARED_SECRET env var not set")

    payload = {
        'receipt-data': receipt_data,
        'password': APP_STORE_SHARED_SECRET,
        'exclude-old-transactions': True,
    }

    is_sandbox = False

    # 第 1 次: production (Apple 推荐先试 production)
    resp = requests.post(PRODUCTION_URL, json=payload, timeout=10)
    resp.raise_for_status()
    result = resp.json()
    status = result.get('status')

    # status=21007 = receipt 来自 sandbox, 切换到 sandbox 重试
    if status == 21007:
        is_sandbox = True
        resp = requests.post(SANDBOX_URL, json=payload, timeout=10)
        resp.raise_for_status()
        result = resp.json()
        status = result.get('status')

    # 最终 status 必须为 0
    if status != 0:
        raise ValueError(f"Apple receipt verification failed with status: {status}")

    return result, is_sandbox


def extract_transaction(receipt_response, expected_product_id):
    """
    从 receipt 响应中提取 transaction_id + product_id.

    Non-Renewing Subscription 的交易在 receipt.in_app 数组中.
    取最新的一笔 (按 purchase_date 排序).

    Returns:
        dict: {transaction_id, product_id, original_transaction_id, purchase_date_ms}
    Raises:
        ValueError: 若未找到匹配 product_id 的 transaction
    """
    receipt = receipt_response.get('receipt', {})
    in_app = receipt.get('in_app', [])

    if not in_app:
        raise ValueError("No in_app purchases found in receipt")

    # 找匹配 product_id 的最新 transaction
    matching = [t for t in in_app if t.get('product_id') == expected_product_id]
    if not matching:
        raise ValueError(
            f"No transaction for product_id={expected_product_id} in receipt. "
            f"Found products: {set(t.get('product_id') for t in in_app)}"
        )

    # 按 purchase_date_ms 排序, 取最新
    matching.sort(key=lambda t: int(t.get('purchase_date_ms', '0')), reverse=True)
    latest = matching[0]

    return {
        'transaction_id': latest['transaction_id'],
        'product_id': latest['product_id'],
        'original_transaction_id': latest.get('original_transaction_id', latest['transaction_id']),
        'purchase_date_ms': int(latest.get('purchase_date_ms', '0')),
    }


def main_handler(event, context):
    conn = None
    cursor = None
    try:
        body = parse_body(event)

        # 输入校验
        user_id = body.get('user_id')
        receipt_data = body.get('receipt_data')
        product_id = body.get('product_id')

        if not user_id:
            return json_response(400, {'error': 'Missing user_id'})
        if not receipt_data:
            return json_response(400, {'error': 'Missing receipt_data'})
        if product_id not in VALID_PRODUCT_IDS:
            return json_response(400, {
                'error': f'Invalid product_id: {product_id}. '
                         f'Valid: {sorted(VALID_PRODUCT_IDS)}'
            })

        # 1. 验证 receipt with Apple
        try:
            receipt_response, is_sandbox = verify_receipt_with_apple(receipt_data)
        except requests.exceptions.RequestException as e:
            print(f"[PURCHASE] Apple API network error: {e}")
            return json_response(503, {'error': 'Apple verification service unavailable'})
        except ValueError as e:
            print(f"[PURCHASE] Receipt validation failed: {e}")
            return json_response(400, {'error': str(e)})

        # 2. 提取 transaction info
        try:
            tx = extract_transaction(receipt_response, product_id)
        except ValueError as e:
            print(f"[PURCHASE] Transaction extraction failed: {e}")
            return json_response(400, {'error': str(e)})

        # 3. 调 process_purchase SQL function（含 is_sandbox 参数）
        conn = get_db_connection()
        cursor = conn.cursor()

        try:
            cursor.execute("""
                SELECT process_purchase(%s, %s, %s, %s, %s, %s)
            """, (
                user_id,
                product_id,
                tx['transaction_id'],
                'apple',
                json.dumps(receipt_response)[:10000],
                is_sandbox,
            ))
            new_expires_at = cursor.fetchone()[0]
            conn.commit()
        except psycopg2.errors.UniqueViolation:
            # transaction_id 已存在 = 客户端重发, 幂等返回
            conn.rollback()
            cursor.close()

            # 查询当前用户的 premium_expires_at 返回 (保持响应一致)
            cursor = conn.cursor()
            cursor.execute(
                "SELECT premium_expires_at FROM users WHERE id = %s",
                (user_id,)
            )
            row = cursor.fetchone()
            cursor.close()

            return json_response(200, {
                'success': True,
                'duplicate': True,
                'premium_expires_at': row[0].isoformat() if row and row[0] else None,
            })
        except psycopg2.Error as e:
            conn.rollback()
            print(f"[PURCHASE] DB error: {e}")
            return json_response(500, {'error': 'Database error during purchase processing'})

        cursor.close()

        # 4. 清 Redis 用户缓存 (下次 restore_session 会重读 DB 的 premium 状态)
        try:
            r = get_redis_client()
            r.delete(f"user:{user_id}")
        except Exception:
            pass

        env_label = "SANDBOX" if is_sandbox else "PRODUCTION"
        print(f"[PURCHASE] [{env_label}] Success: user={user_id} product={product_id} tx={tx['transaction_id']}")

        return json_response(200, {
            'success': True,
            'duplicate': False,
            'premium_expires_at': new_expires_at.isoformat(),
            'product_id': product_id,
            'transaction_id': tx['transaction_id'],
            'is_sandbox': is_sandbox,
        })

    except Exception as e:
        print(f"[PURCHASE ERROR] {str(e)}")
        import traceback
        traceback.print_exc()
        if cursor:
            try:
                cursor.close()
            except Exception:
                pass
        return json_response(500, {'error': str(e)})
