# WanderChina MVP 后端部署任务书

**交付目标：** 部署完整后端基础设施，8 个云函数全部可调用，数据库可读写，POI 初始数据导入完成
**执行者：** Claude Code
**预计时间：** 4-6 小时
**参考文档：** 部署过程中请严格参照以下 4 份配置文档：

```
WANDERCHINA_TENCENT_CLOUD_CONFIG_v2.md    — 主配置（架构/DB/Redis/COS/SCF/Flutter）
DEEPSEEK_API_配置指南_v2.md               — DeepSeek 翻译函数详细参数
DeepSeek_成本监控脚本_v2.md               — 成本监控脚本
WANDERCHINA_BAIDU_SPEECH_CONFIG_v2.md     — 百度语音函数详细参数
```

---

## 全局约束

```yaml
地域:        ap-guangzhou（广州）
VPC:         wanderchina-vpc（172.16.0.0/16）
数据库:      PostgreSQL 1C2G 双机高可用 + PostGIS
缓存:        Redis 1GB 标准主从
对象存储:    2 个 COS Bucket（static 公读 + user 私有）
云函数:      8 个（4 公网 + 4 VPC 内网）
API 触发:    函数 URL（非 API 网关，已停服）
密钥原则:    所有 API Key 仅存在于云函数环境变量，Flutter .env 只存函数 URL
MVP 语种:    en / fr / es（3 种）
MVP 城市:    北京 / 上海 / 广州 / 深圳 / 成都 / 西安（6 个）
```

---

## Phase 0: 前置准备（手动完成）

> 以下步骤需 Calvin 在各平台控制台手动完成，完成后将密钥提供给 Claude Code。

### 0.1 腾讯云账号

```
□ 登录腾讯云控制台 console.cloud.tencent.com
□ 确认已完成实名认证（个人认证即可 MVP）
□ 记录 AppID（控制台右上角 → 账号信息）
□ 创建 API 密钥（访问管理 → 访问密钥 → API 密钥管理）
   → SecretId: __________________________
   → SecretKey: __________________________
```

### 0.2 DeepSeek

```
□ 登录 platform.deepseek.com
□ 充值 ¥50-100
□ 创建 API Key（名称: wanderchina-production）
   → DEEPSEEK_KEY: sk-__________________________
□ 设置余额告警（余额 < ¥10 时邮件提醒）
```

### 0.3 百度智能云

```
□ 登录 cloud.baidu.com
□ 完成实名认证
□ 开通: 短语音识别标准版 + 在线语音合成标准版
□ 创建应用（名称: WanderChina）
   → BAIDU_API_KEY: __________________________
   → BAIDU_SECRET_KEY: __________________________
□ 在控制台确认实际免费额度（ASR/TTS 每日免费次数）
```

### 0.4 高德开放平台

```
□ 登录 lbs.amap.com
□ 创建应用（名称: WanderChina）
□ 获取 Key:
   → iOS Key: __________________________
   → Android Key: __________________________
   → Web Key（POI 数据导入用）: __________________________
```

**Phase 0 完成标志：** 4 组 API 密钥全部到手

---

## Phase 1: 网络基础设施

> 参考: TENCENT_CLOUD_CONFIG v2.0 §2

### 1.1 创建 VPC

```
控制台路径: 私有网络 → VPC → 新建

名称:     wanderchina-vpc
地域:     广州
IPv4 CIDR: 172.16.0.0/16
```

### 1.2 创建子网

```
在 wanderchina-vpc 下创建 3 个子网:

  数据库子网:  wanderchina-db-subnet
    CIDR: 172.16.1.0/24
    可用区: ap-guangzhou-3

  缓存子网:   wanderchina-cache-subnet
    CIDR: 172.16.2.0/24
    可用区: ap-guangzhou-3

  应用子网:   wanderchina-app-subnet
    CIDR: 172.16.3.0/24
    可用区: ap-guangzhou-3
```

### 1.3 创建安全组

```
安全组 1: wanderchina-db-sg
  入站: TCP 5432，来源 172.16.0.0/16
  出站: 全部放行

安全组 2: wanderchina-redis-sg
  入站: TCP 6379，来源 172.16.0.0/16
  出站: 全部放行
```

### ✅ Phase 1 验证

