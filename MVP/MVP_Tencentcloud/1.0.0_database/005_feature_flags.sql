-- ====================================================================
-- 005_feature_flags.sql
--
-- 用途: 创建 feature flag 表 + 初始化 7 条记录
-- 执行时机: Phase 1 Day 1, 在 004 之后
-- 来源:
--   - MEMBERSHIP_PAYMENT_PLAN.md 第 4.2-4.3 节 (6 条核心 flag)
--   - V0_2_OPTIMIZATION_PLAN.md 第 3.6.1 节 (survey_enabled flag)
--
-- 设计原则:
--   - PostgreSQL 存储, 不引入 Redis/配置中心 (减少基础设施)
--   - JSONB 类型支持灵活的 flag 值 (boolean / number / array / object)
--   - 云函数每请求查一次 (DB 内部查询足够快)
--   - Flutter 客户端 5 分钟缓存 (减少调用)
--
-- 修改方式 (MVP 阶段):
--   直接 SQL UPDATE flag_value 字段, 例如:
--     UPDATE feature_flags
--     SET flag_value = 'true'::jsonb, updated_at = NOW(), updated_by = 'admin'
--     WHERE flag_key = 'paywall_enabled';
--
-- 生效时间:
--   - 云函数: 立即生效 (下一次请求)
--   - Flutter 客户端: 最长 5 分钟 (缓存窗口)
-- ====================================================================

BEGIN;

-- -- 1. 表结构 ---------------------------------------------------------

CREATE TABLE IF NOT EXISTS feature_flags (
  flag_key      VARCHAR(128) PRIMARY KEY,
  flag_value    JSONB NOT NULL,
  description   TEXT,
  updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_by    VARCHAR(64)
  -- 'admin' / 'auto' / 运维标识
);

COMMENT ON TABLE feature_flags IS
  'Runtime configuration for paywall, pricing, and gated features.
   Read by both cloud functions (every request) and Flutter client (5-min cache).';


-- -- 2. 初始化数据 (7 条) -----------------------------------------------

-- 付费墙总开关 (5/22 首发默认关闭, 收到稳定反馈后远程开启)
INSERT INTO feature_flags (flag_key, flag_value, description) VALUES
  ('paywall_enabled', 'false'::jsonb,
   '付费墙总开关. 关闭时所有功能免费, 不弹付费墙')
ON CONFLICT (flag_key) DO NOTHING;

-- 免费行程生成次数阈值 (trips_count >= 此值时弹付费墙)
-- 设计: 渐进付费墙 — 用户先用顺手再触发付费
INSERT INTO feature_flags (flag_key, flag_value, description) VALUES
  ('paywall_trigger_itinerary_count', '3'::jsonb,
   '免费行程生成次数. trips_count >= 此值时弹付费墙. modify 不计入配额, 用户可在每个 trip 内无限 AI 编辑')
ON CONFLICT (flag_key) DO NOTHING;

-- 每日免费语音翻译次数
INSERT INTO feature_flags (flag_key, flag_value, description) VALUES
  ('paywall_trigger_voice_daily', '5'::jsonb,
   '每日免费语音翻译次数. 超过此值时弹付费墙')
ON CONFLICT (flag_key) DO NOTHING;

-- AI 编辑是否付费墙
INSERT INTO feature_flags (flag_key, flag_value, description) VALUES
  ('paywall_trigger_ai_edit', 'true'::jsonb,
   'AI 编辑是否付费墙. false 表示免费用户也能 AI 编辑 (本次首发如反馈不好可关闭)')
ON CONFLICT (flag_key) DO NOTHING;

-- 定价临时覆盖 (null 表示用 App Store 标价)
INSERT INTO feature_flags (flag_key, flag_value, description) VALUES
  ('pricing_override', 'null'::jsonb,
   '定价临时覆盖. null 表示用 App Store 标价. 格式: {"pass_7d_cents": 899, ...}')
ON CONFLICT (flag_key) DO NOTHING;

-- 启用付费墙的功能列表 (可临时关闭某项)
INSERT INTO feature_flags (flag_key, flag_value, description) VALUES
  ('paywall_gates', '["itinerary_generate","ai_edit","voice_translate"]'::jsonb,
   '启用付费墙的功能列表. 可临时关闭某项 (如语音翻译反馈差, 从列表移除即可)')
ON CONFLICT (flag_key) DO NOTHING;

-- 付费意愿调研卡片开关 (V0.2 数据采集用)
INSERT INTO feature_flags (flag_key, flag_value, description) VALUES
  ('survey_enabled', 'true'::jsonb,
   '付费意愿调研卡片开关. 收集足够数据后可关闭 (建议收到 100+ 有效响应后关闭)')
ON CONFLICT (flag_key) DO NOTHING;

COMMIT;

-- -- 3. 验证 -----------------------------------------------------------
-- 执行后人工核对:
-- SELECT flag_key, flag_value, description FROM feature_flags ORDER BY flag_key;
-- 预期 7 行
