-- ============================================================================
-- WanderChina MVP — Step 3: 权限配置
-- ============================================================================
-- 执行身份: wanderchina_pg_prod (超级管理员)
-- 依赖:     002_tables.sql
-- ============================================================================
--
-- 用户角色设计:
--   wanderchina_pg_prod  — 超级管理员，DDL 权限，仅用于部署和迁移
--   wc_scf_service       — 云函数专用，仅 DML（SELECT/INSERT/UPDATE/DELETE）
--   wc_readonly          — 数据分析用，仅 SELECT
--
-- 安全原则:
--   1. wc_scf_service 无法 CREATE/DROP/ALTER 表（防止代码 bug 破坏表结构）
--   2. wc_readonly 无法修改任何数据（安全的分析环境）
--   3. 所有密码在生产部署时替换为强密码（≥16位，混合大小写+数字+特殊字符）
--
-- ============================================================================


-- ========================================================================
-- 1. 创建业务用户
-- ========================================================================

-- 云函数专用用户（8 个云函数共用此账号连接 PG）
-- ⚠️ 生产环境务必替换密码
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'wc_scf_service') THEN
        CREATE USER wc_scf_service WITH PASSWORD 'ScfService@2026#CHANGE_ME';
    END IF;
END $$;

-- 只读用户（数据导出、分析、监控）
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'wc_readonly') THEN
        CREATE USER wc_readonly WITH PASSWORD 'Readonly@2026#CHANGE_ME';
    END IF;
END $$;


-- ========================================================================
-- 2. wc_scf_service 权限 — 仅 DML
-- ========================================================================

-- 连接权限
GRANT CONNECT ON DATABASE wanderchina TO wc_scf_service;
GRANT USAGE ON SCHEMA public TO wc_scf_service;

-- 现有表: SELECT / INSERT / UPDATE / DELETE
GRANT SELECT, INSERT, UPDATE, DELETE
    ON ALL TABLES IN SCHEMA public TO wc_scf_service;

-- 序列: 允许使用自增 ID（BIGSERIAL 需要 USAGE + SELECT）
GRANT USAGE, SELECT
    ON ALL SEQUENCES IN SCHEMA public TO wc_scf_service;

-- 函数: 允许调用 hash_password / verify_password 等
GRANT EXECUTE
    ON ALL FUNCTIONS IN SCHEMA public TO wc_scf_service;

-- 未来新建表/序列/函数自动授权（管理员新增表后 wc_scf_service 自动获得 DML 权限）
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO wc_scf_service;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO wc_scf_service;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT EXECUTE ON FUNCTIONS TO wc_scf_service;


-- ========================================================================
-- 3. wc_readonly 权限 — 仅 SELECT
-- ========================================================================

GRANT CONNECT ON DATABASE wanderchina TO wc_readonly;
GRANT USAGE ON SCHEMA public TO wc_readonly;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO wc_readonly;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO wc_readonly;


-- ========================================================================
-- 4. 连接数限制
-- ========================================================================

-- 云函数最多 50 个并发连接（防止连接池泄漏打爆数据库）
ALTER USER wc_scf_service CONNECTION LIMIT 50;

-- 只读用户限制 10 个连接
ALTER USER wc_readonly CONNECTION LIMIT 10;


-- ========================================================================
-- 5. 锁定 DDL 权限
-- ========================================================================

-- 撤销 public schema 的 CREATE 权限（防止任何非管理员用户建表）
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

-- 只有管理员可以 CREATE TABLE / ALTER TABLE / DROP TABLE
GRANT CREATE ON SCHEMA public TO wanderchina_pg_prod;


-- ========================================================================
-- 6. 验证权限
-- ========================================================================

-- 查看用户列表
SELECT rolname, rolcanlogin FROM pg_roles
WHERE rolname IN ('wanderchina_pg_prod', 'wc_scf_service', 'wc_readonly');

-- 查看表权限
SELECT grantee, table_name, privilege_type
FROM information_schema.table_privileges
WHERE table_schema = 'public'
  AND grantee IN ('wc_scf_service', 'wc_readonly')
ORDER BY grantee, table_name, privilege_type;
