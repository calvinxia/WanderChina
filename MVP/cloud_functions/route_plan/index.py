# route_plan/index.py
# -*- coding: utf-8 -*-
"""
路线规划云函数（优化版 v2.1）
- 调用高德路线规划 API 获取路线
- 步行/驾车指令：纯本地模板翻译，零网络调用
- 公交站名：查库翻译（3s 超时），未命中返回中文原文（不 fallback DeepSeek）
- 线路名：规则化翻译（不需要 AI）
- 目标：总响应时间 < 10s
- v2.1: 修复高德返回 list 而非 dict 的类型防御
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


# ===== 类型安全辅助函数 =====

def _safe_dict(value, default=None):
    """确保返回 dict，防御高德返回 list 或其他类型"""
    if default is None:
        default = {}
    if isinstance(value, list):
        return value[0] if value else default
    if isinstance(value, dict):
        return value
    return default


# ===== 纯本地翻译函数（零网络调用）=====

def _translate_walk_instruction(instruction_zh, distance, road_zh=''):
    """步行指令本地翻译，不调任何网络"""
    m = re.search(r'到达(.+)', instruction_zh)
    if m:
        return f"Arrive at destination ({distance}m)"

    for zh, en in WALK_PATTERNS.items():
        if zh in instruction_zh:
            dist_match = re.search(r'(\d+)米', instruction_zh)
            dist_str = f" for {dist_match.group(1)}m" if dist_match else f" for {distance}m"
            road_str = f" on {road_zh}" if road_zh else ''
            return f"{en}{dist_str}{road_str}"

    for zh, en in DIRECTION_MAP.items():
        if f'向{zh}' in instruction_zh:
            return f"Head {en} for {distance}m"

    m = re.search(r'沿(.+?)步行', instruction_zh)
    if m:
        return f"Walk along {m.group(1)} for {distance}m"

    return f"Continue for {distance}m"


def _translate_drive_instruction(instruction_zh, distance, road_zh=''):
    """驾车指令本地翻译，不调任何网络"""
    if '到达目的地' in instruction_zh:
        return f"Arrive at destination"

    for zh, en in DRIVE_PATTERNS.items():
        if zh in instruction_zh:
            dist_str = f" for {distance}m" if distance > 0 else ''
            road_str = f" onto {road_zh}" if road_zh else ''
            return f"{en}{dist_str}{road_str}"

    m = re.search(r'进入(.+)', instruction_zh)
    if m:
        return f"Enter {m.group(1)} for {distance}m"

    m = re.search(r'沿(.+?)行驶', instruction_zh)
    if m:
        return f"Follow {m.group(1)} for {distance}m"

    m = re.search(r'从(.+?)出口', instruction_zh)
    if m:
        return f"Take exit {m.group(1)}"

    return f"Continue for {distance}m"


def translate_line_name(line_zh):
    """规则化翻译线路名（纯本地，不需要 AI）"""
    if not line_zh:
        return line_zh

    m = re.search(r'地铁(\d+)号线', line_zh)
    if m:
        return f"Metro Line {m.group(1)}"

    m = re.search(r'(\d+)号线', line_zh)
    if m:
        return f"Line {m.group(1)}"

    m = re.search(r'(\d+)路', line_zh)
    if m:
        return f"Bus {m.group(1)}"

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

    return line_zh


# ===== 站名翻译（唯一允许的网络调用，严格限时）=====

_station_cache = {}

def lookup_station_name(name_zh, lang):
    """查库翻译站名，3s 超时，未命中直接返回中文原文"""
    if not name_zh:
        return name_zh

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
            # 步行段（类型防御）
            walking = _safe_dict(segment.get('walking', {}))
            if walking and int(walking.get('distance', 0)) > 0:
                walk_steps = walking.get('steps', [])
                distance = int(walking.get('distance', 0))
                duration = int(walking.get('duration', 0))

                # 提取目的地
                destination_zh = ''
                if walk_steps:
                    last_step = _safe_dict(walk_steps[-1]) if walk_steps else {}
                    last_instruction = last_step.get('instruction', '')
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

            # 公交/地铁段（类型防御）
            bus_info = _safe_dict(segment.get('bus', {}))
            buslines = bus_info.get('buslines', [])
            if buslines:
                line = _safe_dict(buslines[0]) if buslines else {}
                line_name_zh = line.get('name', '')
                departure_stop = _safe_dict(line.get('departure_stop', {}))
                arrival_stop = _safe_dict(line.get('arrival_stop', {}))
                departure_zh = departure_stop.get('name', '')
                arrival_zh = arrival_stop.get('name', '')
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

        # 拼接 transit polyline（步行段 + 公交段，类型防御）
        all_polyline_parts = []
        for segment in segments:
            walking = _safe_dict(segment.get('walking', {}))
            for ws in walking.get('steps', []):
                ws = _safe_dict(ws)
                pl = ws.get('polyline', '')
                if pl:
                    all_polyline_parts.append(pl)
            bus_info = _safe_dict(segment.get('bus', {}))
            for bl in bus_info.get('buslines', []):
                bl = _safe_dict(bl)
                pl = bl.get('polyline', '')
                if pl:
                    all_polyline_parts.append(pl)
        all_polyline = ';'.join(all_polyline_parts)

        # 路线摘要
        route_entry = {
            'distance': int(transit.get('distance', 0)),
            'duration': int(transit.get('duration', 0)),
            'cost': float(transit.get('cost', 0) or 0),
            'walking_distance': int(transit.get('walking_distance', 0)),
            'steps': steps,
            'polyline': all_polyline,
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
            raw_step = _safe_dict(raw_step)
            instruction_zh = raw_step.get('instruction', '')
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
