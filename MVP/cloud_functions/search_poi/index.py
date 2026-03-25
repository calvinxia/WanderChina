# search_poi/index.py
# -*- coding: utf-8 -*-
"""
POI 搜索云函数
- action: search — 英文模糊搜索（pg_trgm），供 Flutter 用户搜索
- action: lookup_zh — 中文名精确查找翻译，供 route_plan 查站名
- Redis 缓存: search 1小时，lookup_zh 24小时
"""
import os
import sys
import json

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from shared.db_helper import get_db_connection, get_redis_client, json_response, parse_body


def main_handler(event, context):
    try:
        body = parse_body(event)
        action = body.get('action', 'search')
        lang = body.get('lang', 'en')
        name_col = {'en': 'name_en', 'fr': 'name_fr', 'es': 'name_es'}.get(lang, 'name_en')

        # =============================================================
        # action: lookup_zh（中文名精确查找翻译，供 route_plan 调用）
        # =============================================================
        if action == 'lookup_zh':
            name_zh = body.get('name_zh', '').strip()
            if not name_zh:
                return json_response(400, {'error': 'Missing name_zh'})

            cache_key = f"lookup:{name_zh}:{lang}"

            # 查 Redis 缓存
            try:
                r = get_redis_client()
                cached = r.get(cache_key)
                if cached:
                    cached_data = json.loads(cached)
                    if cached_data.get('found'):  # 只信任 found=true 的缓存
                        return json_response(200, cached_data)
                    else:
                        r.delete(cache_key)  # 清掉 found=false 的旧缓存
            except Exception:
                pass

            # 查数据库
            conn = get_db_connection()
            cursor = conn.cursor()
            cursor.execute(f"""
                SELECT {name_col} FROM poi_translations
                WHERE name_zh = %s AND {name_col} IS NOT NULL
                LIMIT 1
            """, (name_zh,))
            row = cursor.fetchone()
            cursor.close()

            result = {
                'name_zh': name_zh,
                'name_translated': row[0] if row else None,
                'found': row is not None
            }

             # 只缓存命中结果，未命中不缓存（避免改了匹配逻辑后还返回旧的 false）
            if result['found']:
                try:
                    r = get_redis_client()
                    r.setex(cache_key, 86400, json.dumps(result, ensure_ascii=False))
                except Exception:
                    pass

            return json_response(200, result)

        # =============================================================
        # action: search（英文模糊搜索，供 Flutter 用户搜索）
        # =============================================================
        keyword = body.get('keyword', '').strip()
        city = body.get('city')
        limit = min(body.get('limit', 10), 30)

        if not keyword or len(keyword) < 2:
            return json_response(400, {'error': 'Keyword must be at least 2 characters'})

        cache_key = f"search:{city or 'all'}:{keyword.lower()}:{lang}"

        # 查 Redis 缓存
        try:
            r = get_redis_client()
            cached = r.get(cache_key)
            if cached:
                return json_response(200, json.loads(cached))
        except Exception:
            pass

        conn = get_db_connection()
        cursor = conn.cursor()

        sql = f"""
            SELECT
                gaode_poi_id,
                name_zh,
                {name_col} AS name_translated,
                category_en,
                latitude,
                longitude,
                city,
                priority_score,
                similarity({name_col}, %s) AS sim_score
            FROM poi_translations
            WHERE {name_col} IS NOT NULL
              AND (
                {name_col} ILIKE %s
                OR similarity({name_col}, %s) > 0.2
                OR name_zh ILIKE %s
              )
        """
        params = [keyword, f'{keyword}%', keyword, f'%{keyword}%']

        if city:
            sql += " AND city = %s"
            params.append(city)

        sql += f"""
            ORDER BY
                CASE WHEN {name_col} ILIKE %s THEN 0 ELSE 1 END,
                sim_score DESC,
                priority_score DESC
            LIMIT %s
        """
        params.extend([f'{keyword}%', limit])

        cursor.execute(sql, params)
        rows = cursor.fetchall()
        cursor.close()

        results = []
        for row in rows:
            results.append({
                'poi_id': row[0],
                'name_zh': row[1],
                'name_translated': row[2],
                'category_en': row[3],
                'lat': float(row[4]),
                'lng': float(row[5]),
                'city': row[6],
                'priority': row[7],
            })

        response = {'results': results, 'count': len(results)}

        # 缓存 1 小时
        try:
            r = get_redis_client()
            r.setex(cache_key, 3600, json.dumps(response, ensure_ascii=False))
        except Exception:
            pass

        return json_response(200, response)

    except Exception as e:
        print(f"[SEARCH ERROR] {str(e)}")
        import traceback
        traceback.print_exc()
        return json_response(500, {'error': str(e)})
