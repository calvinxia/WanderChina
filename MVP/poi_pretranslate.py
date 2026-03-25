#!/usr/bin/env python3
"""
WanderChina POI 批量预翻译 Round 2（带关键词过滤）
"""
import requests
import time
import psycopg2

TRANSLATE_URL = 'https://1404346995-itkmhigrh9.ap-guangzhou.tencentscf.com'
DB_WRITE_URL = 'https://1404346995-b6c5j0yubd.ap-guangzhou.tencentscf.com'

DB_CONFIG = {
    'host': 'gz-postgres-eixcpo07.sql.tencentcdb.com',
    'port': 26300,
    'database': 'wanderchina',
    'user': 'wanderchina_pg_prod',
    'password': 'WCXs/932628',
}

# 每批定义：(标签, SQL 查询)
BATCHES = [
    ("科教文化-博物馆/纪念馆/剧院", """
    SELECT gaode_poi_id, name_zh, latitude, longitude, city
    FROM poi_translations
    WHERE name_en IS NULL
    AND category_zh = '科教文化服务'
    AND (name_zh LIKE '%博物馆%' OR name_zh LIKE '%美术馆%' OR name_zh LIKE '%展览馆%'
         OR name_zh LIKE '%纪念馆%' OR name_zh LIKE '%科技馆%' OR name_zh LIKE '%天文馆%'
         OR name_zh LIKE '%图书馆%' OR name_zh LIKE '%文化中心%' OR name_zh LIKE '%文化馆%'
         OR name_zh LIKE '%遗址%' OR name_zh LIKE '%故居%'
         OR name_zh LIKE '%音乐厅%' OR name_zh LIKE '%剧院%' OR name_zh LIKE '%剧场%')
    ORDER BY priority_score DESC
    LIMIT 100
"""),

    ("交通设施", """
        SELECT gaode_poi_id, name_zh, latitude, longitude, city
        FROM poi_translations
        WHERE name_en IS NULL
        AND category_zh = '交通设施服务'
        AND priority_score >= 50
        ORDER BY priority_score DESC
        LIMIT 500
    """),

    ("风景名胜", """
        SELECT gaode_poi_id, name_zh, latitude, longitude, city
        FROM poi_translations
        WHERE name_en IS NULL
        AND category_zh = '风景名胜'
        AND priority_score >= 50
        ORDER BY priority_score DESC
        LIMIT 300
    """),

    ("餐饮-过滤连锁快餐", """
        SELECT gaode_poi_id, name_zh, latitude, longitude, city
        FROM poi_translations
        WHERE name_en IS NULL
        AND category_zh = '餐饮服务'
        AND priority_score >= 50
        AND name_zh NOT LIKE '%沙县%' AND name_zh NOT LIKE '%兰州拉面%'
        AND name_zh NOT LIKE '%黄焖鸡%'
        ORDER BY priority_score DESC
        LIMIT 100
    """),

    ("住宿服务", """
        SELECT gaode_poi_id, name_zh, latitude, longitude, city
        FROM poi_translations
        WHERE name_en IS NULL
        AND category_zh = '住宿服务'
        AND priority_score >= 50
        ORDER BY priority_score DESC
        LIMIT 50
    """),

    ("体育休闲", """
        SELECT gaode_poi_id, name_zh, latitude, longitude, city
        FROM poi_translations
        WHERE name_en IS NULL
        AND category_zh = '体育休闲服务'
        AND priority_score >= 50
        ORDER BY priority_score DESC
        LIMIT 24
    """),
]

def pretranslate():
    for label, sql in BATCHES:
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
        cursor.execute(sql)
        rows = cursor.fetchall()
        cursor.close()
        conn.close()

        print(f"\n[{label}] 待翻译: {len(rows)} 条")

        for poi_id, name_zh, lat, lng, city in rows:
            try:
                resp = requests.post(TRANSLATE_URL, json={
                    'text': name_zh,
                    'target_lang': 'en'
                }, timeout=15)
                name_en = resp.json().get('translated_text', '')

                if name_en:
                    requests.post(DB_WRITE_URL, json={
                        'poi_id': poi_id,
                        'name_zh': name_zh,
                        'name_en': name_en,
                        'latitude': float(lat) if lat else None,
                        'longitude': float(lng) if lng else None,
                        'city': city,
                        'action': 'save'
                    }, timeout=10)
                    print(f"  ✓ {name_zh} → {name_en}")

                time.sleep(0.3)

            except Exception as e:
                print(f"  ✗ {name_zh}: {e}")

    print("\n✅ 全部完成")

if __name__ == '__main__':
    pretranslate()