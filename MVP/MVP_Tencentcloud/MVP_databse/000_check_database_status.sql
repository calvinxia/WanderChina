-- ============================================================================
-- WanderChina MVP — 数据库状态检查
-- ============================================================================
-- 用途:     检查数据库是否已初始化，以及当前配置状态
-- 执行身份: wanderchina_pg_prod (超级管理员)
-- 数据库:   wanderchina
-- ============================================================================
--
-- 使用方法:
-- 1. 在 pgAdmin 中连接到 wanderchina 数据库
-- 2. 打开查询工具，粘贴本脚本
-- 3. 点击 "Execute/Run" (F5) 执行
-- 4. 查看输出，判断数据库状态
--
-- ============================================================================

\echo '========================================';
\echo 'WanderChina 数据库状态检查';
\echo '========================================';
\echo '';

-- ========================================================================
-- 1. 数据库基本信息
-- ========================================================================
\echo '1️⃣  数据库基本信息';
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

SELECT
    current_database() AS database_name,
    version() AS postgres_version,
    pg_database_size(current_database()) AS database_size_bytes,
    pg_size_pretty(pg_database_size(current_database())) AS database_size_readable;

\echo '';


-- ========================================================================
-- 2. 扩展安装状态
-- ========================================================================
\echo '2️⃣  扩展安装状态 (预期 5 个)';
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

SELECT
    CASE
        WHEN COUNT(*) = 0 THEN '❌ 未安装任何扩展 - 数据库未初始化'
        WHEN COUNT(*) < 5 THEN '⚠️  部分扩展已安装 - 需要修复'
        WHEN COUNT(*) = 5 THEN '✅ 所有扩展已安装'
        ELSE '⚠️  扩展数量异常'
    END AS status,
    COUNT(*) AS installed_count
FROM pg_extension
WHERE extname IN ('uuid-ossp', 'postgis', 'postgis_topology', 'pgcrypto', 'pg_trgm');

-- 详细列表
SELECT
    'uuid-ossp' AS expected_extension,
    CASE WHEN EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'uuid-ossp')
        THEN '✅ 已安装' ELSE '❌ 未安装' END AS status
UNION ALL
SELECT 'postgis',
    CASE WHEN EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'postgis')
        THEN '✅ 已安装' ELSE '❌ 未安装' END
UNION ALL
SELECT 'postgis_topology',
    CASE WHEN EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'postgis_topology')
        THEN '✅ 已安装' ELSE '❌ 未安装' END
UNION ALL
SELECT 'pgcrypto',
    CASE WHEN EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto')
        THEN '✅ 已安装' ELSE '❌ 未安装' END
UNION ALL
SELECT 'pg_trgm',
    CASE WHEN EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_trgm')
        THEN '✅ 已安装' ELSE '❌ 未安装' END;

\echo '';


-- ========================================================================
-- 3. 业务表状态
-- ========================================================================
\echo '3️⃣  业务表状态 (预期 6 个)';
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

SELECT
    CASE
        WHEN COUNT(*) = 0 THEN '❌ 未创建任何表 - 数据库未初始化'
        WHEN COUNT(*) < 6 THEN '⚠️  部分表已创建 - 初始化不完整'
        WHEN COUNT(*) = 6 THEN '✅ 所有业务表已创建'
        ELSE '⚠️  表数量异常 (超过预期)'
    END AS status,
    COUNT(*) AS table_count
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE';

-- 详细列表
SELECT
    table_name,
    pg_size_pretty(pg_total_relation_size(quote_ident(table_name))) AS size,
    (SELECT COUNT(*) FROM information_schema.columns
     WHERE table_name = t.table_name AND table_schema = 'public') AS column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

\echo '';


-- ========================================================================
-- 4. 用户账号状态
-- ========================================================================
\echo '4️⃣  用户账号状态 (预期 2 个业务用户)';
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

SELECT
    CASE
        WHEN COUNT(*) = 0 THEN '❌ 业务用户未创建'
        WHEN COUNT(*) = 1 THEN '⚠️  仅创建了 1 个业务用户'
        WHEN COUNT(*) = 2 THEN '✅ 业务用户已创建'
        ELSE '⚠️  用户数量异常'
    END AS status,
    COUNT(*) AS user_count
