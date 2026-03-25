-- ============================================================================
-- WanderChina MVP — 权限修复脚本
-- ============================================================================
-- 用途:     修复现有配置，使其符合 TENCENT_CLOUD_CONFIG_v2.md 第3章要求
-- 执行身份: wanderchina_pg_prod (超级管理员)
-- 依赖:     数据库 wanderchina 已创建
-- 参考文档: TENCENT_CLOUD_CONFIG_v2.md Section 3.3-3.4
-- 生成日期: 2026-03-06
-- ============================================================================
--
-- 本脚本修复 5 个问题:
-- 1. 添加缺失的 postgis_topology 扩展
-- 2. 更新 wc_scf_service 密码 (CHANGE_ME → 正式密码)
-- 3. 设置 wc_scf_service 连接限制 (50)
-- 4. 更新 wc_readonly 密码 (CHANGE_ME → 正式密码)
-- 5. 设置 wc_readonly 连接限制 (10)
--
-- ⚠️ 重要提示:
-- - 执行前请确认已备份现有配置
-- - 如果用户已存在且密码正确，部分语句会报错但不影响结果
-- - 密码修改会立即生效，确保更新应用配置文件
-- ============================================================================


-- ========================================================================
-- 第 1 部分: 添加缺失的 PostGIS 扩展
-- ========================================================================

\echo '========================================';
\echo '1. 安装 postgis_topology 扩展';
\echo '========================================';

-- 根据 TENCENT_CLOUD_CONFIG_v2.md Section 3.3
CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- 验证扩展
SELECT '✅ Extensions Installed:' AS status;
SELECT extname, extversion FROM pg_extension
WHERE extname IN ('uuid-ossp', 'postgis', 'postgis_topology', 'pgcrypto', 'pg_trgm')
ORDER BY extname;
-- 预期: 5 行


-- ========================================================================
-- 第 2 部分: 删除旧用户（如果存在）
-- ========================================================================

\echo '';
\echo '========================================';
\echo '2. 清理旧用户配置';
\echo '========================================';

-- 注意: 如果用户正在使用中，此步骤会失败
-- 在生产环境执行前，确保没有活动连接

-- 撤销所有权限（避免依赖问题）
DO $$
BEGIN
    -- wc_scf_service
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'wc_scf_service') THEN
        REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM wc_scf_service;
        REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM wc_scf_service;
        REVOKE ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public FROM wc_scf_service;
        REVOKE USAGE ON SCHEMA public FROM wc_scf_service;
        REVOKE CONNECT ON DATABASE wanderchina FROM wc_scf_service;

        -- 删除用户
        DROP USER wc_scf_service;
        RAISE NOTICE '✅ wc_scf_service 已删除';
    ELSE
        RAISE NOTICE 'ℹ️  wc_scf_service 不存在，跳过';
    END IF;

    -- wc_readonly
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'wc_readonly') THEN
        REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM wc_readonly;
        REVOKE USAGE ON SCHEMA public FROM wc_readonly;
        REVOKE CONNECT ON DATABASE wanderchina FROM wc_readonly;

        DROP USER wc_readonly;
        RAISE NOTICE '✅ wc_readonly 已删除';
    ELSE
        RAISE NOTICE 'ℹ️  wc_readonly 不存在，跳过';
    END IF;
END $$;


-- ========================================================================
-- 第 3 部分: 重新创建用户（按文档要求）
-- ========================================================================

\echo '';
\echo '========================================';
\echo '3. 创建用户 (正式密码 + 连接限制)';
\echo '========================================';

-- 根据 TENCENT_CLOUD_CONFIG_v2.md Section 3.4
-- 密码来源: WANDERCHINA_BACKEND_DEPLOYMENT_TASKS.md

-- wc_scf_service: 云函数专用用户
CREATE USER wc_scf_service WITH
    PASSWORD 'ScfService@2026#Secure'
    CONNECTION LIMIT 50;

\echo '✅ wc_scf_service 创建成功 (密码: ScfService@2026#Secure, 连接限制: 50)';

-- wc_readonly: 只读用户
CREATE USER wc_readonly WITH
    PASSWORD 'Readonly@2026#Safe'
    CONNECTION LIMIT 10;

\echo '✅ wc_readonly 创建成功 (密码: Readonly@2026#Safe, 连接限制: 10)';


-- ========================================================================
-- 第 4 部分: 配置 wc_scf_service 权限（仅 DML）
-- ========================================================================

\echo '';
\echo '========================================';
\echo '4. 配置 wc_scf_service 权限 (DML only)';
\echo '========================================';

-- 数据库连接权限
GRANT CONNECT ON DATABASE wanderchina TO wc_scf_service;
GRANT USAGE ON SCHEMA public TO wc_scf_service;

-- 现有表: SELECT / INSERT / UPDATE / DELETE
GRANT SELECT, INSERT, UPDATE, DELETE
    ON ALL TABLES IN SCHEMA public TO wc_scf_service;

