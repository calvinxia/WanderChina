-- ============================================================================
-- WanderChina MVP — Step 5: 部署验证
-- ============================================================================
-- 执行身份: wanderchina_pg_prod
-- 用途:     部署完成后运行，确认所有组件正常
-- ============================================================================


-- ========================================================================
-- 1. 扩展检查（预期 5 个）
-- ========================================================================
SELECT '1. Extensions' AS check_section;

SELECT extname, extversion FROM pg_extension
WHERE extname IN ('uuid-ossp', 'postgis', 'postgis_topology', 'pgcrypto', 'pg_trgm')
ORDER BY extname;
-- 预期: 5 行


-- ========================================================================
-- 2. 表检查（预期 6 个: 5 业务表 + 1 导航指令表）
-- ========================================================================
SELECT '2. Tables' AS check_section;

SELECT table_name, pg_size_pretty(pg_total_relation_size(quote_ident(table_name)))
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;
-- 预期: nav_instructions_i18n, poi_translations, trip_days, trips, user_sessions, users


-- ========================================================================
-- 3. 索引检查
-- ========================================================================
SELECT '3. Indexes' AS check_section;

SELECT indexname, tablename
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
-- 预期: ~15 个索引（含主键索引）


-- ========================================================================
-- 4. 触发器检查
-- ========================================================================
SELECT '4. Triggers' AS check_section;

SELECT trigger_name, event_object_table, action_timing, event_manipulation
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;
-- 预期:
--   poi_translations: trg_poi_sync_spatial (INSERT/UPDATE), trg_poi_updated_at (UPDATE)
--   trips:            trg_trips_updated_at (UPDATE)
--   trip_days:        trg_trip_days_updated_at (UPDATE)
--   users:            trg_users_updated_at (UPDATE)


-- ========================================================================
-- 5. 函数检查
-- ========================================================================
SELECT '5. Functions' AS check_section;

SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN ('hash_password', 'verify_password', 'update_updated_at_column', 'sync_poi_spatial_fields')
ORDER BY routine_name;
-- 预期: 4 行


-- ========================================================================
-- 6. 用户与权限检查
-- ========================================================================
SELECT '6. Users & Permissions' AS check_section;

-- 用户存在
SELECT rolname, rolcanlogin FROM pg_roles
WHERE rolname IN ('wc_scf_service', 'wc_readonly');
-- 预期: 2 行

-- wc_scf_service 权限（应有 SELECT/INSERT/UPDATE/DELETE）
SELECT DISTINCT privilege_type
FROM information_schema.table_privileges
WHERE grantee = 'wc_scf_service'
  AND table_schema = 'public'
ORDER BY privilege_type;
-- 预期: DELETE, INSERT, SELECT, UPDATE

-- wc_readonly 权限（应仅有 SELECT）
SELECT DISTINCT privilege_type
FROM information_schema.table_privileges
WHERE grantee = 'wc_readonly'
  AND table_schema = 'public'
ORDER BY privilege_type;
-- 预期: SELECT


-- ========================================================================
-- 7. 种子数据检查
-- ========================================================================
SELECT '7. Seed Data' AS check_section;

-- POI 总数
SELECT COUNT(*) AS total_pois FROM poi_translations;
-- 预期: 76 (33 景点 + 43 地铁/交通枢纽)

-- 按城市统计
SELECT city, COUNT(*) AS count
FROM poi_translations
GROUP BY city
ORDER BY count DESC;

-- 按分类统计
SELECT category_en, COUNT(*) AS count
FROM poi_translations
GROUP BY category_en
ORDER BY count DESC;

-- 导航指令
SELECT COUNT(*) AS total_nav FROM nav_instructions_i18n;
-- 预期: ~26


-- ========================================================================
-- 8. PostGIS + Geohash 触发器验证
-- ========================================================================
SELECT '8. Spatial Trigger Test' AS check_section;

-- 检查 geohash 和 location 是否被触发器自动填充
SELECT
    gaode_poi_id,
    name_en,
    city,
    latitude,
    longitude,
    geohash,
    CASE WHEN location IS NOT NULL THEN 'OK' ELSE 'MISSING' END AS location_status
FROM poi_translations
WHERE gaode_poi_id IN ('SEED_BJ_A01', 'SEED_SH_A01', 'SEED_GZ_A01', 'SEED_CD_A03', 'SEED_XA_A01');
-- 预期: 5 行，全部 geohash 有值，location_status = 'OK'


-- ========================================================================
-- 9. 密码函数验证
-- ========================================================================
SELECT '9. Password Functions' AS check_section;

DO $$
DECLARE
    hashed TEXT;
    is_valid BOOLEAN;
BEGIN
    hashed := hash_password('TestPassword123!');
    is_valid := verify_password('TestPassword123!', hashed);

    IF is_valid THEN
        RAISE NOTICE '✅ Password hash/verify: OK';
    ELSE
        RAISE EXCEPTION '❌ Password verify FAILED';
    END IF;

    -- 错误密码应返回 false
    is_valid := verify_password('WrongPassword', hashed);
    IF NOT is_valid THEN
        RAISE NOTICE '✅ Wrong password rejected: OK';
    ELSE
        RAISE EXCEPTION '❌ Wrong password was NOT rejected';
    END IF;
END $$;


-- ========================================================================
-- 10. DML 权限验证（以 wc_scf_service 身份执行）
-- ========================================================================
SELECT '10. SCF Service Permission Test' AS check_section;

-- ⚠️ 以下测试需要切换到 wc_scf_service 用户连接
-- 如果用管理员执行，可以跳过此段

-- 测试 INSERT
-- INSERT INTO users (device_id, preferred_lang) VALUES ('test_device_001', 'en');

-- 测试 SELECT
-- SELECT * FROM users WHERE device_id = 'test_device_001';

-- 测试 UPDATE
-- UPDATE users SET display_name = 'Test User' WHERE device_id = 'test_device_001';

-- 测试 DELETE（清理测试数据）
-- DELETE FROM users WHERE device_id = 'test_device_001';

-- 测试 DDL（应该失败）
-- CREATE TABLE test_ddl (id INT);  -- 预期: ERROR: permission denied


-- ========================================================================
-- 11. Geohash 空间查询验证
-- ========================================================================
SELECT '11. Geohash Query Test' AS check_section;

-- 按 geohash 前缀查询（模拟 get_nearby_pois 云函数逻辑）
-- 查询故宫附近的 POI（geohash 前缀应该相同）
SELECT gaode_poi_id, name_en, category_en, geohash,
       ST_Distance(
           location,
           ST_SetSRID(ST_MakePoint(116.3972, 39.9163), 4326)::geography
       ) AS distance_meters
FROM poi_translations
WHERE geohash LIKE (
    SELECT LEFT(geohash, 5) FROM poi_translations WHERE gaode_poi_id = 'SEED_BJ_A01'
) || '%'
ORDER BY distance_meters
LIMIT 10;
-- 预期: 返回故宫周边的 POI（天安门、国家博物馆等）


-- ========================================================================
-- 完成
-- ========================================================================
SELECT '========================================' AS divider;
SELECT '✅ 验证完成 — 如果以上全部通过，数据库部署成功' AS result;
SELECT '下一步: 关闭外网访问，开始 Phase 3 (Redis)' AS next_step;
