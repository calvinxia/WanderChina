-- ============================================================================
-- 验证当前数据库连接
-- ============================================================================
-- 用途: 确认是否已创建 wanderchina 数据库并正确连接
-- ============================================================================

\echo '========================================';
\echo '检查当前数据库连接';
\echo '========================================';
\echo '';

-- 显示当前连接的数据库
SELECT
    current_database() AS current_database,
    current_user AS current_user,
    inet_server_addr() AS server_address,
    inet_server_port() AS server_port;

\echo '';
\echo '========================================';
\echo '检查 wanderchina 数据库是否存在';
\echo '========================================';
\echo '';

-- 列出所有数据库
SELECT
    datname AS database_name,
    pg_encoding_to_char(encoding) AS encoding,
    datcollate AS collation,
    CASE
        WHEN datname = 'wanderchina' THEN '✅ 目标数据库'
        WHEN datname = 'postgres' THEN '⚠️  默认数据库'
        ELSE ''
    END AS status
FROM pg_database
WHERE datname IN ('postgres', 'wanderchina', 'template0', 'template1')
ORDER BY datname;

\echo '';

-- 判断并给出建议
DO $$
DECLARE
    current_db TEXT;
    db_exists BOOLEAN;
BEGIN
    SELECT current_database() INTO current_db;
    SELECT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'wanderchina') INTO db_exists;

    RAISE NOTICE '';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    RAISE NOTICE '诊断结果:';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    RAISE NOTICE '';
    RAISE NOTICE '当前连接的数据库: %', current_db;

    IF db_exists THEN
        RAISE NOTICE 'wanderchina 数据库: ✅ 已存在';
        RAISE NOTICE '';

        IF current_db = 'wanderchina' THEN
            RAISE NOTICE '🟢 状态: 正确';
            RAISE NOTICE '';
            RAISE NOTICE '您已正确连接到 wanderchina 数据库';
            RAISE NOTICE '可以继续执行初始化脚本:';
            RAISE NOTICE '  1. 001_functions.sql';
            RAISE NOTICE '  2. 002_tables.sql';
            RAISE NOTICE '  3. 006_fix_permissions.sql';
            RAISE NOTICE '  4. 004_seed_data.sql';
            RAISE NOTICE '  5. 005_verify.sql';
        ELSE
            RAISE NOTICE '🟡 状态: 需要切换数据库';
            RAISE NOTICE '';
            RAISE NOTICE '❌ 当前连接到: % (错误)', current_db;
            RAISE NOTICE '✅ 应该连接到: wanderchina';
            RAISE NOTICE '';
            RAISE NOTICE '请在 pgAdmin 中:';
            RAISE NOTICE '1. 断开当前连接';
            RAISE NOTICE '2. 在左侧树中展开: Servers → WanderChina Production';
            RAISE NOTICE '3. 右键点击 "wanderchina" 数据库';
            RAISE NOTICE '4. 选择 "Query Tool"';
            RAISE NOTICE '5. 重新执行此检查脚本确认';
        END IF;
    ELSE
        RAISE NOTICE 'wanderchina 数据库: ❌ 不存在';
        RAISE NOTICE '';
        RAISE NOTICE '🔴 状态: 需要创建数据库';
        RAISE NOTICE '';
        RAISE NOTICE '请先执行以下 SQL 创建数据库:';
        RAISE NOTICE '';
        RAISE NOTICE '---------------------------------------';
        RAISE NOTICE 'CREATE DATABASE wanderchina';
        RAISE NOTICE '    WITH ';
        RAISE NOTICE '    OWNER = wanderchina_pg_prod';
        RAISE NOTICE '    ENCODING = ''UTF8''';
        RAISE NOTICE '    LC_COLLATE = ''en_US.UTF-8''';
        RAISE NOTICE '    LC_CTYPE = ''en_US.UTF-8''';
        RAISE NOTICE '    TEMPLATE = template0;';
        RAISE NOTICE '---------------------------------------';
        RAISE NOTICE '';
        RAISE NOTICE '然后断开连接，重新连接到 wanderchina 数据库';
    END IF;

    RAISE NOTICE '';
END $$;

\echo '';
\echo '========================================';
\echo '检查完成';
\echo '========================================';
