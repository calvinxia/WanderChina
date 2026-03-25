#!/usr/bin/env python3
"""
WanderChina POI 初始导入脚本
数据来源: 高德开放平台 POI 搜索 API
目标: 6 城市 × 200 核心 POI = ~1200 条
"""
import requests
import json
import time
import psycopg2

AMAP_KEY = '830c1b8b21b36c32c292afd170c04463'

# 6 个 MVP 城市
CITIES = {
    '北京': '110000',
    '上海': '310000',
    '广州': '440100',
    '深圳': '440300',
    '成都': '510100',
    '西安': '610100',
}

# 核心 POI 类型（高德分类编码）
POI_TYPES_ROUND2 = [
    '110101',  # 世界遗产
    '110102',  # 国家级景点
    '110200',  # 公园广场
    '110300',  # 主题公园
    '141201',  # 博物馆
    '141300',  # 美术馆
    '141400',  # 展览馆
    '141500',  # 科技馆
    '150500',  # 地铁站
    '150100',  # 火车站
    '150200',  # 长途汽车站
    '150400',  # 机场
    '050100',  # 中餐厅
    '050500',  # 小吃快餐
    '080300',  # 星级酒店
    '080600',  # 青年旅舍
]

DB_CONFIG = {
    'host': 'gz-postgres-eixcpo07.sql.tencentcdb.com',
    'port': 26300,
    'database': 'wanderchina',
    'user': 'wanderchina_pg_prod',
    'password': 'WCXs/932628',
}

def fetch_pois(city_code, poi_type, page=1, page_size=25):
    """调用高德 POI 搜索"""
    url = 'https://restapi.amap.com/v3/place/text'
    params = {
        'key': AMAP_KEY,
        'types': poi_type,
        'city': city_code,
        'citylimit': 'true',
        'offset': page_size,
        'page': page,
        'extensions': 'all',
    }
    resp = requests.get(url, params=params, timeout=10)
    data = resp.json()
    if data['status'] == '1':
        return data.get('pois', [])
    return []

def import_city(conn, city_name, city_code):
    """导入单个城市的 POI"""
    cursor = conn.cursor()
    count = 0

    for poi_type in POI_TYPES_ROUND2:
        for page in range(1, 5):  # 每种类型最多 4 页
            pois = fetch_pois(city_code, poi_type, page)
            if not pois:
                break

            for poi in pois:
                try:
                    location = poi.get('location', '').split(',')
                    if len(location) != 2:
                        continue

                    lng, lat = float(location[0]), float(location[1])
                    gaode_id = poi.get('id', '')
                    name = poi.get('name', '')
                    category = poi.get('type', '').split(';')[0] if poi.get('type') else ''
                    address = poi.get('address', '')
                    district = poi.get('adname', '')

                    # 根据评分/热度设置优先级
                    biz = poi.get('biz_ext', {})
                    rating = float(biz.get('rating', 0) or 0)
                    priority = int(rating * 20) if rating > 0 else 50

                    cursor.execute("""
                        INSERT INTO poi_translations
                        (gaode_poi_id, name_zh, category_zh, address_zh,
                         city, district, latitude, longitude, priority_score, source)
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, 'amap')
                        ON CONFLICT (gaode_poi_id) DO UPDATE SET
                            category_zh = EXCLUDED.category_zh,
                            address_zh = EXCLUDED.address_zh,
                            priority_score = GREATEST(poi_translations.priority_score, EXCLUDED.priority_score),
                            updated_at = NOW()
                    """, (gaode_id, name, category, address,
                          city_name, district, lat, lng, priority))
                    count += 1

                except Exception as e:
                    conn.rollback()
                    print(f"  跳过 POI [{name}]: {e}")
                    continue

            time.sleep(0.2)  # 高德限流

    conn.commit()
    cursor.close()
    print(f"  {city_name}: 导入 {count} 条 POI")
    return count

def main():
    conn = psycopg2.connect(**DB_CONFIG)
    total = 0

    for city_name, city_code in CITIES.items():
        print(f"正在导入: {city_name} ({city_code})")
        total += import_city(conn, city_name, city_code)

    conn.close()
    print(f"\n完成！共导入 {total} 条 POI")

if __name__ == '__main__':
    main()
