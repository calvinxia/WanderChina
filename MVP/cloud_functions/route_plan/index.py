# route_plan/index.py
# -*- coding: utf-8 -*-
"""
路线规划云函数（优化版 v2）
- 调用高德路线规划 API 获取路线
- 步行/驾车指令：纯本地模板翻译，零网络调用
- 公交站名：查库翻译（3s 超时），未命中返回中文原文（不 fallback DeepSeek）
- 线路名：规则化翻译（不需要 AI）
- 目标：总响应时间 < 10s
"""
import os
import sys
import re
import json

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from shared.db_helper import json_response, parse_body

AMAP_BASE = 'https://restapi.amap.com'

MODE_ENDPOINTS = {
    'transit': '/v3/direction/transit/integrated',
    'walking': '/v3/direction/walking',
    'driving': '/v3/direction/driving',
}

# ===== 本地翻译字典（零网络调用）=====

WALK_PATTERNS = {
    '左转': 'Turn left',
    '右转': 'Turn right',
    '向左转': 'Turn left',
    '向右转': 'Turn right',
    '左前方转弯': 'Turn slight left',
    '右前方转弯': 'Turn slight right',
    '向左前方行走': 'Bear left',
    '向右前方行走': 'Bear right',
    '向左后方行走': 'Bear left',
    '向右后方行走': 'Bear right',
    '直行': 'Go straight',
    '继续前进': 'Continue straight',
    '掉头': 'Make a U-turn',
    '到达目的地': 'Arrive at destination',
}

DIRECTION_MAP = {
    '东南': 'southeast', '东北': 'northeast',
    '西南': 'southwest', '西北': 'northwest',
    '东': 'east', '西': 'west', '南': 'south', '北': 'north',
}

DRIVE_PATTERNS = {
    '左转': 'Turn left',
    '右转': 'Turn right',
    '向左转': 'Turn left',
    '向右转': 'Turn right',
    '左前方转弯': 'Turn slight left',
    '右前方转弯': 'Turn slight right',
    '直行': 'Go straight',
    '靠左': 'Keep left',
    '靠右': 'Keep right',
    '掉头': 'Make a U-turn',
    '进入环岛': 'Enter roundabout',
    '离开环岛': 'Exit roundabout',
    '到达目的地': 'Arrive at destination',
    '减速行驶': 'Slow down',
}


# ===== 纯本地翻译函数（零网络调用）=====

def _translate_walk_instruction(instruction_zh, distance, road_zh=''):
    """步行指令本地翻译，不调任何网络"""
    # 匹配"到达XXX"
    m = re.search(r'到达(.+)', instruction_zh)
    if m:
        return f"Arrive at destination ({distance}m)"

    # 匹配方向动作
    for zh, en in WALK_PATTERNS.items():
        if zh in instruction_zh:
            dist_match = re.search(r'(\d+)米', instruction_zh)
            dist_str = f" for {dist_match.group(1)}m" if dist_match else f" for {distance}m"
            road_str = f" on {road_zh}" if road_zh else ''
            return f"{en}{dist_str}{road_str}"

    # 匹配"向X步行Y米"
    for zh, en in DIRECTION_MAP.items():
        if f'向{zh}' in instruction_zh:
            return f"Head {en} for {distance}m"

    # 匹配"沿XXX步行Y米"
    m = re.search(r'沿(.+?)步行', instruction_zh)
    if m:
        return f"Walk along {m.group(1)} for {distance}m"

    # 兜底
    return f"Continue for {distance}m"


def _translate_drive_instruction(instruction_zh, distance, road_zh=''):
    """驾车指令本地翻译，不调任何网络"""
    # 匹配"到达目的地"
    if '到达目的地' in instruction_zh:
        return f"Arrive at destination"

    # 匹配方向动作
    for zh, en in DRIVE_PATTERNS.items():
        if zh in instruction_zh:
            dist_str = f" for {distance}m" if distance > 0 else ''
            road_str = f" onto {road_zh}" if road_zh else ''
            return f"{en}{dist_str}{road_str}"

    # 匹配"进入XXX"
    m = re.search(r'进入(.+)', instruction_zh)
    if m:
        return f"Enter {m.group(1)} for {distance}m"

    # 匹配"沿XXX行驶Y米"
    m = re.search(r'沿(.+?)行驶', instruction_zh)
    if m:
        return f"Follow {m.group(1)} for {distance}m"

    # 匹配"从XXX出口离开"
    m = re.search(r'从(.+?)出口', instruction_zh)
    if m:
        return f"Take exit {m.group(1)}"

    # 兜底
    return f"Continue for {distance}m"


