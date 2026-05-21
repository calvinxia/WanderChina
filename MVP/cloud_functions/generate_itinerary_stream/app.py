# generate_itinerary_stream/app.py
# -*- coding: utf-8 -*-
"""
流式行程生成 Web 函数（Flask + SSE）
- 关闭 thinking mode（优先响应速度）
- 开启 stream
- 括号深度计数法增量解析
- 不写 DB，不连 VPC
"""
import os
import json
import time
from flask import Flask, request, Response

app = Flask(__name__)

DEEPSEEK_API_KEY = os.environ.get('DEEPSEEK_API_KEY', '')


def _build_prompt(cities, days, interests, budget_level='medium', language='english'):
    city_str = ', '.join(cities) if cities else 'Beijing'
    interest_str = ', '.join(interests) if interests else 'Culture, Food'

    return f"""Create a {days}-day travel itinerary for {city_str}, China.
Traveler interests: {interest_str}.
Budget level: {budget_level}.

Return ONLY valid JSON, no markdown or explanation:
{{
  "days": [
    {{
      "day_number": 1,
      "title": "Day theme",
      "city": "{cities[0] if cities else 'Beijing'}",
      "summary": "One sentence summary",
      "estimated_cost": 200,
      "activities": [
        {{
          "time": "09:00",
          "name": "Place Name",
          "name_zh": "中文名",
          "duration": "2 hrs",
          "cost": "¥60",
          "category": "sightseeing",
          "imageKeyword": "descriptive photo search term",
          "description": "Brief description"
        }}
      ]
    }}
  ]
}}

Rules:
- Use real, specific venue names (e.g. "Dim sum at Dian Du De 点都德" not "Lunch at a local dim sum restaurant"). Every activity must reference an actual named place that exists in the city.
- Exactly {days} days, 4-5 activities per day
- Realistic times and costs in CNY
- Each activity must have a category (sightseeing, food, shopping, transport, entertainment) and an imageKeyword for photo search (e.g. "Cantonese dim sum" for a dim sum restaurant, "ancient city wall" for Xi'an Wall)
- Allow at least 30 minutes gap between activities at different locations for transit
- If two activities are in different districts of the city, allow 45-60 minutes for travel
- Bilingual place names (English + Chinese)
- Descriptions in {language}"""


def _stream_deepseek(prompt):
    """调用 DeepSeek streaming API，yield 原始 chunk"""
    import requests

    for attempt in range(3):
        try:
            t_start = time.time()
            resp = requests.post(
                'https://api.deepseek.com/v1/chat/completions',
                headers={
                    'Authorization': f'Bearer {DEEPSEEK_API_KEY}',
                    'Content-Type': 'application/json',
                },
                json={
                    'model': 'deepseek-v4-flash',
                    'messages': [{'role': 'user', 'content': prompt}],
                    'temperature': 0.3,
                    'max_tokens': 16384,
                    'thinking': {'type': 'disabled'},
                    'stream': True,
                },
                stream=True,
                timeout=60,
            )
            resp.raise_for_status()
            print(f"[TIMING][stream] API connected: {(time.time()-t_start)*1000:.0f}ms")

            for line in resp.iter_lines(decode_unicode=True):
                if not line or not line.startswith('data: '):
                    continue
                payload = line[6:]  # strip "data: "
                if payload.strip() == '[DONE]':
                    break
                try:
                    chunk = json.loads(payload)
                    delta = chunk.get('choices', [{}])[0].get('delta', {})
                    content = delta.get('content', '')
                    if content:
                        yield content
                except json.JSONDecodeError:
                    continue
            return  # 成功，不重试

        except Exception as e:
            print(f"[STREAM] Retry {attempt+1}/3: {e}")
            if attempt < 2:
                time.sleep(2)
            else:
                raise


