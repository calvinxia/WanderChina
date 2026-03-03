-- ============================================================================
-- WanderChina 扩展安装脚本
-- ============================================================================

-- 1. UUID 生成扩展（用于主键）
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. PostGIS 地理空间扩展（核心，用于 POI 坐标）
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "postgis_topology";

-- 3. 密码哈希扩展（用于用户认证）
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 4. 模糊文本搜索扩展（用于景点名称搜索）
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- 5. 组合索引扩展（用于优化查询）
CREATE EXTENSION IF NOT EXISTS "btree_gin";

