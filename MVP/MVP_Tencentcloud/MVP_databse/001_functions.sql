-- ============================================================================
-- WanderChina MVP — Step 1: 公共函数
-- ============================================================================
-- 执行身份: wanderchina_pg_prod
-- 依赖:     000_extensions.sql (pgcrypto, postgis)
-- ============================================================================

-- ============================================================================
-- 1. 密码哈希函数（user_auth 云函数调用）
-- ============================================================================

-- 哈希密码 (bcrypt, cost=10)
CREATE OR REPLACE FUNCTION hash_password(password TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN crypt(password, gen_salt('bf', 10));
END;
$$ LANGUAGE plpgsql IMMUTABLE SECURITY DEFINER;

-- 验证密码
CREATE OR REPLACE FUNCTION verify_password(password TEXT, password_hash TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN password_hash = crypt(password, password_hash);
END;
$$ LANGUAGE plpgsql IMMUTABLE SECURITY DEFINER;

COMMENT ON FUNCTION hash_password(TEXT)       IS 'bcrypt 哈希，云函数注册时调用';
COMMENT ON FUNCTION verify_password(TEXT,TEXT) IS 'bcrypt 校验，云函数登录时调用';

-- ============================================================================
-- 2. updated_at 自动更新触发器函数（所有表共用）
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_updated_at_column()
    IS '通用触发器: INSERT/UPDATE 时自动刷新 updated_at';

-- ============================================================================
-- 3. poi_translations 空间字段自动同步触发器函数
-- ============================================================================
-- 当 latitude/longitude 写入或更新时，自动计算:
--   location  → PostGIS GEOGRAPHY(POINT, 4326)，用于空间范围查询
--   geohash   → 精度 7（约 150m×150m），用于 Redis 缓存 key 和前缀查询

CREATE OR REPLACE FUNCTION sync_poi_spatial_fields()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
        NEW.location := ST_SetSRID(
            ST_MakePoint(NEW.longitude, NEW.latitude), 4326
        )::geography;
        NEW.geohash := ST_GeoHash(
            ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326), 7
        );
    END IF;
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION sync_poi_spatial_fields()
    IS 'poi_translations 专用: lat/lng → location(PostGIS) + geohash(精度7) 自动同步';