FROM pg_roles
WHERE rolname IN ('wc_scf_service', 'wc_readonly');

-- 详细列表
SELECT
    rolname AS username,
    rolcanlogin AS can_login,
    rolconnlimit AS connection_limit,
    CASE
        WHEN rolconnlimit = -1 THEN '⚠️  无限制 (需要修复)'
        WHEN rolname = 'wc_scf_service' AND rolconnlimit = 50 THEN '✅ 正确'
        WHEN rolname = 'wc_scf_service' AND rolconnlimit != 50 THEN '❌ 错误 (应为 50)'
        WHEN rolname = 'wc_readonly' AND rolconnlimit = 10 THEN '✅ 正确'
        WHEN rolname = 'wc_readonly' AND rolconnlimit != 10 THEN '❌ 错误 (应为 10)'
        ELSE '⚠️  未知状态'
    END AS connection_limit_status
FROM pg_roles
WHERE rolname IN ('wc_scf_service', 'wc_readonly')
ORDER BY rolname;

\echo '';


-- ========================================================================
-- 5. 用户权限状态
-- ========================================================================
\echo '5️⃣  用户权限状态';
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

-- wc_scf_service 权限检查
SELECT 'wc_scf_service 权限' AS check_type;
SELECT
    CASE
        WHEN COUNT(DISTINCT privilege_type) = 4 THEN '✅ 权限完整 (SELECT/INSERT/UPDATE/DELETE)'
        WHEN COUNT(DISTINCT privilege_type) > 0 THEN '⚠️  部分权限 (需要检查)'
        ELSE '❌ 无权限'
    END AS status,
    STRING_AGG(DISTINCT privilege_type, ', ') AS granted_privileges
FROM information_schema.table_privileges
WHERE grantee = 'wc_scf_service'
  AND table_schema = 'public';

-- wc_readonly 权限检查
SELECT 'wc_readonly 权限' AS check_type;
SELECT
    CASE
        WHEN COUNT(DISTINCT privilege_type) = 1 AND MAX(privilege_type) = 'SELECT' THEN '✅ 权限正确 (仅 SELECT)'
        WHEN COUNT(DISTINCT privilege_type) > 1 THEN '⚠️  权限过多 (应仅 SELECT)'
        WHEN COUNT(DISTINCT privilege_type) = 0 THEN '❌ 无权限'
        ELSE '⚠️  未知状态'
    END AS status,
    STRING_AGG(DISTINCT privilege_type, ', ') AS granted_privileges
FROM information_schema.table_privileges
WHERE grantee = 'wc_readonly'
  AND table_schema = 'public';

\echo '';


-- ========================================================================
-- 6. 函数状态
-- ========================================================================
\echo '6️⃣  函数状态 (预期 4 个)';
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

SELECT
    CASE
        WHEN COUNT(*) = 0 THEN '❌ 未创建任何函数'
        WHEN COUNT(*) < 4 THEN '⚠️  部分函数已创建'
        WHEN COUNT(*) = 4 THEN '✅ 所有函数已创建'
        ELSE '⚠️  函数数量异常'
    END AS status,
    COUNT(*) AS function_count
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN ('hash_password', 'verify_password', 'update_updated_at_column', 'sync_poi_spatial_fields');

\echo '';


-- ========================================================================
-- 7. 种子数据状态
-- ========================================================================
\echo '7️⃣  种子数据状态';
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

DO $$
DECLARE
    poi_count INT;
    nav_count INT;
    table_exists BOOLEAN;
