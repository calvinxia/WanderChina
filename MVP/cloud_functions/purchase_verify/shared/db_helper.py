# shared/db_helper.py
# -*- coding: utf-8 -*-
"""
云函数公共模块
- 数据库连接（心跳检测 + 自动重连）
- Redis 客户端（复用连接）
- 统一响应格式
- 请求体解析
注意: psycopg2 和 redis 使用懒加载，公网函数 import 此模块不会报错
"""
import os
import json

_db_conn = None
_redis_client = None

def get_db_connection():
    """获取数据库连接（带心跳检测和自动重连）"""
    import psycopg2
    global _db_conn

    if _db_conn is not None:
        try:
            cur = _db_conn.cursor()
            cur.execute("SELECT 1")
            cur.close()
        except Exception:
            try:
                _db_conn.close()
            except Exception:
                pass
            _db_conn = None

    if _db_conn is None:
        _db_conn = psycopg2.connect(
            host=os.environ['DB_HOST'],
            port=int(os.environ.get('DB_PORT', 5432)),
            database=os.environ['DB_NAME'],
            user=os.environ['DB_USER'],
            password=os.environ['DB_PASSWORD'],
            sslmode='disable',
            connect_timeout=10,
            keepalives=1,
            keepalives_idle=60,
            keepalives_interval=10,
            keepalives_count=3
        )

    return _db_conn

def get_redis_client():
    """获取 Redis 客户端（复用连接）"""
    import redis
    global _redis_client

    if _redis_client is None:
        _redis_client = redis.Redis(
            host=os.environ['REDIS_HOST'],
            port=int(os.environ.get('REDIS_PORT', 6379)),
            password=os.environ.get('REDIS_PASSWORD', ''),
            decode_responses=True,
            socket_connect_timeout=5,
            socket_keepalive=True
        )
        _redis_client.ping()

    return _redis_client

def json_response(status_code, body_dict):
    """统一响应格式"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(body_dict, ensure_ascii=False)
    }

def parse_body(event):
    """解析请求体"""
    if isinstance(event, dict) and 'body' in event:
        return json.loads(event['body'])
    return event
