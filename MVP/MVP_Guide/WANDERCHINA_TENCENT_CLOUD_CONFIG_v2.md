# WanderChina — 腾讯云服务配置指南（v2.0）

**适用阶段：** MVP → Early Growth  
**更新日期：** 2026-03-02  
**架构决策：** 腾讯云（主服务）+ Cloudflare R2（静态资源/备份）  
**变更说明：** 基于 v1.0 三轮审查（31 项调整）后的完整重写版，消除所有冲突和重复

---

## 目录

1. [整体架构](#1-整体架构)
2. [账号与基础配置](#2-账号与基础配置)
3. [PostgreSQL 数据库](#3-postgresql-数据库)
4. [Redis 缓存](#4-redis-缓存)
5. [对象存储 COS](#5-对象存储-cos)
6. [CDN 内容分发](#6-cdn-内容分发)
7. [云函数 SCF](#7-云函数-scf)
8. [安全配置](#8-安全配置)
9. [监控与告警](#9-监控与告警)
10. [Cloudflare R2](#10-cloudflare-r2)
11. [Flutter 端配置](#11-flutter-端配置)
12. [费用估算](#12-费用估算)
13. [上线检查清单](#13-上线检查清单)

---

## 1. 整体架构

```
┌─────────────────────────────────────────────────────────────┐
│                  Flutter App (iOS / Android)                  │
│  ∙ 高德地图 SDK（中文底图 + 翻译蒙层）                         │
│  ∙ sqflite（本地翻译缓存/离线行程）                            │
│  ∙ 云函数 URL（HTTPS 调用，App 内无任何数据库密钥）              │
└─────────────────────────────────────────────────────────────┘
         │                              │
         ▼                              ▼
  ┌──────────────────┐           ┌──────────────────┐
  │  公网云函数（4个）  │           │  内网云函数（4个）  │
  │  不启用 VPC       │           │  启用 VPC         │
  ├──────────────────┤           ├──────────────────┤
  │ deepseek_translate│           │ translate_db_write│
  │ baidu_voice_asr  │           │ get_nearby_pois   │
  │ baidu_voice_tts  │           │ user_auth         │
  │ get_cos_token    │           │ create_trip       │
  └──────────────────┘           └──────────────────┘
         │                              │
         ▼                              ▼
  ┌──────────────────┐           ┌──────────────────┐
  │ DeepSeek API     │           │ PostgreSQL 1C2G  │
  │ 百度语音 API      │           │  双机高可用       │
  │ 腾讯云 STS       │           │ Redis 1GB 主从   │
  └──────────────────┘           └──────────────────┘
                                        │
                                 ┌──────────────────┐
                                 │ COS 对象存储      │
                                 │（静态资源 + 离线包）│
                                 └──────────────────┘
                                        │
                                 ┌──────────────────┐
                                 │ Cloudflare R2    │
                                 │（备份 + 海外 CDN） │
                                 └──────────────────┘

核心设计原则:
  ① App 不存储任何后端密钥（通过云函数隔离）
  ② 拆分公网/内网函数，跳过 NAT 网关（节省 ¥360/月）
  ③ 函数 URL 触发器取代已废弃的 API 网关（2025-06-30 下线）
```

---

## 2. 账号与基础配置

### 2.1 注册与实名认证

```
1. 访问 cloud.tencent.com 注册账号
2. 完成个人实名认证（身份证 + 手机号）
   - 如需 ICP 备案自定义域名，建议升级为企业认证
3. 开通子账号（CAM）：建议不直接使用主账号操作
```

### 2.2 地域选择

```yaml
首选地域: 广州（ap-guangzhou）
  原因: Calvin 在广州，运维方便；覆盖华南，到北上成西延迟 < 30ms

备选地域: 上海（ap-shanghai）
  原因: 如用户以华东为主时可迁移
```

> 所有服务（PostgreSQL / Redis / COS / SCF）**必须在同一地域**，否则内网流量需额外付费。

### 2.3 VPC 私有网络配置

```
VPC 名称:     wanderchina-vpc
网段:         172.16.0.0/16

子网规划:
  数据库子网:  172.16.1.0/24   (ap-guangzhou-3)
  缓存子网:   172.16.2.0/24   (ap-guangzhou-3)
  应用子网:   172.16.3.0/24   (ap-guangzhou-3)
```

**操作路径：** 控制台 → 私有网络 → 新建 VPC

---

## 3. PostgreSQL 数据库

### 3.1 产品选择

**使用：云数据库 PostgreSQL（标准版）**

> TDSQL-C PostgreSQL 版本已停售，当前只有标准版可用。

### 3.2 创建实例

**操作路径：** 控制台 → 数据库 → 云数据库 PostgreSQL → 新建实例

```yaml
计费模式:    按量计费（MVP 推荐）或 包年包月（稳定后转）
地域:        广州
可用区:      广州六区
数据库版本:  PostgreSQL 14.x
实例名:      wanderchina-pg-prod

规格配置:
  内存规格:  1核2GB（MVP 阶段）
             → 成长期可升级为 2核4GB、4核8GB
  存储类型:  SSD 云盘
  存储空间:  20 GB（可在线扩容至 6000GB）

架构版本:    双机高可用（自动主备切换，为潜在需求预留余量）

网络:
  VPC:       wanderchina-vpc
  子网:      数据库子网 172.16.1.0/24

安全组:      wanderchina-db-sg（见第8节）
访问密码:    [生成强密码，≥16位，含大小写+数字+符号]
```

**费用预估（1核2GB 双机高可用）：**
- 按量计费：约 ¥0.45/小时 = ¥324/月
- 包年包月：约 ¥260/月（节省 20%）

### 3.3 PostGIS 扩展安装

```sql
-- 连接数据库后执行
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- 验证
SELECT PostGIS_Version();
```

### 3.4 数据库用户权限管理

```
wanderchina_pg_prod (超级管理员)
  用途: 建表、修改结构、执行 SQL 脚本
  权限: SUPERUSER
  使用场景: 仅用于数据库维护和初始化

wc_scf_service (云函数专用用户)
  用途: 云函数连接数据库执行业务操作
  权限: SELECT, INSERT, UPDATE, DELETE（无 DDL 权限）
  使用场景: 所有云函数

wc_readonly (只读用户，可选)
  用途: 数据分析、报表查询
  权限: SELECT ONLY
```

**创建专用数据库：**

```sql
CREATE DATABASE wanderchina
    WITH 
    OWNER = wanderchina_pg_prod
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;

\c wanderchina

-- 安装扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
```

**创建云函数专用用户（仅 DML，无 DDL）：**

```sql
CREATE USER wc_scf_service WITH PASSWORD 'ScfService@2026#Secure';

GRANT CONNECT ON DATABASE wanderchina TO wc_scf_service;
GRANT USAGE ON SCHEMA public TO wc_scf_service;

-- 仅授予 DML 权限（SELECT/INSERT/UPDATE/DELETE）
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO wc_scf_service;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO wc_scf_service;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wc_scf_service;

-- 未来新建表的默认权限
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO wc_scf_service;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO wc_scf_service;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT EXECUTE ON FUNCTIONS TO wc_scf_service;

-- 限制连接数
ALTER USER wc_scf_service CONNECTION LIMIT 50;

-- 撤销 PUBLIC 的 CREATE 权限
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT CREATE ON SCHEMA public TO wanderchina_pg_prod;
```

**创建只读用户：**

```sql
CREATE USER wc_readonly WITH PASSWORD 'Readonly@2026#Safe';
GRANT CONNECT ON DATABASE wanderchina TO wc_readonly;
GRANT USAGE ON SCHEMA public TO wc_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO wc_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO wc_readonly;
ALTER USER wc_readonly CONNECTION LIMIT 10;
```

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

这些表在之前的 SQL 脚本中已设计，此处列出表名供参考：

```
✅ road_translations          — 道路名翻译
✅ transit_station_translations — 地铁/公交站翻译
✅ route_instruction_translations — 导航指令翻译
✅ area_translations           — 区域/地标翻译
✅ translation_cache           — 通用运行时翻译缓存
```

详细建表脚本见 `001_initial_schema.sql` 和 `002_row_level_security.sql`。

### 3.6 连接信息

```yaml
内网地址（VPC内，云函数使用）:
  Host:     172.16.1.x
  Port:     5432

外网地址（本地开发/pgAdmin 使用，可临时开启）:
  Host:     gz-cdb-xxxxxxxx.sql.tencentcdb.com
  Port:     26300
  SSL:      require
```

### 3.7 备份配置

```yaml
自动备份:
  备份频率:  每天一次
  备份时间:  凌晨 02:00–04:00
  保留天数:  7 天

手动备份:
  发版前手动触发一次备份快照
```

---

## 4. Redis 缓存

### 4.1 用途说明

```
缓存用途分类:
  ① POI 翻译热点缓存    TTL: 24h    约 50MB
  ② 区域 POI 列表缓存   TTL: 1h     约 30MB
  ③ 用户 Session        TTL: 7d     约 10MB
  ④ 高德 POI 搜索结果   TTL: 1h     约 30MB
  ⑤ 速率限制计数器      TTL: 2min   约 5MB

预估总使用量: 约 200MB（含冗余）
```

### 4.2 创建实例

```yaml
计费模式:    按量计费
地域:        广州（与 PostgreSQL 同区）
版本:        Redis 7.0
架构:        标准架构（主从版，1主1从）
内存规格:    1 GB（MVP 阶段足够，可在线扩容）
实例名:      wanderchina-redis-prod

网络:
  VPC:       wanderchina-vpc
  子网:      缓存子网 172.16.2.0/24

访问密码:    [生成强密码]
```

### 4.3 Key 命名规范（统一）

```
# ===== 翻译缓存 =====
poi:trans:{gaode_poi_id}:{lang}         → 单个 POI 翻译（TTL 24h）
  例: poi:trans:B000A7BD6F:en

geo:poi:{geohash_prefix5}:{lang}        → 区域 POI 列表 JSON（TTL 1h）
  例: geo:poi:wx4g0:en

# ===== 速率限制 =====
rl:nearby:{user_id}:{minute}            → 地图查询频率（TTL 120s）
rl:translate:{user_id}:{minute}         → 翻译请求频率（TTL 120s）
rl:deepseek:global:{second}             → DeepSeek 全局令牌桶（TTL 2s）

# ===== 会话 =====
session:{user_id}                       → 用户会话（TTL 7d）
  例: session:user_12345

# ===== 搜索缓存 =====
search:{city}:{keyword}:{page}          → 搜索结果（TTL 1h）
  例: search:北京:故宫:1
```

### 4.4 连接信息

```yaml
内网地址:
  Host:     172.16.2.x
  Port:     6379
  Auth:     [设置的密码]
```

---

## 5. 对象存储 COS

### 5.1 Bucket 规划

创建 **2 个 Bucket**：

**Bucket 1：静态资源（公有读）**

```yaml
名称:         wanderchina-static-[AppID]
地域:         广州
访问权限:     公有读私有写
用途:
  - 景点图片: attractions/{gaode_poi_id}.jpg
  - 城市缩略图: cities/{city_name}.jpg
  - 离线翻译包: offline/poi_translations_{city}_{version}.json
  - App 更新资源: app/assets/
```

**Bucket 2：用户内容（私有）**

```yaml
名称:         wanderchina-user-[AppID]
地域:         广州
访问权限:     私有读写
用途:
  - 用户头像: user/avatars/{user_id}.jpg
  - 行程封面: trips/covers/{trip_id}.jpg
  - (v2) 社区图片: posts/{post_id}/{img_index}.jpg
```

> 用户内容 Bucket 配合 `get_cos_token` 云函数使用——Flutter 通过临时凭证直传 COS，不经过后端。

### 5.2 CORS 配置

**静态资源 Bucket（公有读）：**

```json
{
  "CORSRules": [{
    "AllowedOrigins": ["*"],
    "AllowedMethods": ["GET"],
    "AllowedHeaders": ["*"],
    "MaxAgeSeconds": 86400
  }]
}
```

**用户内容 Bucket（私有，临时凭证直传）：**

```json
{
  "CORSRules": [{
    "AllowedOrigins": ["*"],
    "AllowedMethods": ["GET", "PUT", "POST"],
    "AllowedHeaders": ["*"],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3600
  }]
}
```

### 5.3 生命周期规则

```yaml
旧版本离线翻译包:
  前缀: offline/
  规则: 保留最新3个版本，更早的转至低频存储（节省70%存储费）
```

---

## 6. CDN 内容分发

### 6.1 MVP 阶段

**直接使用 COS 默认域名**，无需配置 CDN 自定义域名（避免 ICP 备案阻塞）：

```yaml
访问地址: https://wanderchina-static-[AppID].cos.ap-guangzhou.myqcloud.com
特点:
  ✅ 自带 HTTPS 证书
  ✅ 腾讯云全国节点加速
  ✅ 无需备案
  ✅ 无需申请 SSL 证书
```

### 6.2 正式上线后（可选）

配置自定义域名 `static.wanderchina.com` 需完成：
1. 个人认证升级企业认证
2. 域名实名认证满 3 天
3. ICP 备案（审核 7-20 工作日）
4. 申请腾讯云免费 SSL 证书（有效期 3 个月，50 张/账号额度）

---

## 7. 云函数 SCF（必需）

> **重要通知：** 腾讯云 API 网关已于 2025-06-30 停止服务。本文档使用**函数 URL**作为触发器（官方推荐替代方案），配置更简单且完全免费。

> **架构决策：** 拆分公网/内网函数，跳过 NAT 网关（节省 ¥360/月）。

> **费用提醒：** SCF 永久免费额度已于 2022-06-01 取消。新用户前 3 个月有免费试用套餐，之后按量计费。

### 7.1 为什么必须用云函数

**安全问题：** Flutter 直连后端服务需要在 App 内硬编码 PostgreSQL 密码、DeepSeek API Key、百度 API Key、COS 密钥等——这些密钥会被反编译提取。

**解决方案：** 云函数作为中间层，密钥保存在云端环境变量，App 只调用函数 URL。

```
Flutter App
    ↓ HTTPS（无密钥）
公网云函数（调用外部 API）
    ↓ 函数 URL 互相调用
内网云函数（访问数据库/Redis）
    ↓ VPC 内网
PostgreSQL / Redis
```

### 7.2 拆分云函数架构（跳过 NAT 网关）

```yaml
【公网函数】不启用 VPC
  作用: 调用外部 API（DeepSeek、百度语音）+ 下发 COS 凭证
  优势: 可以访问公网，无需 NAT 网关

  函数列表:
    ✅ deepseek_translate     (调用 DeepSeek 翻译 API)
    ✅ baidu_voice_asr        (调用百度语音识别)
    ✅ baidu_voice_tts        (调用百度语音合成)
    ✅ get_cos_token          (下发 COS 临时凭证)

【内网函数】启用 VPC
  作用: 访问内网数据库和 Redis
  优势: 高速内网连接，安全隔离

  函数列表:
    ✅ translate_db_write     (写入翻译结果到数据库 + Redis 缓存)
    ✅ get_nearby_pois        (按 geohash 查询附近 POI)
    ✅ user_auth              (用户注册/登录/匿名认证/资料管理)
    ✅ create_trip            (AI 行程生成 + 存储)
```

**架构图：**

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter App                             │
└─────────────────────────────────────────────────────────────┘
       │                      │                      │
       ▼                      ▼                      ▼
┌─────────────┐        ┌─────────────┐        ┌─────────────┐
│ 公网云函数   │        │ 内网云函数   │        │ 独立云函数   │
│ (无 VPC)    │        │ (VPC 内网)  │        │ (无 VPC)    │
│             │        │             │        │             │
│ deepseek_   │        │ translate_  │        │ get_cos_    │
│  translate  │        │  db_write   │        │  token      │
│ baidu_asr   │        │ get_nearby_ │        │             │
│ baidu_tts   │        │  pois       │        │             │
│             │        │ user_auth   │        │             │
│             │        │ create_trip │        │             │
└─────────────┘        └─────────────┘        └─────────────┘
       │                      │                      │
       ▼                      ▼                      ▼
DeepSeek API           PostgreSQL                COS STS API
百度语音 API            Redis
```

**成本对比：**

| 方案 | NAT 网关 | 月费 |
|------|---------|------|
| ❌ 传统方案（VPC + NAT） | 需要 | ¥360/月 |
| ✅ 拆分函数方案 | 不需要 | **¥0** |

### 7.3 通用工具：数据库连接（带自动重连）

所有内网函数共用此模块，解决 SCF 实例冻结后数据库断连问题：

```python
# shared/db_helper.py
import os
import psycopg2
import redis

_db_conn = None
_redis_client = None

def get_db_connection():
    """获取数据库连接（带心跳检测和自动重连）"""
    global _db_conn

    if _db_conn is not None:
        try:
            cur = _db_conn.cursor()
            cur.execute("SELECT 1")
            cur.close()
        except Exception:
            try:
                _db_conn.close()
            except Exception:
                pass
            _db_conn = None

    if _db_conn is None:
        _db_conn = psycopg2.connect(
            host=os.environ['DB_HOST'],
            port=int(os.environ.get('DB_PORT', 5432)),
            database=os.environ['DB_NAME'],
            user=os.environ['DB_USER'],
            password=os.environ['DB_PASSWORD'],
            sslmode='require',
            connect_timeout=10,
            keepalives=1,
            keepalives_idle=60,
            keepalives_interval=10,
            keepalives_count=3
        )

    return _db_conn

def get_redis_client():
    """获取 Redis 客户端（复用连接）"""
    global _redis_client

    if _redis_client is None:
        _redis_client = redis.Redis(
            host=os.environ['REDIS_HOST'],
            port=int(os.environ.get('REDIS_PORT', 6379)),
            password=os.environ.get('REDIS_PASSWORD', ''),
            decode_responses=True,
            socket_connect_timeout=5,
            socket_keepalive=True
        )
        _redis_client.ping()

    return _redis_client

def json_response(status_code, body_dict):
    """统一响应格式"""
    import json
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(body_dict, ensure_ascii=False)
    }

def parse_body(event):
    """解析请求体"""
    import json
    if isinstance(event, dict) and 'body' in event:
        return json.loads(event['body'])
    return event
```

### 7.4 公网函数 1：deepseek_translate

**基础配置：**

```yaml
函数名称:   deepseek_translate
运行环境:   Python 3.9
地域:       广州

执行配置:
  内存:       256 MB
  超时时间:   15 秒

网络配置:
  VPC:        不启用  ← 关键：可访问公网 DeepSeek API

环境变量:
  DEEPSEEK_KEY:  sk-xxxxxxxxxxxxxxxx

触发器:
  类型:       函数 URL
  鉴权方式:   免鉴权
  CORS:       开启（允许 POST, OPTIONS）
```

**函数代码 `index.py`：**

```python
# deepseek_translate/index.py
# -*- coding: utf-8 -*-
"""
DeepSeek 翻译云函数
- 支持 Prompt Caching（节省 90% 输入成本）
- MVP 仅支持 en/fr/es 三语种
- 成本精确计算（基于 V3.2 USD 定价 × 汇率）
"""
import json
import os
import requests

# DeepSeek V3.2 定价（USD → RMB）
USD_TO_CNY = 7.2
PRICE_INPUT_CACHED = 0.028 * USD_TO_CNY / 1_000_000     # $0.028/1M → ≈¥0.20/M
PRICE_INPUT_UNCACHED = 0.28 * USD_TO_CNY / 1_000_000    # $0.28/1M  → ≈¥2.02/M
PRICE_OUTPUT = 0.42 * USD_TO_CNY / 1_000_000             # $0.42/1M  → ≈¥3.02/M

# 固定 System Prompt（提高缓存命中率）
SYSTEM_PROMPTS = {
    'en': 'Translate the following Chinese text to English. Output only the translation, no explanations.',
    'fr': 'Translate the following Chinese text to French. Output only the translation, no explanations.',
    'es': 'Translate the following Chinese text to Spanish. Output only the translation, no explanations.',
}

SUPPORTED_LANGS = list(SYSTEM_PROMPTS.keys())

def translate_with_deepseek(text, target_lang):
    url = 'https://api.deepseek.com/v1/chat/completions'
    api_key = os.environ.get('DEEPSEEK_KEY')
    if not api_key:
        raise ValueError('Missing DEEPSEEK_KEY')

    headers = {
        'Authorization': f'Bearer {api_key}',
        'Content-Type': 'application/json'
    }

    payload = {
        'model': 'deepseek-chat',
        'messages': [
            {'role': 'system', 'content': SYSTEM_PROMPTS[target_lang]},
            {'role': 'user', 'content': text}
        ],
        'temperature': 0.3,
        'max_tokens': 100,
        'top_p': 0.9
    }

    try:
        response = requests.post(url, headers=headers, json=payload, timeout=10)
        response.raise_for_status()
        result = response.json()

        translated_text = result['choices'][0]['message']['content'].strip()

        usage = result.get('usage', {})
        prompt_tokens = usage.get('prompt_tokens', 0)
        completion_tokens = usage.get('completion_tokens', 0)
        prompt_details = usage.get('prompt_tokens_details', {})
        cached_tokens = prompt_details.get('cached_tokens', 0)
        uncached_tokens = prompt_tokens - cached_tokens

        cost = (
            uncached_tokens * PRICE_INPUT_UNCACHED +
            cached_tokens * PRICE_INPUT_CACHED +
            completion_tokens * PRICE_OUTPUT
        )

        cache_hit_rate = (cached_tokens / prompt_tokens * 100) if prompt_tokens > 0 else 0
        print(f"[TRANSLATE] '{text[:30]}' → '{translated_text[:30]}' | "
              f"tokens={prompt_tokens}(cached:{cached_tokens})+{completion_tokens} | "
              f"cache={cache_hit_rate:.0f}% | cost=¥{cost:.6f}")

        return {
            'translated_text': translated_text,
            'usage': {
                'prompt_tokens': prompt_tokens,
                'cached_tokens': cached_tokens,
                'completion_tokens': completion_tokens,
                'cache_hit_rate': cache_hit_rate
            },
            'cost': cost
        }

    except requests.exceptions.Timeout:
        raise Exception('DeepSeek API timeout')
    except requests.exceptions.HTTPError as e:
        raise Exception(f'DeepSeek API error: {e.response.status_code}')

def main_handler(event, context):
    try:
        if isinstance(event, dict) and 'body' in event:
            body = json.loads(event['body'])
        else:
            body = event

        text = body.get('text')
        target_lang = body.get('target_lang', 'en')

        if not text:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'Missing parameter: text'})
            }

        if target_lang not in SUPPORTED_LANGS:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': f'Unsupported language. Supported: {SUPPORTED_LANGS}'})
            }

        result = translate_with_deepseek(text, target_lang)

        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({
                'translated_text': result['translated_text'],
                'source_text': text,
                'target_lang': target_lang,
                'usage': result['usage'],
                'cost': result['cost']
            }, ensure_ascii=False)
        }

    except Exception as e:
        print(f'[ERROR] {str(e)}')
        import traceback; traceback.print_exc()
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': str(e)})
        }
```

**requirements.txt：**

```
requests==2.31.0
```

### 7.5 内网函数 1：translate_db_write

**基础配置：**

```yaml
函数名称:   translate_db_write
运行环境:   Python 3.9

执行配置:
  内存:       256 MB
  超时时间:   10 秒

网络配置:
  VPC:        启用  ← 关键：访问内网数据库
  VPC:        wanderchina-vpc
  子网:       应用子网（172.16.3.0/24）

环境变量:
  DB_HOST:         172.16.1.x
  DB_PORT:         5432
  DB_NAME:         wanderchina
  DB_USER:         wc_scf_service
  DB_PASSWORD:     ScfService@2026#Secure
  REDIS_HOST:      172.16.2.x
  REDIS_PORT:      6379
  REDIS_PASSWORD:  [设置的密码]

触发器:     函数 URL
```

**函数代码 `index.py`：**

```python
# translate_db_write/index.py
# -*- coding: utf-8 -*-
"""
翻译结果写入 + Redis 缓存查询
支持三种操作: get（查单语缓存）、batch_get（查多语缓存）、save（写入数据库+缓存）
"""
import json
import os
import psycopg2
import redis

# ===== 全局连接（复用） =====
_db_conn = None
_redis_client = None

def get_db_connection():
    global _db_conn
    if _db_conn is not None:
        try:
            cur = _db_conn.cursor()
            cur.execute("SELECT 1")
            cur.close()
        except Exception:
            try: _db_conn.close()
            except: pass
            _db_conn = None
    if _db_conn is None:
        _db_conn = psycopg2.connect(
            host=os.environ['DB_HOST'],
            port=int(os.environ.get('DB_PORT', 5432)),
            database=os.environ['DB_NAME'],
            user=os.environ['DB_USER'],
            password=os.environ['DB_PASSWORD'],
            sslmode='require',
            connect_timeout=10,
            keepalives=1, keepalives_idle=60,
            keepalives_interval=10, keepalives_count=3
        )
    return _db_conn

def get_redis_client():
    global _redis_client
    if _redis_client is None:
        _redis_client = redis.Redis(
            host=os.environ['REDIS_HOST'],
            port=int(os.environ.get('REDIS_PORT', 6379)),
            password=os.environ.get('REDIS_PASSWORD', ''),
            decode_responses=True,
            socket_connect_timeout=5,
            socket_keepalive=True
        )
        _redis_client.ping()
    return _redis_client

def json_response(status_code, body_dict):
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(body_dict, ensure_ascii=False)
    }

# ===== 缓存操作 =====

def cache_get(poi_id, lang):
    try:
        r = get_redis_client()
        return r.get(f"poi:trans:{poi_id}:{lang}")
    except Exception as e:
        print(f"[REDIS GET ERROR] {e}")
        return None

def cache_batch_get(poi_id, languages):
    """批量查询多语种缓存（1 次 Redis pipeline）"""
    try:
        r = get_redis_client()
        pipe = r.pipeline()
        for lang in languages:
            pipe.get(f"poi:trans:{poi_id}:{lang}")
        results = pipe.execute()
        return dict(zip(languages, results))
    except Exception as e:
        print(f"[REDIS BATCH ERROR] {e}")
        return {lang: None for lang in languages}

def cache_set(poi_id, lang, text, ttl=86400):
    try:
        r = get_redis_client()
        r.setex(f"poi:trans:{poi_id}:{lang}", ttl, text)
    except Exception as e:
        print(f"[REDIS SET ERROR] {e}")

# ===== 数据库操作 =====

def save_to_database(poi_id, name_zh, name_en, name_fr=None, name_es=None,
                     latitude=None, longitude=None, city=None, category_zh=None):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("""
            INSERT INTO poi_translations
            (gaode_poi_id, name_zh, name_en, name_fr, name_es,
             latitude, longitude, city, category_zh, source)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, 'deepseek')
            ON CONFLICT (gaode_poi_id) DO UPDATE SET
                name_en = EXCLUDED.name_en,
                name_fr = COALESCE(EXCLUDED.name_fr, poi_translations.name_fr),
                name_es = COALESCE(EXCLUDED.name_es, poi_translations.name_es),
                updated_at = NOW(),
                usage_count = poi_translations.usage_count + 1
        """, (poi_id, name_zh, name_en, name_fr, name_es,
              latitude, longitude, city, category_zh))
        conn.commit()
        print(f"[DB SAVED] POI {poi_id}")
    except Exception as e:
        conn.rollback()
        raise
    finally:
        cursor.close()

# ===== 主入口 =====

def main_handler(event, context):
    try:
        if isinstance(event, dict) and 'body' in event:
            body = json.loads(event['body'])
        else:
            body = event

        action = body.get('action', 'save')
        poi_id = body.get('poi_id')

        if not poi_id:
            return json_response(400, {'error': 'Missing poi_id'})

        # ===== action: get（查询单语缓存）=====
        if action == 'get':
            lang = body.get('target_lang', 'en')
            cached = cache_get(poi_id, lang)
            return json_response(200, {
                'poi_id': poi_id,
                'target_lang': lang,
                'cached': cached is not None,
                'translated_text': cached
            })

        # ===== action: batch_get（批量查询多语缓存）=====
        if action == 'batch_get':
            languages = body.get('languages', ['en', 'fr', 'es'])
            results = cache_batch_get(poi_id, languages)
            all_cached = all(v is not None for v in results.values())
            return json_response(200, {
                'poi_id': poi_id,
                'all_cached': all_cached,
                'translations': results
            })

        # ===== action: save（保存翻译到 DB + Redis）=====
        name_zh = body.get('name_zh')
        name_en = body.get('name_en')
        name_fr = body.get('name_fr')
        name_es = body.get('name_es')

        if not all([name_zh, name_en]):
            return json_response(400, {'error': 'Missing name_zh or name_en'})

        save_to_database(
            poi_id=poi_id,
            name_zh=name_zh,
            name_en=name_en,
            name_fr=name_fr,
            name_es=name_es,
            latitude=body.get('latitude'),
            longitude=body.get('longitude'),
            city=body.get('city'),
            category_zh=body.get('category_zh')
        )

        # 写入缓存
        cache_set(poi_id, 'en', name_en)
        if name_fr: cache_set(poi_id, 'fr', name_fr)
        if name_es: cache_set(poi_id, 'es', name_es)

        return json_response(200, {
            'success': True,
            'poi_id': poi_id
        })

    except Exception as e:
        print(f"[ERROR] {str(e)}")
        import traceback; traceback.print_exc()
        return json_response(500, {'error': str(e)})
```

**requirements.txt：**

```
psycopg2-binary==2.9.9
redis==5.0.1
```

### 7.6 内网函数 2：get_nearby_pois

**基础配置：** 与 translate_db_write 相同（VPC 启用，同环境变量）

```python
# get_nearby_pois/index.py
# -*- coding: utf-8 -*-
"""
按 geohash 前缀查询附近 POI
支持三层速率限制 + geohash 区域缓存
"""
import json
import os
import psycopg2
import redis
import time

_db_conn = None
_redis_client = None

def get_db_connection():
    global _db_conn
    if _db_conn is not None:
        try:
            cur = _db_conn.cursor(); cur.execute("SELECT 1"); cur.close()
        except Exception:
            try: _db_conn.close()
            except: pass
            _db_conn = None
    if _db_conn is None:
        _db_conn = psycopg2.connect(
            host=os.environ['DB_HOST'],
            port=int(os.environ.get('DB_PORT', 5432)),
            database=os.environ['DB_NAME'],
            user=os.environ['DB_USER'],
            password=os.environ['DB_PASSWORD'],
            sslmode='require', connect_timeout=10,
            keepalives=1, keepalives_idle=60,
            keepalives_interval=10, keepalives_count=3
        )
    return _db_conn

def get_redis_client():
    global _redis_client
    if _redis_client is None:
        _redis_client = redis.Redis(
            host=os.environ['REDIS_HOST'],
            port=int(os.environ.get('REDIS_PORT', 6379)),
            password=os.environ.get('REDIS_PASSWORD', ''),
            decode_responses=True,
            socket_connect_timeout=5, socket_keepalive=True
        )
        _redis_client.ping()
    return _redis_client

def json_response(code, body):
    return {
        'statusCode': code,
        'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
        'body': json.dumps(body, ensure_ascii=False)
    }

def check_rate_limit(user_id):
    """检查用户速率限制（60次/分钟）"""
    try:
        r = get_redis_client()
        minute = int(time.time()) // 60
        key = f"rl:nearby:{user_id}:{minute}"
        count = r.incr(key)
        if count == 1:
            r.expire(key, 120)
        return count <= 60
    except Exception:
        return True  # Redis 故障时放行

def main_handler(event, context):
    try:
        if isinstance(event, dict) and 'body' in event:
            body = json.loads(event['body'])
        else:
            body = event

        lat = body.get('latitude')
        lng = body.get('longitude')
        lang = body.get('lang', 'en')
        radius = min(body.get('radius', 2000), 5000)  # 最大 5km
        limit = min(body.get('limit', 50), 100)
        user_id = body.get('user_id', 'anonymous')

        if lat is None or lng is None:
            return json_response(400, {'error': 'Missing latitude/longitude'})

        # 速率限制
        if not check_rate_limit(user_id):
            return json_response(429, {'error': 'Rate limit exceeded (60/min)'})

        # 先查 geohash 区域缓存
        from hashlib import md5
        geohash_key = f"{round(lat, 2)}:{round(lng, 2)}:{lang}"
        cache_key = f"geo:poi:{md5(geohash_key.encode()).hexdigest()[:10]}:{lang}"

        try:
            r = get_redis_client()
            cached = r.get(cache_key)
            if cached:
                print(f"[CACHE HIT] {cache_key}")
                return json_response(200, json.loads(cached))
        except Exception:
            pass

        # 查询数据库
        conn = get_db_connection()
        cursor = conn.cursor()

        # 选择翻译列
        name_col = {'en': 'name_en', 'fr': 'name_fr', 'es': 'name_es'}.get(lang, 'name_en')
        cat_col = {'en': 'category_en', 'fr': 'category_fr', 'es': 'category_es'}.get(lang, 'category_en')

        cursor.execute(f"""
            SELECT
                gaode_poi_id,
                name_zh,
                {name_col} AS name_translated,
                {cat_col} AS category_translated,
                latitude,
                longitude,
                priority_score,
                ST_Distance(
                    location,
                    ST_SetSRID(ST_MakePoint(%s, %s), 4326)::geography
                ) AS distance_meters
            FROM poi_translations
            WHERE ST_DWithin(
                location,
                ST_SetSRID(ST_MakePoint(%s, %s), 4326)::geography,
                %s
            )
            AND {name_col} IS NOT NULL
            ORDER BY priority_score DESC, distance_meters ASC
            LIMIT %s
        """, (lng, lat, lng, lat, radius, limit))

        rows = cursor.fetchall()
        columns = ['poi_id', 'name_zh', 'name_translated', 'category',
                   'lat', 'lng', 'priority', 'distance']

        pois = []
        for row in rows:
            poi = dict(zip(columns, row))
            poi['distance'] = round(float(poi['distance']), 1)
            poi['lat'] = float(poi['lat'])
            poi['lng'] = float(poi['lng'])
            pois.append(poi)

        cursor.close()

        result = {
            'pois': pois,
            'count': len(pois),
            'center': {'lat': lat, 'lng': lng},
            'radius': radius,
            'lang': lang
        }

        # 写入区域缓存（1 小时）
        try:
            r = get_redis_client()
            r.setex(cache_key, 3600, json.dumps(result, ensure_ascii=False))
        except Exception:
            pass

        return json_response(200, result)

    except Exception as e:
        print(f"[ERROR] {str(e)}")
        import traceback; traceback.print_exc()
        return json_response(500, {'error': str(e)})
```

### 7.7 内网函数 3：user_auth

**基础配置：** VPC 启用，环境变量同 translate_db_write，额外增加：

```yaml
额外环境变量:
  JWT_SECRET:      [生成随机字符串，≥32位]
  JWT_EXPIRES_HOURS: 168    # 7 天
```

```python
# user_auth/index.py
# -*- coding: utf-8 -*-
"""
用户认证云函数
支持: 匿名注册（device_id）、邮箱注册/登录、Token 刷新
MVP 阶段以 device_id 匿名认证为主，邮箱注册为可选
"""
import json
import os
import psycopg2
import redis
import hashlib
import hmac
import time
import base64
import uuid

_db_conn = None
_redis_client = None

def get_db_connection():
    global _db_conn
    if _db_conn is not None:
        try:
            cur = _db_conn.cursor(); cur.execute("SELECT 1"); cur.close()
        except Exception:
            try: _db_conn.close()
            except: pass
            _db_conn = None
    if _db_conn is None:
        _db_conn = psycopg2.connect(
            host=os.environ['DB_HOST'],
            port=int(os.environ.get('DB_PORT', 5432)),
            database=os.environ['DB_NAME'],
            user=os.environ['DB_USER'],
            password=os.environ['DB_PASSWORD'],
            sslmode='require', connect_timeout=10,
            keepalives=1, keepalives_idle=60,
            keepalives_interval=10, keepalives_count=3
        )
    return _db_conn

def get_redis_client():
    global _redis_client
    if _redis_client is None:
        _redis_client = redis.Redis(
            host=os.environ['REDIS_HOST'],
            port=int(os.environ.get('REDIS_PORT', 6379)),
            password=os.environ.get('REDIS_PASSWORD', ''),
            decode_responses=True,
            socket_connect_timeout=5, socket_keepalive=True
        )
        _redis_client.ping()
    return _redis_client

def json_response(code, body):
    return {
        'statusCode': code,
        'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
        'body': json.dumps(body, ensure_ascii=False)
    }

# ===== JWT 简易实现（避免额外依赖） =====

def create_jwt(user_id, expires_hours=168):
    """生成简易 JWT（HMAC-SHA256）"""
    secret = os.environ['JWT_SECRET']
    header = base64.urlsafe_b64encode(json.dumps(
        {"alg": "HS256", "typ": "JWT"}).encode()).decode().rstrip('=')
    now = int(time.time())
    payload_data = {
        "sub": str(user_id),
        "iat": now,
        "exp": now + expires_hours * 3600
    }
    payload = base64.urlsafe_b64encode(
        json.dumps(payload_data).encode()).decode().rstrip('=')
    sig_input = f"{header}.{payload}"
    signature = base64.urlsafe_b64encode(
        hmac.new(secret.encode(), sig_input.encode(), hashlib.sha256).digest()
    ).decode().rstrip('=')
    return f"{header}.{payload}.{signature}"

def verify_jwt(token):
    """验证 JWT，返回 payload 或 None"""
    try:
        secret = os.environ['JWT_SECRET']
        parts = token.split('.')
        if len(parts) != 3:
            return None
        sig_input = f"{parts[0]}.{parts[1]}"
        expected_sig = base64.urlsafe_b64encode(
            hmac.new(secret.encode(), sig_input.encode(), hashlib.sha256).digest()
        ).decode().rstrip('=')
        if not hmac.compare_digest(parts[2], expected_sig):
            return None
        # 补齐 padding
        payload_str = parts[1] + '=' * (4 - len(parts[1]) % 4)
        payload = json.loads(base64.urlsafe_b64decode(payload_str))
        if payload.get('exp', 0) < time.time():
            return None
        return payload
    except Exception:
        return None

# ===== 密码哈希 =====

def hash_password(password):
    """bcrypt 风格哈希（使用 pgcrypto 在数据库端完成）"""
    # MVP 使用 SHA256 + salt，生产环境建议升级为 bcrypt
    salt = os.urandom(16).hex()
    hashed = hashlib.sha256(f"{salt}{password}".encode()).hexdigest()
    return f"{salt}${hashed}"

def verify_password(password, stored_hash):
    salt, hashed = stored_hash.split('$', 1)
    return hashlib.sha256(f"{salt}{password}".encode()).hexdigest() == hashed

# ===== 主入口 =====

def main_handler(event, context):
    try:
        if isinstance(event, dict) and 'body' in event:
            body = json.loads(event['body'])
        else:
            body = event

        action = body.get('action')
        conn = get_db_connection()
        cursor = conn.cursor()

        # ===== 匿名认证（device_id）=====
        if action == 'anonymous_auth':
            device_id = body.get('device_id')
            if not device_id:
                return json_response(400, {'error': 'Missing device_id'})

            # 查找或创建匿名用户
            cursor.execute(
                "SELECT id, preferred_lang FROM users WHERE device_id = %s",
                (device_id,)
            )
            row = cursor.fetchone()

            if row:
                user_id = str(row[0])
                cursor.execute(
                    "UPDATE users SET last_login_at = NOW() WHERE id = %s",
                    (row[0],)
                )
            else:
                user_id = str(uuid.uuid4())
                preferred_lang = body.get('preferred_lang', 'en')
                cursor.execute("""
                    INSERT INTO users (id, device_id, preferred_lang, last_login_at)
                    VALUES (%s, %s, %s, NOW())
                """, (user_id, device_id, preferred_lang))

            conn.commit()
            cursor.close()

            token = create_jwt(user_id)

            # 存入 Redis session
            try:
                r = get_redis_client()
                r.setex(f"session:{user_id}", 7 * 86400, json.dumps({
                    'device_id': device_id,
                    'login_type': 'anonymous'
                }))
            except Exception:
                pass

            return json_response(200, {
                'user_id': user_id,
                'token': token,
                'is_new_user': row is None
            })

        # ===== 邮箱注册 =====
        elif action == 'register':
            email = body.get('email', '').strip().lower()
            password = body.get('password')
            username = body.get('username')

            if not email or not password:
                return json_response(400, {'error': 'Missing email or password'})
            if len(password) < 8:
                return json_response(400, {'error': 'Password must be >= 8 chars'})

            # 检查邮箱是否已注册
            cursor.execute("SELECT id FROM users WHERE email = %s", (email,))
            if cursor.fetchone():
                cursor.close()
                return json_response(409, {'error': 'Email already registered'})

            user_id = str(uuid.uuid4())
            pw_hash = hash_password(password)
            device_id = body.get('device_id')
            preferred_lang = body.get('preferred_lang', 'en')

            cursor.execute("""
                INSERT INTO users (id, email, password_hash, username,
                    device_id, preferred_lang, last_login_at)
                VALUES (%s, %s, %s, %s, %s, %s, NOW())
            """, (user_id, email, pw_hash, username, device_id, preferred_lang))

            conn.commit()
            cursor.close()

            token = create_jwt(user_id)
            return json_response(201, {
                'user_id': user_id,
                'token': token
            })

        # ===== 邮箱登录 =====
        elif action == 'login':
            email = body.get('email', '').strip().lower()
            password = body.get('password')

            if not email or not password:
                return json_response(400, {'error': 'Missing email or password'})

            cursor.execute(
                "SELECT id, password_hash FROM users WHERE email = %s AND is_active = true",
                (email,)
            )
            row = cursor.fetchone()
            if not row or not verify_password(password, row[1]):
                cursor.close()
                return json_response(401, {'error': 'Invalid credentials'})

            user_id = str(row[0])
            cursor.execute(
                "UPDATE users SET last_login_at = NOW() WHERE id = %s",
                (row[0],)
            )
            conn.commit()
            cursor.close()

            token = create_jwt(user_id)
            return json_response(200, {
                'user_id': user_id,
                'token': token
            })

        # ===== Token 验证 =====
        elif action == 'verify':
            token = body.get('token')
            if not token:
                return json_response(400, {'error': 'Missing token'})

            payload = verify_jwt(token)
            if not payload:
                return json_response(401, {'error': 'Invalid or expired token'})

            return json_response(200, {
                'valid': True,
                'user_id': payload['sub']
            })

        # ===== 获取用户资料 =====
        elif action == 'get_profile':
            user_id = body.get('user_id')
            if not user_id:
                return json_response(400, {'error': 'Missing user_id'})

            cursor.execute("""
                SELECT id, email, username, display_name, avatar_url,
                       preferred_lang, is_premium, premium_expires_at,
                       trips_count, translations_count,
                       created_at, last_login_at
                FROM users WHERE id = %s AND is_active = true
            """, (user_id,))
            row = cursor.fetchone()
            cursor.close()

            if not row:
                return json_response(404, {'error': 'User not found'})

            return json_response(200, {
                'user_id': str(row[0]),
                'email': row[1],
                'username': row[2],
                'display_name': row[3],
                'avatar_url': row[4],
                'preferred_lang': row[5],
                'is_premium': row[6],
                'trips_count': row[8],
                'translations_count': row[9],
                'created_at': str(row[10]),
                'last_login_at': str(row[11]) if row[11] else None
            })

        # ===== 更新用户资料 =====
        elif action == 'update_profile':
            user_id = body.get('user_id')
            if not user_id:
                return json_response(400, {'error': 'Missing user_id'})

            updates = []
            params = []
            for field in ['username', 'display_name', 'avatar_url', 'preferred_lang']:
                if field in body:
                    updates.append(f"{field} = %s")
                    params.append(body[field])

            if not updates:
                cursor.close()
                return json_response(400, {'error': 'No fields to update'})

            params.append(user_id)
            cursor.execute(
                f"UPDATE users SET {', '.join(updates)}, updated_at = NOW() "
                f"WHERE id = %s AND is_active = true",
                params
            )
            conn.commit()
            cursor.close()

            return json_response(200, {'success': True, 'user_id': user_id})

        else:
            cursor.close()
            return json_response(400, {
                'error': f'Unknown action: {action}. '
                         f'Supported: anonymous_auth, register, login, verify, '
                         f'get_profile, update_profile'
            })

    except Exception as e:
        print(f"[AUTH ERROR] {str(e)}")
        import traceback; traceback.print_exc()
        return json_response(500, {'error': str(e)})
```

### 7.8 内网函数 4：create_trip

**基础配置：** VPC 启用，环境变量同 translate_db_write，额外增加：

```yaml
额外环境变量:
  DEEPSEEK_TRIP_URL:  [deepseek_translate 函数 URL]
  # 注意：create_trip 是 VPC 内网函数，不能直接调用 DeepSeek API
  # 行程生成的 AI 调用通过请求公网函数 deepseek_translate 的函数 URL 实现
  # 或者：直接在 Flutter 端调用 DeepSeek，将结果传入 create_trip 保存
```

**设计说明：** create_trip 是 VPC 内网函数，无法直接访问公网 DeepSeek API。两种架构可选：

```
方案 A（推荐）：Flutter 端编排
  Flutter → deepseek_translate（公网函数，生成行程 JSON）
         → create_trip（内网函数，保存行程到 DB）
  优势: 简单，函数职责单一

方案 B：内网函数调用公网函数
  Flutter → create_trip（内网函数）
         → 内部 HTTP 调用 deepseek_translate 函数 URL
         → 保存到 DB
  劣势: 内网函数调公网函数 URL 需要 NAT 或 DNS 配置
```

**MVP 采用方案 A**——Flutter 负责编排，create_trip 仅负责存储：

```python
# create_trip/index.py
# -*- coding: utf-8 -*-
"""
行程创建与管理云函数
操作: create（创建行程）、get（获取行程）、list（列出用户行程）、update（更新行程）
Flutter 端负责调用 DeepSeek 生成行程 JSON，本函数仅负责持久化存储
"""
import json
import os
import psycopg2
import uuid

_db_conn = None

def get_db_connection():
    global _db_conn
    if _db_conn is not None:
        try:
            cur = _db_conn.cursor(); cur.execute("SELECT 1"); cur.close()
        except Exception:
            try: _db_conn.close()
            except: pass
            _db_conn = None
    if _db_conn is None:
        _db_conn = psycopg2.connect(
            host=os.environ['DB_HOST'],
            port=int(os.environ.get('DB_PORT', 5432)),
            database=os.environ['DB_NAME'],
            user=os.environ['DB_USER'],
            password=os.environ['DB_PASSWORD'],
            sslmode='require', connect_timeout=10,
            keepalives=1, keepalives_idle=60,
            keepalives_interval=10, keepalives_count=3
        )
    return _db_conn

def json_response(code, body):
    return {
        'statusCode': code,
        'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
        'body': json.dumps(body, ensure_ascii=False, default=str)
    }

def main_handler(event, context):
    try:
        if isinstance(event, dict) and 'body' in event:
            body = json.loads(event['body'])
        else:
            body = event

        action = body.get('action', 'create')
        conn = get_db_connection()
        cursor = conn.cursor()

        # ===== 创建行程 =====
        if action == 'create':
            trip_id = str(uuid.uuid4())
            user_id = body.get('user_id')         # UUID 或 None
            device_id = body.get('device_id')       # 匿名用户
            title = body.get('title', 'My Trip')
            cities = body.get('cities', [])
            duration_days = body.get('duration_days', 1)
            itinerary_json = body.get('itinerary')  # DeepSeek 生成的完整行程
            interests = body.get('interests', [])
            budget_level = body.get('budget_level', 'medium')
            start_date = body.get('start_date')
            end_date = body.get('end_date')

            if not cities:
                cursor.close()
                return json_response(400, {'error': 'Missing cities'})

            cursor.execute("""
                INSERT INTO trips
                (id, user_id, device_id, title, cities, duration_days,
                 itinerary_json, interests, budget_level, start_date, end_date, status)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, 'draft')
                RETURNING id, created_at
            """, (trip_id, user_id, device_id, title, cities, duration_days,
                  json.dumps(itinerary_json) if itinerary_json else None,
                  interests, budget_level, start_date, end_date))

            result = cursor.fetchone()

            # 如果有 itinerary，按天拆分存入 trip_days
            if itinerary_json and isinstance(itinerary_json, dict):
                days = itinerary_json.get('days', [])
                for day in days:
                    day_num = day.get('day_number', 1)
                    cursor.execute("""
                        INSERT INTO trip_days
                        (trip_id, day_number, city, activities, summary, estimated_cost)
                        VALUES (%s, %s, %s, %s, %s, %s)
                    """, (trip_id, day_num,
                          day.get('city', cities[0] if cities else ''),
                          json.dumps(day.get('activities', [])),
                          day.get('summary'),
                          day.get('estimated_cost')))

            # 更新用户行程计数
            if user_id:
                cursor.execute("""
                    UPDATE users SET trips_count = trips_count + 1
                    WHERE id = %s
                """, (user_id,))

            conn.commit()
            cursor.close()

            return json_response(201, {
                'trip_id': trip_id,
                'created_at': str(result[1])
            })

        # ===== 获取单个行程 =====
        elif action == 'get':
            trip_id = body.get('trip_id')
            if not trip_id:
                cursor.close()
                return json_response(400, {'error': 'Missing trip_id'})

            cursor.execute("""
                SELECT id, title, cities, duration_days, itinerary_json,
                       budget_level, interests, status, start_date, end_date,
                       created_at, updated_at
                FROM trips WHERE id = %s
            """, (trip_id,))
            row = cursor.fetchone()

            if not row:
                cursor.close()
                return json_response(404, {'error': 'Trip not found'})

            # 获取天数详情
            cursor.execute("""
                SELECT day_number, city, activities, summary, estimated_cost
                FROM trip_days WHERE trip_id = %s ORDER BY day_number
            """, (trip_id,))
            days = []
            for d in cursor.fetchall():
                days.append({
                    'day_number': d[0],
                    'city': d[1],
                    'activities': d[2] if isinstance(d[2], list) else json.loads(d[2] or '[]'),
                    'summary': d[3],
                    'estimated_cost': float(d[4]) if d[4] else None
                })

            cursor.close()
            return json_response(200, {
                'trip_id': str(row[0]),
                'title': row[1],
                'cities': row[2],
                'duration_days': row[3],
                'budget_level': row[5],
                'interests': row[6],
                'status': row[7],
                'start_date': str(row[8]) if row[8] else None,
                'end_date': str(row[9]) if row[9] else None,
                'days': days,
                'created_at': str(row[10]),
                'updated_at': str(row[11])
            })

        # ===== 列出用户行程 =====
        elif action == 'list':
            user_id = body.get('user_id')
            device_id = body.get('device_id')
            limit = min(body.get('limit', 20), 50)

            if user_id:
                cursor.execute("""
                    SELECT id, title, cities, duration_days, status, created_at
                    FROM trips WHERE user_id = %s
                    ORDER BY created_at DESC LIMIT %s
                """, (user_id, limit))
            elif device_id:
                cursor.execute("""
                    SELECT id, title, cities, duration_days, status, created_at
                    FROM trips WHERE device_id = %s
                    ORDER BY created_at DESC LIMIT %s
                """, (device_id, limit))
            else:
                cursor.close()
                return json_response(400, {'error': 'Missing user_id or device_id'})

            trips = []
            for row in cursor.fetchall():
                trips.append({
                    'trip_id': str(row[0]),
                    'title': row[1],
                    'cities': row[2],
                    'duration_days': row[3],
                    'status': row[4],
                    'created_at': str(row[5])
                })

            cursor.close()
            return json_response(200, {'trips': trips, 'count': len(trips)})

        # ===== 更新行程 =====
        elif action == 'update':
            trip_id = body.get('trip_id')
            if not trip_id:
                cursor.close()
                return json_response(400, {'error': 'Missing trip_id'})

            updates = []
            params = []
            for field in ['title', 'status', 'budget_level']:
                if field in body:
                    updates.append(f"{field} = %s")
                    params.append(body[field])

            if body.get('itinerary'):
                updates.append("itinerary_json = %s")
                params.append(json.dumps(body['itinerary']))

            if not updates:
                cursor.close()
                return json_response(400, {'error': 'No fields to update'})

            params.append(trip_id)
            cursor.execute(
                f"UPDATE trips SET {', '.join(updates)}, updated_at = NOW() WHERE id = %s",
                params
            )
            conn.commit()
            cursor.close()

            return json_response(200, {'success': True, 'trip_id': trip_id})

        else:
            cursor.close()
            return json_response(400, {
                'error': f'Unknown action: {action}. '
                         f'Supported: create, get, list, update'
            })

    except Exception as e:
        print(f"[TRIP ERROR] {str(e)}")
        import traceback; traceback.print_exc()
        return json_response(500, {'error': str(e)})
```

### 7.9 公网函数 2-4：百度语音 & COS Token

**baidu_voice_asr / baidu_voice_tts：** 配置与 deepseek_translate 类似（公网，无 VPC），环境变量为 `BAIDU_API_KEY` 和 `BAIDU_SECRET_KEY`。具体实现参照百度语音 REST API 文档。

**get_cos_token：** 公网函数，无 VPC，环境变量为 `COS_SECRET_ID`、`COS_SECRET_KEY`、`COS_BUCKET`（wanderchina-user-[AppID]）、`COS_REGION`。调用腾讯云 STS 接口生成临时凭证（有效期 1800s），Policy 限制只能写入 `user/avatars/{user_id}/` 路径，防止越权访问。

### 7.10 完整翻译流程

```
用户在地图看到 "故宫博物院"
    ↓
Flutter 调用 translate_db_write → action: batch_get
    ↓ 1 次 Redis pipeline 查询 en/fr/es
    ↓
  ├── 缓存全部命中 → 直接返回（~50ms）
  │
  └── 缓存未命中 →
        Flutter 并行调用 deepseek_translate × 3 语种
        ↓ DeepSeek API 返回翻译（~2-3s）
        ↓
        Flutter 调用 translate_db_write → action: save
        ↓ 写入 PostgreSQL + Redis 缓存
        ↓
        地图显示 "Palace Museum"
```

### 7.11 函数 URL 触发器配置步骤

每个云函数部署后，需要启用函数 URL：

```
操作路径: 云函数 → 选择函数 → 触发管理 → 创建触发器

触发器类型:  函数 URL
鉴权方式:    免鉴权（MVP 阶段，后续可切换为 JWT 鉴权）
CORS:
  允许来源:  *
  允许方法:  POST, OPTIONS
  允许头部:  Content-Type

部署后获取 URL 格式:
  https://service-{id}-{appid}.gz.tencentcs.com/
```

### 7.12 SCF 费用说明

```yaml
⚠️ 永久免费额度已于 2022-06-01 取消

新用户前 3 个月: 免费试用套餐（价值约 ¥115/月）
3 个月后按量计费:
  调用次数:   ¥0.0133/万次
  资源使用:   ¥0.00011108/GB-秒
  外网流出:   ¥0.80/GB

函数 URL 触发器: ✅ 完全免费
NAT 网关: ✅ 不需要 = 节省 ¥360/月

MVP 阶段预估（12.5 万次/月）:
  前 3 月: ¥0（免费试用期）
  第 4 月起: ≈ ¥2-5/月

成长期（125 万次/月）:
  ≈ ¥15-20/月
```

### 7.13 最佳实践

**1. 连接池复用**

```python
# ✅ 全局变量复用连接 + 心跳检测
_db_conn = None
def get_db_connection():
    global _db_conn
    # 先检测连接是否存活...
    if _db_conn is None:
        _db_conn = psycopg2.connect(...)
    return _db_conn
```

**2. 超时控制**

```python
response = requests.post(url, json=payload, timeout=10)
```

**3. 环境变量验证**

```python
required_vars = ['DB_HOST', 'DB_USER', 'DB_PASSWORD']
missing = [v for v in required_vars if not os.environ.get(v)]
if missing:
    return json_response(500, {'error': f'Missing env vars: {missing}'})
```

**4. VPC 配置检查清单**

```
公网函数（不启用 VPC）:
  ✅ deepseek_translate
  ✅ baidu_voice_asr
  ✅ baidu_voice_tts
  ✅ get_cos_token

内网函数（启用 VPC → wanderchina-vpc → 应用子网）:
  ✅ translate_db_write
  ✅ get_nearby_pois
  ✅ user_auth
  ✅ create_trip
```

---

## 8. 安全配置

###**数据库安全组（wanderchina-db-sg）**

```
入站规则:
  来源: VPC内网 172.16.0.0/16
  端口: 5432（PostgreSQL）
  说明: 仅允许内网访问

  来源: 你的开发机 IP（临时，调试用）
  端口: 5432
  说明: 本地开发调试，上线后删除

出站规则:
  全部放行
```

**Redis 安全组（wanderchina-redis-sg）**

```
入站规则:
  来源: VPC内网 172.16.0.0/16
  端口: 6379
  说明: 仅允许内网访问
```

### 8.2 API 密钥管理

**密钥隔离原则：Flutter App 内不存放任何后端密钥**

```yaml
Flutter App .env（仅存放函数 URL，无密钥）:
  TRANSLATE_URL=https://service-xxx.gz.tencentcs.com/
  DB_WRITE_URL=https://service-yyy.gz.tencentcs.com/
  NEARBY_URL=https://service-zzz.gz.tencentcs.com/
  AUTH_URL=https://service-aaa.gz.tencentcs.com/
  TRIP_URL=https://service-bbb.gz.tencentcs.com/
  COS_TOKEN_URL=https://service-ccc.gz.tencentcs.com/
  ASR_URL=https://service-ddd.gz.tencentcs.com/
  TTS_URL=https://service-eee.gz.tencentcs.com/

云函数环境变量（密钥只在云端，不进代码仓库）:
  DB_HOST / DB_USER / DB_PASSWORD
  REDIS_HOST / REDIS_PASSWORD
  DEEPSEEK_KEY
  BAIDU_API_KEY / BAIDU_SECRET_KEY
  COS_SECRET_ID / COS_SECRET_KEY
  JWT_SECRET

本地开发 .env（加入 .gitignore，仅供 pgAdmin/psql 调试）:
  DB_HOST=gz-cdb-xxxxxxxx.sql.tencentcdb.com   # 外网地址
  DB_PORT=26300                                  # 外网端口
  DB_NAME=wanderchina
  DB_USER=wc_readonly                            # 只读账号
  DB_PASSWORD=Readonly@2026#Safe
```

### 8.3 CORS 配置

MVP 阶段允许所有来源（函数 URL 触发器已内置 CORS 支持）：

```yaml
允许来源: *
允许方法: POST, OPTIONS
允许头部: Content-Type, Authorization

正式上线后收紧为:
  允许来源: https://wanderchina.com, https://app.wanderchina.com
```

### 8.4 输入校验

所有云函数必须验证输入参数：

```python
# 文本长度限制（防止滥用 DeepSeek）
MAX_TEXT_LENGTH = 200

# POI ID 格式验证（高德 POI ID 格式）
import re
POI_ID_PATTERN = re.compile(r'^B[0-9A-Z]{9}$')

# 坐标范围验证（中国境内）
def validate_coordinates(lat, lng):
    return (18.0 <= lat <= 54.0) and (73.0 <= lng <= 135.0)
```

---

## 9. 监控与告警

### 9.1 基础监控（免费）

腾讯云默认为所有产品提供基础监控：

```
PostgreSQL 监控指标:
  - CPU 使用率（告警阈值: >80%）
  - 内存使用率（告警阈值: >85%）
  - 存储使用率（告警阈值: >75%）
  - 连接数（告警阈值: >80% 最大连接数）
  - 慢查询数量（告警阈值: >10条/分钟）

Redis 监控指标:
  - 内存使用率（告警阈值: >85%）
  - 连接数
  - QPS

云函数 SCF 监控:
  - 调用次数
  - 错误率（告警阈值: >5%）
  - 平均耗时
  - 并发数
```

### 9.2 告警配置

```yaml
操作路径: 云监控 → 告警策略 → 新建

告警策略名:   wanderchina-alert
告警对象:     wanderchina-pg-prod, wanderchina-redis-prod
通知方式:     短信 + 邮件
```

### 9.3 数据库慢查询日志

```sql
-- 在腾讯云控制台 → 数据库 → 参数设置 中修改：
log_min_duration_statement = 1000  -- 超过 1 秒的查询记录日志
```

---

## 10. Cloudflare R2

### 10.1 用途

R2 作为 COS 的补充：
1. POI 翻译数据的全量备份
2. 面向海外用户的静态资源 CDN（Cloudflare 全球节点）

### 10.2 创建 Bucket

```yaml
Bucket 名称:  wanderchina-backup
地域:         Automatic
```

### 10.3 API Token

```yaml
操作路径: Cloudflare Dashboard → My Profile → API Tokens → Create Token

权限: Account → Cloudflare R2 Storage → Edit

保存:
  Account ID:         xxxxxxxx
  Access Key ID:      xxxxxxxx
  Secret Access Key:  xxxxxxxx
  Endpoint:           https://{Account_ID}.r2.cloudflarestorage.com
```

### 10.4 备份策略

**MVP 阶段（推荐）：** 依赖 PostgreSQL 自动备份（7 天保留），暂不启用 R2 自动同步。

**原因：** R2 备份脚本需要从 VPC 内网连接数据库，但公网脚本无法访问 VPC 内网地址。正确方案需要拆分为 SCF 定时函数（VPC）导出到 COS + 公网函数上传到 R2，MVP 阶段复杂度不必要。

**成长阶段方案：**

```
SCF 定时触发（VPC 内网）
  → 查询 PostgreSQL 导出 JSON
  → 上传到 COS（VPC 内网直通）
  → 触发公网函数上传到 R2

频率: 每日凌晨 3:00
```

### 10.5 离线翻译包

```python
# 为 6 个城市生成离线翻译包
CITIES = ['北京', '上海', '广州', '深圳', '成都', '西安']
# Key: offline/poi_{city_pinyin}_v{version}.json
# 例: offline/poi_beijing_v20260302.json
```

---

## 11. Flutter 端配置

### 11.1 依赖配置

**pubspec.yaml（仅需要的包）：**

```yaml
dependencies:
  flutter:
    sdk: flutter

  # 地图
  amap_flutter_map: ^3.0.0
  amap_flutter_location: ^3.0.0

  # 网络
  http: ^1.1.0
  dio: ^5.4.0

  # 存储（本地缓存，非直连数据库）
  sqflite: ^2.3.0
  shared_preferences: ^2.2.0

  # 环境变量
  flutter_dotenv: ^5.1.0

  # 状态管理
  provider: ^6.1.0

  # 音频（语音翻译）
  record: ^5.0.0

  # JSON 序列化
  json_annotation: ^4.8.1
```

> ⚠️ **不使用 `postgres` 包**——App 不直连数据库，所有数据操作通过云函数 URL。

### 11.2 环境配置

**.env 文件（仅函数 URL，无密钥）：**

```env
# ===== 云函数 URL（部署后填入实际地址）=====
# 公网函数
TRANSLATE_URL=https://service-xxx.gz.tencentcs.com/
ASR_URL=https://service-xxx.gz.tencentcs.com/
TTS_URL=https://service-xxx.gz.tencentcs.com/
COS_TOKEN_URL=https://service-xxx.gz.tencentcs.com/

# 内网函数（通过函数 URL 对外暴露）
DB_WRITE_URL=https://service-xxx.gz.tencentcs.com/
NEARBY_URL=https://service-xxx.gz.tencentcs.com/
AUTH_URL=https://service-xxx.gz.tencentcs.com/
TRIP_URL=https://service-xxx.gz.tencentcs.com/

# ===== 高德地图 =====
AMAP_KEY_IOS=xxxxxxxxxx
AMAP_KEY_ANDROID=xxxxxxxxxx

# ===== COS（静态资源读取 + 用户内容上传）=====
COS_STATIC_URL=https://wanderchina-static-xxxxx.cos.ap-guangzhou.myqcloud.com
COS_USER_BUCKET=wanderchina-user-xxxxx
COS_REGION=ap-guangzhou
```

### 11.3 API 客户端

```dart
// lib/services/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiClient {
  static String get translateUrl => dotenv.env['TRANSLATE_URL']!;
  static String get dbWriteUrl => dotenv.env['DB_WRITE_URL']!;
  static String get nearbyUrl => dotenv.env['NEARBY_URL']!;
  static String get authUrl => dotenv.env['AUTH_URL']!;
  static String get tripUrl => dotenv.env['TRIP_URL']!;
  static String get cosTokenUrl => dotenv.env['COS_TOKEN_URL']!;
  static String get asrUrl => dotenv.env['ASR_URL']!;
  static String get ttsUrl => dotenv.env['TTS_URL']!;

  /// 通用 POST 请求
  static Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    ).timeout(timeout);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    }
    throw Exception('API error ${response.statusCode}: ${response.body}');
  }
}
```

### 11.4 翻译服务（使用 batch_get 优化）

```dart
// lib/services/translation_service.dart
class TranslationService {
  /// 智能翻译 POI（1 次缓存检查替代 3 次）
  static Future<POITranslation?> translatePOI({
    required String poiId,
    required String nameZh,
    double? latitude,
    double? longitude,
    String? city,
  }) async {
    try {
      // Step 1: 批量检查缓存（1 次 HTTP）
      final cacheResult = await ApiClient.post(
        ApiClient.dbWriteUrl,
        {
          'poi_id': poiId,
          'action': 'batch_get',
          'languages': ['en', 'fr', 'es'],
        },
      );

      if (cacheResult['all_cached'] == true) {
        final t = cacheResult['translations'];
        return POITranslation(
          poiId: poiId, nameZh: nameZh,
          nameEn: t['en'] ?? '', nameFr: t['fr'] ?? '', nameEs: t['es'] ?? '',
          fromCache: true,
        );
      }

      // Step 2: 并行调用 DeepSeek 翻译
      final results = await Future.wait([
        ApiClient.post(ApiClient.translateUrl, {'text': nameZh, 'target_lang': 'en'}),
        ApiClient.post(ApiClient.translateUrl, {'text': nameZh, 'target_lang': 'fr'}),
        ApiClient.post(ApiClient.translateUrl, {'text': nameZh, 'target_lang': 'es'}),
      ]);

      final nameEn = results[0]['translated_text'] as String;
      final nameFr = results[1]['translated_text'] as String;
      final nameEs = results[2]['translated_text'] as String;

      // Step 3: 保存到 DB + Redis
      await ApiClient.post(ApiClient.dbWriteUrl, {
        'poi_id': poiId,
        'name_zh': nameZh,
        'name_en': nameEn,
        'name_fr': nameFr,
        'name_es': nameEs,
        'latitude': latitude,
        'longitude': longitude,
        'city': city,
        'action': 'save',
      });

      return POITranslation(
        poiId: poiId, nameZh: nameZh,
        nameEn: nameEn, nameFr: nameFr, nameEs: nameEs,
        fromCache: false,
      );
    } catch (e) {
      print('Translation failed: $e');
      return null;
    }
  }
}

class POITranslation {
  final String poiId, nameZh, nameEn, nameFr, nameEs;
  final bool fromCache;

  POITranslation({
    required this.poiId, required this.nameZh,
    required this.nameEn, required this.nameFr, required this.nameEs,
    this.fromCache = false,
  });

  bool get hasAllTranslations =>
      nameEn.isNotEmpty && nameFr.isNotEmpty && nameEs.isNotEmpty;
}
```

### 11.5 性能对比

| 场景 | 响应时间 | 成本 | 数据来源 |
|------|---------|------|---------|
| 缓存命中（batch_get） | ~50ms | ¥0 | Redis |
| 缓存未命中 | ~2-3s | ¥0.000075 | DeepSeek API |

---

## 12. 费用估算

### 12.1 腾讯云月费

| 服务 | 规格 | MVP 月费 |
|------|------|---------|
| PostgreSQL | 1C2G 双机高可用 | ¥260（包月）/ ¥324（按量） |
| Redis | 1GB 主从 | ¥60 |
| SCF 云函数 | ~12.5万次/月 | ¥0（前3月）→ ¥2-5 |
| COS | 2 Buckets（静态 + 用户内容）~15GB | ¥5 |
| CDN | COS 默认域名 | ¥0（含在 COS 流量中） |
| **小计** | | **¥327-394** |

### 12.2 第三方 API 月费（按 500 活跃用户估算）

| 服务 | 用量 | 月费 |
|------|------|------|
| 百度 ASR | 12,500 次 × ¥0.0042 | ¥52 |
| 百度 TTS | 12,500 次 × ¥0.004 | ¥50 |
| DeepSeek 翻译 | 12,500 次 × ¥0.000334 | ¥4 |
| DeepSeek 行程 | 1,500 次 × ¥0.0085 | ¥13 |
| 高德地图 | 300K/天免费额度内 | ¥0 |
| **小计** | | **≈ ¥120** |

### 12.3 总费用

| 阶段 | 腾讯云 | 第三方 API | 总计 |
|------|--------|-----------|------|
| **MVP（0-1K MAU）** | ¥327-394 | ¥120 | **¥447-514/月** |
| 成长期（1万 MAU） | ¥340-400 | ¥2,400 | ¥2,740-2,800 |
| 规模化（10万 MAU） | ¥800-1,200 | ¥22,400 | ¥23,200-23,600 |

> **成本大头不在基础设施，在 API 调用。** 百度语音占第三方成本的 85%。优化方向：减少无效语音调用、增大翻译缓存命中率、探索更便宜的 TTS 方案。

---

## 13. 上线检查清单

### 基础设施

- [ ] VPC 创建完成，3 个子网配置正确
- [ ] PostgreSQL 双机高可用实例创建
- [ ] PostGIS 扩展安装 + 数据表创建（poi_translations, users, trips, trip_days）
- [ ] wc_scf_service 用户创建（仅 DML，无 DDL）
- [ ] Redis 实例创建
- [ ] COS 静态资源 Bucket 创建（wanderchina-static）
- [ ] COS 用户内容 Bucket 创建（wanderchina-user，私有读写）

### 云函数

- [ ] deepseek_translate 部署 + 函数 URL 启用
- [ ] baidu_voice_asr 部署 + 函数 URL 启用
- [ ] baidu_voice_tts 部署 + 函数 URL 启用
- [ ] get_cos_token 部署 + 函数 URL 启用
- [ ] translate_db_write 部署（VPC）+ 函数 URL 启用
- [ ] get_nearby_pois 部署（VPC）+ 函数 URL 启用
- [ ] user_auth 部署（VPC）+ 函数 URL 启用
- [ ] create_trip 部署（VPC）+ 函数 URL 启用
- [ ] 所有函数环境变量配置正确
- [ ] VPC 函数能连通 PostgreSQL 和 Redis

### 安全

- [ ] 安全组规则配置（数据库仅 VPC 内网可访问）
- [ ] Flutter .env 中无任何后端密钥（仅函数 URL）
- [ ] 所有云函数密钥通过环境变量注入
- [ ] .gitignore 包含 .env 文件

### 数据

- [ ] POI 翻译数据初始导入（6 城市核心 POI）
- [ ] PostgreSQL 自动备份配置（每日，保留 7 天）

### Flutter

- [ ] 高德地图 SDK 集成 + Key 配置
- [ ] ApiClient 所有函数 URL 填入 .env
- [ ] 地图翻译蒙层功能测试
- [ ] 语音翻译流程测试

### 监控

- [ ] 基础监控告警配置（CPU/内存/存储阈值）
- [ ] 云函数错误率告警
- [ ] 慢查询日志开启

### 延后项（正式上线前）

- [ ] ICP 备案 + 自定义域名（CDN）
- [ ] R2 自动备份脚本（SCF 定时任务方案）

---

**— 文档结束 —**

**版本历史:**
- v1.0（2026-02-13）: 初始版本
- v2.0（2026-03-02）: 三轮审查后完整重写，消除所有冲突和重复
  - 新增: user_auth 完整实现（匿名 + 邮箱注册/登录 + 资料 CRUD）
  - 新增: create_trip 完整实现（行程 CRUD）
  - 新增: users / user_sessions / trips / trip_days 表设计
  - 新增: 用户内容 COS Bucket（配合用户注册，支持头像上传）
  - 合并: get_user_data 功能并入 user_auth（get_profile / update_profile）
  - 修复: poi_translations 表统一 lat/lng + PostGIS location + geohash
  - 修复: 数据库连接增加心跳检测和自动重连
  - 修复: Redis 缓存检查由 3 次 HTTP → 1 次 batch_get
  - 修复: wc_scf_service 移除 DDL 权限
  - 修复: DeepSeek 定价更新为 V3.2 USD 标准
  - 修复: SCF 免费额度说明更正
  - 保留: PostgreSQL 双机高可用（为潜在需求预留余量）
  - 删除: 合并版翻译函数代码（违反拆分架构）
  - 删除: Flutter 直连数据库代码（安全隐患）
  - 删除: 重复章节编号
