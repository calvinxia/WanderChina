-- ====================================================================
-- 003_transactions_table.sql
--
-- 用途: 创建交易记录表 (财务审计 + 退款追踪 + 防重复处理)
-- 执行时机: Phase 1 Day 1, 在 002 之后
-- 来源: MEMBERSHIP_PAYMENT_PLAN.md 第 2.2 节 "新增 transactions 表"
--
-- 关键决策:
--   1. ON DELETE SET NULL (而非 CASCADE):
--      用户删除账号后, 交易记录保留 (财务审计需要), user_id 置空脱敏
--   2. amount_cents (INTEGER) 而非 DECIMAL:
--      美分整数避免浮点精度问题
--   3. transaction_id UNIQUE 约束:
--      平台 (Apple/Google/Alipay) 的回调幂等保证, 防重复处理
--   4. 主键用 uuid_generate_v4() 与现有 trips/trip_days/user_sessions 一致
--
-- 索引设计:
--   - user_id: 查询某用户的所有交易 (个人账单页)
--   - status: 筛选 pending 交易做异步 reconciliation
--   - created_at DESC: 财务报表按时间倒序
-- ====================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS transactions (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID REFERENCES users(id) ON DELETE SET NULL,
  -- SET NULL 而非 CASCADE: 账号删除后保留交易记录用于审计

  product_id      VARCHAR(64) NOT NULL,
  -- 'pass_7d' / 'pass_14d' / 'pass_30d'

  platform        VARCHAR(32) NOT NULL,
  -- 'apple' / 'google' / 'alipay' / 'wechat'

  transaction_id  TEXT NOT NULL UNIQUE,
  -- 平台返回的唯一交易 ID. UNIQUE 保证幂等

  amount_cents    INTEGER NOT NULL,
  -- 美分整数, 避免浮点精度

  currency        VARCHAR(8) DEFAULT 'USD',

  status          VARCHAR(32) NOT NULL,
  -- 'pending' / 'completed' / 'failed' / 'refunded'

  receipt_data    TEXT,
  -- 平台收据原始数据, 用于争议时重新验证

  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  verified_at     TIMESTAMP
  -- 服务端验证通过的时间. NULL 表示未验证或验证失败
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_transactions_user_id
  ON transactions(user_id);

CREATE INDEX IF NOT EXISTS idx_transactions_status
  ON transactions(status);

CREATE INDEX IF NOT EXISTS idx_transactions_created_at
  ON transactions(created_at DESC);

-- 表级注释
COMMENT ON TABLE transactions IS
  'Payment transaction records for audit and refund tracking.
   Records preserved on user deletion (user_id SET NULL).
   Use transaction_id UNIQUE for idempotency on platform callbacks.';

COMMIT;
