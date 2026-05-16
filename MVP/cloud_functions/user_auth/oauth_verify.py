# user_auth/oauth_verify.py
# -*- coding: utf-8 -*-
"""
OAuth ID Token 验证模块.
当前只支持 Apple (Google 因腾讯云广州 SCF 无法访问 googleapis.com 暂时移除).
"""
import os
import time
import jwt
import requests as http_requests
from jwt.algorithms import RSAAlgorithm

# 全局缓存 (云函数容器复用周期内有效)
_apple_jwks = None
_apple_jwks_fetched_at = None

JWKS_CACHE_TTL = 86400  # 24 小时

APPLE_JWKS_URL = 'https://appleid.apple.com/auth/keys'

APPLE_CLIENT_ID = os.environ.get('APPLE_CLIENT_ID', '')


def _fetch_jwks_with_retry(url, max_retries=3, timeout=10):
    """fetch JWKS with retry for transient failures"""
    last_exception = None
    for attempt in range(max_retries):
        try:
            resp = http_requests.get(url, timeout=timeout)
            resp.raise_for_status()
            return resp.json()
        except Exception as e:
            last_exception = e
            print(f"[oauth_verify] JWKS fetch attempt {attempt+1}/{max_retries} failed: {e}")
    raise last_exception


def get_apple_jwks():
    global _apple_jwks, _apple_jwks_fetched_at
    if _apple_jwks and _apple_jwks_fetched_at and \
       (time.time() - _apple_jwks_fetched_at) < JWKS_CACHE_TTL:
        return _apple_jwks
    _apple_jwks = _fetch_jwks_with_retry(APPLE_JWKS_URL)
    _apple_jwks_fetched_at = time.time()
    return _apple_jwks


def _find_key_by_kid(jwks, kid):
    for key in jwks['keys']:
        if key['kid'] == kid:
            return RSAAlgorithm.from_jwk(key)
    raise ValueError(f"Key id {kid} not found in JWKS")


def verify_apple_id_token(id_token):
    """Verify Apple ID token, return decoded payload (with sub, email)."""
    if not APPLE_CLIENT_ID:
        raise RuntimeError("APPLE_CLIENT_ID env var not set")
    headers = jwt.get_unverified_header(id_token)
    kid = headers['kid']
    public_key = _find_key_by_kid(get_apple_jwks(), kid)
    decoded = jwt.decode(
        id_token,
        public_key,
        algorithms=['RS256'],
        audience=APPLE_CLIENT_ID,
        issuer='https://appleid.apple.com'
    )
    return decoded
