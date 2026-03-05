-- ============================================================================
-- WanderChina MVP — Step 0: PostgreSQL 扩展安装
-- ============================================================================
-- 目标数据库: wanderchina (腾讯云 PostgreSQL 16)
-- 执行身份:   wanderchina_pg_prod (超级管理员)
-- 版本:       MVP v2.0
-- 日期:       2026-03-04
-- ============================================================================

-- UUID 主键生成
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- PostGIS 空间索引（POI 地理查询 + geohash 自动计算）
CREATE EXTENSION IF NOT EXISTS "postgis";

-- 密码哈希（bcrypt，用于 user_auth 云函数）
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 模糊文本搜索（POI 名称搜索，后续使用）
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============================================================================
-- 验证
-- ============================================================================
-- 执行后应返回 4 行:
SELECT extname, extversion FROM pg_extension
WHERE extname IN ('uuid-ossp', 'postgis', 'pgcrypto', 'pg_trgm')
ORDER BY extname;
