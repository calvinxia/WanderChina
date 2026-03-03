-- ============================================================================
-- 地图翻译层数据库表结构
-- ============================================================================
-- 用于存储地图元素的中英文翻译数据
-- 支持城市：北京、上海、广州、深圳、成都、西安
-- 创建日期：2026-01-28
-- ============================================================================

-- 启用UUID扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- 1. 道路名称翻译表
-- ============================================================================
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

-- ============================================================================
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

-- ============================================================================
-- 4. 区域/地名翻译表
-- ============================================================================
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

-- ============================================================================
-- 5. 翻译缓存表
-- ============================================================================
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

-- ============================================================================
-- 6. 翻译反馈表（可选）
-- ============================================================================
-- 用户可以报告错误或建议更好的翻译
CREATE TABLE IF NOT EXISTS translation_feedback (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- 反馈信息
    translation_type VARCHAR(50) NOT NULL,        -- 翻译类型
    reference_id UUID,                            -- 关联的翻译记录ID

    original_text VARCHAR(500) NOT NULL,          -- 原文
    current_translation VARCHAR(500) NOT NULL,    -- 当前翻译
    suggested_translation VARCHAR(500),           -- 建议翻译

    -- 反馈详情
    feedback_type VARCHAR(50) NOT NULL,           -- 反馈类型：error/improvement/missing
    feedback_comment TEXT,                        -- 反馈说明

    -- 用户信息
    user_id UUID,                                 -- 用户ID
    city VARCHAR(50),                             -- 城市

    -- 处理状态
    status VARCHAR(50) DEFAULT 'pending',         -- 状态：pending/reviewed/accepted/rejected
    admin_notes TEXT,                             -- 管理员备注
    processed_by UUID,                            -- 处理人
    processed_at TIMESTAMP,                       -- 处理时间

    -- 时间戳
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX idx_translation_feedback_type ON translation_feedback(translation_type);
CREATE INDEX idx_translation_feedback_status ON translation_feedback(status);
CREATE INDEX idx_translation_feedback_user ON translation_feedback(user_id);

-- 添加注释
COMMENT ON TABLE translation_feedback IS '用户翻译反馈表';
COMMENT ON COLUMN translation_feedback.feedback_type IS '反馈类型：error=错误翻译, improvement=改进建议, missing=缺失翻译';

-- ============================================================================
-- 触发器：自动更新updated_at字段
-- ============================================================================

-- 创建更新时间戳的函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为所有表添加触发器
CREATE TRIGGER update_road_translations_updated_at BEFORE UPDATE ON road_translations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_transit_station_translations_updated_at BEFORE UPDATE ON transit_station_translations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_route_instruction_translations_updated_at BEFORE UPDATE ON route_instruction_translations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_area_translations_updated_at BEFORE UPDATE ON area_translations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_translation_cache_updated_at BEFORE UPDATE ON translation_cache
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_translation_feedback_updated_at BEFORE UPDATE ON translation_feedback
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 视图：快速查询常用翻译
-- ============================================================================

-- 高优先级道路翻译视图
CREATE OR REPLACE VIEW high_priority_roads AS
SELECT
    city,
    road_name_zh,
    road_name_en,
    road_type,
    road_level,
    verified
FROM road_translations
WHERE road_level <= 2 AND verified = true
ORDER BY city, road_level;

-- 验证过的站点翻译视图
CREATE OR REPLACE VIEW verified_stations AS
SELECT
    city,
    station_type,
    station_name_zh,
    station_name_en,
    line_name_en,
    latitude,
    longitude
FROM transit_station_translations
WHERE verified = true
ORDER BY city, station_type, line_number;

-- ============================================================================
-- 完成
-- ============================================================================

COMMENT ON SCHEMA public IS '地图翻译层数据库 - 支持北京、上海、广州、深圳、成都、西安';