def translate_line_name(line_zh):
    """规则化翻译线路名（纯本地，不需要 AI）"""
    if not line_zh:
        return line_zh

    # 地铁X号线 → Metro Line X
    m = re.search(r'地铁(\d+)号线', line_zh)
    if m:
        return f"Metro Line {m.group(1)}"

    # X号线 → Line X
    m = re.search(r'(\d+)号线', line_zh)
    if m:
        return f"Line {m.group(1)}"

    # 公交X路 → Bus X
    m = re.search(r'(\d+)路', line_zh)
    if m:
        return f"Bus {m.group(1)}"

    # 特殊线路
    if '机场' in line_zh and ('快线' in line_zh or '线' in line_zh):
        return "Airport Express"
    if '磁悬浮' in line_zh:
        return "Maglev Train"
    if '有轨电车' in line_zh:
        return "Tram"
    if 'APM' in line_zh:
        return "APM Line"
    if '快速公交' in line_zh or 'BRT' in line_zh:
        return "BRT"

    # 其他：保留原文（外国游客给司机看）
    return line_zh


# ===== 站名翻译（唯一允许的网络调用，严格限时）=====

# 内存缓存：同一次请求内避免重复查库
_station_cache = {}

def lookup_station_name(name_zh, lang):
    """查库翻译站名，3s 超时，未命中直接返回中文原文"""
    if not name_zh:
        return name_zh

    # 检查内存缓存
    cache_key = f"{name_zh}_{lang}"
    if cache_key in _station_cache:
        return _station_cache[cache_key]

    search_url = os.environ.get('SEARCH_URL')
    if not search_url:
        return name_zh

    try:
        import requests
        resp = requests.post(search_url, json={
            'action': 'lookup_zh',
            'name_zh': name_zh,
            'lang': lang
        }, timeout=3)
        result = resp.json()
        if result.get('found') and result.get('name_translated'):
            translated = result['name_translated']
            _station_cache[cache_key] = translated
            return translated
    except Exception:
        pass

    # DB 未命中 → DeepSeek fallback（仅限站名，3s 超时）
    translate_url = os.environ.get('TRANSLATE_URL')
    if translate_url:
        try:
            import requests
            resp = requests.post(translate_url, json={
                'text': name_zh,
                'target_lang': lang
            }, timeout=3)
            translated = resp.json().get('translated_text', name_zh)
            _station_cache[cache_key] = translated
            return translated
        except Exception:
            pass
            
    _station_cache[cache_key] = name_zh
    return name_zh


# ===== 公交路线解析 =====

def parse_transit_route(route_data, lang):
    routes = []
    transits = route_data.get('route', {}).get('transits', [])

    for transit in transits[:3]:
        steps = []
        segments = transit.get('segments', [])

        for segment in segments:
            # 步行段
            walking = segment.get('walking', {})
            if walking and int(walking.get('distance', 0)) > 0:
                walk_steps = walking.get('steps', [])
                distance = int(walking.get('distance', 0))
                duration = int(walking.get('duration', 0))

                # 提取目的地
                destination_zh = ''
                if walk_steps:
                    last_instruction = walk_steps[-1].get('instruction', '')
                    m = re.search(r'到达(.+)', last_instruction)
                    if m:
                        destination_zh = m.group(1)

                instruction_zh = f"步行{distance}米" + (f"至{destination_zh}" if destination_zh else '')

                step = {
                    'type': 'walking',
                    'instruction_zh': instruction_zh,
                    'distance': distance,
                    'duration': duration,
                    'destination_zh': destination_zh,
                }

                if lang != 'zh':
                    if destination_zh:
                        dest_en = lookup_station_name(destination_zh, lang)
                        step['instruction_en'] = f"Walk {distance}m to {dest_en}"
                        step['destination_en'] = dest_en
                    else:
                        step['instruction_en'] = f"Walk {distance}m"

                steps.append(step)

            # 公交/地铁段
            bus_info = segment.get('bus', {})
            buslines = bus_info.get('buslines', [])
            if buslines:
                line = buslines[0]
                line_name_zh = line.get('name', '')
                departure_zh = line.get('departure_stop', {}).get('name', '')
                arrival_zh = line.get('arrival_stop', {}).get('name', '')
                via_num = int(line.get('via_num', 0))
                distance = int(line.get('distance', 0))
                duration = int(line.get('duration', 0))

                instruction_zh = f"乘坐{line_name_zh}, {departure_zh}上车, {arrival_zh}下车"
                if via_num > 0:
                    instruction_zh += f"（经过{via_num}站）"

                step = {
                    'type': 'transit',
                    'instruction_zh': instruction_zh,
                    'line_zh': line_name_zh,
                    'distance': distance,
                    'duration': duration,
                }

                if lang != 'zh':
                    line_en = translate_line_name(line_name_zh)
                    departure_en = lookup_station_name(departure_zh, lang)
                    arrival_en = lookup_station_name(arrival_zh, lang)

                    step['instruction_en'] = f"Take {line_en}"
                    step['line_en'] = line_en
                    step['sub_steps'] = [
                        {
                            'action': 'board',
                            'text_zh': f"{departure_zh}上车",
                            'text_en': f"Board at {departure_en}",
                            'station_zh': departure_zh,
                            'station_en': departure_en,
                        },
                        {
                            'action': 'alight',
                            'text_zh': f"{arrival_zh}下车" + (f"（经过{via_num}站）" if via_num else ''),
                            'text_en': f"Alight at {arrival_en}" + (f" ({via_num} stops)" if via_num else ''),
                            'station_zh': arrival_zh,
                            'station_en': arrival_en,
                            'via_stops': via_num,
                        }
                    ]

                steps.append(step)

        # 路线摘要
        route_entry = {
            'distance': int(transit.get('distance', 0)),
            'duration': int(transit.get('duration', 0)),
            'cost': float(transit.get('cost', 0) or 0),
            'walking_distance': int(transit.get('walking_distance', 0)),
            'steps': steps,
        }

        if lang != 'zh':
            parts = []
            for s in steps:
                if s['type'] == 'walking':
                    parts.append('Walk')
                elif s['type'] == 'transit':
                    line_en = s.get('line_en', s.get('line_zh', ''))
                    via = s.get('sub_steps', [{}])[-1].get('via_stops', 0) if s.get('sub_steps') else 0
                    parts.append(f"{line_en} ({via} stops)" if via else line_en)

            total_min = route_entry['duration'] // 60
            cost = route_entry['cost']
            route_entry['summary_en'] = f"{' → '.join(parts)} | {total_min} min" + (f" | ¥{cost:.0f}" if cost else '')

        routes.append(route_entry)

    return routes


