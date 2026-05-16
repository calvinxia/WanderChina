-- ====================================================================
-- 007_users_oauth_fields.sql
--
-- 用途: 给 users 表加 OAuth 关联字段 + 邮箱验证状态 + 软删除支持
-- 执行时机: Phase 1 Day 1 (5/5), 在 run_all.sql 里追加执行
-- 来源: 2026-05-08 schema 诊断后发现的 4 个缺失字段
--
-- 决策依据:
--   - apple_user_id / google_user_id 必须 UNIQUE 但允许 NULL
--     UNIQUE: 同一 OAuth 用户只能关联到一个账号
--     允许 NULL: 仅邮箱注册的用户没有这两个字段
--   - email_verified 默认 FALSE: forgot_password 流程要求邮箱已验证
--   - deleted_at 用 TIMESTAMP NULL: NULL 表示活跃, 非 NULL 表示已删除时间
--
-- 不修改的内容:
--   - users.email UNIQUE 约束保留 (现有 users_email_key)
--     理由: 应用层 apple_sign_in 必须先查 email 做合并, UNIQUE 是防御性兜底
--   - users.phone UNIQUE 约束保留 (现有 users_phone_key)
--
-- 影响范围:
--   - users 表追加 4 列, 不影响现有数据
--   - 2 个部分唯一索引 (apple_user_id, google_user_id)
--
-- 回滚: 可回滚 (DROP COLUMN + DROP INDEX)
-- ====================================================================

BEGIN;

-- 1. OAuth 用户 ID
ALTER TABLE users ADD COLUMN IF NOT EXISTS
    apple_user_id TEXT;

ALTER TABLE users ADD COLUMN IF NOT EXISTS
    google_user_id TEXT;

-- 部分唯一索引 (只对 NOT NULL 的值唯一)
-- 这样允许多个用户的 apple_user_id 都为 NULL (仅邮箱注册的用户)
-- 但同一个 apple_user_id 只能关联一个账号
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_apple_user_id
    ON users(apple_user_id)
    WHERE apple_user_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_google_user_id
    ON users(google_user_id)
    WHERE google_user_id IS NOT NULL;

-- 2. 邮箱验证状态 (forgot_password / reset_password 流程依赖)
ALTER TABLE users ADD COLUMN IF NOT EXISTS
    email_verified BOOLEAN DEFAULT FALSE;

-- OAuth 注册的用户邮箱已被 Apple/Google 验证, 应自动设为 TRUE
-- 这部分逻辑在 user_auth 云函数的 apple_sign_in / google_sign_in 中处理

-- 3. 软删除标记 (delete_account 流程依赖)
ALTER TABLE users ADD COLUMN IF NOT EXISTS
    deleted_at TIMESTAMP;

-- 4. 字段注释
COMMENT ON COLUMN users.apple_user_id IS
    'Apple Sign-In sub claim (userIdentifier). 跨设备/卸载重装稳定. UNIQUE WHERE NOT NULL.';

COMMENT ON COLUMN users.google_user_id IS
    'Google Sign-In sub claim. 跨设备/卸载重装稳定. UNIQUE WHERE NOT NULL.';

COMMENT ON COLUMN users.email_verified IS
    '邮箱是否已验证. OAuth 注册自动设为 TRUE, 邮箱注册需要发验证码确认.';

COMMENT ON COLUMN users.deleted_at IS
    '软删除时间戳. NULL 表示活跃账号. 非 NULL 表示已删除, email/password_hash 应一并置 NULL.';

COMMIT;

-- ====================================================================
-- 执行后验证查询:
--
-- SELECT column_name, data_type FROM information_schema.columns
--   WHERE table_name = 'users'
--     AND column_name IN ('apple_user_id', 'google_user_id', 'email_verified', 'deleted_at');
-- 预期 4 行
--
-- SELECT indexname FROM pg_indexes
--   WHERE tablename = 'users'
--     AND indexname IN ('idx_users_apple_user_id', 'idx_users_google_user_id');
-- 预期 2 行
-- ====================================================================