BEGIN
    -- 检查 poi_translations 表是否存在
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'poi_translations'
    ) INTO table_exists;

    IF table_exists THEN
        SELECT COUNT(*) INTO poi_count FROM poi_translations;
        RAISE NOTICE 'poi_translations: % 条记录 (预期: 76)', poi_count;

        IF poi_count = 0 THEN
            RAISE NOTICE '❌ POI 表为空 - 未导入种子数据';
        ELSIF poi_count < 76 THEN
            RAISE NOTICE '⚠️  POI 数据不完整';
        ELSIF poi_count = 76 THEN
            RAISE NOTICE '✅ POI 种子数据完整';
        ELSE
            RAISE NOTICE '✅ POI 表有 % 条记录 (超过种子数据)', poi_count;
        END IF;
    ELSE
        RAISE NOTICE '❌ poi_translations 表不存在';
    END IF;

    -- 检查 nav_instructions_i18n 表
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'nav_instructions_i18n'
    ) INTO table_exists;

    IF table_exists THEN
        SELECT COUNT(*) INTO nav_count FROM nav_instructions_i18n;
        RAISE NOTICE 'nav_instructions_i18n: % 条记录 (预期: ~26)', nav_count;

        IF nav_count = 0 THEN
            RAISE NOTICE '❌ 导航指令表为空';
        ELSIF nav_count >= 20 THEN
            RAISE NOTICE '✅ 导航指令数据已导入';
        ELSE
            RAISE NOTICE '⚠️  导航指令数据可能不完整';
        END IF;
    ELSE
        RAISE NOTICE '❌ nav_instructions_i18n 表不存在';
    END IF;
END $$;

\echo '';


-- ========================================================================
-- 8. 综合判断
-- ========================================================================
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
\echo '📊 综合判断';
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

DO $$
DECLARE
    ext_count INT;
    table_count INT;
    user_count INT;
    func_count INT;
BEGIN
    -- 统计各项状态
    SELECT COUNT(*) INTO ext_count FROM pg_extension
    WHERE extname IN ('uuid-ossp', 'postgis', 'postgis_topology', 'pgcrypto', 'pg_trgm');

    SELECT COUNT(*) INTO table_count FROM information_schema.tables
    WHERE table_schema = 'public' AND table_type = 'BASE TABLE';

    SELECT COUNT(*) INTO user_count FROM pg_roles
    WHERE rolname IN ('wc_scf_service', 'wc_readonly');

    SELECT COUNT(*) INTO func_count FROM information_schema.routines
    WHERE routine_schema = 'public'
      AND routine_name IN ('hash_password', 'verify_password', 'update_updated_at_column', 'sync_poi_spatial_fields');

    RAISE NOTICE '';
    RAISE NOTICE '当前状态统计:';
    RAISE NOTICE '  - 扩展: %/5', ext_count;
    RAISE NOTICE '  - 业务表: %/6', table_count;
    RAISE NOTICE '  - 业务用户: %/2', user_count;
    RAISE NOTICE '  - 函数: %/4', func_count;
    RAISE NOTICE '';

    -- 综合判断
    IF ext_count = 0 AND table_count = 0 AND user_count = 0 AND func_count = 0 THEN
        RAISE NOTICE '🔴 数据库状态: 完全未初始化';
        RAISE NOTICE '';
        RAISE NOTICE '📝 推荐操作:';
        RAISE NOTICE '   按顺序执行已更新的初始化脚本:';
        RAISE NOTICE '   1. 000_extensions.sql';
        RAISE NOTICE '   2. 001_functions.sql';
        RAISE NOTICE '   3. 002_tables.sql';
        RAISE NOTICE '   4. 003_permissions.sql';
        RAISE NOTICE '   5. 004_seed_data.sql';
        RAISE NOTICE '   6. 005_verify.sql';
    ELSIF ext_count = 5 AND table_count = 6 AND user_count = 2 AND func_count = 4 THEN
        RAISE NOTICE '🟢 数据库状态: 已完全初始化';
        RAISE NOTICE '';
        RAISE NOTICE '⚠️  但需要检查:';
        RAISE NOTICE '   - 用户密码是否正确 (执行 006_fix_permissions.sql 更新)';
        RAISE NOTICE '   - 用户连接限制是否设置';
    ELSIF ext_count > 0 OR table_count > 0 OR user_count > 0 OR func_count > 0 THEN
        RAISE NOTICE '🟡 数据库状态: 部分初始化（不完整）';
        RAISE NOTICE '';
        RAISE NOTICE '📝 推荐操作:';
        RAISE NOTICE '   执行修复脚本: 006_fix_permissions.sql';
        RAISE NOTICE '   然后补充缺失的初始化步骤';
    ELSE
        RAISE NOTICE '⚪ 数据库状态: 未知';
    END IF;

    RAISE NOTICE '';
END $$;

\echo '========================================';
\echo '检查完成';
\echo '========================================';
