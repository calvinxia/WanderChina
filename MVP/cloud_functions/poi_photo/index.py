# poi_photo/index.py
# -*- coding: utf-8 -*-
"""
POI 图片获取云函数（公网函数）
调用高德 Place API 获取 POI 图片 URL，不访问数据库。
Unplash优化
支持批量查询，减少网络往返次数。

架构位置：第 12 个云函数（公网）
"""
import os
import json
import urllib.request
import urllib.parse
import urllib.error

UNSPLASH_ACCESS_KEY = os.environ.get('UNSPLASH_ACCESS_KEY', '')

def _get_unsplash_photo(query, per_page=1):
    """从 Unsplash 搜索高质量图片

    返回: {'photo_url': str, 'photographer': str, 'photographer_url': str} 或 None
    Unsplash 要求：hotlink 图片 URL + 显示摄影师署名
    """
    if not UNSPLASH_ACCESS_KEY:
        return None

    try:
        params = urllib.parse.urlencode({
            'query': query,
            'per_page': per_page,
            'orientation': 'landscape',
            'content_filter': 'high',
        })
        url = f'https://api.unsplash.com/search/photos?{params}'

        req = urllib.request.Request(url, headers={
            'Authorization': f'Client-ID {UNSPLASH_ACCESS_KEY}',
            'Accept-Version': 'v1',
        })

        with urllib.request.urlopen(req, timeout=5) as resp:
            data = json.loads(resp.read().decode('utf-8'))

        results = data.get('results', [])
        if not results:
            return None

        photo = results[0]
        # 用 regular 尺寸（1080px 宽，Detail Sheet 够用）
        photo_url = photo.get('urls', {}).get('regular')
        photographer = photo.get('user', {}).get('name', 'Unknown')
        photographer_url = photo.get('user', {}).get('links', {}).get('html', '')

        return {
            'photo_url': photo_url,
            'photographer': photographer,
            'photographer_url': photographer_url,
            'source': 'unsplash',
        }
    except Exception as e:
        print(f'[UNSPLASH] Search failed for "{query}": {e}')
        return None


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
            name_en = body.get('name_en', '').strip()
            city = body.get('city', '')
            category = body.get('category', '').strip()
            image_keyword = body.get('image_keyword', '').strip()

            if not name_zh and not name_en:
                return _response(400, {'error': 'Missing name_zh or name_en'})

            # === Unsplash 优先（根据 category 构建搜索词）===
            unsplash_result = None
            if UNSPLASH_ACCESS_KEY:
                if category == 'food' and image_keyword:
                    # 餐厅：用 imageKeyword 搜美食图
                    unsplash_query = image_keyword
                elif category == 'sightseeing' and name_en:
                    # 景点：用英文名 + China 搜地标图
                    unsplash_query = f'{name_en} China'
                elif category == 'shopping' and name_en:
                    unsplash_query = f'{name_en} market China'
                elif image_keyword:
                    # 其他有 imageKeyword 的：直接用
                    unsplash_query = image_keyword
                else:
                    unsplash_query = None

                if unsplash_query:
                    unsplash_result = _get_unsplash_photo(unsplash_query)
                    if unsplash_result:
                        print(f'[PHOTO] Unsplash hit: "{unsplash_query}" → {unsplash_result["photographer"]}')

            # === Unsplash 命中 → 直接返回 ===
            if unsplash_result and unsplash_result.get('photo_url'):
                return _response(200, {
                    'name_zh': name_zh,
                    'photo_url': unsplash_result['photo_url'],
                    'photographer': unsplash_result.get('photographer'),
                    'photographer_url': unsplash_result.get('photographer_url'),
                    'source': 'unsplash',
                    'poi_id': None,
                    'lat': None,
                    'lng': None,
                    'category': category,
                })

            # === Unsplash 未命中 → fallback 到高德 ===
            print(f'[PHOTO] Unsplash miss, falling back to Amap: name_zh={name_zh}')
            result = _get_photo(name_zh, city, amap_key)

            return _response(200, {
                'name_zh': name_zh,
                'photo_url': result['photo_url'],
                'photographer': None,
                'photographer_url': None,
                'source': 'amap',
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
                name_en = item.get('name_en', '').strip()
                item_city = item.get('city', city)
                category = item.get('category', '').strip()
                image_keyword = item.get('image_keyword', '').strip()

                photo_url = None
                photographer = None
                photographer_url = None
                source = None

                # Unsplash 优先
                if UNSPLASH_ACCESS_KEY and (category or image_keyword):
                    if category == 'food' and image_keyword:
                        unsplash_query = image_keyword
                    elif category == 'sightseeing' and name_en:
                        unsplash_query = f'{name_en} China'
                    elif category == 'shopping' and name_en:
                        unsplash_query = f'{name_en} market China'
                    elif image_keyword:
                        unsplash_query = image_keyword
                    else:
                        unsplash_query = None

                    if unsplash_query:
                        unsplash_result = _get_unsplash_photo(unsplash_query)
                        if unsplash_result and unsplash_result.get('photo_url'):
                            photo_url = unsplash_result['photo_url']
                            photographer = unsplash_result.get('photographer')
                            photographer_url = unsplash_result.get('photographer_url')
                            source = 'unsplash'

                # Unsplash 未命中 → fallback 高德
                if not photo_url and name_zh:
                    amap_result = _get_photo(name_zh, item_city, amap_key)
                    if amap_result.get('photo_url'):
                        photo_url = amap_result['photo_url']
                        source = 'amap'

                results.append({
                    'name_zh': name_zh,
                    'name_en': name_en,
                    'photo_url': photo_url,
                    'photographer': photographer,
                    'photographer_url': photographer_url,
                    'source': source,
                    'category': category,
                })

            return _response(200, {'results': results, 'count': len(results)})

        else:
            return _response(400, {'error': f'Unknown action: {action}. Supported: single, batch'})

    except Exception as e:
        print(f"[PHOTO ERROR] {str(e)}")
        return _response(500, {'error': str(e)})
