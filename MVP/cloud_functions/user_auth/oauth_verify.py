# user_auth/oauth_verify.py
# -*- coding: utf-8 -*-
"""
OAuth ID Token 验证模块.
支持 Apple 和 Google Sign-In.
Google 验证经 Cloudflare 代理中转(广州 SCF 无法直连 googleapis.com).
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


# ============================================================================
# Google Sign-In 验证(方式 1:经 Cloudflare 中转 tokeninfo 端点)
# ----------------------------------------------------------------------------
# 背景:广州 SCF 无法直连 googleapis.com(2026-05-12 实测 TCP 阻断),
#       故经 gproxy.wanderchina.app 中转。详见 ADR_google_signin_verification.md
# 约束:必须带正常 User-Agent,否则 Cloudflare bot 防护返回 403
# ============================================================================

GOOGLE_PROXY_URL = os.environ.get(
    'GOOGLE_PROXY_URL',
    'https://gproxy.wanderchina.app/verify-google-token'
)
GOOGLE_WEB_CLIENT_ID = os.environ.get('GOOGLE_WEB_CLIENT_ID', '')

_PROXY_UA = 'Mozilla/5.0 (compatible; WanderChina-SCF/1.0)'


def verify_google_id_token(id_token):
    """验证 Google ID token,返回解析后的 payload(含 sub, email)。

    方式 1:将 id_token 经 gproxy 转发至 Google tokeninfo 端点,
    由 Google 验证并返回解析结果。

    Raises:
        RuntimeError: 配置缺失
        ValueError:   token 无效 / aud 不匹配 / 验证失败
    """
    if not GOOGLE_WEB_CLIENT_ID:
        raise RuntimeError("GOOGLE_WEB_CLIENT_ID env var not set")

    url = f"{GOOGLE_PROXY_URL}?token={id_token}"
    try:
        resp = http_requests.get(
            url,
            headers={'User-Agent': _PROXY_UA},
            timeout=10,
        )
    except Exception as e:
        raise ValueError(f"Google token verification request failed: {e}")

    if resp.status_code != 200:
        raise ValueError(
            f"Google token invalid (status {resp.status_code}): {resp.text[:200]}"
        )

    try:
        payload = resp.json()
    except Exception as e:
        raise ValueError(f"Google tokeninfo returned non-JSON: {e}")

    aud = payload.get('aud')
    if aud != GOOGLE_WEB_CLIENT_ID:
        raise ValueError(f"Google token aud mismatch: {aud}")

    iss = payload.get('iss')
    if iss not in ('accounts.google.com', 'https://accounts.google.com'):
        raise ValueError(f"Google token iss invalid: {iss}")

    if not payload.get('sub'):
        raise ValueError("Google token missing sub")

    return payload