```
□ VPC 172.16.0.0/16 已创建
□ 3 个子网可用
□ 2 个安全组规则正确
```

---

## Phase 2: 数据库

> 参考: TENCENT_CLOUD_CONFIG v2.0 §3

### 2.1 创建 PostgreSQL 实例

```
控制台路径: 云数据库 → PostgreSQL → 新建

实例名:    wanderchina-pg-prod
版本:      PostgreSQL 16
规格:      1核2GB
架构:      双机高可用
存储:      20GB SSD（自动扩容）
VPC:       wanderchina-vpc
子网:      wanderchina-db-subnet (172.16.1.0/24)
安全组:    wanderchina-db-sg
管理员:    wanderchina_pg_prod
密码:      [生成强密码，≥16位，记录下来]

⚠️ 选择包月（¥260/月）或按量付费（¥324/月），推荐包月
```

### 2.2 开启外网访问（临时，用于初始化）

```
实例详情 → 基本信息 → 外网地址 → 开启

记录:
  内网地址: 172.16.1.x:5432    ← 云函数使用
  外网地址: gz-cdb-xxx:26300   ← 本地 psql 使用（初始化后关闭）
```

### 2.3 连接数据库并初始化

用 psql 或 pgAdmin 连接外网地址，以 wanderchina_pg_prod 身份执行以下 SQL：

