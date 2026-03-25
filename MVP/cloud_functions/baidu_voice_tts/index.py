# baidu_voice_tts/index.py
# -*- coding: utf-8 -*-
"""
百度语音合成云函数
- 返回 MP3 音频的 Base64 编码（便于 JSON 传输）
- MVP 仅支持中文和英语
- 中文用度小美（per=0），英文用英文女声（per=103）
"""
import os
import sys
import time
import base64
import requests
import urllib.parse

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from shared.db_helper import json_response, parse_body

_token_cache = {'token': None, 'expires': 0}

def get_access_token():
    global _token_cache
    now = int(time.time())
    if _token_cache['token'] and now < _token_cache['expires'] - 86400:
        return _token_cache['token']

    resp = requests.post(
        'https://aip.baidubce.com/oauth/2.0/token',
        params={
            'grant_type': 'client_credentials',
            'client_id': os.environ['BAIDU_API_KEY'],
            'client_secret': os.environ['BAIDU_SECRET_KEY'],
        },
        timeout=10
    )
    resp.raise_for_status()
    data = resp.json()
    _token_cache = {
        'token': data['access_token'],
        'expires': now + data.get('expires_in', 2592000)
    }
    return _token_cache['token']

# MVP 仅支持中文和英语
VOICE_MAP = {
    'zh': {'per': 0, 'lan': 'zh'},     # 度小美
    'en': {'per': 103, 'lan': 'en'},    # 英文女声
}

def main_handler(event, context):
    """
    云函数入口
    输入: {"text": "地铁站在哪里", "language": "zh"}
    输出: {"audio_base64": "...", "format": "mp3"} 或 {"error": "..."}
    """
    try:
        body = parse_body(event)

        text = body.get('text', '').strip()
        language = body.get('language', 'zh')

        if not text:
            return json_response(400, {'error': 'Missing text'})
        if len(text) > 1024:
            return json_response(400, {'error': 'Text exceeds 1024 characters'})

        if language not in VOICE_MAP:
            return json_response(400, {
                'error': f'MVP only supports zh/en for TTS. '
                         f'French/Spanish voice output will be supported in a future version.'
            })

        token = get_access_token()
        voice = VOICE_MAP[language]
        encoded_text = urllib.parse.quote(text)

        resp = requests.post(
            'https://tsn.baidu.com/text2audio',
            data={
                'tex': encoded_text,
                'lan': voice['lan'],
                'cuid': body.get('device_id', 'wanderchina'),
                'ctp': '1',
                'tok': token,
                'per': str(voice['per']),
                'spd': str(body.get('speed', 5)),
                'pit': str(body.get('pitch', 5)),
                'vol': str(body.get('volume', 9)),
                'aue': '3',  # MP3
            },
            timeout=10
        )

        content_type = resp.headers.get('Content-Type', '')
        if 'audio' in content_type or 'octet-stream' in content_type:
            audio_b64 = base64.b64encode(resp.content).decode('utf-8')
            print(f"[TTS] lang={language} | text='{text[:30]}' | size={len(resp.content)}b")
            return json_response(200, {
                'audio_base64': audio_b64,
                'format': 'mp3',
                'size': len(resp.content)
            })
        else:
            error = resp.json() if resp.text else {'err_msg': 'Unknown error'}
            print(f"[TTS ERROR] {error}")
            return json_response(200, {
                'audio_base64': None,
                'error': error.get('err_msg', 'TTS failed')
            })

    except Exception as e:
        print(f"[TTS EXCEPTION] {str(e)}")
        import traceback
        traceback.print_exc()
        return json_response(500, {'error': str(e)})
