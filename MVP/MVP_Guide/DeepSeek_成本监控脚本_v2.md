# DeepSeek API 成本监控脚本

**用途：** 监控 DeepSeek API 使用情况和成本
**更新日期：** 2026-03-02（v2.0）

---

## MVP 阶段监控策略

```
DeepSeek MVP 月费 ≈ ¥12，不值得部署 Prometheus/Grafana 等重型监控。
MVP 推荐方案:
  ① DeepSeek 后台余额告警（余额 < ¥10 时邮件提醒）
  ② 云函数日志内置成本打印（已在 deepseek_translate 实现）
  ③ 本地 Python 脚本按需分析（本文档脚本 1）

成长阶段（月费 > ¥100 时）:
  ④ 腾讯云 SCF 日志 API 查询（本文档脚本 2）
  ⑤ Prometheus + Grafana（可选，月费 > ¥1000 时考虑）
```

---

## 脚本 1：成本分析（Python，MVP 推荐）

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
DeepSeek API 成本监控脚本（v2.0）
- 定价基于 USD → RMB 换算
- 支持从云函数日志解析
- 生成成本报告
"""

import re
import json
from datetime import datetime
from collections import defaultdict

class DeepSeekCostMonitor:
    """DeepSeek API 成本监控器"""

    # DeepSeek V3.2 定价（USD → RMB）
    USD_TO_CNY = 7.2
    PRICE_UNCACHED_INPUT = 0.28 * USD_TO_CNY / 1_000_000   # $0.28/1M → ≈¥2.02/M
    PRICE_CACHED_INPUT = 0.028 * USD_TO_CNY / 1_000_000    # $0.028/1M → ≈¥0.20/M
    PRICE_OUTPUT = 0.42 * USD_TO_CNY / 1_000_000            # $0.42/1M → ≈¥3.02/M

    def __init__(self):
        self.stats = {
            'total_calls': 0,
            'total_uncached_tokens': 0,
            'total_cached_tokens': 0,
            'total_completion_tokens': 0,
            'total_cost': 0.0,
            'by_date': defaultdict(lambda: {
                'calls': 0, 'uncached': 0, 'cached': 0,
                'completion': 0, 'cost': 0.0
            }),
            'by_language': defaultdict(lambda: {
                'calls': 0, 'cost': 0.0
            })
        }

    def calculate_cost(self, uncached, cached, completion):
        return (
            uncached * self.PRICE_UNCACHED_INPUT +
            cached * self.PRICE_CACHED_INPUT +
            completion * self.PRICE_OUTPUT
        )

    def add_record(self, date, uncached, cached, completion, language='en'):
        self.stats['total_calls'] += 1
        self.stats['total_uncached_tokens'] += uncached
        self.stats['total_cached_tokens'] += cached
        self.stats['total_completion_tokens'] += completion

        cost = self.calculate_cost(uncached, cached, completion)
        self.stats['total_cost'] += cost

        day = self.stats['by_date'][date]
        day['calls'] += 1
        day['uncached'] += uncached
        day['cached'] += cached
        day['completion'] += completion
        day['cost'] += cost

        lang = self.stats['by_language'][language]
        lang['calls'] += 1
        lang['cost'] += cost

    def get_cache_hit_rate(self):
        total = self.stats['total_cached_tokens'] + self.stats['total_uncached_tokens']
        return (self.stats['total_cached_tokens'] / total * 100) if total > 0 else 0.0

    def generate_report(self):
        lines = []
        lines.append("=" * 70)
        lines.append("DeepSeek API 成本监控报告")
        lines.append(f"生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        lines.append(f"定价基准: USD × {self.USD_TO_CNY} CNY/USD")
        lines.append("=" * 70)
        lines.append("")

        # 总体统计
        total_tokens = (self.stats['total_uncached_tokens'] +
                       self.stats['total_cached_tokens'] +
                       self.stats['total_completion_tokens'])
        lines.append("【总体统计】")
        lines.append(f"  总调用次数:       {self.stats['total_calls']:,}")
        lines.append(f"  总 Token 数:      {total_tokens:,}")
        lines.append(f"    输入（未缓存）: {self.stats['total_uncached_tokens']:,}")
        lines.append(f"    输入（缓存）:   {self.stats['total_cached_tokens']:,}")
        lines.append(f"    输出:           {self.stats['total_completion_tokens']:,}")
        lines.append(f"  缓存命中率:       {self.get_cache_hit_rate():.1f}%")
        lines.append(f"  总成本:           ¥{self.stats['total_cost']:.4f}")
        lines.append("")

        # 每日统计
        if self.stats['by_date']:
            lines.append("【每日统计】")
            lines.append(f"{'日期':<12} {'调用':<8} {'成本':<12} {'缓存率':<8}")
            lines.append("-" * 42)
            for date in sorted(self.stats['by_date'].keys()):
                d = self.stats['by_date'][date]
                total_p = d['cached'] + d['uncached']
                rate = (d['cached'] / total_p * 100) if total_p > 0 else 0
                lines.append(f"{date:<12} {d['calls']:<8} ¥{d['cost']:<11.4f} {rate:<7.0f}%")
            lines.append("")

        # 月度预估
        days = max(len(self.stats['by_date']), 1)
        daily_avg = self.stats['total_cost'] / days
        lines.append("【月度预估】")
        lines.append(f"  日均成本:   ¥{daily_avg:.4f}")
        lines.append(f"  预估月成本: ¥{daily_avg * 30:.2f}")
        lines.append(f"  预估年成本: ¥{daily_avg * 365:.2f}")
        lines.append("")

        # 告警检查
        cache_rate = self.get_cache_hit_rate()
        if daily_avg > 0.5:
            lines.append("【⚠️ 成本告警】")
            lines.append(f"  日均成本 ¥{daily_avg:.4f} 偏高，请检查是否存在异常调用")
        if cache_rate < 60 and self.stats['total_calls'] > 100:
            lines.append("【⚠️ 缓存告警】")
            lines.append(f"  缓存命中率 {cache_rate:.1f}% 偏低")
            lines.append("  建议: 检查 System Prompt 是否固定 / Redis 缓存是否生效")
        if daily_avg <= 0.5 and cache_rate >= 60:
            lines.append("【✅ 状态正常】")

        lines.append("")
        lines.append("=" * 70)
        return "\n".join(lines)

    def save_report(self, filename=None):
        if filename is None:
            filename = f"deepseek_cost_{datetime.now().strftime('%Y%m%d')}.txt"
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(self.generate_report())
        print(f"报告已保存: {filename}")


def parse_scf_logs(log_text):
    """
    解析云函数日志文本

    日志格式（由 deepseek_translate v2.0 生成）:
    [TRANSLATE] '故宫博物院' → 'Palace Museum' | tokens=30(cached:25)+5 | cache=83% | cost=¥0.000021
    """
    monitor = DeepSeekCostMonitor()

    pattern = re.compile(
        r'\[TRANSLATE\].*?tokens=(\d+)\(cached:(\d+)\)\+(\d+).*?cost=¥([\d.]+)'
    )
    date_pattern = re.compile(r'(\d{4}-\d{2}-\d{2})')
    lang_pattern = re.compile(r"'target_lang':\s*'(\w+)'")

    current_date = datetime.now().strftime('%Y-%m-%d')
    current_lang = 'en'

    for line in log_text.split('\n'):
        # 提取日期
        dm = date_pattern.search(line)
        if dm:
            current_date = dm.group(1)

        # 提取语言
        lm = lang_pattern.search(line)
        if lm:
            current_lang = lm.group(1)

        # 提取 token 信息
        m = pattern.search(line)
        if m:
            prompt = int(m.group(1))
            cached = int(m.group(2))
            completion = int(m.group(3))
            uncached = prompt - cached

            monitor.add_record(
                date=current_date,
                uncached=uncached,
                cached=cached,
                completion=completion,
                language=current_lang
            )

    return monitor


# ===== 使用示例 =====
if __name__ == '__main__':
    monitor = DeepSeekCostMonitor()

    # 模拟 MVP 一周数据（每天 ~70 次翻译）
    for day in range(1, 8):
        date = f"2026-03-{day:02d}"
        for _ in range(70):
            monitor.add_record(
                date=date,
                uncached=5,
                cached=25,
                completion=5,
                language='en'
            )

    print(monitor.generate_report())
    monitor.save_report()
```

---

## 脚本 2：腾讯云 SCF 日志查询（成长阶段）

```python
#!/usr/bin/env python3
"""
从腾讯云函数 API 查询日志（需安装 tencentcloud-sdk-python）
适用于: 月费 > ¥100 时的自动化成本追踪
"""

from tencentcloud.common import credential
from tencentcloud.scf.v20180416 import scf_client, models
from datetime import datetime, timedelta
import json

class SCFLogAnalyzer:
    def __init__(self, secret_id, secret_key, region='ap-guangzhou'):
        cred = credential.Credential(secret_id, secret_key)
        self.client = scf_client.ScfClient(cred, region)

    def get_logs(self, function_name, hours=24):
        """获取最近 N 小时的云函数日志"""
        end_time = datetime.now()
        start_time = end_time - timedelta(hours=hours)

        try:
            req = models.GetFunctionLogsRequest()
            req.from_json_string(json.dumps({
                "FunctionName": function_name,
                "StartTime": start_time.strftime('%Y-%m-%d %H:%M:%S'),
                "EndTime": end_time.strftime('%Y-%m-%d %H:%M:%S'),
                "Limit": 1000
            }))
            resp = self.client.GetFunctionLogs(req)

            # 合并所有日志内容
            log_text = '\n'.join(
                log.Log for log in (resp.Data or []) if log.Log
            )
            return log_text

        except Exception as e:
            print(f"获取日志失败: {e}")
            return ""

    def analyze(self, function_name='deepseek_translate', hours=24):
        """获取日志并生成成本报告"""
        log_text = self.get_logs(function_name, hours)
        if not log_text:
            print("无日志数据")
            return None
        monitor = parse_scf_logs(log_text)
        return monitor.generate_report()


if __name__ == '__main__':
    # 替换为实际密钥（或从环境变量读取）
    import os
    analyzer = SCFLogAnalyzer(
        secret_id=os.environ.get('TC_SECRET_ID', ''),
        secret_key=os.environ.get('TC_SECRET_KEY', ''),
    )
    report = analyzer.analyze('deepseek_translate', hours=168)  # 最近 7 天
    if report:
        print(report)
```

---

## 告警配置

```python
def check_alerts(monitor):
    """成本异常检测"""
    days = max(len(monitor.stats['by_date']), 1)
    daily_avg = monitor.stats['total_cost'] / days

    alerts = []

    # MVP 阶段: 日均 > ¥0.5 即异常（正常值 ≈ ¥0.003）
    if daily_avg > 0.5:
        alerts.append(f"⚠️ 日均成本 ¥{daily_avg:.4f} 超标（阈值 ¥0.5），可能存在 API Key 泄露")

    # 缓存命中率 < 50%
    cache_rate = monitor.get_cache_hit_rate()
    if cache_rate < 50 and monitor.stats['total_calls'] > 100:
        alerts.append(f"⚠️ 缓存命中率 {cache_rate:.1f}%，建议检查 System Prompt 是否固定")

    # 单日调用量异常（超过日均 10 倍）
    for date, d in monitor.stats['by_date'].items():
        avg_calls = monitor.stats['total_calls'] / days
        if d['calls'] > avg_calls * 10 and avg_calls > 10:
            alerts.append(f"⚠️ {date} 调用量 {d['calls']} 次，超过日均 {avg_calls:.0f} 的 10 倍")

    return alerts
```

---

## 成长阶段扩展：Prometheus（可选）

当月费超过 ¥1,000 时，可考虑部署 Prometheus + Grafana 监控。此处不展开，需要时再设计。核心指标：

```
deepseek_api_calls_total{language, status}     — 总调用次数
deepseek_tokens_used{type}                     — Token 使用量
deepseek_cost_yuan_total                       — 总成本（RMB）
deepseek_cache_hit_rate_percent                — 缓存命中率
deepseek_api_latency_seconds                   — API 延迟
```

---

**版本历史：**
- v1.0（2026-02-25）: 初始版本
- v2.0（2026-03-02）:
  - 修正: 定价从 ¥ 改为 USD × 汇率
  - 修正: 告警阈值从 ¥1/天降为 ¥0.5/天
  - 修正: SCFLogAnalyzer 补全实现
  - 修正: 日志解析正则匹配 v2.0 云函数输出格式
  - 调整: Prometheus 方案降级为"成长阶段可选"
  - 新增: MVP 阶段监控策略说明
  - 新增: 单日调用量异常检测