# ===== 步行/驾车路线解析（零网络调用）=====

def parse_walking_driving_route(route_data, mode, lang):
    routes = []
    paths = route_data.get('route', {}).get('paths', [])

    for path in paths[:2]:
        steps = []
        for raw_step in path.get('steps', []):
            instruction_zh = raw_step.get('instruction', '')
            # road 字段可能是字符串或空数组
            road_raw = raw_step.get('road', '')
            road_zh = road_raw if isinstance(road_raw, str) else ''
            distance = int(raw_step.get('distance', 0))
            duration = int(raw_step.get('duration', 0))

            step = {
                'type': mode,
                'instruction_zh': instruction_zh,
                'road_zh': road_zh,
                'distance': distance,
                'duration': duration,
                'polyline': raw_step.get('polyline', ''),
            }

            if lang != 'zh':
                if mode == 'walking':
                    step['instruction_en'] = _translate_walk_instruction(instruction_zh, distance, road_zh)
                else:
                    step['instruction_en'] = _translate_drive_instruction(instruction_zh, distance, road_zh)
                # 路名保留中文（打车给司机看）
                if road_zh:
                    step['road_en'] = road_zh

            steps.append(step)

        all_polyline = ';'.join(s.get('polyline', '') for s in steps if s.get('polyline'))

        routes.append({
            'distance': int(path.get('distance', 0)),
            'duration': int(path.get('duration', 0)),
            'steps': steps,
            'polyline': all_polyline,
        })

    return routes


# ===== 主入口 =====

def main_handler(event, context):
    # 每次请求重置站名缓存
    global _station_cache
    _station_cache = {}

    try:
        body = parse_body(event)

        origin = body.get('origin')
        destination = body.get('destination')
        mode = body.get('mode', 'transit')
        city = body.get('city', '北京')
        lang = body.get('lang', 'en')

        if not origin or not destination:
            return json_response(400, {'error': 'Missing origin or destination'})

        if mode not in MODE_ENDPOINTS:
            return json_response(400, {
                'error': f'Unsupported mode. Supported: {list(MODE_ENDPOINTS.keys())}'
            })

        amap_key = os.environ.get('AMAP_WEB_KEY')
        if not amap_key:
            return json_response(500, {'error': 'Missing AMAP_WEB_KEY'})

        # 调用高德路线规划 API
        import requests
        params = {
            'key': amap_key,
            'origin': origin,
            'destination': destination,
        }
        if mode == 'transit':
            params['city'] = city
            params['strategy'] = 0

        url = AMAP_BASE + MODE_ENDPOINTS[mode]
        resp = requests.get(url, params=params, timeout=10)
        data = resp.json()

        if data.get('status') != '1':
            return json_response(502, {
                'error': f"Gaode API error: {data.get('info', 'Unknown')}"
            })

        # 解析路线
        if mode == 'transit':
            routes = parse_transit_route(data, lang)
        else:
            routes = parse_walking_driving_route(data, mode, lang)

        return json_response(200, {
            'routes': routes,
            'count': len(routes),
            'origin': origin,
            'destination': destination,
            'mode': mode,
        })

    except Exception as e:
        print(f"[ROUTE ERROR] {str(e)}")
        import traceback
        traceback.print_exc()
        return json_response(500, {'error': str(e)})