```sql
-- ========================================
-- Step 1: 安装扩展
-- ========================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ========================================
-- Step 2: 创建业务用户
-- ========================================

-- 云函数专用（仅 DML，无 DDL）
CREATE USER wc_scf_service WITH PASSWORD 'ScfService@2026#Secure';
GRANT CONNECT ON DATABASE wanderchina TO wc_scf_service;
GRANT USAGE ON SCHEMA public TO wc_scf_service;

-- 只读用户（数据分析）
CREATE USER wc_readonly WITH PASSWORD 'Readonly@2026#Safe';
GRANT CONNECT ON DATABASE wanderchina TO wc_readonly;
GRANT USAGE ON SCHEMA public TO wc_readonly;

-- ========================================
-- Step 3: 创建表 — poi_translations
-- ========================================
CREATE TABLE IF NOT EXISTS poi_translations (
    id              BIGSERIAL PRIMARY KEY,
    gaode_poi_id    VARCHAR(20) NOT NULL UNIQUE,
    name_zh         VARCHAR(200) NOT NULL,
    name_en         VARCHAR(300),
    name_fr         VARCHAR(300),
    name_es         VARCHAR(300),
    category_zh     VARCHAR(100),
    category_en     VARCHAR(100),
    category_fr     VARCHAR(100),
    category_es     VARCHAR(100),
    address_zh      VARCHAR(500),
    city            VARCHAR(50),
    district        VARCHAR(50),
    latitude        DECIMAL(10, 6),
    longitude       DECIMAL(10, 6),
    location        GEOGRAPHY(POINT, 4326),
    geohash         VARCHAR(12),
    priority_score  INTEGER DEFAULT 50,
    source          VARCHAR(20) DEFAULT 'deepseek',
    confidence      DECIMAL(3, 2) DEFAULT 0.95,
    verified        BOOLEAN DEFAULT FALSE,
    usage_count     INTEGER DEFAULT 0,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_poi_location_gist
    ON poi_translations USING GIST (location);

CREATE INDEX IF NOT EXISTS idx_poi_geohash
    ON poi_translations (geohash text_pattern_ops);

CREATE INDEX IF NOT EXISTS idx_poi_city_priority
    ON poi_translations (city, priority_score DESC);

CREATE INDEX IF NOT EXISTS idx_poi_category
    ON poi_translations (category_zh);

CREATE INDEX IF NOT EXISTS idx_poi_latlng
    ON poi_translations (latitude, longitude);

-- 触发器: lat/lng → location + geohash 自动同步
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
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_poi_sync_spatial
    BEFORE INSERT OR UPDATE OF latitude, longitude
    ON poi_translations
    FOR EACH ROW EXECUTE FUNCTION sync_poi_spatial_fields();

-- ========================================
-- Step 4: 创建表 — users
-- ========================================
CREATE TABLE IF NOT EXISTS users (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email               VARCHAR(255) UNIQUE,
    phone               VARCHAR(20) UNIQUE,
    password_hash       VARCHAR(255),
    username            VARCHAR(50),
    display_name        VARCHAR(100),
    avatar_url          VARCHAR(500),
    device_id           VARCHAR(100),
    preferred_lang      VARCHAR(5) DEFAULT 'en',
    is_premium          BOOLEAN DEFAULT FALSE,
    premium_expires_at  TIMESTAMP WITH TIME ZONE,
    is_active           BOOLEAN DEFAULT TRUE,
    trips_count         INTEGER DEFAULT 0,
    translations_count  INTEGER DEFAULT 0,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login_at       TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users (phone);
CREATE INDEX IF NOT EXISTS idx_users_device ON users (device_id);

-- ========================================
-- Step 5: 创建表 — user_sessions
-- ========================================
CREATE TABLE IF NOT EXISTS user_sessions (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    refresh_token VARCHAR(500) NOT NULL,
    token_family  VARCHAR(100),
    device_id     VARCHAR(100),
    device_type   VARCHAR(20),
    app_version   VARCHAR(20),
    ip_address    INET,
    is_revoked    BOOLEAN DEFAULT FALSE,
    created_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at    TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_sessions_user ON user_sessions (user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_token ON user_sessions (refresh_token);

-- ========================================
-- Step 6: 创建表 — trips
-- ========================================
CREATE TABLE IF NOT EXISTS trips (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID REFERENCES users(id) ON DELETE SET NULL,
    device_id       VARCHAR(100),
    title           VARCHAR(200) DEFAULT 'My Trip',
    cities          TEXT[] NOT NULL,
    duration_days   INTEGER DEFAULT 1,
    start_date      DATE,
    end_date        DATE,
    budget_level    VARCHAR(20) DEFAULT 'medium',
    budget_amount   DECIMAL(10, 2),
    interests       TEXT[],
    travel_style    VARCHAR(20),
    itinerary_json  JSONB,
    status          VARCHAR(20) DEFAULT 'draft',
    is_public       BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_trips_user ON trips (user_id);
CREATE INDEX IF NOT EXISTS idx_trips_device ON trips (device_id);
CREATE INDEX IF NOT EXISTS idx_trips_status ON trips (status);

-- ========================================
-- Step 7: 创建表 — trip_days
-- ========================================
CREATE TABLE IF NOT EXISTS trip_days (
    id              BIGSERIAL PRIMARY KEY,
    trip_id         UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    day_number      INTEGER NOT NULL,
    city            VARCHAR(50),
    date            DATE,
    activities      JSONB DEFAULT '[]'::jsonb,
    summary         TEXT,
    estimated_cost  DECIMAL(10, 2),
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE (trip_id, day_number)
);

CREATE INDEX IF NOT EXISTS idx_trip_days_trip ON trip_days (trip_id);

-- ========================================
-- Step 8: 授权
-- ========================================

-- wc_scf_service: 仅 DML
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO wc_scf_service;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO wc_scf_service;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wc_scf_service;

-- 未来新建表自动授权
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO wc_scf_service;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO wc_scf_service;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT EXECUTE ON FUNCTIONS TO wc_scf_service;

-- 禁止 wc_scf_service 创建表
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT CREATE ON SCHEMA public TO wanderchina_pg_prod;

-- wc_readonly: 仅 SELECT
GRANT SELECT ON ALL TABLES IN SCHEMA public TO wc_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO wc_readonly;
```

### 2.4 验证

```sql
-- 以 wc_scf_service 身份连接，验证权限
-- 应该成功:
INSERT INTO poi_translations (gaode_poi_id, name_zh, name_en, latitude, longitude, city)
VALUES ('B000A8UJVW', '故宫博物院', 'Palace Museum', 39.916345, 116.397155, '北京');

SELECT * FROM poi_translations WHERE gaode_poi_id = 'B000A8UJVW';

-- 应该失败:
CREATE TABLE test_table (id INT);  -- ERROR: permission denied
```

### ✅ Phase 2 验证

```
□ PostgreSQL 实例运行中
□ PostGIS 扩展已安装
□ 4 张表已创建（poi_translations, users, trips, trip_days）
□ 空间触发器工作（插入 lat/lng 后 location 和 geohash 自动填充）
□ wc_scf_service 可 CRUD 但不能建表
□ wc_readonly 只能 SELECT
```

---

## Phase 3: Redis

