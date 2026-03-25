-- ============================================================================
-- WanderChina MVP — Step 2: 数据表
-- ============================================================================
-- 执行身份: wanderchina_pg_prod
-- 依赖:     000_extensions.sql, 001_functions.sql
-- 表数量:   5 (poi_translations, users, user_sessions, trips, trip_days)
-- ============================================================================
--
-- 设计决策记录（解决 Config v2.0 与部署文档差异）:
--
--   poi_translations.id          → BIGSERIAL（高德 POI 数量可达十万级）
--   poi_translations.gaode_poi_id → VARCHAR(20)（高德 POI ID 固定格式 B0xxxx，够用）
--   poi_translations.latitude    → DECIMAL(10,7)（精度到 ~1cm，保留最大精度）
--   poi_translations.longitude   → DECIMAL(10,7)（同上）
--   category 索引                → category_en（外国用户查询场景，en 优先）
--   users.password_hash          → TEXT（bcrypt 输出长度固定 60 字符，但 TEXT 更灵活）
--   user_sessions.token_family   → UUID（防重放攻击，语义更明确）
--   trip_days.id                 → BIGSERIAL（简单自增，无需 UUID）
--   updated_at 触发器            → 所有 5 张表统一配置
--   address_en/address_zh        → 保留（POI 详情页需要地址翻译）
--   last_accessed_at             → 保留（统计 POI 热度用于优先级排序）
--
-- ============================================================================


-- ========================================================================
-- Table 1: poi_translations — 地图翻译蒙层核心表
-- ========================================================================
-- 数据流: 高德 POI → DeepSeek 翻译 → 写入此表 → get_nearby_pois 云函数读取
-- 查询模式:
--   1. geohash 前缀查询（地图视窗批量拉取，命中 Redis 缓存）
--   2. PostGIS 空间范围查询（geohash 未覆盖时的 fallback）
--   3. city + priority_score DESC（启动时预加载高优先级 POI）
--   4. gaode_poi_id 精确查询（单个 POI 详情）

CREATE TABLE IF NOT EXISTS poi_translations (
    id                  BIGSERIAL PRIMARY KEY,
    gaode_poi_id        VARCHAR(20) NOT NULL UNIQUE,

    -- 中文原文
    name_zh             VARCHAR(200) NOT NULL,
    category_zh         VARCHAR(100),
    address_zh          VARCHAR(500),

    -- 英文翻译
    name_en             VARCHAR(300),
    category_en         VARCHAR(100),
    address_en          VARCHAR(500),

    -- 法文翻译
    name_fr             VARCHAR(300),
    category_fr         VARCHAR(100),

    -- 西班牙文翻译
    name_es             VARCHAR(300),
    category_es         VARCHAR(100),

    -- 地理位置（GCJ-02 坐标系，高德原始坐标）
    latitude            DECIMAL(10, 7) NOT NULL,
    longitude           DECIMAL(10, 7) NOT NULL,
    location            GEOGRAPHY(POINT, 4326),     -- PostGIS，触发器自动填充
    geohash             VARCHAR(12),                 -- 精度 7，触发器自动填充

    -- 元数据
    city                VARCHAR(50) NOT NULL,
    district            VARCHAR(100),
    priority_score      INTEGER DEFAULT 50,          -- 0-100，越高越优先显示

    -- 翻译来源与质量
    source              VARCHAR(20) DEFAULT 'deepseek',  -- deepseek / manual / gaode / fallback
    confidence          DECIMAL(3, 2) DEFAULT 0.90,
    verified            BOOLEAN DEFAULT FALSE,

    -- 统计
    usage_count         INTEGER DEFAULT 0,
    last_accessed_at    TIMESTAMP WITH TIME ZONE,

    -- 时间戳
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- 约束: MVP 阶段仅支持 6 城市
    CONSTRAINT chk_poi_city CHECK (
        city IN ('北京', '上海', '广州', '深圳', '成都', '西安')
    )
);

-- ----- 索引 -----

-- PostGIS 空间索引（ST_DWithin 范围查询）
CREATE INDEX IF NOT EXISTS idx_poi_location_gist
    ON poi_translations USING GIST (location);

-- Geohash 前缀查询（LIKE 'ws10a%'，配合 Redis 缓存 key）
CREATE INDEX IF NOT EXISTS idx_poi_geohash
    ON poi_translations (geohash text_pattern_ops);

