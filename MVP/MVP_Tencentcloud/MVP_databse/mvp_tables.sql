### 3.5 数据表设计

#### 3.5.1 poi_translations（POI 翻译表——地图蒙层核心）

```sql
CREATE TABLE IF NOT EXISTS poi_translations (
    id              SERIAL PRIMARY KEY,
    gaode_poi_id    TEXT NOT NULL UNIQUE,

    -- 中文原文
    name_zh         TEXT NOT NULL,
    category_zh     VARCHAR(100),
    address_zh      TEXT,

    -- 英文翻译
    name_en         TEXT NOT NULL,
    category_en     VARCHAR(100),
    address_en      TEXT,

    -- 法文翻译
    name_fr         TEXT,
    category_fr     VARCHAR(100),

    -- 西班牙文翻译
    name_es         TEXT,
    category_es     VARCHAR(100),

    -- 地理位置（GCJ-02 坐标系）
    latitude        DECIMAL(10, 7) NOT NULL,
    longitude       DECIMAL(10, 7) NOT NULL,
    location        GEOGRAPHY(POINT, 4326),    -- PostGIS 空间索引

    -- geohash（用于区域批量查询）
    geohash         VARCHAR(12),

    -- 元数据
    city            VARCHAR(50) NOT NULL,
    district        VARCHAR(100),
    priority_score  INTEGER DEFAULT 0,

    -- 翻译来源
    source          VARCHAR(50) DEFAULT 'deepseek',
    confidence      DECIMAL(3, 2) DEFAULT 0.9,
    verified        BOOLEAN DEFAULT false,

    -- 统计
    usage_count     INTEGER DEFAULT 0,
    last_accessed_at TIMESTAMP,

    -- 时间戳
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- 约束
    CONSTRAINT chk_poi_city CHECK (
        city IN ('北京', '上海', '广州', '深圳', '成都', '西安')
    )
);

-- ===== 索引 =====

-- PostGIS 空间索引（区域范围查询）
CREATE INDEX IF NOT EXISTS idx_poi_location_gist
    ON poi_translations USING GIST (location);

-- Geohash 前缀查询
CREATE INDEX IF NOT EXISTS idx_poi_geohash
    ON poi_translations (geohash text_pattern_ops);

-- 城市 + 优先级（预加载热门 POI）
CREATE INDEX IF NOT EXISTS idx_poi_city_priority
    ON poi_translations (city, priority_score DESC);

-- 分类索引
CREATE INDEX IF NOT EXISTS idx_poi_category
    ON poi_translations (category_en);

-- lat/lng 复合索引（兼容非 PostGIS 查询）
CREATE INDEX IF NOT EXISTS idx_poi_latlng
    ON poi_translations (latitude, longitude);

-- ===== 触发器：lat/lng → location + geohash 自动同步 =====

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

CREATE TRIGGER trg_poi_sync_spatial
    BEFORE INSERT OR UPDATE OF latitude, longitude
    ON poi_translations
    FOR EACH ROW EXECUTE FUNCTION sync_poi_spatial_fields();

-- 更新时间戳触发器（非坐标字段变更时也需要更新 updated_at）
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_poi_updated_at
    BEFORE UPDATE ON poi_translations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

#### 3.5.2 users（用户表）

```sql
CREATE TABLE IF NOT EXISTS users (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- 认证信息
    email           VARCHAR(255) UNIQUE,
    password_hash   TEXT,                         -- bcrypt 哈希
    phone           VARCHAR(20) UNIQUE,
    
    -- 用户资料
    username        VARCHAR(50),
    display_name    VARCHAR(100),
    avatar_url      TEXT,
    preferred_lang  VARCHAR(10) DEFAULT 'en',     -- en/fr/es
    
    -- 设备与匿名标识
    device_id       VARCHAR(255),                 -- MVP 阶段匿名用户标识
    
    -- 状态
    is_active       BOOLEAN DEFAULT true,
    is_premium      BOOLEAN DEFAULT false,
    premium_expires_at TIMESTAMP,
    
    -- 统计
    trips_count     INTEGER DEFAULT 0,
    translations_count INTEGER DEFAULT 0,
    
    -- 时间戳
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login_at   TIMESTAMP
);

-- 索引
CREATE INDEX idx_users_email ON users (email) WHERE email IS NOT NULL;
CREATE INDEX idx_users_phone ON users (phone) WHERE phone IS NOT NULL;
CREATE INDEX idx_users_device_id ON users (device_id) WHERE device_id IS NOT NULL;

-- 更新时间戳触发器
CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

#### 3.5.3 user_sessions（用户会话表）

