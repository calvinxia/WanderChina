# poi_photo/index.py
# -*- coding: utf-8 -*-
"""
POI 图片获取云函数（公网函数）
调用高德 Place API 获取 POI 图片 URL，不访问数据库。
支持批量查询，减少网络往返次数。

架构位置：第 12 个云函数（公网）
"""
import os
import json
import urllib.request
import urllib.parse
import urllib.error


def _get_photo(name_zh, city='', amap_key=''):
    """获取单个 POI 的图片 URL"""
    params = urllib.parse.urlencode({
        'key': amap_key,
        'keywords': name_zh,
        'city': city,
        'extensions': 'all',
        'offset': '1',
    })
    url = f'https://restapi.amap.com/v3/place/text?{params}'

    try:
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=5) as resp:
            data = json.loads(resp.read().decode('utf-8'))

        if data.get('status') == '1' and data.get('pois'):
            poi = data['pois'][0]
            photo_url = None
            photos = poi.get('photos', [])
            if photos:
                raw_url = photos[0].get('url', '')
                if raw_url:
                    photo_url = raw_url.replace('http://', 'https://')
                    
                    # 解析坐标
            location = poi.get('location', '')
            lng, lat = None, None
            if location and ',' in location:
                parts = location.split(',')
                lng = float(parts[0])
                lat = float(parts[1])

            return {
                'photo_url': photo_url,
                'poi_id': poi.get('id'),
                'lat': lat,
                'lng': lng,
                'category': poi.get('type', ''),
            }
        return {'photo_url': None, 'poi_id': None, 'lat': None, 'lng': None, 'category': None}
    except Exception:
        return {'photo_url': None, 'poi_id': None, 'lat': None, 'lng': None, 'category': None}

def _response(code, body):
    return {
        'statusCode': code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
        },
        'body': json.dumps(body, ensure_ascii=False),
    }


def main_handler(event, context):
    try:
        # 解析请求体
        if isinstance(event.get('body'), str):
            body = json.loads(event['body'])
        elif isinstance(event.get('body'), dict):
            body = event['body']
        else:
            body = event

        amap_key = os.environ.get('AMAP_WEB_KEY')
        if not amap_key:
            return _response(500, {'error': 'Missing AMAP_WEB_KEY'})

        action = body.get('action', 'single')

        # ===== 单个查询 =====
       if action == 'single':
            name_zh = body.get('name_zh', '').strip()
            city = body.get('city', '')

            if not name_zh:
                return _response(400, {'error': 'Missing name_zh'})

            result = _get_photo(name_zh, city, amap_key)

            return _response(200, {
                'name_zh': name_zh,
                'photo_url': result['photo_url'],
                'poi_id': result['poi_id'],
                'lat': result['lat'],
                'lng': result['lng'],
                'category': result['category'],
            })


        # ===== 批量查询（行程详情页用）=====
        elif action == 'batch':
            items = body.get('items', [])
            city = body.get('city', '')

            if not items or len(items) > 20:
                return _response(400, {'error': 'items required, max 20'})

            results = []
            for item in items:
                name_zh = item.get('name_zh', '').strip()
                item_city = item.get('city', city)
                photo_url = _get_photo(name_zh, item_city, amap_key) if name_zh else None
                results.append({
                    'name_zh': name_zh,
                    'photo_url': photo_url,
                })

            return _response(200, {
                'name_zh': name_zh,
                'photo_url': result['photo_url'],
                'poi_id': result['poi_id'],
                'lat': result['lat'],
                'lng': result['lng'],
                'category': result['category'],
            })

        else:
            return _response(400, {'error': f'Unknown action: {action}. Supported: single, batch'})

    except Exception as e:
        print(f"[PHOTO ERROR] {str(e)}")
        return _response(500, {'error': str(e)})
