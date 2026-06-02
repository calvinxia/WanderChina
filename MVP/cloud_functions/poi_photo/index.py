# poi_photo/index.py
# -*- coding: utf-8 -*-
"""
POI 图片获取云函数（公网函数）v2.2
- Unsplash 优先 + 高德 Amap fallback
- Unsplash 合规：hotlink + 摄影师署名 + download trigger
- 图片质量优化：取 3 张跳过黑白、分层搜索策略
- 支持 single / batch / ping

架构位置：第 12 个云函数（公网）
"""
import os
import json
import urllib.request
import urllib.parse
import urllib.error

UNSPLASH_ACCESS_KEY = os.environ.get('UNSPLASH_ACCESS_KEY', '')

# 黑白/极暗色判断阈值
_BW_COLORS = {'#000000', '#ffffff', '#333333', '#111111', '#fefefe', '#0a0a0a', '#1a1a1a'}


def _get_unsplash_photo(query, per_page=3):
    """从 Unsplash 搜索高质量图片（优先彩色）

    Unsplash 合规要求：
    1. hotlink 图片 URL（不下载存储）✅
    2. 显示摄影师署名 ✅
    3. 触发 download_location ✅

    Args:
        query: 搜索关键词
        per_page: 取回候选数量（从中选最佳）

    Returns:
        dict 或 None
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

        # 优先选彩色照片（跳过黑白/极暗）
        photo = None
        for candidate in results[:per_page]:
            color = (candidate.get('color') or '#000000').lower()
            if color not in _BW_COLORS:
                photo = candidate
                break
        if photo is None:
            photo = results[0]  # 全是黑白则取第一张

        # regular 尺寸（1080px 宽，Detail Sheet 够用）
        photo_url = photo.get('urls', {}).get('regular')
        photographer = photo.get('user', {}).get('name', 'Unknown')
        photographer_url = photo.get('user', {}).get('links', {}).get('html', '')

        # UTM 参数（Unsplash 合规）
        if photographer_url:
            photographer_url += '?utm_source=wanderchina&utm_medium=referral'

        # 触发 download 追踪（fire-and-forget）
        download_location = photo.get('links', {}).get('download_location', '')
        if download_location:
            try:
                dl_req = urllib.request.Request(download_location, headers={
                    'Authorization': f'Client-ID {UNSPLASH_ACCESS_KEY}',
                    'Accept-Version': 'v1',
                })
                urllib.request.urlopen(dl_req, timeout=3)
            except Exception:
                pass

        return {
            'photo_url': photo_url,
            'photographer': photographer,
            'photographer_url': photographer_url,
            'source': 'unsplash',
        }
    except Exception as e:
        print(f'[UNSPLASH] Search failed for "{query}": {e}')
        return None


def _search_unsplash_with_fallback(category, image_keyword, name_en, city):
    """分层搜索策略：精确 → 泛化 → 放弃

    Returns:
        dict 或 None
    """
    if not UNSPLASH_ACCESS_KEY:
        return None

    queries = []

    if category == 'food' and image_keyword:
        # 美食：精确菜名 → 菜名+城市 → 菜名+Chinese cuisine
        queries.append(image_keyword)
        if city:
            queries.append(f'{image_keyword} {city}')
        queries.append(f'{image_keyword} Chinese cuisine')

    elif category == 'sightseeing' and name_en:
        # 景点：地标+城市 → 地标+China → 纯地标
        if city:
            queries.append(f'{name_en} {city} China')
        queries.append(f'{name_en} China landmark')
        queries.append(name_en)

    elif category == 'shopping' and name_en:
        queries.append(f'{name_en} market China')
        queries.append(f'{name_en} shopping')

    elif image_keyword:
        queries.append(image_keyword)
        if city:
            queries.append(f'{image_keyword} {city}')

    else:
        return None

    # 逐层尝试，找到好结果就返回
    for query in queries:
        result = _get_unsplash_photo(query, per_page=3)
        if result and result.get('photo_url'):
            print(f'[PHOTO] Unsplash hit: "{query}" → {result["photographer"]}')
            return result

    return None


def _get_photo(name_zh, city='', amap_key=''):
    """获取单个 POI 的高德图片 URL（fallback）"""
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
    # 定时触发器预热 — 快速返回保持容器热
    if isinstance(event, dict) and 'TriggerName' in event:
        return {'statusCode': 200, 'body': '{"status":"warm"}'}

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

            # === Unsplash 分层搜索 ===
            unsplash_result = _search_unsplash_with_fallback(
                category, image_keyword, name_en, city
            )

            # === Unsplash 命中 → 直接返回 ===
            if unsplash_result and unsplash_result.get('photo_url'):
                return _response(200, {
                    'name_zh': name_zh,
                    'photo_url': unsplash_result['photo_url'],
                    'photographer': unsplash_result.get('photographer'),
                    'photographer_url': unsplash_result.get('photographer_url'),
                    'unsplash_url': 'https://unsplash.com/?utm_source=wanderchina&utm_medium=referral',
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
                'unsplash_url': None,
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
                unsplash_url = None
                source = None

                # Unsplash 分层搜索
                unsplash_result = _search_unsplash_with_fallback(
                    category, image_keyword, name_en, item_city
                )
                if unsplash_result and unsplash_result.get('photo_url'):
                    photo_url = unsplash_result['photo_url']
                    photographer = unsplash_result.get('photographer')
                    photographer_url = unsplash_result.get('photographer_url')
                    unsplash_url = 'https://unsplash.com/?utm_source=wanderchina&utm_medium=referral'
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
                    'unsplash_url': unsplash_url,
                    'source': source,
                    'category': category,
                })

            return _response(200, {'results': results, 'count': len(results)})

        elif action == 'ping':
            return _response(200, {'status': 'warm'})

        else:
            return _response(400, {'error': f'Unknown action: {action}. Supported: single, batch, ping'})

    except Exception as e:
        print(f"[PHOTO ERROR] {str(e)}")
        return _response(500, {'error': str(e)})