```sql
CREATE TABLE IF NOT EXISTS user_sessions (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- JWT 令牌
    refresh_token   TEXT NOT NULL UNIQUE,
    token_family    UUID NOT NULL DEFAULT uuid_generate_v4(),  -- 令牌族（用于检测重放）
    
    -- 设备信息
    device_id       VARCHAR(255),
    device_type     VARCHAR(50),       -- ios / android
    app_version     VARCHAR(20),
    
    -- 状态
    is_revoked      BOOLEAN DEFAULT false,
    
    -- 时间戳
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at      TIMESTAMP NOT NULL,
    last_used_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sessions_user ON user_sessions (user_id);
CREATE INDEX idx_sessions_refresh ON user_sessions (refresh_token) WHERE NOT is_revoked;
CREATE INDEX idx_sessions_expires ON user_sessions (expires_at);
```

#### 3.5.4 trips（行程表）

```sql
CREATE TABLE IF NOT EXISTS trips (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID REFERENCES users(id) ON DELETE SET NULL,
    device_id       VARCHAR(255),                 -- 匿名用户也能创建行程
    
    -- 行程基本信息
    title           VARCHAR(200) NOT NULL,
    description     TEXT,
    
    -- 城市与日期
    cities          TEXT[] NOT NULL,               -- ['北京', '西安']
    start_date      DATE,
    end_date        DATE,
    duration_days   INTEGER NOT NULL DEFAULT 1,
    
    -- 预算
    budget_level    VARCHAR(20) DEFAULT 'medium',  -- budget / medium / luxury
    budget_amount   DECIMAL(10, 2),
    budget_currency VARCHAR(3) DEFAULT 'CNY',
    
    -- 用户偏好（生成行程时的输入）
    interests       TEXT[],                        -- ['history', 'food', 'nature']
    travel_style    VARCHAR(50),                   -- backpacker / comfort / luxury
    
    -- AI 生成内容
    itinerary_json  JSONB,                         -- DeepSeek 生成的完整行程 JSON
    generation_model VARCHAR(50) DEFAULT 'deepseek-chat',
    
    -- 状态
    status          VARCHAR(20) DEFAULT 'draft',   -- draft / active / completed / archived
    is_public       BOOLEAN DEFAULT false,
    
    -- 统计
    views_count     INTEGER DEFAULT 0,
    saves_count     INTEGER DEFAULT 0,
    
    -- 时间戳
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 索引
CREATE INDEX idx_trips_user ON trips (user_id) WHERE user_id IS NOT NULL;
CREATE INDEX idx_trips_device ON trips (device_id) WHERE device_id IS NOT NULL;
CREATE INDEX idx_trips_cities ON trips USING GIN (cities);
CREATE INDEX idx_trips_status ON trips (status);
CREATE INDEX idx_trips_created ON trips (created_at DESC);

CREATE TRIGGER trg_trips_updated_at
    BEFORE UPDATE ON trips
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

#### 3.5.5 trip_days（行程天数详情表）

```sql
CREATE TABLE IF NOT EXISTS trip_days (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id         UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    
    day_number      INTEGER NOT NULL,              -- 第几天（1, 2, 3...）
    city            VARCHAR(50) NOT NULL,
    date            DATE,
    
    -- 当天活动（JSON 数组）
    activities      JSONB NOT NULL DEFAULT '[]',
    /*
    activities 结构示例:
    [
      {
        "order": 1,
        "poi_id": "B000A8UJVW",
        "name_zh": "故宫博物院",
        "name_en": "Palace Museum",
        "category": "Attraction",
        "start_time": "09:00",
        "duration_minutes": 180,
        "transport_to_next": "subway",
        "notes": "Arrive early to avoid crowds"
      }
    ]
    */
    
    -- 当天概要
    summary         TEXT,
    estimated_cost  DECIMAL(10, 2),
    
    -- 时间戳
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE (trip_id, day_number)
);

CREATE INDEX idx_trip_days_trip ON trip_days (trip_id);

CREATE TRIGGER trg_trip_days_updated_at
    BEFORE UPDATE ON trip_days
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

#### 3.5.6 其他翻译表（道路/站点/区域/指令/缓存）
-- Translation cache
CREATE TABLE public.translations_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    text_hash VARCHAR(64) NOT NULL,
    source_lang VARCHAR(10) NOT NULL,
    target_lang VARCHAR(10) NOT NULL,
    translation TEXT NOT NULL,
    confidence NUMERIC(3, 2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    UNIQUE (text_hash, source_lang, target_lang)
);