> 参考: TENCENT_CLOUD_CONFIG v2.0 §4

### 3.1 创建 Redis 实例

```
控制台路径: 云数据库 → Redis → 新建

实例名:    wanderchina-redis-prod
版本:      Redis 6.2
架构:      标准架构（主从）
内存:      1GB
VPC:       wanderchina-vpc
子网:      wanderchina-cache-subnet (172.16.2.0/24)
安全组:    wanderchina-redis-sg
密码:      [生成强密码，记录下来]
```

### 3.2 记录连接信息

```
内网地址:  172.16.2.x:6379
密码:      [上面设置的密码]
```

### ✅ Phase 3 验证

```
□ Redis 实例运行中
□ 内网地址已记录
```

---

## Phase 4: 对象存储 COS

> 参考: TENCENT_CLOUD_CONFIG v2.0 §5

### 4.1 创建 Bucket

```
Bucket 1 — 静态资源（公有读）:
  名称:     wanderchina-static-{AppID}
  地域:     广州
  访问权限: 公有读私有写

Bucket 2 — 用户内容（私有）:
  名称:     wanderchina-user-{AppID}
  地域:     广州
  访问权限: 私有读写
```

### 4.2 CORS 配置

```
Bucket 1（静态）:
  AllowedOrigins: *
  AllowedMethods: GET
  MaxAgeSeconds: 86400

Bucket 2（用户）:
  AllowedOrigins: *
  AllowedMethods: GET, PUT, POST
  ExposeHeaders: ETag
  MaxAgeSeconds: 3600
```

### ✅ Phase 4 验证

```
□ 2 个 Bucket 已创建
□ 可通过默认域名访问 static bucket
□ CORS 配置正确
```

---

## Phase 5: 云函数部署

> 参考: TENCENT_CLOUD_CONFIG v2.0 §7 + DEEPSEEK_API v2.0 §4 + BAIDU_SPEECH v2.0 §6

### 5.0 密钥汇总（Claude Code 需要这些值设为环境变量）

```yaml
# ----- 数据库 -----
DB_HOST:         [Phase 2 获取的内网 IP]
DB_PORT:         5432
DB_NAME:         wanderchina
DB_USER:         wc_scf_service
DB_PASSWORD:     ScfService@2026#Secure

# ----- Redis -----
REDIS_HOST:      [Phase 3 获取的内网 IP]
REDIS_PORT:      6379
REDIS_PASSWORD:  [Phase 3 设置的密码]

# ----- DeepSeek -----
DEEPSEEK_KEY:    [Phase 0 获取]

# ----- 百度语音 -----
BAIDU_API_KEY:    [Phase 0 获取]
BAIDU_SECRET_KEY: [Phase 0 获取]

# ----- COS -----
COS_SECRET_ID:   [Phase 0 腾讯云密钥]
COS_SECRET_KEY:  [Phase 0 腾讯云密钥]
COS_BUCKET:      wanderchina-user-{AppID}
COS_REGION:      ap-guangzhou

# ----- JWT -----
JWT_SECRET:      [生成 ≥32 位随机字符串]
```

### 5.1 公网函数 ×4（不启用 VPC）

| 函数名 | 内存 | 超时 | 环境变量 | 代码来源 |
|--------|------|------|---------|---------|
| deepseek_translate | 256MB | 15s | DEEPSEEK_KEY | TENCENT_CONFIG v2.0 §7.4 |
| baidu_voice_asr | 256MB | 15s | BAIDU_API_KEY, BAIDU_SECRET_KEY | BAIDU_SPEECH v2.0 §6.1 |
| baidu_voice_tts | 256MB | 15s | BAIDU_API_KEY, BAIDU_SECRET_KEY | BAIDU_SPEECH v2.0 §6.2 |
| get_cos_token | 128MB | 10s | COS_SECRET_ID, COS_SECRET_KEY, COS_BUCKET, COS_REGION | 需编写 STS 凭证下发代码 |

**每个公网函数部署后操作：**
```
触发管理 → 创建触发器:
  类型:     函数 URL
  鉴权方式: 免鉴权
  CORS:     开启（POST, OPTIONS）

记录函数 URL: https://service-{id}-{appid}.gz.tencentcs.com/
```

### 5.2 VPC 内网函数 ×4（启用 VPC）