def _try_parse_partial(buffer):
    """
    括号深度计数法：尝试从不完整的 JSON buffer 中提取已完成的 day 对象。
    不用 rfind('},{') — description 字段可能含 } 字面量。
    """
    depth = 0
    in_string = False
    escape_next = False
    days = []
    day_start = None

    # 找到 "days": [ 的起始位置
    days_idx = buffer.find('"days"')
    if days_idx == -1:
        return None
    bracket_idx = buffer.find('[', days_idx)
    if bracket_idx == -1:
        return None

    i = bracket_idx + 1
    while i < len(buffer):
        c = buffer[i]

        if escape_next:
            escape_next = False
            i += 1
            continue

        if c == '\\' and in_string:
            escape_next = True
            i += 1
            continue

        if c == '"' and not escape_next:
            in_string = not in_string
            i += 1
            continue

        if in_string:
            i += 1
            continue

        # 不在字符串内
        if c == '{':
            if depth == 0:
                day_start = i
            depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0 and day_start is not None:
                day_str = buffer[day_start:i+1]
                try:
                    day_obj = json.loads(day_str)
                    days.append(day_obj)
                except json.JSONDecodeError:
                    pass
                day_start = None

        i += 1

    if not days:
        return None

    return {'days': days}


@app.route('/', methods=['POST', 'GET'])
def generate_stream():
    """SSE 流式端点"""
    if request.method == 'GET':
        return Response('generate_itinerary_stream is running', status=200)

    t_total = time.time()

    try:
        body = request.get_json(force=True) or {}
        cities = body.get('cities', [])
        days = body.get('days', 1)
        interests = body.get('interests', [])
        budget_level = body.get('budget_level', 'medium')
        language = body.get('language', 'english')

        if not cities:
            return Response(
                json.dumps({'error': 'Missing cities'}),
                status=400,
                content_type='application/json',
            )

        prompt = _build_prompt(cities, days, interests, budget_level, language)
        print(f"[TIMING][stream] cities={cities}, days={days}, interests={interests}")

        def event_stream():
            buffer = ''
            last_day_count = 0
            partial_count = 0

            try:
                for chunk in _stream_deepseek(prompt):
                    buffer += chunk

                    # 尝试增量解析
                    partial = _try_parse_partial(buffer)
                    if partial and len(partial['days']) > last_day_count:
                        last_day_count = len(partial['days'])
                        partial_count += 1
                        yield f"data: {json.dumps({'event': 'partial', 'data': partial}, ensure_ascii=False)}\n\n"

                # 流结束，解析完整 JSON
                # 清理 markdown 包裹
                clean = buffer.strip()
                if '```json' in clean:
                    clean = clean.split('```json')[1].split('```')[0]
                elif '```' in clean:
                    clean = clean.split('```')[1].split('```')[0]

                final_obj = json.loads(clean.strip())

                if 'days' not in final_obj or not isinstance(final_obj['days'], list):
                    raise ValueError('Response missing days array')

                t_end = time.time()
                print(f"[TIMING][stream] total={int((t_end-t_total)*1000)}ms, "
                      f"partial_events={partial_count}, days={len(final_obj['days'])}")

                # 构建 title
                city_str = ', '.join(cities)
                interest_str = interests[0] if interests else 'Culture'
                title = f"{city_str} · {days} Days · {interest_str}"

                yield f"data: {json.dumps({'event': 'complete', 'data': {'title': title, 'itinerary': final_obj}}, ensure_ascii=False)}\n\n"

            except Exception as e:
                print(f"[STREAM ERROR] {e}")
                import traceback
                traceback.print_exc()
                yield f"data: {json.dumps({'event': 'error', 'message': str(e)})}\n\n"

        return Response(
            event_stream(),
            mimetype='text/event-stream',
            headers={
                'Cache-Control': 'no-cache',
                'Connection': 'keep-alive',
                'X-Accel-Buffering': 'no',
                'Access-Control-Allow-Origin': '*',
            },
        )

    except Exception as e:
        print(f"[STREAM ERROR] {e}")
        return Response(
            json.dumps({'error': str(e)}),
            status=500,
            content_type='application/json',
        )


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=9000)