-- 存储道路、街道、大道等的中英文对照
CREATE TABLE IF NOT EXISTS road_translations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- 基本信息
    road_name_zh VARCHAR(200) NOT NULL,           -- 中文道路名称
    road_name_en VARCHAR(200) NOT NULL,           -- 英文道路名称
    city VARCHAR(50) NOT NULL,                    -- 所属城市
    district VARCHAR(100),                        -- 所属区域

    -- 道路类型
    road_type VARCHAR(50),                        -- 道路类型：高速/国道/省道/市道/街道
    road_level INTEGER DEFAULT 5,                 -- 道路等级：1-5（1最重要）

    -- 坐标信息（可选，用于精确匹配）
    start_lat DECIMAL(10, 7),                     -- 起点纬度
    start_lng DECIMAL(10, 7),                     -- 起点经度
    end_lat DECIMAL(10, 7),                       -- 终点纬度
    end_lng DECIMAL(10, 7),                       -- 终点经度

    -- 翻译元数据
    translation_source VARCHAR(50) DEFAULT 'manual',  -- 翻译来源：manual/api/community
    translation_confidence DECIMAL(3, 2) DEFAULT 1.0, -- 翻译置信度 0.0-1.0
    verified BOOLEAN DEFAULT false,                   -- 是否已人工验证

    -- 使用统计
    usage_count INTEGER DEFAULT 0,                -- 使用次数

    -- 时间戳
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- 索引
    CONSTRAINT road_translations_unique UNIQUE (road_name_zh, city)
);

-- 创建索引
CREATE INDEX idx_road_translations_city ON road_translations(city);
CREATE INDEX idx_road_translations_zh ON road_translations(road_name_zh);
CREATE INDEX idx_road_translations_level ON road_translations(road_level);
CREATE INDEX idx_road_translations_verified ON road_translations(verified);

-- 添加注释
COMMENT ON TABLE road_translations IS '道路名称中英文翻译表';
COMMENT ON COLUMN road_translations.road_level IS '道路等级：1=高速/主干道, 2=国道/城市快速路, 3=省道/主要街道, 4=市道/次要街道, 5=小路/巷道';

-- 2. 公交站点翻译表
-- ============================================================================
-- 存储公交站、地铁站等交通站点的中英文对照
CREATE TABLE IF NOT EXISTS transit_station_translations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- 基本信息
    station_name_zh VARCHAR(200) NOT NULL,        -- 中文站点名称
    station_name_en VARCHAR(200) NOT NULL,        -- 英文站点名称
    city VARCHAR(50) NOT NULL,                    -- 所属城市
    district VARCHAR(100),                        -- 所属区域

    -- 站点类型
    station_type VARCHAR(50) NOT NULL,            -- 站点类型：bus/metro/train/airport
    line_name_zh VARCHAR(100),                    -- 线路名称（中文）
    line_name_en VARCHAR(100),                    -- 线路名称（英文）
    line_number VARCHAR(50),                      -- 线路编号

    -- 坐标信息
    latitude DECIMAL(10, 7) NOT NULL,             -- 纬度
    longitude DECIMAL(10, 7) NOT NULL,            -- 经度

    -- 翻译元数据
    translation_source VARCHAR(50) DEFAULT 'manual',
    translation_confidence DECIMAL(3, 2) DEFAULT 1.0,
    verified BOOLEAN DEFAULT false,

    -- 使用统计
    usage_count INTEGER DEFAULT 0,

    -- 时间戳
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- 约束
    CONSTRAINT transit_station_unique UNIQUE (station_name_zh, city, station_type)
);

-- 创建索引
CREATE INDEX idx_transit_station_city ON transit_station_translations(city);
CREATE INDEX idx_transit_station_type ON transit_station_translations(station_type);
CREATE INDEX idx_transit_station_line ON transit_station_translations(line_number);
CREATE INDEX idx_transit_station_location ON transit_station_translations(latitude, longitude);
CREATE INDEX idx_transit_station_zh ON transit_station_translations(station_name_zh);

-- 添加注释
COMMENT ON TABLE transit_station_translations IS '公交/地铁站点中英文翻译表';
COMMENT ON COLUMN transit_station_translations.station_type IS '站点类型：bus=公交站, metro=地铁站, train=火车站, airport=机场';