| 函数名 | 内存 | 超时 | 环境变量 | 代码来源 |
|--------|------|------|---------|---------|
| translate_db_write | 256MB | 10s | DB_*, REDIS_* | TENCENT_CONFIG v2.0 §7.5 |
| get_nearby_pois | 256MB | 10s | DB_*, REDIS_* | TENCENT_CONFIG v2.0 §7.6 |
| user_auth | 256MB | 10s | DB_*, REDIS_*, JWT_SECRET | TENCENT_CONFIG v2.0 §7.7 |
| create_trip | 256MB | 10s | DB_* | TENCENT_CONFIG v2.0 §7.8 |

**VPC 配置（所有内网函数统一）：**
```
VPC:     wanderchina-vpc
子网:    wanderchina-app-subnet (172.16.3.0/24)
```

**requirements.txt（内网函数共用）：**
```
psycopg2-binary==2.9.9
redis==5.0.1
```

### 5.3 get_cos_token 函数代码（需编写）

```python
# get_cos_token/index.py
import json
import os
from tencentcloud.common import credential
from tencentcloud.sts.v20180813 import sts_client, models

def json_response(code, body):
    return {
        'statusCode': code,
        'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
        'body': json.dumps(body, ensure_ascii=False)
    }

def main_handler(event, context):
    try:
        if isinstance(event, dict) and 'body' in event:
            body = json.loads(event['body'])
        else:
            body = event

        user_id = body.get('user_id', 'anonymous')
        bucket = os.environ['COS_BUCKET']
        region = os.environ['COS_REGION']

        cred = credential.Credential(
            os.environ['COS_SECRET_ID'],
            os.environ['COS_SECRET_KEY']
        )
        client = sts_client.StsClient(cred, region)

        req = models.GetFederationTokenRequest()
        req.Name = f'wanderchina-{user_id[:8]}'
        req.DurationSeconds = 1800
        req.Policy = json.dumps({
            "version": "2.0",
            "statement": [{
                "effect": "allow",
                "action": [
                    "cos:PutObject",
                    "cos:InitiateMultipartUpload",
                    "cos:UploadPart",
                    "cos:CompleteMultipartUpload"
                ],
                "resource": [
                    f"qcs::cos:{region}:uid/*:{bucket}/user/avatars/{user_id}/*",
                    f"qcs::cos:{region}:uid/*:{bucket}/trips/covers/*"
                ]
            }]
        })

        resp = client.GetFederationToken(req)
        creds = resp.Credentials

        return json_response(200, {
            'tmpSecretId': creds.TmpSecretId,
            'tmpSecretKey': creds.TmpSecretKey,
            'sessionToken': creds.Token,
            'expiredTime': resp.ExpiredTime,
            'bucket': bucket,
            'region': region
        })

    except Exception as e:
        print(f"[COS TOKEN ERROR] {str(e)}")
        return json_response(500, {'error': str(e)})
```

**requirements.txt:**
```
tencentcloud-sdk-python-sts==3.0.1000
```

### ✅ Phase 5 验证

逐个测试 8 个函数 URL：