-- 城市 + 优先级（启动预加载 TOP N）
CREATE INDEX IF NOT EXISTS idx_poi_city_priority
    ON poi_translations (city, priority_score DESC);

-- 英文分类索引（按类型筛选 POI）
CREATE INDEX IF NOT EXISTS idx_poi_category_en
    ON poi_translations (category_en);

-- 中文分类索引（导入脚本按中文分类批量处理）
CREATE INDEX IF NOT EXISTS idx_poi_category_zh
    ON poi_translations (category_zh);

-- lat/lng 复合索引（兼容非 PostGIS 的简单范围查询）
CREATE INDEX IF NOT EXISTS idx_poi_latlng
    ON poi_translations (latitude, longitude);

-- ----- 触发器 -----

-- lat/lng 写入时自动计算 location + geohash（同时更新 updated_at）
CREATE TRIGGER trg_poi_sync_spatial
    BEFORE INSERT OR UPDATE OF latitude, longitude
    ON poi_translations
    FOR EACH ROW EXECUTE FUNCTION sync_poi_spatial_fields();

-- 非坐标字段变更时也更新 updated_at
CREATE TRIGGER trg_poi_updated_at
    BEFORE UPDATE ON poi_translations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- ========================================================================
-- Table 2: users — 用户表
-- ========================================================================
-- MVP 支持两种用户:
--   1. 匿名用户: 仅 device_id，可创建行程、使用地图翻译
--   2. 注册用户: email + password_hash，可跨设备同步

CREATE TABLE IF NOT EXISTS users (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- 认证信息（注册用户）
    email               VARCHAR(255) UNIQUE,
    password_hash       TEXT,                           -- bcrypt via hash_password()
    phone               VARCHAR(20) UNIQUE,

    -- 用户资料
    username            VARCHAR(50),
    display_name        VARCHAR(100),
    avatar_url          VARCHAR(500),                   -- COS 对象 URL
    preferred_lang      VARCHAR(5) DEFAULT 'en',        -- en / fr / es

    -- 设备标识（匿名用户）
    device_id           VARCHAR(100),

    -- 状态
    is_active           BOOLEAN DEFAULT TRUE,
    is_premium          BOOLEAN DEFAULT FALSE,
    premium_expires_at  TIMESTAMP WITH TIME ZONE,

    -- 统计
    trips_count         INTEGER DEFAULT 0,
    translations_count  INTEGER DEFAULT 0,

    -- 时间戳
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login_at       TIMESTAMP WITH TIME ZONE
);

-- ----- 索引 -----
CREATE INDEX IF NOT EXISTS idx_users_email     ON users (email)     WHERE email IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_users_phone     ON users (phone)     WHERE phone IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_users_device_id ON users (device_id) WHERE device_id IS NOT NULL;

-- ----- 触发器 -----
CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- ========================================================================
-- Table 3: user_sessions — 用户会话表
-- ========================================================================
-- JWT refresh token 管理
-- token_family: 令牌族 UUID，用于检测 refresh token 重放攻击
--   如果同一 token_family 出现两次刷新，说明 token 被盗用，撤销整个族

