# get_nearby_pois/index.py
# -*- coding: utf-8 -*-
"""
按 geohash 前缀查询附近 POI
- 用 PostGIS ST_GeoHash 计算真实 geohash（精度5，约5km）
- Redis 缓存 key 格式: geo:poi:{geohash_prefix5}:{lang}
- 三层速率限制
"""
import os
import sys
import time
import json

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from shared.db_helper import get_db_connection, get_redis_client, json_response, parse_body

def check_rate_limit(user_id):
    """检查用户速率限制（60次/分钟）"""
    try:
        r = get_redis_client()
        minute = int(time.time()) // 60
        key = f"rl:nearby:{user_id}:{minute}"
        count = r.incr(key)
        if count == 1:
            r.expire(key, 120)
        return count <= 60
    except Exception:
        return True

def main_handler(event, context):
    try:
        body = parse_body(event)

        lat = body.get('latitude')
        lng = body.get('longitude')
        lang = body.get('lang', 'en')
        radius = min(body.get('radius', 2000), 5000)
        limit = min(body.get('limit', 50), 100)
        user_id = body.get('user_id', 'anonymous')

        if lat is None or lng is None:
            return json_response(400, {'error': 'Missing latitude/longitude'})

        # 速率限制
        if not check_rate_limit(user_id):
            return json_response(429, {'error': 'Rate limit exceeded (60/min)'})

        # 用 PostGIS 计算真实 geohash 前缀（精度5，约5km×5km）
        conn = get_db_connection()
        gh_cursor = conn.cursor()
        gh_cursor.execute(
            "SELECT ST_GeoHash(ST_SetSRID(ST_MakePoint(%s, %s), 4326), 5)",
            (lng, lat)
        )
        geohash_prefix = gh_cursor.fetchone()[0]
        gh_cursor.close()

        # 构造缓存 key（符合 Config v2 §4.3 命名规范）
        cache_key = f"geo:poi:{geohash_prefix}:{lang}"

        # 查 Redis 缓存
        try:
            r = get_redis_client()
            cached = r.get(cache_key)
            if cached:
                print(f"[CACHE HIT] {cache_key}")
                return json_response(200, json.loads(cached))
        except Exception:
            pass

        # 缓存未命中，查数据库
        cursor = conn.cursor()

        name_col = {'en': 'name_en', 'fr': 'name_fr', 'es': 'name_es'}.get(lang, 'name_en')
        cat_col = {'en': 'category_en', 'fr': 'category_fr', 'es': 'category_es'}.get(lang, 'category_en')

        cursor.execute(f"""
            SELECT
                gaode_poi_id,
                name_zh,
                {name_col} AS name_translated,
                {cat_col} AS category_translated,
                latitude,
                longitude,
                priority_score,
                ST_Distance(
                    location,
                    ST_SetSRID(ST_MakePoint(%s, %s), 4326)::geography
                ) AS distance_meters
            FROM poi_translations
            WHERE ST_DWithin(
                location,
                ST_SetSRID(ST_MakePoint(%s, %s), 4326)::geography,
                %s
            )
            AND {name_col} IS NOT NULL
            ORDER BY priority_score DESC, distance_meters ASC
            LIMIT %s
        """, (lng, lat, lng, lat, radius, limit))

        rows = cursor.fetchall()
        columns = ['poi_id', 'name_zh', 'name_translated', 'category',
                   'lat', 'lng', 'priority', 'distance']

        pois = []
        for row in rows:
            poi = dict(zip(columns, row))
            poi['distance'] = round(float(poi['distance']), 1)
            poi['lat'] = float(poi['lat'])
            poi['lng'] = float(poi['lng'])
            pois.append(poi)

        cursor.close()

        result = {
            'pois': pois,
            'count': len(pois),
            'center': {'lat': lat, 'lng': lng},
            'radius': radius,
            'lang': lang,
            'geohash': geohash_prefix
        }

        # 写入区域缓存（1 小时）
        try:
            r = get_redis_client()
            r.setex(cache_key, 3600, json.dumps(result, ensure_ascii=False))
        except Exception:
            pass

        return json_response(200, result)

    except Exception as e:
        print(f"[ERROR] {str(e)}")
        import traceback
        traceback.print_exc()
        return json_response(500, {'error': str(e)})
