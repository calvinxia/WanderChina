-- ====================================================================
-- 006_password_resets_table.sql
--
-- 用途: 存储密码重置 token (6 位数字, 10 分钟过期)
-- 执行时机: Phase 1 Day 2 (与"忘记密码"功能开发同时执行)
-- 来源: MEMBERSHIP_PAYMENT_PLAN.md 第 5.X 节 "忘记密码" 功能
--
-- ⚠️ 注意: 原始方案文档中只有使用代码片段, 没有 DDL.
--    本文件 schema 是根据使用方式 (云函数 user_auth/forgot_password) 推断:
--      INSERT INTO password_resets (email, token, expires_at)
--      VALUES (%s, %s, NOW() + INTERVAL '10 minutes')
--
--    如果你在 user_auth 云函数里实际用了不同字段, 请相应调整本文件.
--    建议在 Phase 1 Day 2 开发"忘记密码"时同步审核此表设计.
--
-- 安全考量:
--   1. token 字段存储已 hash 的值, 不是明文
--      (云函数代码: hash(reset_token) 后再 INSERT)
--   2. expires_at 强制 10 分钟过期, 减少暴力破解时间窗口
--   3. used 字段标记 token 是否已使用, 防止重放攻击
--   4. 索引 email + expires_at 加速验证查询
-- ====================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS password_resets (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email       VARCHAR(255) NOT NULL,
  token       TEXT NOT NULL,
  -- 已 hash 的 token, 不是明文

  expires_at  TIMESTAMP NOT NULL,
  -- 通常 NOW() + INTERVAL '10 minutes'

  used        BOOLEAN DEFAULT FALSE,
  -- 防止重放: token 验证通过后立即置 TRUE

  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 索引: 验证 token 时按 email 查询, 同时过滤未过期+未使用
CREATE INDEX IF NOT EXISTS idx_password_resets_email_active
  ON password_resets(email, expires_at)
  WHERE used = FALSE;

-- 表注释
COMMENT ON TABLE password_resets IS
  'Password reset tokens (hashed, 10-min expiry).
   Cleanup recommended: DELETE FROM password_resets WHERE expires_at < NOW() - INTERVAL ''1 day''
   Run as a scheduled cleanup task or via cron.';

COMMIT;
