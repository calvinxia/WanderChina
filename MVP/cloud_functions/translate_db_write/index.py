# translate_db_write/index.py
# -*- coding: utf-8 -*-
"""
翻译结果写入 + Redis 缓存查询
支持三种操作: get（查单语缓存）、batch_get（查多语缓存）、save（写入数据库+缓存）
"""
import os
import sys

# 导入共享模块（符合 cloud_functions_order 要求）
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from shared.db_helper import get_db_connection, get_redis_client, json_response, parse_body

# ===== 缓存操作 =====

def cache_get(poi_id, lang):
    try:
        r = get_redis_client()
        return r.get(f"poi:trans:{poi_id}:{lang}")
    except Exception as e:
        print(f"[REDIS GET ERROR] {e}")
        return None

def cache_batch_get(poi_id, languages):
    """批量查询多语种缓存（1 次 Redis pipeline）"""
    try:
        r = get_redis_client()
        pipe = r.pipeline()
        for lang in languages:
            pipe.get(f"poi:trans:{poi_id}:{lang}")
        results = pipe.execute()
        return dict(zip(languages, results))
    except Exception as e:
        print(f"[REDIS BATCH ERROR] {e}")
        return {lang: None for lang in languages}

def cache_set(poi_id, lang, text, ttl=86400):
    try:
        r = get_redis_client()
        r.setex(f"poi:trans:{poi_id}:{lang}", ttl, text)
    except Exception as e:
        print(f"[REDIS SET ERROR] {e}")

# ===== 数据库操作 =====

def save_to_database(poi_id, name_zh, name_en, name_fr=None, name_es=None,
                     latitude=None, longitude=None, city=None, category_zh=None):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("""
            INSERT INTO poi_translations
            (gaode_poi_id, name_zh, name_en, name_fr, name_es,
             latitude, longitude, city, category_zh, source)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, 'deepseek')
            ON CONFLICT (gaode_poi_id) DO UPDATE SET
                name_en = EXCLUDED.name_en,
                name_fr = COALESCE(EXCLUDED.name_fr, poi_translations.name_fr),
                name_es = COALESCE(EXCLUDED.name_es, poi_translations.name_es),
                updated_at = NOW(),
                usage_count = poi_translations.usage_count + 1
        """, (poi_id, name_zh, name_en, name_fr, name_es,
              latitude, longitude, city, category_zh))
        conn.commit()
        print(f"[DB SAVED] POI {poi_id}")
    except Exception as e:
        conn.rollback()
        raise
    finally:
        cursor.close()

# ===== 主入口 =====

def main_handler(event, context):
    """云函数入口（符合 cloud_functions_order 统一规范）"""
    try:
        # 使用统一的请求体解析
        body = parse_body(event)

        action = body.get('action', 'save')
        poi_id = body.get('poi_id')

        if not poi_id:
            return json_response(400, {'error': 'Missing poi_id'})

        # ===== action: get（查询单语缓存）=====
        if action == 'get':
            lang = body.get('target_lang', 'en')
            cached = cache_get(poi_id, lang)
            return json_response(200, {
                'poi_id': poi_id,
                'target_lang': lang,
                'cached': cached is not None,
                'translated_text': cached
            })

        # ===== action: batch_get（批量查询多语缓存）=====
        if action == 'batch_get':
            languages = body.get('languages', ['en', 'fr', 'es'])
            results = cache_batch_get(poi_id, languages)
            all_cached = all(v is not None for v in results.values())
            return json_response(200, {
                'poi_id': poi_id,
                'all_cached': all_cached,
                'translations': results
            })

        # ===== action: save（保存翻译到 DB + Redis）=====
        name_zh = body.get('name_zh')
        name_en = body.get('name_en')
        name_fr = body.get('name_fr')
        name_es = body.get('name_es')

        if not all([name_zh, name_en]):
            return json_response(400, {'error': 'Missing name_zh or name_en'})

        save_to_database(
            poi_id=poi_id,
            name_zh=name_zh,
            name_en=name_en,
            name_fr=name_fr,
            name_es=name_es,
            latitude=body.get('latitude'),
            longitude=body.get('longitude'),
            city=body.get('city'),
            category_zh=body.get('category_zh')
        )

        # 写入缓存
        cache_set(poi_id, 'en', name_en)
        if name_fr: cache_set(poi_id, 'fr', name_fr)
        if name_es: cache_set(poi_id, 'es', name_es)

        return json_response(200, {
            'success': True,
            'poi_id': poi_id
        })

    except Exception as e:
        print(f"[ERROR] {str(e)}")
        import traceback
        traceback.print_exc()
        return json_response(500, {'error': str(e)})
