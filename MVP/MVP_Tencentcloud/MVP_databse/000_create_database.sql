-- ============================================================================
-- WanderChina MVP — 创建专用数据库
-- ============================================================================
-- 用途:     创建 wanderchina 专用数据库（如果尚未创建）
-- 执行身份: wanderchina_pg_prod (超级管理员)
-- 连接数据库: postgres (默认数据库)
-- 参考文档: TENCENT_CLOUD_CONFIG_v2.md Section 3.4
-- ============================================================================
--
-- ⚠️ 重要说明:
-- 1. 此脚本必须在连接到 "postgres" 数据库时执行
-- 2. 不能在 wanderchina 数据库中执行（会报错：cannot create database from within a database）
-- 3. 执行完成后，需要断开连接并重新连接到 wanderchina 数据库
--
-- ============================================================================

\echo '========================================';
\echo '创建 WanderChina 专用数据库';
\echo '========================================';
\echo '';

-- 检查当前连接的数据库
DO $$
DECLARE
    current_db TEXT;
BEGIN
    SELECT current_database() INTO current_db;

    IF current_db != 'postgres' THEN
        RAISE EXCEPTION '❌ 错误: 当前连接到 % 数据库。创建数据库必须在 postgres 数据库中执行！', current_db;
    ELSE
        RAISE NOTICE '✅ 当前连接: postgres 数据库（正确）';
    END IF;
END $$;

\echo '';

-- 检查 wanderchina 数据库是否已存在
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_database WHERE datname = 'wanderchina') THEN
        RAISE NOTICE '⚠️  wanderchina 数据库已存在，跳过创建';
    ELSE
        RAISE NOTICE '创建 wanderchina 数据库...';
    END IF;
END $$;

-- 创建数据库（如果不存在）
-- 根据 TENCENT_CLOUD_CONFIG_v2.md Section 3.4
CREATE DATABASE wanderchina
    WITH
    OWNER = wanderchina_pg_prod
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;

\echo '';
\echo '✅ wanderchina 数据库创建成功！';
\echo '';
\echo '========================================';
\echo '下一步操作';
\echo '========================================';
\echo '';
\echo '1. 在 pgAdmin 左侧树中，右键点击当前连接';
\echo '2. 选择 "Disconnect Server"';
\echo '3. 展开 Servers → WanderChina Production';
\echo '4. 右键点击 "wanderchina" 数据库';
\echo '5. 选择 "Query Tool"';
\echo '';
\echo '6. 执行 000_extensions.sql 安装扩展';
\echo '';
\echo '或者，如果扩展已安装，继续执行:';
\echo '   - 001_functions.sql';
\echo '   - 002_tables.sql';
\echo '   - 006_fix_permissions.sql';
\echo '   - 004_seed_data.sql';
\echo '   - 005_verify.sql';
\echo '';
