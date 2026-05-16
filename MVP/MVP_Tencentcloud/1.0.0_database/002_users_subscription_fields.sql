-- ====================================================================
-- 002_users_subscription_fields.sql
--
-- 用途: 给 users 表加上付费订阅相关元数据字段
-- 执行时机: Phase 1 Day 1, 在 001 之后
-- 来源: MEMBERSHIP_PAYMENT_PLAN.md 第 2.1 节 "users 表新增字段"
--
-- 关键决策: 不引入 tier 字段
--   - is_premium (boolean) + premium_expires_at (timestamp) 已能完整表达当前业务
--   - 额外的 tier 会和 is_premium 语义重复, 造成双源真相
--   - 未来真需要多层级时再加 (free/pro/enterprise)
--
-- 字段说明:
--   subscription_started_at:    订阅开始时间 (用于续费判断/过期通知)
--   subscription_product_id:    'pass_7d' / 'pass_14d' / 'pass_30d'
--   subscription_platform:      'apple' / 'google' / 'alipay' / 'wechat'
--   subscription_transaction_id: 平台交易 ID (用于幂等防重复处理)
--   premium_source:             区分真实付费 vs 赠送
--                               NULL / 'purchase' / 'complimentary' / 'promo'
--                               (用于财务分析时过滤掉赠送用户)
--
-- 注意: 已存在 is_premium / premium_expires_at 字段, 本迁移仅新增, 不改动
-- ====================================================================

BEGIN;

ALTER TABLE users ADD COLUMN IF NOT EXISTS
  subscription_started_at TIMESTAMP;

ALTER TABLE users ADD COLUMN IF NOT EXISTS
  subscription_product_id VARCHAR(64);

ALTER TABLE users ADD COLUMN IF NOT EXISTS
  subscription_platform VARCHAR(32);

ALTER TABLE users ADD COLUMN IF NOT EXISTS
  subscription_transaction_id TEXT;

ALTER TABLE users ADD COLUMN IF NOT EXISTS
  premium_source VARCHAR(32);

-- 字段注释 (PostgreSQL 内置文档, pgAdmin/DBeaver 可见)
COMMENT ON COLUMN users.subscription_started_at IS
  '订阅开始时间. 用于续费判断和过期通知';
COMMENT ON COLUMN users.subscription_product_id IS
  '产品 ID: pass_7d / pass_14d / pass_30d';
COMMENT ON COLUMN users.subscription_platform IS
  '支付平台: apple / google / alipay / wechat';
COMMENT ON COLUMN users.subscription_transaction_id IS
  '平台交易 ID. 用于防止重复处理 (Apple/Google 偶发回调)';
COMMENT ON COLUMN users.premium_source IS
  '会员来源: NULL / purchase / complimentary / promo. 用于财务分析过滤';

COMMIT;