-- 序列权限（BIGSERIAL 自增 ID）
GRANT USAGE, SELECT
    ON ALL SEQUENCES IN SCHEMA public TO wc_scf_service;

-- 函数权限（hash_password, verify_password 等）
GRANT EXECUTE
    ON ALL FUNCTIONS IN SCHEMA public TO wc_scf_service;

-- 未来新建表/序列/函数的默认权限
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO wc_scf_service;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO wc_scf_service;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT EXECUTE ON FUNCTIONS TO wc_scf_service;

\echo '✅ wc_scf_service 权限配置完成 (DML: SELECT/INSERT/UPDATE/DELETE)';


-- ========================================================================
-- 第 5 部分: 配置 wc_readonly 权限（仅 SELECT）
-- ========================================================================

\echo '';
\echo '========================================';
\echo '5. 配置 wc_readonly 权限 (SELECT only)';
\echo '========================================';

GRANT CONNECT ON DATABASE wanderchina TO wc_readonly;
GRANT USAGE ON SCHEMA public TO wc_readonly;

-- 现有表: SELECT ONLY
GRANT SELECT ON ALL TABLES IN SCHEMA public TO wc_readonly;

-- 未来新建表的默认权限
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO wc_readonly;

\echo '✅ wc_readonly 权限配置完成 (SELECT only)';


-- ========================================================================
-- 第 6 部分: 锁定 DDL 权限
-- ========================================================================

\echo '';
\echo '========================================';
\echo '6. 锁定 DDL 权限 (仅管理员可建表)';
\echo '========================================';

-- 撤销 public schema 的 CREATE 权限
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

-- 只有管理员可以 CREATE TABLE / ALTER TABLE / DROP TABLE
GRANT CREATE ON SCHEMA public TO wanderchina_pg_prod;

\echo '✅ DDL 权限已锁定 (仅 wanderchina_pg_prod 可执行)';


-- ========================================================================
-- 第 7 部分: 验证配置
-- ========================================================================

\echo '';
\echo '========================================';
\echo '7. 验证最终配置';
\echo '========================================';

-- 扩展验证
\echo '';
\echo '7.1 扩展列表 (预期 5 个):';
SELECT extname, extversion FROM pg_extension
WHERE extname IN ('uuid-ossp', 'postgis', 'postgis_topology', 'pgcrypto', 'pg_trgm')
ORDER BY extname;

-- 用户验证
\echo '';
\echo '7.2 用户配置 (预期 2 个):';
SELECT
    rolname AS username,
    rolcanlogin AS can_login,
    rolconnlimit AS connection_limit
FROM pg_roles
WHERE rolname IN ('wc_scf_service', 'wc_readonly')
ORDER BY rolname;
-- 预期:
--   wc_scf_service | t | 50
--   wc_readonly    | t | 10

-- wc_scf_service 权限验证
\echo '';
\echo '7.3 wc_scf_service 权限 (预期: DELETE, INSERT, SELECT, UPDATE):';
SELECT DISTINCT privilege_type
FROM information_schema.table_privileges
WHERE grantee = 'wc_scf_service'
  AND table_schema = 'public'
ORDER BY privilege_type;

-- wc_readonly 权限验证
\echo '';
\echo '7.4 wc_readonly 权限 (预期: SELECT):';
SELECT DISTINCT privilege_type
FROM information_schema.table_privileges
WHERE grantee = 'wc_readonly'
  AND table_schema = 'public'
ORDER BY privilege_type;

-- Schema CREATE 权限验证
\echo '';
\echo '7.5 Schema CREATE 权限 (预期: 仅 wanderchina_pg_prod):';
SELECT
    r.rolname,
    n.nspname,
    CASE
        WHEN has_schema_privilege(r.rolname, n.nspname, 'CREATE') THEN 'YES'
        ELSE 'NO'
    END AS can_create
FROM pg_roles r, pg_namespace n
WHERE n.nspname = 'public'
  AND r.rolname IN ('wanderchina_pg_prod', 'wc_scf_service', 'wc_readonly')
ORDER BY r.rolname;


-- ========================================================================
-- 完成
-- ========================================================================

\echo '';
\echo '========================================';
\echo '✅ 权限修复完成';
\echo '========================================';
\echo '';
\echo '修复内容:';
\echo '  1. ✅ 添加 postgis_topology 扩展';
\echo '  2. ✅ wc_scf_service 密码更新为 ScfService@2026#Secure';
\echo '  3. ✅ wc_scf_service 连接限制设为 50';
\echo '  4. ✅ wc_readonly 密码更新为 Readonly@2026#Safe';
\echo '  5. ✅ wc_readonly 连接限制设为 10';
\echo '';
\echo '下一步:';
\echo '  - 更新云函数的数据库连接配置 (使用新密码)';
\echo '  - 运行 005_verify.sql 进行完整验证';
\echo '  - 如果一切正常，执行 004_seed_data.sql 导入种子数据';
\echo '';
\echo '⚠️  重要: 请在 .env 文件中更新密码';
\echo '    DB_PASSWORD=ScfService@2026#Secure';
\echo '';