```bash
# 1. deepseek_translate
curl -X POST {TRANSLATE_URL} \
  -H "Content-Type: application/json" \
  -d '{"text": "故宫博物院", "target_lang": "en"}'
# 期望: {"translated_text": "Palace Museum", ...}

# 2. translate_db_write — 保存翻译
curl -X POST {DB_WRITE_URL} \
  -H "Content-Type: application/json" \
  -d '{"poi_id": "B000A8UJVW", "name_zh": "故宫博物院", "name_en": "Palace Museum", "latitude": 39.916345, "longitude": 116.397155, "city": "北京", "action": "save"}'
# 期望: {"success": true, "poi_id": "B000A8UJVW"}

# 3. translate_db_write — 批量缓存查询
curl -X POST {DB_WRITE_URL} \
  -H "Content-Type: application/json" \
  -d '{"poi_id": "B000A8UJVW", "action": "batch_get", "languages": ["en", "fr", "es"]}'
# 期望: {"all_cached": false, "translations": {"en": "Palace Museum", "fr": null, "es": null}}

# 4. get_nearby_pois
curl -X POST {NEARBY_URL} \
  -H "Content-Type: application/json" \
  -d '{"latitude": 39.916, "longitude": 116.397, "lang": "en", "radius": 2000}'
# 期望: {"pois": [...], "count": N}

# 5. user_auth — 匿名认证
curl -X POST {AUTH_URL} \
  -H "Content-Type: application/json" \
  -d '{"action": "anonymous_auth", "device_id": "test-device-001", "preferred_lang": "en"}'
# 期望: {"user_id": "...", "token": "...", "is_new_user": true}

# 6. user_auth — 获取资料
curl -X POST {AUTH_URL} \
  -H "Content-Type: application/json" \
  -d '{"action": "get_profile", "user_id": "[Step 5 返回的 user_id]"}'
# 期望: {"user_id": "...", "preferred_lang": "en", ...}

# 7. create_trip
curl -X POST {TRIP_URL} \
  -H "Content-Type: application/json" \
  -d '{"action": "create", "device_id": "test-device-001", "title": "Beijing 3-Day", "cities": ["北京"], "duration_days": 3}'
# 期望: {"trip_id": "...", "created_at": "..."}

# 8. get_cos_token
curl -X POST {COS_TOKEN_URL} \
  -H "Content-Type: application/json" \
  -d '{"user_id": "test-user-001"}'
# 期望: {"tmpSecretId": "...", "sessionToken": "...", ...}

# 9. baidu_voice_tts（用文本测试，不需要音频）
curl -X POST {TTS_URL} \
  -H "Content-Type: application/json" \
  -d '{"text": "Welcome to Beijing", "language": "en"}'
# 期望: {"audio_base64": "...", "format": "mp3", "size": N}

# 10. baidu_voice_asr（需要真实音频，可跳过或用小段 Base64 测试）
```

```
□ 8 个函数 URL 全部记录
□ deepseek_translate 返回翻译结果
□ translate_db_write 保存后 Redis 有缓存
□ get_nearby_pois 返回 PostGIS 距离查询结果
□ user_auth 匿名注册 + 获取资料正常
□ create_trip 创建 + 查询正常
□ get_cos_token 返回临时凭证
□ baidu_voice_tts 返回 Base64 音频
```

---

## Phase 6: POI 数据初始导入

### 6.1 编写导入脚本

从高德 POI 搜索 API 批量获取 6 城市核心景点，写入 poi_translations 表：

```python
#!/usr/bin/env python3
"""
WanderChina POI 初始导入脚本
数据来源: 高德开放平台 POI 搜索 API
目标: 6 城市 × 200 核心 POI = ~1200 条
"""
import requests
import json
import time
import psycopg2

AMAP_KEY = '[高德 Web Key]'

# 6 个 MVP 城市
CITIES = {
    '北京': '110000',
    '上海': '310000',
    '广州': '440100',
    '深圳': '440300',
    '成都': '510100',
    '西安': '610100',
}

# 核心 POI 类型（高德分类编码）
POI_TYPES = [
    '110000',  # 风景名胜
    '110100',  # 旅游景点
    '110200',  # 公园广场
    '060000',  # 购物
    '050000',  # 餐饮
    '070000',  # 住宿
    '150000',  # 交通
    '141200',  # 博物馆
]

DB_CONFIG = {
    'host': '[外网地址]',
    'port': 26300,
    'database': 'wanderchina',
    'user': 'wanderchina_pg_prod',
    'password': '[密码]',
}

def fetch_pois(city_code, poi_type, page=1, page_size=25):
    """调用高德 POI 搜索"""
    url = 'https://restapi.amap.com/v3/place/text'
    params = {
        'key': AMAP_KEY,
        'types': poi_type,
        'city': city_code,
        'citylimit': 'true',
        'offset': page_size,
        'page': page,
        'extensions': 'all',
    }
    resp = requests.get(url, params=params, timeout=10)
    data = resp.json()
    if data['status'] == '1':
        return data.get('pois', [])
    return []

def import_city(conn, city_name, city_code):
    """导入单个城市的 POI"""
    cursor = conn.cursor()
    count = 0

    for poi_type in POI_TYPES:
        for page in range(1, 5):  # 每种类型最多 4 页
            pois = fetch_pois(city_code, poi_type, page)
            if not pois:
                break

            for poi in pois:
                try:
                    location = poi.get('location', '').split(',')
                    if len(location) != 2:
                        continue

                    lng, lat = float(location[0]), float(location[1])
                    gaode_id = poi.get('id', '')
                    name = poi.get('name', '')
                    category = poi.get('type', '').split(';')[0] if poi.get('type') else ''
                    address = poi.get('address', '')
                    district = poi.get('adname', '')

                    # 根据评分/热度设置优先级
                    biz = poi.get('biz_ext', {})
                    rating = float(biz.get('rating', 0) or 0)
                    priority = int(rating * 20) if rating > 0 else 50

                    cursor.execute("""
                        INSERT INTO poi_translations
                        (gaode_poi_id, name_zh, category_zh, address_zh,
                         city, district, latitude, longitude, priority_score, source)
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, 'amap')
                        ON CONFLICT (gaode_poi_id) DO UPDATE SET
                            category_zh = EXCLUDED.category_zh,
                            address_zh = EXCLUDED.address_zh,
                            priority_score = GREATEST(poi_translations.priority_score, EXCLUDED.priority_score),
                            updated_at = NOW()
                    """, (gaode_id, name, category, address,
                          city_name, district, lat, lng, priority))
                    count += 1

                except Exception as e:
                    print(f"  跳过 POI: {e}")
                    continue

            time.sleep(0.2)  # 高德限流

    conn.commit()
    cursor.close()
    print(f"  {city_name}: 导入 {count} 条 POI")
    return count

def main():
    conn = psycopg2.connect(**DB_CONFIG)
    total = 0

    for city_name, city_code in CITIES.items():
        print(f"正在导入: {city_name} ({city_code})")
        total += import_city(conn, city_name, city_code)

    conn.close()
    print(f"\n完成！共导入 {total} 条 POI")

if __name__ == '__main__':
    main()
```