-- ============================================================================
-- 3. 路线指令翻译表
-- ============================================================================
-- 存储路线规划中的导航指令模板（如"左转"、"右转"等）
CREATE TABLE IF NOT EXISTS route_instruction_translations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- 指令信息
    instruction_zh VARCHAR(200) NOT NULL,         -- 中文指令
    instruction_en VARCHAR(200) NOT NULL,         -- 英文指令
    instruction_type VARCHAR(50) NOT NULL,        -- 指令类型：turn/straight/arrive/depart

    -- 指令参数（用于动态替换）
    has_parameters BOOLEAN DEFAULT false,         -- 是否包含参数
    parameter_description TEXT,                   -- 参数说明

    -- 使用场景
    route_type VARCHAR(50),                       -- 适用路线类型：driving/walking/transit/riding

    -- 翻译元数据
    translation_source VARCHAR(50) DEFAULT 'manual',
    verified BOOLEAN DEFAULT true,

    -- 使用统计
    usage_count INTEGER DEFAULT 0,

    -- 时间戳
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- 约束
    CONSTRAINT route_instruction_unique UNIQUE (instruction_zh, instruction_type)
);

-- 创建索引
CREATE INDEX idx_route_instruction_type ON route_instruction_translations(instruction_type);
CREATE INDEX idx_route_instruction_route_type ON route_instruction_translations(route_type);

-- 添加注释
COMMENT ON TABLE route_instruction_translations IS '路线导航指令中英文翻译表';
COMMENT ON COLUMN route_instruction_translations.instruction_type IS '指令类型：turn=转弯, straight=直行, arrive=到达, depart=出发';

-- 存储区域、地标、商圈等的中英文对照
CREATE TABLE IF NOT EXISTS area_translations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- 基本信息
    area_name_zh VARCHAR(200) NOT NULL,           -- 中文区域名称
    area_name_en VARCHAR(200) NOT NULL,           -- 英文区域名称
    city VARCHAR(50) NOT NULL,                    -- 所属城市
    parent_area VARCHAR(100),                     -- 上级区域

    -- 区域类型
    area_type VARCHAR(50) NOT NULL,               -- 区域类型：district/business/landmark
    area_level INTEGER DEFAULT 3,                 -- 区域等级：1-5（1最重要）

    -- 边界信息（可选）
    boundary_polygon TEXT,                        -- 区域边界（GeoJSON格式）
    center_lat DECIMAL(10, 7),                    -- 中心点纬度
    center_lng DECIMAL(10, 7),                    -- 中心点经度

    -- 翻译元数据
    translation_source VARCHAR(50) DEFAULT 'manual',
    translation_confidence DECIMAL(3, 2) DEFAULT 1.0,
    verified BOOLEAN DEFAULT false,

    -- 使用统计
    usage_count INTEGER DEFAULT 0,

    -- 时间戳
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- 约束
    CONSTRAINT area_translations_unique UNIQUE (area_name_zh, city, area_type)
);

-- 创建索引
CREATE INDEX idx_area_translations_city ON area_translations(city);
CREATE INDEX idx_area_translations_type ON area_translations(area_type);
CREATE INDEX idx_area_translations_level ON area_translations(area_level);
CREATE INDEX idx_area_translations_zh ON area_translations(area_name_zh);

-- 添加注释
COMMENT ON TABLE area_translations IS '区域/地标中英文翻译表';
COMMENT ON COLUMN area_translations.area_type IS '区域类型：district=行政区, business=商圈, landmark=地标';

-- 存储运行时的翻译缓存（API翻译结果等）
CREATE TABLE IF NOT EXISTS translation_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- 缓存信息
    cache_key VARCHAR(500) NOT NULL,              -- 缓存键（原文+类型）
    source_text VARCHAR(500) NOT NULL,            -- 原文（中文）
    translated_text VARCHAR(500) NOT NULL,        -- 译文（英文）
    translation_type VARCHAR(50) NOT NULL,        -- 翻译类型：road/station/instruction/area
    city VARCHAR(50),                             -- 相关城市

    -- 翻译元数据
    translation_source VARCHAR(50) NOT NULL,      -- 翻译来源：api/manual/dictionary
    translation_confidence DECIMAL(3, 2),         -- 翻译置信度

    -- 缓存管理
    hit_count INTEGER DEFAULT 0,                  -- 命中次数
    last_accessed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- 最后访问时间
    expires_at TIMESTAMP,                         -- 过期时间

    -- 时间戳
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- 约束
    CONSTRAINT translation_cache_unique UNIQUE (cache_key, translation_type)
);

-- 创建索引
CREATE INDEX idx_translation_cache_key ON translation_cache(cache_key);
CREATE INDEX idx_translation_cache_type ON translation_cache(translation_type);
CREATE INDEX idx_translation_cache_city ON translation_cache(city);
CREATE INDEX idx_translation_cache_expires ON translation_cache(expires_at);

-- 添加注释
COMMENT ON TABLE translation_cache IS '翻译结果缓存表';