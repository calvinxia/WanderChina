-- ====================================================================
-- 004_usage_quota_table.sql
--
-- 用途: 追踪付费墙周期性配额 (语音翻译每日次数等)
-- 执行时机: Phase 1 Day 1, 在 003 之后
-- 来源: MEMBERSHIP_PAYMENT_PLAN.md 第 2.3 节 "新增 usage_quota 表"
--
-- 与现有 users 表计数字段的分工:
--   ┌─────────────────────────────────────────────────────────────┐
--   │ 字段                  │ 用途                  │ 重置周期     │
--   ├─────────────────────────────────────────────────────────────┤
--   │ users.trips_count     │ 历史累计行程数        │ 永不重置     │
--   │ users.translations_   │ 历史累计翻译次数      │ 永不重置     │
--   │   count               │ (用于成就/分析)        │              │
--   ├─────────────────────────────────────────────────────────────┤
--   │ usage_quota           │ 周期性配额 (付费墙)   │ 按 feature   │
--   │   .used_count         │                       │ 周期重置     │
--   └─────────────────────────────────────────────────────────────┘
--
-- 关键决策:
--   1. itinerary_generate 不在此表, 直接用 users.trips_count 判断
--      (生成行程是 lifetime 配额, 不需要周期重置)
--   2. ON DELETE CASCADE: 用户删除账号后, 配额数据无审计价值, 直接清理
--   3. 复合主键 (user_id, feature) 自然防重复, 不需要额外 UNIQUE 约束
--
-- 重置逻辑由云函数控制 (purchase_verify / 业务函数检查 last_reset_at):
--   语音翻译: 每日 0 点重置 (检查 last_reset_at < CURRENT_DATE)
-- ====================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS usage_quota (
  user_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  feature            VARCHAR(64) NOT NULL,
  -- 'voice_translate' 等周期性配额功能
  -- 注意: 'itinerary_generate' 不在此表

  used_count         INTEGER DEFAULT 0,
  last_reset_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  PRIMARY KEY (user_id, feature)
);

-- 表级注释 (重要: 避免未来开发者误用此表做 lifetime 统计)
COMMENT ON TABLE usage_quota IS
  'Cyclic usage quota for paywall enforcement. Resets per feature-specific cycle.
   Do NOT use for lifetime stats: users.trips_count and users.translations_count
   are lifetime cumulative counters for achievements/analytics.';

COMMIT;