### 6.2 批量预翻译核心 POI

```python
"""
对 priority_score > 70 的高优先级 POI 预翻译英文名
调用 deepseek_translate 云函数
"""
import requests
import time
import psycopg2

TRANSLATE_URL = '[deepseek_translate 函数 URL]'
DB_WRITE_URL = '[translate_db_write 函数 URL]'

def pretranslate_top_pois():
    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor()

    cursor.execute("""
        SELECT gaode_poi_id, name_zh, latitude, longitude, city
        FROM poi_translations
        WHERE name_en IS NULL AND priority_score > 70
        ORDER BY priority_score DESC
        LIMIT 500
    """)

    rows = cursor.fetchall()
    print(f"待翻译: {len(rows)} 条")

    for poi_id, name_zh, lat, lng, city in rows:
        try:
            # 调用翻译
            resp = requests.post(TRANSLATE_URL, json={
                'text': name_zh,
                'target_lang': 'en'
            }, timeout=15)
            name_en = resp.json().get('translated_text', '')

            if name_en:
                # 写入数据库 + 缓存
                requests.post(DB_WRITE_URL, json={
                    'poi_id': poi_id,
                    'name_zh': name_zh,
                    'name_en': name_en,
                    'latitude': float(lat) if lat else None,
                    'longitude': float(lng) if lng else None,
                    'city': city,
                    'action': 'save'
                }, timeout=10)
                print(f"  ✓ {name_zh} → {name_en}")

            time.sleep(0.3)

        except Exception as e:
            print(f"  ✗ {name_zh}: {e}")

    cursor.close()
    conn.close()

pretranslate_top_pois()
```

### ✅ Phase 6 验证

```sql
-- 检查导入数量
SELECT city, COUNT(*) FROM poi_translations GROUP BY city ORDER BY COUNT(*) DESC;
-- 期望: 6 个城市，每个 100-300 条

-- 检查空间数据
SELECT gaode_poi_id, name_zh, geohash, ST_AsText(location::geometry)
FROM poi_translations WHERE city = '北京' LIMIT 5;
-- 期望: geohash 和 location 已自动填充

-- 检查预翻译
SELECT COUNT(*) FROM poi_translations WHERE name_en IS NOT NULL;
-- 期望: > 100 条已翻译
```

---

## Phase 7: 收尾

### 7.1 关闭数据库外网访问

```
控制台 → PostgreSQL 实例 → 基本信息 → 外网地址 → 关闭

⚠️ 关闭后只能通过 VPC 内网访问，确保云函数测试通过后再关闭
```

### 7.2 配置监控告警

