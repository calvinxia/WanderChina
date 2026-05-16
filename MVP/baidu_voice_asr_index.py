# baidu_voice_asr/index.py
# -*- coding: utf-8 -*-
"""
百度语音识别云函数
- 百度密钥仅在云端，Flutter 不接触
- 自动管理 Access Token（30 天有效）
- MVP 支持中文和英语
- 中文用极速版 pro_api (dev_pid: 80001)
- 英文用标准版 server_api (dev_pid: 1737)
- 音频格式从请求体获取（wav/pcm/m4a）
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


# ===== 语言配置 =====

# 中文：极速版 pro_api，dev_pid 80001
# 英文：标准版 server_api，dev_pid 1737
LANG_CONFIG = {
    'zh': {'dev_pid': 80001, 'api': 'https://vop.baidu.com/pro_api'},
    'en': {'dev_pid': 1737,  'api': 'https://vop.baidu.com/server_api'},
}


def main_handler(event, context):
    """
    云函数入口
    输入: {
        "audio_base64": "...",
        "audio_len": 12800,
        "language": "en",       // "zh" 或 "en"
        "format": "wav"         // "wav", "pcm", "m4a"
    }
    输出: {"text": "I love China", "err_no": 0}
    """
    try:
        body = parse_body(event)

        audio_base64 = body.get('audio_base64')
        language = body.get('language', 'zh')
        audio_len = body.get('audio_len')
        audio_format = body.get('format', 'pcm')

        if not audio_base64 or not audio_len:
            return json_response(400, {'error': 'Missing audio_base64 or audio_len'})

        if language not in LANG_CONFIG:
            return json_response(400, {
                'error': f'MVP only supports zh/en for ASR. '
                         f'French/Spanish voice input will be supported in a future version.'
            })

        config = LANG_CONFIG[language]
        token = get_access_token()

        print(f"[ASR] lang={language}, format={audio_format}, len={audio_len}, "
              f"dev_pid={config['dev_pid']}, api={config['api']}")

        resp = requests.post(
            config['api'],
            headers={'Content-Type': 'application/json'},
            json={
                'format': audio_format,
                'rate': 16000,
                'channel': 1,
                'cuid': body.get('device_id', 'wanderchina'),
                'token': token,
                'dev_pid': config['dev_pid'],
                'speech': audio_base64,
                'len': audio_len,
            },
            timeout=15
        )

        result = resp.json()
        err_no = result.get('err_no', -1)

        if err_no == 0:
            text = result['result'][0] if result.get('result') else ''
            print(f"[ASR OK] lang={language} | result='{text[:80]}'")
            return json_response(200, {
                'text': text,
                'recognized_text': text,
                'err_no': 0,
            })
        else:
            err_msg = result.get('err_msg', 'Unknown error')
            print(f"[ASR ERROR] err_no={err_no}, err_msg={err_msg}")
            return json_response(200, {
                'text': None,
                'recognized_text': None,
                'err_no': err_no,
                'err_msg': err_msg,
            })

    except Exception as e:
        print(f"[ASR EXCEPTION] {str(e)}")
        import traceback
        traceback.print_exc()
        return json_response(500, {'error': str(e)})
