BEGIN;

-- B1:只增不减的行程创建计数
ALTER TABLE users ADD COLUMN trips_created_total INTEGER NOT NULL DEFAULT 0;
UPDATE users SET trips_created_total = trips_count;

-- 账号合并记录
ALTER TABLE users ADD COLUMN merged_into_user_id UUID NULL REFERENCES users(id);

-- 防枚举注册:邮箱验证码
CREATE TABLE email_verifications (
    id          SERIAL PRIMARY KEY,
    email       TEXT NOT NULL,
    code_hash   TEXT NOT NULL,
    attempts    INTEGER NOT NULL DEFAULT 0,
    expires_at  TIMESTAMP NOT NULL,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_email_verifications_email ON email_verifications(email);

-- 找回密码验证码的尝试次数
ALTER TABLE password_resets ADD COLUMN attempts INTEGER NOT NULL DEFAULT 0;

COMMIT;

--核对
-- 新列都在
SELECT table_name, column_name, data_type, column_default
FROM information_schema.columns
WHERE (table_name = 'users' AND column_name IN ('trips_created_total', 'merged_into_user_id'))
   OR (table_name = 'password_resets' AND column_name = 'attempts');

-- 回填正确,应返回 0
SELECT COUNT(*) FROM users WHERE trips_created_total <> trips_count;

-- 新表存在
SELECT to_regclass('public.email_verifications');

--更新行程总计数（后端更新完毕后）
UPDATE users SET trips_created_total = GREATEST(trips_created_total, trips_count);