CREATE TABLE IF NOT EXISTS user_sessions (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- JWT 令牌
    refresh_token       TEXT NOT NULL UNIQUE,
    token_family        UUID NOT NULL DEFAULT uuid_generate_v4(),

    -- 设备信息
    device_id           VARCHAR(100),
    device_type         VARCHAR(20),                    -- ios / android
    app_version         VARCHAR(20),
    ip_address          INET,

    -- 状态
    is_revoked          BOOLEAN DEFAULT FALSE,

    -- 时间戳
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at          TIMESTAMP WITH TIME ZONE NOT NULL,
    last_used_at        TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ----- 索引 -----
CREATE INDEX IF NOT EXISTS idx_sessions_user    ON user_sessions (user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_refresh ON user_sessions (refresh_token) WHERE NOT is_revoked;
CREATE INDEX IF NOT EXISTS idx_sessions_expires ON user_sessions (expires_at);


-- ========================================================================
-- Table 4: trips — 行程表
-- ========================================================================
-- 匿名用户通过 device_id 关联，注册用户通过 user_id 关联
-- itinerary_json: DeepSeek 生成的完整行程 JSON，一次性存储
-- trip_days 表存储按天拆分的详情（方便查询和修改单天）

CREATE TABLE IF NOT EXISTS trips (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID REFERENCES users(id) ON DELETE SET NULL,
    device_id           VARCHAR(100),                   -- 匿名用户标识

    -- 行程基本信息
    title               VARCHAR(200) NOT NULL DEFAULT 'My Trip',
    description         TEXT,

    -- 城市与日期
    cities              TEXT[] NOT NULL,                 -- ['北京', '西安']
    start_date          DATE,
    end_date            DATE,
    duration_days       INTEGER NOT NULL DEFAULT 1,

    -- 预算
    budget_level        VARCHAR(20) DEFAULT 'medium',   -- budget / medium / luxury
    budget_amount       DECIMAL(10, 2),
    budget_currency     VARCHAR(3) DEFAULT 'CNY',

    -- 用户偏好（AI 生成行程的输入参数）
    interests           TEXT[],                         -- ['history', 'food', 'nature']
    travel_style        VARCHAR(50),                    -- backpacker / comfort / luxury

    -- AI 生成内容
    itinerary_json      JSONB,                          -- DeepSeek 完整响应
    generation_model    VARCHAR(50) DEFAULT 'deepseek-chat',

    -- 状态
    status              VARCHAR(20) DEFAULT 'draft',    -- draft / active / completed / archived
    is_public           BOOLEAN DEFAULT FALSE,

    -- 统计
    views_count         INTEGER DEFAULT 0,
    saves_count         INTEGER DEFAULT 0,

    -- 时间戳
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- 约束
    CONSTRAINT chk_trips_dates CHECK (
        end_date IS NULL OR start_date IS NULL OR end_date >= start_date
    ),
    CONSTRAINT chk_trips_duration CHECK (duration_days >= 1),
    CONSTRAINT chk_trips_status CHECK (
        status IN ('draft', 'active', 'completed', 'archived')
    ),
    CONSTRAINT chk_trips_budget_level CHECK (
        budget_level IN ('budget', 'medium', 'luxury')
    )
);

-- ----- 索引 -----
CREATE INDEX IF NOT EXISTS idx_trips_user    ON trips (user_id)    WHERE user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_trips_device  ON trips (device_id)  WHERE device_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_trips_cities  ON trips USING GIN (cities);
CREATE INDEX IF NOT EXISTS idx_trips_status  ON trips (status);
CREATE INDEX IF NOT EXISTS idx_trips_created ON trips (created_at DESC);

-- ----- 触发器 -----
CREATE TRIGGER trg_trips_updated_at
    BEFORE UPDATE ON trips
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- ========================================================================
-- Table 5: trip_days — 行程天数详情表
-- ========================================================================
-- 每天的具体活动安排，activities 为 JSONB 数组
--
-- activities 结构示例:
-- [
--   {
--     "order": 1,
--     "poi_id": "B000A8UJVW",
--     "name_zh": "故宫博物院",
--     "name_en": "Palace Museum",
--     "category": "Attraction",
--     "start_time": "09:00",
--     "duration_minutes": 180,
--     "transport_to_next": "subway",
--     "notes": "Arrive early to avoid crowds"
--   }
-- ]

CREATE TABLE IF NOT EXISTS trip_days (
    id                  BIGSERIAL PRIMARY KEY,
    trip_id             UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,

    day_number          INTEGER NOT NULL,               -- 第几天（1, 2, 3...）
    city                VARCHAR(50) NOT NULL,
    date                DATE,

    -- 当天活动
    activities          JSONB NOT NULL DEFAULT '[]'::jsonb,

    -- 概要
    summary             TEXT,
    estimated_cost      DECIMAL(10, 2),

    -- 时间戳
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- 约束: 同一行程内天数不重复
    UNIQUE (trip_id, day_number)
);

-- ----- 索引 -----
CREATE INDEX IF NOT EXISTS idx_trip_days_trip ON trip_days (trip_id);

-- ----- 触发器 -----
CREATE TRIGGER trg_trip_days_updated_at
    BEFORE UPDATE ON trip_days
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- ========================================================================
-- 完成: 5 张表创建完毕
-- ========================================================================
-- 验证:
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;
-- 应返回: poi_translations, trip_days, trips, user_sessions, users
