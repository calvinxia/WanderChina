# baidu_voice_asr/index.py
# -*- coding: utf-8 -*-
"""
百度语音识别云函数
- 百度密钥仅在云端，Flutter 不接触
- 自动管理 Access Token（30 天有效）
- MVP 仅支持中文和英语
"""
import os
import sys
import time
import requests

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from shared.db_helper import json_response, parse_body

# ===== Token 管理（全局缓存）=====
_token_cache = {'token': None, 'expires': 0}

def get_access_token():
    """获取百度 Access Token（自动缓存 + 刷新）"""
    global _token_cache
    now = int(time.time())

    if _token_cache['token'] and now < _token_cache['expires'] - 86400:
        return _token_cache['token']

    api_key = os.environ.get('BAIDU_API_KEY')
    secret_key = os.environ.get('BAIDU_SECRET_KEY')
    if not api_key or not secret_key:
        raise ValueError('Missing BAIDU_API_KEY or BAIDU_SECRET_KEY')

    resp = requests.post(
        'https://aip.baidubce.com/oauth/2.0/token',
        params={
            'grant_type': 'client_credentials',
            'client_id': api_key,
            'client_secret': secret_key,
        },
        timeout=10
    )
    resp.raise_for_status()
    data = resp.json()

    _token_cache = {
        'token': data['access_token'],
        'expires': now + data.get('expires_in', 2592000)
    }
    print(f"[TOKEN] 百度 Token 刷新成功，有效期 {data.get('expires_in', 2592000) // 86400} 天")
    return _token_cache['token']

# ===== 语言配置（MVP 仅支持中文和英语）=====
DEV_PID_MAP = {
    'zh': 80001,   # 普通话
    'en': 1737,   # 英语
}

def main_handler(event, context):
    """
    云函数入口
    输入: {"audio_base64": "...", "language": "en", "audio_len": 12800}
    输出: {"text": "where is the subway", "err_no": 0}
    """
    try:
        body = parse_body(event)

        audio_base64 = body.get('audio_base64')
        language = body.get('language', 'zh')
        audio_len = body.get('audio_len')

        if not audio_base64 or not audio_len:
            return json_response(400, {'error': 'Missing audio_base64 or audio_len'})

        if language not in DEV_PID_MAP:
            return json_response(400, {
                'error': f'MVP only supports zh/en for ASR. '
                         f'French/Spanish voice input will be supported in a future version.'
            })

        token = get_access_token()

        resp = requests.post(
            'https://vop.baidu.com/pro_api',
            headers={'Content-Type': 'application/json'},
            json={
                'format': 'pcm',
                'rate': 16000,
                'channel': 1,
                'cuid': body.get('device_id', 'wanderchina'),
                'token': token,
                'dev_pid': DEV_PID_MAP[language],
                'speech': audio_base64,
                'len': audio_len,
            },
            timeout=10
        )

        result = resp.json()
        err_no = result.get('err_no', -1)

        if err_no == 0:
            text = result['result'][0] if result.get('result') else ''
            print(f"[ASR] lang={language} | result='{text[:50]}'")
            return json_response(200, {'text': text, 'err_no': 0})
        else:
            print(f"[ASR ERROR] err_no={err_no}, err_msg={result.get('err_msg')}")
            return json_response(200, {
                'text': None,
                'err_no': err_no,
                'err_msg': result.get('err_msg', 'Unknown error')
            })

    except Exception as e:
        print(f"[ASR EXCEPTION] {str(e)}")
        import traceback
        traceback.print_exc()
        return json_response(500, {'error': str(e)})