```
云监控 → 告警策略 → 新建:
  名称: wanderchina-infra-alert
  对象: PostgreSQL + Redis + SCF
  规则:
    - PostgreSQL CPU > 80% 持续 5 分钟
    - PostgreSQL 存储 > 75%
    - Redis 内存 > 85%
    - SCF 错误率 > 5%
  通知: 短信 + 邮件
```

### 7.3 生成 Flutter .env

```env
# ===== 云函数 URL =====
TRANSLATE_URL=https://service-xxx.gz.tencentcs.com/
DB_WRITE_URL=https://service-xxx.gz.tencentcs.com/
NEARBY_URL=https://service-xxx.gz.tencentcs.com/
AUTH_URL=https://service-xxx.gz.tencentcs.com/
TRIP_URL=https://service-xxx.gz.tencentcs.com/
COS_TOKEN_URL=https://service-xxx.gz.tencentcs.com/
ASR_URL=https://service-xxx.gz.tencentcs.com/
TTS_URL=https://service-xxx.gz.tencentcs.com/

# ===== 高德地图 =====
AMAP_KEY_IOS=xxxxxxxxxx
AMAP_KEY_ANDROID=xxxxxxxxxx

# ===== COS =====
COS_STATIC_URL=https://wanderchina-static-xxxxx.cos.ap-guangzhou.myqcloud.com
COS_USER_BUCKET=wanderchina-user-xxxxx
COS_REGION=ap-guangzhou
```

### 7.4 记录所有连接信息

```yaml
# ===== 供后续开发使用 =====

PostgreSQL:
  内网: 172.16.1.x:5432
  数据库: wanderchina
  云函数用户: wc_scf_service / [密码]
  管理员: wanderchina_pg_prod / [密码]
  只读: wc_readonly / [密码]

Redis:
  内网: 172.16.2.x:6379
  密码: [密码]

COS:
  静态: https://wanderchina-static-{AppID}.cos.ap-guangzhou.myqcloud.com
  用户: wanderchina-user-{AppID}

云函数 URL（8 个）:
  deepseek_translate:   https://service-xxx.gz.tencentcs.com/
  translate_db_write:   https://service-xxx.gz.tencentcs.com/
  get_nearby_pois:      https://service-xxx.gz.tencentcs.com/
  user_auth:            https://service-xxx.gz.tencentcs.com/
  create_trip:          https://service-xxx.gz.tencentcs.com/
  baidu_voice_asr:      https://service-xxx.gz.tencentcs.com/
  baidu_voice_tts:      https://service-xxx.gz.tencentcs.com/
  get_cos_token:        https://service-xxx.gz.tencentcs.com/
```

---

## 最终验证清单

```
基础设施:
  □ VPC + 3 子网 + 2 安全组
  □ PostgreSQL 双机高可用运行中
  □ Redis 主从运行中
  □ COS 2 个 Bucket 可访问

数据库:
  □ 4 张表已创建
  □ PostGIS 空间索引工作
  □ 用户权限正确（DML only）
  □ 6 城市 POI 数据已导入（≥ 600 条）
  □ 核心 POI 英文翻译完成（≥ 100 条）

云函数:
  □ 8 个函数全部部署成功
  □ 4 公网函数无 VPC
  □ 4 内网函数在 wanderchina-vpc
  □ 8 个函数 URL 全部可调用
  □ 环境变量配置无遗漏

端到端:
  □ 翻译链路: translate → db_write(save) → db_write(batch_get) ✓
  □ 地图链路: get_nearby_pois 返回带距离的 POI ✓
  □ 用户链路: anonymous_auth → get_profile ✓
  □ 行程链路: create_trip(create) → create_trip(get) ✓
  □ 语音链路: tts 返回 Base64 音频 ✓

安全:
  □ 数据库外网已关闭
  □ Flutter .env 无任何后端密钥
  □ 告警策略已配置

交付物:
  □ Flutter .env 文件（8 个函数 URL）
  □ 连接信息汇总表
  □ POI 数据导入完成确认
```

---

**后端部署完成后，下一步是 Flutter 端开发——需要 Calvin 提供：**

1. 现有 Flutter 代码库（或 GitHub repo）
2. 屏幕规格文档（SCREEN_SPECIFICATIONS_v2.md）
3. 高德地图翻译蒙层的交互设计
4. 已完成模块清单 + 待开发模块清单
