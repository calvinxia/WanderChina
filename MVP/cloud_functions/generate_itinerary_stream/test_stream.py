#!/usr/bin/env python3
"""
流式行程生成边界测试（10 个 case）
用法: STREAM_URL=https://xxx python3 test_stream.py
"""
import os
import sys
import json
import time
import requests

STREAM_URL = os.environ.get('STREAM_URL', '')

if not STREAM_URL:
    print("Usage: STREAM_URL=https://xxx python3 test_stream.py")
    sys.exit(1)

TEST_CASES = [
    {'cities': ['Beijing'], 'days': 1, 'interests': ['Culture']},
    {'cities': ['Shanghai'], 'days': 3, 'interests': ['Food', 'Shopping']},
    {'cities': ['Chengdu'], 'days': 5, 'interests': ['Food', 'Nature']},
    {"cities": ["Xi'an"], 'days': 2, 'interests': ['History']},  # 城市名含引号
    {'cities': ['Hangzhou'], 'days': 7, 'interests': ['Nature', 'Culture', 'Food']},
    {'cities': ['Guangzhou'], 'days': 1, 'interests': ['Food']},
    {'cities': ['Shenzhen'], 'days': 3, 'interests': ['Technology', 'Shopping']},
    {'cities': ['Beijing'], 'days': 5, 'interests': ['History', 'Art']},
    {'cities': ['Chengdu'], 'days': 1, 'interests': ['Food']},  # 最小 case
    {'cities': ['Shanghai'], 'days': 7, 'interests': ['Culture', 'Food', 'Shopping', 'Nature']},  # 最大 case
]

results = []

for i, case in enumerate(TEST_CASES):
    print(f"\n{'='*60}")
    print(f"Test {i+1}/10: {case['cities'][0]} · {case['days']}d · {case['interests']}")
    print(f"{'='*60}")

    t_start = time.time()
    partial_count = 0
    final_days = 0
    success = False
    error_msg = None

    try:
        resp = requests.post(
            STREAM_URL,
            json={**case, 'language': 'english'},
            stream=True,
            timeout=90,
        )

        for line in resp.iter_lines(decode_unicode=True):
            if not line or not line.startswith('data: '):
                continue
            payload = line[6:]
            try:
                event = json.loads(payload)
                evt_type = event.get('event')

                if evt_type == 'partial':
                    partial_count += 1
                    days_so_far = len(event.get('data', {}).get('days', []))
                    print(f"  partial #{partial_count}: {days_so_far} days")

                elif evt_type == 'complete':
                    itinerary = event['data']['itinerary']
                    final_days = len(itinerary.get('days', []))
                    title = event['data'].get('title', '?')
                    print(f"  complete: {title} ({final_days} days)")
                    success = True

                elif evt_type == 'error':
                    error_msg = event.get('message', 'unknown')
                    print(f"  ERROR: {error_msg}")

            except json.JSONDecodeError as e:
                print(f"  JSON parse error: {e}")

    except Exception as e:
        error_msg = str(e)
        print(f"  EXCEPTION: {e}")

    duration = time.time() - t_start

    result = {
        'case': f"{case['cities'][0]}_{case['days']}d",
        'success': success,
        'duration_s': round(duration, 1),
        'partial_events': partial_count,
        'final_days': final_days,
        'expected_days': case['days'],
        'days_match': final_days == case['days'],
        'error': error_msg,
    }
    results.append(result)
    print(f"  Duration: {duration:.1f}s | Partials: {partial_count} | Days: {final_days}/{case['days']}")

# 汇总
print(f"\n{'='*60}")
print("SUMMARY")
print(f"{'='*60}")
passed = sum(1 for r in results if r['success'] and r['days_match'])
print(f"Passed: {passed}/10")
for r in results:
    status = '✅' if r['success'] and r['days_match'] else '❌'
    print(f"  {status} {r['case']}: {r['duration_s']}s, "
          f"{r['partial_events']} partials, "
          f"days={r['final_days']}/{r['expected_days']}"
          f"{' ERROR: ' + r['error'] if r['error'] else ''}")
