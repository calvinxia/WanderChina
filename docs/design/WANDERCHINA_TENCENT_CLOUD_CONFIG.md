# WanderChina — 腾讯云服务配置指南

**适用阶段：** MVP → Early Growth  
**更新日期：** 2026-02-13  
**架构决策：** 腾讯云（主服务）+ Cloudflare R2（静态资源/备份）

---

## 目录

1. [整体架构](#1-整体架构)
2. [账号与基础配置](#2-账号与基础配置)
3. [PostgreSQL 数据库（TDSQL-C）](#3-postgresql-数据库tdsql-c)
4. [Redis 缓存](#4-redis-缓存)
5. [对象存储 COS](#5-对象存储-cos)
6. [CDN 内容分发](#6-cdn-内容分发)
7. [API 网关](#7-api-网关可选)
8. [安全配置](#8-安全配置)
9. [监控与告警](#9-监控与告警)
10. [Cloudflare R2 配置](#10-cloudflare-r2-配置)
11. [Flutter 端连接配置](#11-flutter-端连接配置)
12. [费用估算](#12-费用估算)
13. [上线检查清单](#13-上线检查清单)

---

## 1. 整体架构

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter App (iOS/Android)               │
└─────────────────────────────────────────────────────────────┘
          │                │               │
          ▼                ▼               ▼
   ┌─────────────┐  ┌──────────────┐  ┌──────────────┐
   │  高德地图   │  │ 云函数 SCF    │  │ DeepSeek API │
   │   SDK       │  │  (中间层)     │  │  (AI翻译)    │
   └─────────────┘  └──────────────┘  └──────────────┘
                            │
              ┌─────────────┴─────────────┐
              │       腾讯云 (主服务)        │
              │                           │
              │  ┌──────────────────────┐ │
              │  │  云数据库 PostgreSQL  │ │  ← POI翻译/用户/行程
              │  └──────────────────────┘ │
              │  ┌──────────────────────┐ │
              │  │    Redis 缓存        │ │  ← 热点数据/Session
              │  └──────────────────────┘ │
              │  ┌──────────────────────┐ │
              │  │    COS 对象存储      │ │  ← 用户头像/行程图片
              │  └──────────────────────┘ │
              │  ┌──────────────────────┐ │
              │  │    CDN 加速          │ │  ← 静态资源分发
              │  └──────────────────────┘ │
              └───────────────────────────┘
                            │
              ┌─────────────┴─────────────┐
              │     Cloudflare R2          │
              │  (POI翻译包备份 / 离线数据) │
              └───────────────────────────┘

云函数 SCF 作用:
  ① 隔离密钥（App 不存储任何 API Key）
  ② 下发临时 COS 凭证
  ③ 调用 DeepSeek/百度语音 API
  ④ 访问内网 PostgreSQL/Redis
```

---

## 2. 账号与基础配置

### 2.1 注册与实名认证

```
1. 访问 cloud.tencent.com 注册账号
2. 完成个人实名认证（身份证 + 手机号）
   - 如需备案，建议尽早升级为企业认证
3. 开通子账号（CAM）：建议不直接使用主账号操作
```

### 2.2 地域选择

WanderChina 的用户主要是在中国境内旅游的外国人，**所有服务选择同一地域**以减少内网通信延迟：

```yaml
首选地域: 广州（ap-guangzhou）
  原因: 你人在广州，运维方便；
        覆盖华南，到北上成西延迟 < 30ms

备选地域: 上海（ap-shanghai）
  原因: 如用户以华东为主时可迁移
```

> 所有服务（PostgreSQL / Redis / COS）**必须在同一地域**，否则内网流量需额外付费。

### 2.3 VPC 私有网络配置

创建一个专用 VPC，所有服务在内网通信，不暴露公网：

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

## 3. PostgreSQL 数据库（TDSQL-C）

### 3.1 产品选择

**使用：云数据库 PostgreSQL（标准版）**

> **说明：** 腾讯云的 TDSQL-C PostgreSQL 版本已停售，当前只有标准版云数据库 PostgreSQL 可用。TDSQL-C 仅支持 MySQL。

| 产品 | 特点 | 适用场景 |
|------|------|---------|
| **云数据库 PostgreSQL** ✅ | 固定规格，按量或包月 | 所有阶段通用 |
| TDSQL-C | 仅 MySQL，无 PostgreSQL | 不适用 |

**计费方式选择：**
- MVP 阶段：按量计费（灵活，可随时删除）
- 稳定运营：包年包月（便宜 15-20%）

### 3.2 创建实例

**操作路径：** 控制台 → 数据库 → 云数据库 PostgreSQL → 新建实例

```yaml
计费模式:    按量计费（MVP 推荐）或 包年包月（稳定后）
地域:        广州
可用区:      广州三区
数据库版本:  PostgreSQL 14.x
实例名:      wanderchina-pg-prod

规格配置:
  内存规格:  1核2GB（MVP 阶段）
             → 成长期可升级为 2核4GB、4核8GB
  存储类型:  SSD 云盘
  存储空间:  20 GB（可在线扩容至 6000GB）
  
架构版本:    双机高可用（生产推荐，自动主备切换）
             或 单机版（开发测试，便宜 50%）

网络:
  VPC:       wanderchina-vpc
  子网:      数据库子网 172.16.1.0/24
  
安全组:      wanderchina-db-sg（见第8节）

访问密码:    [生成强密码，≥16位，含大小写+数字+符号]

标签（可选）:
  项目:      WanderChina
  环境:      Production
```

**费用预估（1核2GB 双机高可用）：**
- 按量计费：约 ¥0.45/小时 = ¥324/月
- 包年包月：约 ¥260/月（节省 20%）

### 3.3 PostGIS 扩展安装

POI 坐标需要 PostGIS 支持，连接数据库后执行：

```sql
-- 安装 PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- 验证
SELECT PostGIS_Version();
```

### 3.4 数据库用户权限管理

#### 权限架构设计

根据 WanderChina 的架构（Flutter → 云函数 SCF → PostgreSQL），需要创建以下用户：

```
wanderchina_pg_prod (超级管理员)
  用途: 建表、修改结构、执行 SQL 脚本
  权限: SUPERUSER
  使用场景: 仅用于数据库维护和初始化

wc_scf_service (云函数专用用户)
  用途: 云函数连接数据库执行业务操作
  权限: SELECT, INSERT, UPDATE, DELETE
  使用场景: 所有云函数（翻译、行程、用户认证等）

wc_readonly (只读用户，可选)
  用途: 数据分析、报表查询
  权限: SELECT ONLY
  使用场景: BI 工具、数据分析师访问
```

#### 创建用户和授权

**连接到数据库：** pgAdmin → WanderChina-MVP → 右键 postgres → Query Tool

**步骤 1: 创建云函数专用用户（核心业务用户）**

```sql
-- ============================================================================
-- 创建云函数专用用户
-- ============================================================================

-- 1. 创建用户
CREATE USER wc_scf_service WITH PASSWORD 'ScfService@2026#Secure';

-- 2. 授予连接数据库的权限
GRANT CONNECT ON DATABASE postgres TO wc_scf_service;

-- 3. 授予 public schema 的使用权限
GRANT USAGE ON SCHEMA public TO wc_scf_service;

-- 4. 授予所有现有表的读写权限
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO wc_scf_service;

-- 5. 授予序列（自增ID）的使用权限
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO wc_scf_service;

-- 6. 授予执行函数的权限
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wc_scf_service;

-- 7. 设置未来创建的表的默认权限（重要！）
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO wc_scf_service;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO wc_scf_service;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT EXECUTE ON FUNCTIONS TO wc_scf_service;

-- 8. 限制最大连接数
ALTER USER wc_scf_service CONNECTION LIMIT 50;
```

**步骤 2: 创建只读用户（可选，用于数据分析）**

```sql
-- ============================================================================
-- 创建只读用户
-- ============================================================================

-- 1. 创建用户
CREATE USER wc_readonly WITH PASSWORD 'Readonly@2026#Safe';

-- 2. 授予连接权限
GRANT CONNECT ON DATABASE postgres TO wc_readonly;

-- 3. 授予 schema 使用权限
GRANT USAGE ON SCHEMA public TO wc_readonly;

-- 4. 授予所有表的只读权限
GRANT SELECT ON ALL TABLES IN SCHEMA public TO wc_readonly;

-- 5. 设置未来表的默认只读权限
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO wc_readonly;

-- 6. 限制最大连接数
ALTER USER wc_readonly CONNECTION LIMIT 10;
```

**步骤 3: 创建应用专用数据库（推荐）**

为了更好的隔离，建议创建专用数据库而不是使用默认的 `postgres`：

```sql
-- ============================================================================
-- 创建 WanderChina 专用数据库
-- ============================================================================

-- 1. 创建数据库
CREATE DATABASE wanderchina
    WITH 
    OWNER = wanderchina_pg_prod
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;

-- 2. 连接到新数据库（在 pgAdmin 中切换数据库）
\c wanderchina

-- 3. 重新安装扩展（在新数据库中）
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "postgis_topology";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- 4. 授予云函数用户权限
GRANT CONNECT ON DATABASE wanderchina TO wc_scf_service;
GRANT USAGE ON SCHEMA public TO wc_scf_service;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO wc_scf_service;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO wc_scf_service;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wc_scf_service;

-- 设置默认权限
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO wc_scf_service;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO wc_scf_service;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT EXECUTE ON FUNCTIONS TO wc_scf_service;

-- 5. 授予只读用户权限
GRANT CONNECT ON DATABASE wanderchina TO wc_readonly;
GRANT USAGE ON SCHEMA public TO wc_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO wc_readonly;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO wc_readonly;
```

#### 验证权限配置

**测试云函数用户权限：**

```sql
-- 切换到 wc_scf_service 用户
SET ROLE wc_scf_service;

-- 测试读取权限（应该成功）
SELECT version();

-- 测试写入权限（创建测试表）
CREATE TABLE test_permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    test_data TEXT
);

-- 插入数据
INSERT INTO test_permissions (test_data) VALUES ('test');

-- 查询数据
SELECT * FROM test_permissions;

-- 删除测试表
DROP TABLE test_permissions;

-- 切换回管理员
RESET ROLE;
```

**测试只读用户权限：**

```sql
-- 切换到只读用户
SET ROLE wc_readonly;

-- 测试读取（应该成功）
SELECT version();

-- 测试写入（应该失败）
CREATE TABLE should_fail (id INT);
-- ERROR: permission denied for schema public

-- 切换回管理员
RESET ROLE;
```

#### 安全最佳实践

**1. 密码强度要求**

```
推荐的密码格式：
  wc_scf_service:  ScfService@2026#Secure    (≥16位，大小写+数字+符号)
  wc_readonly:     Readonly@2026#Safe        (≥16位，大小写+数字+符号)
```

**2. 撤销不必要的 PUBLIC 权限**

```sql
-- 撤销 public schema 的默认权限（增强安全性）
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

-- 只允许管理员创建对象
GRANT CREATE ON SCHEMA public TO wanderchina_pg_prod;
```

**3. 定期审计**

```sql
-- 查看所有用户及其权限
SELECT 
    usename AS "用户名",
    usecreatedb AS "可创建数据库",
    usesuper AS "超级用户",
    valuntil AS "密码过期时间"
FROM pg_user
ORDER BY usename;

-- 查看某个用户的表权限
SELECT 
    grantee,
    table_schema,
    table_name,
    privilege_type
FROM information_schema.table_privileges
WHERE grantee = 'wc_scf_service'
ORDER BY table_name;

-- 查看当前连接数
SELECT 
    usename,
    COUNT(*) as connection_count
FROM pg_stat_activity
GROUP BY usename;
```

#### 云函数连接配置

**环境变量配置（云函数 SCF）：**

```yaml
DB_HOST:     172.16.1.x   # VPC 内网地址（不是外网地址！）
DB_PORT:     5432          # 内网端口
DB_NAME:     wanderchina   # 专用数据库
DB_USER:     wc_scf_service
DB_PASSWORD: ScfService@2026#Secure
DB_SSL:      require       # VPC 内网建议启用 SSL
```

**Python 云函数连接示例：**

```python
import os
import psycopg2

# 全局连接（复用连接池）
_db_conn = None

def get_db_connection():
    global _db_conn
    
    if _db_conn is None or _db_conn.closed:
        _db_conn = psycopg2.connect(
            host=os.environ['DB_HOST'],
            port=int(os.environ['DB_PORT']),
            database=os.environ['DB_NAME'],
            user=os.environ['DB_USER'],
            password=os.environ['DB_PASSWORD'],
            sslmode='require',
            connect_timeout=10
        )
    
    return _db_conn

def main_handler(event, context):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute("SELECT version()")
    result = cursor.fetchone()
    
    return {
        'statusCode': 200,
        'body': f'Connected to: {result[0]}'
    }
```

> **重要：** 云函数使用 `wc_scf_service` 账号连接数据库，从 VPC 内网访问。外网地址仅用于本地开发和维护。

### 3.5 连接信息

创建完成后，在控制台获取：

```yaml
内网地址（VPC内访问）:
  Host:     172.16.1.x（TDSQL-C 分配的内网 IP）
  Port:     5432
  
外网地址（本地开发访问，可临时开启）:
  Host:     gz-cdb-xxxxxxxx.sql.tencentcdb.com
  Port:     5432
  SSL:      require
```

### 3.6 备份配置

```yaml
自动备份:
  备份频率:  每天一次
  备份时间:  凌晨 02:00–04:00（低峰期）
  保留天数:  7 天（免费，超出按量付费）
  
手动备份:
  发版前:    手动触发一次备份快照
```

---

## 4. Redis 缓存

### 4.1 用途说明

```
缓存用途分类:
  ① POI 翻译热点缓存    TTL: 24h    约 50MB
  ② 用户 Session        TTL: 7d     约 10MB
  ③ DeepSeek 翻译结果   TTL: 30d    约 20MB
  ④ 高德 POI 搜索结果   TTL: 1h     约 30MB
  
预估总使用量: 约 200MB（含冗余）
```

### 4.2 创建实例

**操作路径：** 控制台 → 数据库 → Redis → 新建实例

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

### 4.3 Key 命名规范

```
poi:trans:{gaode_poi_id}:{lang}     → POI翻译缓存
  例: poi:trans:B000A7BD6F:en

session:{user_id}                    → 用户会话
  例: session:user_12345

search:{city}:{keyword}:{page}       → 搜索结果缓存
  例: search:北京:故宫:1

deepseek:trans:{md5(original_text)}  → DeepSeek 翻译结果
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

创建两个 Bucket，分开存储用途不同的文件：

**Bucket 1：用户内容（私有）**

```yaml
名称:         wanderchina-user-[AppID]
地域:         广州
访问权限:     私有读写
用途:
  - 用户头像: user/avatars/{user_id}.jpg
  - 行程封面: trips/covers/{trip_id}.jpg
  - (v2) 社区图片: posts/{post_id}/{img_index}.jpg
```

**Bucket 2：静态资源（公有读）**

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

### 5.2 CORS 配置（静态资源 Bucket）

```json
{
  "CORSRules": [
    {
      "AllowedOrigins": ["*"],
      "AllowedMethods": ["GET"],
      "AllowedHeaders": ["*"],
      "MaxAgeSeconds": 86400
    }
  ]
}
```

### 5.3 生命周期规则

```yaml
用户上传的临时文件:
  前缀: temp/
  规则: 7天后自动删除

旧版本离线翻译包:
  前缀: offline/
  规则: 保留最新3个版本，更早的转至低频存储（节省70%存储费）
```

### 5.4 COS 密钥配置

**不要在 App 中硬编码 SecretKey**，使用临时密钥：

```dart
// Flutter 端获取临时 COS 上传密钥的流程：
// 1. Flutter App → 后端 API 请求临时凭证
// 2. 后端调用腾讯云 STS 生成临时 SecretId/SecretKey（有效期 1800s）
// 3. Flutter 用临时凭证直传 COS，不经过后端

// 后端（Node.js/Python 均可）获取临时密钥示例：
// POST https://sts.tencentcloudapi.com
// Action: GetFederationToken
// Policy: 限制只能写入 user/avatars/{user_id}/ 路径
```

---

## 6. CDN 内容分发

### 6.1 接入配置

将 COS 静态资源 Bucket 绑定 CDN，提升全国访问速度：

**操作路径：** 控制台 → CDN → 域名管理 → 添加域名

```yaml
加速域名:    static.wanderchina.com（需备案）
             或 static.wanderchina.app（.app 域名无需备案，但 HTTPS 要求）
源站类型:    COS 源
源站地址:    wanderchina-static-[AppID].cos.ap-guangzhou.myqcloud.com
协议:        HTTPS
             
缓存规则:
  景点图片 (/attractions/*):   30天
  城市图片 (/cities/*):        30天
  离线翻译包 (/offline/*):     7天（更新频繁）
  App 资源 (/app/*):           1天
```

### 6.2 HTTPS 证书

```yaml
证书来源:    腾讯云免费 DV 证书（Let's Encrypt）
             控制台 → SSL 证书 → 免费申请
有效期:      1年，到期前30天腾讯云会发邮件提醒
```

---

## 7. 云函数 SCF（必需）

> **重要通知（2024-07-01 更新）：**  
> 腾讯云 API 网关将于 2025年6月30日停止服务。本文档已更新为使用**函数 URL**作为云函数触发器，这是腾讯云官方推荐的替代方案。函数 URL 配置更简单且完全免费，完全满足 WanderChina 的需求。

> **架构优化（NAT 网关优化）：**  
> 为避免使用 NAT 网关（约 ¥360/月），采用**拆分云函数**架构：公网函数调用外部 API（DeepSeek、百度），内网函数访问数据库。两者通过函数 URL 互相调用，**零额外成本**。

### 7.1 为什么必须用云函数

**安全问题：** 如果 Flutter 直连所有服务，需要在 App 内硬编码：
- PostgreSQL 密码
- 百度 API Key/Secret Key
- DeepSeek API Key
- COS 访问密钥

这些密钥会被反编译提取，造成严重安全隐患。

**解决方案：** 用云函数作为中间层，密钥保存在云端，App 只调用云函数接口。

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

**核心思路：** 将云函数分为两类，避免使用昂贵的 NAT 网关

```yaml
【公网函数】不启用 VPC
  作用: 调用外部 API（DeepSeek、百度语音）
  优势: 可以访问公网，无需 NAT 网关
  
  函数列表:
    ✅ deepseek_translate     (调用 DeepSeek 翻译 API)
    ✅ baidu_voice_asr        (调用百度语音识别)
    ✅ baidu_voice_tts        (调用百度语音合成)

【内网函数】启用 VPC
  作用: 访问内网数据库和 Redis
  优势: 高速内网连接，安全隔离
  
  函数列表:
    ✅ translate_db_write     (写入翻译结果到数据库)
    ✅ create_trip            (创建行程)
    ✅ user_auth              (用户认证)
    ✅ get_user_data          (获取用户数据)

【独立函数】不需要 VPC
  作用: 生成临时凭证，不需要访问内网
  
  函数列表:
    ✅ get_cos_token          (下发 COS 临时凭证)
```

**架构图：**

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter App                             │
└─────────────────────────────────────────────────────────────┘
          │                    │                    │
          ▼                    ▼                    ▼
   ┌─────────────┐      ┌─────────────┐      ┌─────────────┐
   │ 公网云函数   │      │ 内网云函数   │      │ 独立云函数   │
   │ (无 VPC)    │      │ (VPC 内网)  │      │ (无 VPC)    │
   └─────────────┘      └─────────────┘      └─────────────┘
          │                    │                    │
          ▼                    ▼                    ▼
   ┌─────────────┐      ┌─────────────┐      ┌─────────────┐
   │ DeepSeek    │      │ PostgreSQL  │      │ COS STS     │
   │ 百度语音     │      │ Redis       │      │ API         │
   └─────────────┘      └─────────────┘      └─────────────┘
   
   公网 API             VPC 内网访问         公网 API
   (HTTPS)             (172.16.x.x)        (HTTPS)
```

**成本对比：**

| 方案 | NAT 网关 | 月费 |
|------|---------|------|
| ❌ 传统方案（VPC + NAT） | 需要 | ¥360/月 |
| ✅ 拆分函数方案 | 不需要 | **¥0** |

### 7.3 需要的云函数清单

#### 公网函数（不启用 VPC）

| 函数名 | 功能 | 外部依赖 | 触发场景 |
|--------|------|---------|---------|
| `deepseek_translate` | 调用 DeepSeek 翻译 API | DeepSeek API | POI 名称翻译 |
| `baidu_voice_asr` | 调用百度语音识别 | 百度语音 API | 用户语音输入 |
| `baidu_voice_tts` | 调用百度语音合成 | 百度语音 API | 播放翻译结果 |
| `get_cos_token` | 生成 COS 临时凭证 | 腾讯云 STS | 用户上传图片 |

#### 内网函数（启用 VPC）

| 函数名 | 功能 | 内网依赖 | 触发场景 |
|--------|------|---------|---------|
| `translate_db_write` | 写入翻译到数据库 | PostgreSQL + Redis | 保存翻译结果 |
| `create_trip` | 创建行程记录 | PostgreSQL | 用户保存行程 |
| `user_auth` | 用户登录认证 | PostgreSQL + Redis | 用户登录 |
| `get_user_data` | 获取用户数据 | PostgreSQL + Redis | 加载用户信息 |

#### 完整翻译流程示例

```
用户在地图看到 "故宫博物院"
    ↓
Flutter 调用 deepseek_translate（公网函数）
    ↓ 调用 DeepSeek API
    ↓ 返回 {"en": "Palace Museum", "fr": "Musée du Palais", "es": "Museo del Palacio"}
    ↓
Flutter 调用 translate_db_write（内网函数）
    ↓ 写入 PostgreSQL poi_translations 表
    ↓ 写入 Redis 缓存（key: poi:trans:POI_ID:en）
    ↓ 返回 success
    ↓
地图显示 "Palace Museum"
```

---

### 7.4 创建公网云函数

#### 函数 1：deepseek_translate（DeepSeek 翻译）

**操作路径：** 控制台 → Serverless → 云函数 SCF → 新建

**基础配置：**

```yaml
函数名称:   deepseek_translate
运行环境:   Python 3.9
地域:       广州

执行配置:
  内存:       256 MB
  超时时间:   15 秒
  执行方法:   index.main_handler
  
网络配置:
  VPC:        不启用  ← 关键：可以访问公网 DeepSeek API
  
环境变量:
  DEEPSEEK_KEY:  sk-xxxxxxxxxxxxxxxx
  
触发器:
  类型:       函数 URL
  鉴权方式:   免鉴权
  CORS:       开启
    允许来源: *
    允许方法: POST, OPTIONS
```

**函数代码：**

创建文件 `index.py`：

```python
# deepseek_translate/index.py
# -*- coding: utf-8 -*-
"""
DeepSeek 翻译云函数（优化版）
- 支持 Prompt Caching（节省 90% 输入成本）
- 详细的 token 使用日志
- 成本监控
"""
import json
import os
import requests

# 固定的 System Prompt（会被 DeepSeek 缓存）
SYSTEM_PROMPTS = {
    'en': 'Translate the following Chinese text to English. Output only the translation, no explanations.',
    'fr': 'Translate the following Chinese text to French. Output only the translation, no explanations.',
    'es': 'Translate the following Chinese text to Spanish. Output only the translation, no explanations.',
    'de': 'Translate the following Chinese text to German. Output only the translation, no explanations.',
    'ja': 'Translate the following Chinese text to Japanese. Output only the translation, no explanations.',
    'ko': 'Translate the following Chinese text to Korean. Output only the translation, no explanations.',
}

def translate_with_deepseek(text, target_lang):
    """
    调用 DeepSeek API 翻译文本
    
    Args:
        text: 要翻译的中文文本
        target_lang: 目标语言代码
    
    Returns:
        dict: {
            'translated_text': str,
            'usage': dict,
            'cost': float
        }
    """
    url = 'https://api.deepseek.com/v1/chat/completions'
    
    # 从环境变量获取 API Key
    api_key = os.environ.get('DEEPSEEK_KEY')
    if not api_key:
        raise ValueError('Missing DEEPSEEK_KEY in environment variables')
    
    headers = {
        'Authorization': f'Bearer {api_key}',
        'Content-Type': 'application/json'
    }
    
    # 使用固定的 System Prompt（提高缓存命中率）
    system_prompt = SYSTEM_PROMPTS.get(target_lang, SYSTEM_PROMPTS['en'])
    
    payload = {
        'model': 'deepseek-chat',
        'messages': [
            {
                'role': 'system',
                'content': system_prompt  # 固定内容，会被缓存
            },
            {
                'role': 'user',
                'content': text
            }
        ],
        'temperature': 0.3,      # 低温度提高确定性
        'max_tokens': 100,       # POI 名称通常很短
        'top_p': 0.9
    }
    
    try:
        response = requests.post(
            url, 
            headers=headers, 
            json=payload, 
            timeout=10
        )
        response.raise_for_status()
        
        result = response.json()
        
        # 提取翻译结果
        translated_text = result['choices'][0]['message']['content'].strip()
        
        # 提取 token 使用量
        usage = result.get('usage', {})
        prompt_tokens = usage.get('prompt_tokens', 0)
        completion_tokens = usage.get('completion_tokens', 0)
        total_tokens = usage.get('total_tokens', 0)
        
        # 提取缓存信息（V3.2 新增）
        prompt_details = usage.get('prompt_tokens_details', {})
        cached_tokens = prompt_details.get('cached_tokens', 0)
        uncached_tokens = prompt_tokens - cached_tokens
        
        # 计算成本（DeepSeek V3.2 定价）
        cost = (
            uncached_tokens * 2 / 1_000_000 +     # 未缓存输入: ¥2/百万
            cached_tokens * 0.2 / 1_000_000 +      # 缓存输入: ¥0.2/百万
            completion_tokens * 3 / 1_000_000      # 输出: ¥3/百万
        )
        
        # 详细日志
        cache_hit_rate = (cached_tokens / prompt_tokens * 100) if prompt_tokens > 0 else 0
        print(f"Translation: '{text[:30]}...' → '{translated_text[:30]}...'")
        print(f"Tokens - Prompt: {prompt_tokens} (cached: {cached_tokens}, uncached: {uncached_tokens}), "
              f"Completion: {completion_tokens}, Total: {total_tokens}")
        print(f"Cache hit rate: {cache_hit_rate:.1f}%")
        print(f"Cost: ¥{cost:.8f}")
        
        return {
            'translated_text': translated_text,
            'usage': {
                'prompt_tokens': prompt_tokens,
                'cached_tokens': cached_tokens,
                'uncached_tokens': uncached_tokens,
                'completion_tokens': completion_tokens,
                'total_tokens': total_tokens,
                'cache_hit_rate': cache_hit_rate
            },
            'cost': cost
        }
        
    except requests.exceptions.Timeout:
        raise Exception('DeepSeek API request timeout')
    except requests.exceptions.HTTPError as e:
        if e.response.status_code == 401:
            raise Exception('Invalid DeepSeek API key')
        elif e.response.status_code == 429:
            raise Exception('DeepSeek rate limit exceeded')
        else:
            raise Exception(f'DeepSeek API error: {e.response.text}')
    except Exception as e:
        raise Exception(f'Translation failed: {str(e)}')

def main_handler(event, context):
    """
    云函数入口
    
    输入:
    {
      "text": "故宫博物院",
      "target_lang": "en"
    }
    
    输出:
    {
      "translated_text": "Palace Museum",
      "source_text": "故宫博物院",
      "target_lang": "en",
      "usage": {...},
      "cost": 0.000075
    }
    """
    try:
        # 解析请求体
        if isinstance(event, dict) and 'body' in event:
            body = json.loads(event['body'])
        else:
            body = event
        
        text = body.get('text')
        target_lang = body.get('target_lang', 'en')
        
        # 参数验证
        if not text:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': 'Missing required parameter: text'
                }, ensure_ascii=False)
            }
        
        supported_langs = ['en', 'fr', 'es', 'de', 'ja', 'ko']
        if target_lang not in supported_langs:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': f'Unsupported language. Supported: {", ".join(supported_langs)}'
                }, ensure_ascii=False)
            }
        
        # 调用翻译
        result = translate_with_deepseek(text, target_lang)
        
        # 返回结果
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'translated_text': result['translated_text'],
                'source_text': text,
                'target_lang': target_lang,
                'usage': result['usage'],
                'cost': result['cost']
            }, ensure_ascii=False)
        }
        
    except Exception as e:
        print(f'Translation error: {str(e)}')
        import traceback
        traceback.print_exc()
        
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': str(e)
            }, ensure_ascii=False)
        }
```

创建文件 `requirements.txt`：

```txt
requests==2.31.0
```

**部署后复制函数 URL：**

```
https://service-abc123-1234567.gz.apigw.tencentcs.com/release/deepseek_translate
```

**优化说明：**

1. ✅ **固定 System Prompt** - 使用常量字典，每个语言固定一个 prompt，提高缓存命中率
2. ✅ **详细日志** - 记录缓存命中率、token 使用、成本
3. ✅ **成本计算** - 精确计算每次调用的成本（区分缓存/非缓存）
4. ✅ **错误处理** - 完善的异常处理和堆栈跟踪

---

#### 函数 2：translate_db_write（写入翻译到数据库 + Redis 缓存）

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
  DB_HOST:         172.16.1.9  ← PostgreSQL 内网地址
  DB_PORT:         5432
  DB_NAME:         wanderchina
  DB_USER:         wc_scf_service
  DB_PASSWORD:     ScfService@2026#Secure
  REDIS_HOST:      172.16.2.x  ← Redis 内网地址
  REDIS_PORT:      6379
  REDIS_PASSWORD:  your_redis_password
  
触发器:     函数 URL
```

#### 函数 2：translate_db_write（写入翻译到数据库 + Redis 缓存）

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
  DB_HOST:         172.16.1.9  ← PostgreSQL 内网地址
  DB_PORT:         5432
  DB_NAME:         wanderchina
  DB_USER:         wc_scf_service
  DB_PASSWORD:     ScfService@2026#Secure
  REDIS_HOST:      172.16.2.x  ← Redis 内网地址
  REDIS_PORT:      6379
  REDIS_PASSWORD:  your_redis_password
  
触发器:     函数 URL
```

**函数代码：**

创建文件 `index.py`：

```python
# translate_db_write/index.py
# -*- coding: utf-8 -*-
"""
翻译结果写入云函数（带 Redis 缓存）
- 写入 PostgreSQL 数据库
- 写入 Redis 缓存（24小时）
- 先查缓存，避免重复翻译
"""
import json
import os
import psycopg2
import redis

# 全局连接池（复用连接）
_db_conn = None
_redis_client = None

def get_db_connection():
    """获取数据库连接（复用连接池）"""
    global _db_conn
    
    if _db_conn is None or _db_conn.closed:
        _db_conn = psycopg2.connect(
            host=os.environ['DB_HOST'],
            port=int(os.environ.get('DB_PORT', 5432)),
            database=os.environ['DB_NAME'],
            user=os.environ['DB_USER'],
            password=os.environ['DB_PASSWORD'],
            sslmode='require',
            connect_timeout=10
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
        # 测试连接
        _redis_client.ping()
    
    return _redis_client

def get_cached_translation(poi_id, target_lang):
    """
    从 Redis 获取缓存的翻译
    
    Args:
        poi_id: POI ID
        target_lang: 目标语言
    
    Returns:
        str or None: 缓存的翻译结果
    """
    try:
        r = get_redis_client()
        cache_key = f"poi:trans:{poi_id}:{target_lang}"
        cached = r.get(cache_key)
        
        if cached:
            print(f"Cache hit: {cache_key} = {cached}")
            return cached
        else:
            print(f"Cache miss: {cache_key}")
            return None
            
    except Exception as e:
        print(f"Redis get error: {str(e)}")
        return None  # 缓存失败不影响主流程

def set_cached_translation(poi_id, target_lang, translated_text, ttl=86400):
    """
    将翻译结果写入 Redis 缓存
    
    Args:
        poi_id: POI ID
        target_lang: 目标语言
        translated_text: 翻译结果
        ttl: 过期时间（秒），默认 24 小时
    """
    try:
        r = get_redis_client()
        cache_key = f"poi:trans:{poi_id}:{target_lang}"
        r.setex(cache_key, ttl, translated_text)
        print(f"Cache set: {cache_key} = {translated_text} (TTL: {ttl}s)")
        
    except Exception as e:
        print(f"Redis set error: {str(e)}")
        # 缓存写入失败不影响主流程

def save_to_database(poi_id, name_zh, name_en, name_fr=None, name_es=None):
    """
    将翻译结果保存到 PostgreSQL
    
    Args:
        poi_id: POI ID
        name_zh: 中文名称
        name_en: 英文名称
        name_fr: 法文名称（可选）
        name_es: 西班牙文名称（可选）
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("""
            INSERT INTO poi_translations 
            (gaode_poi_id, name_zh, name_en, name_fr, name_es, source)
            VALUES (%s, %s, %s, %s, %s, 'deepseek')
            ON CONFLICT (gaode_poi_id) DO UPDATE SET
                name_en = EXCLUDED.name_en,
                name_fr = EXCLUDED.name_fr,
                name_es = EXCLUDED.name_es,
                updated_at = NOW()
        """, (poi_id, name_zh, name_en, name_fr, name_es))
        
        conn.commit()
        print(f"Database saved: POI {poi_id}")
        
    except Exception as e:
        conn.rollback()
        print(f"Database error: {str(e)}")
        raise
    finally:
        cursor.close()

def main_handler(event, context):
    """
    云函数入口
    
    输入:
    {
      "poi_id": "B000A8UJVW",
      "name_zh": "故宫博物院",
      "name_en": "Palace Museum",
      "name_fr": "Musée du Palais",
      "name_es": "Museo del Palacio"
    }
    
    或者只查询缓存:
    {
      "poi_id": "B000A8UJVW",
      "target_lang": "en",
      "action": "get"
    }
    
    输出:
    {
      "success": true,
      "poi_id": "B000A8UJVW",
      "cached": true/false
    }
    """
    try:
        if isinstance(event, dict) and 'body' in event:
            body = json.loads(event['body'])
        else:
            body = event
        
        action = body.get('action', 'save')  # 默认是保存
        poi_id = body.get('poi_id')
        
        if not poi_id:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': 'Missing poi_id'
                }, ensure_ascii=False)
            }
        
        # 操作 1: 获取缓存（查询模式）
        if action == 'get':
            target_lang = body.get('target_lang', 'en')
            cached_text = get_cached_translation(poi_id, target_lang)
            
            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'poi_id': poi_id,
                    'target_lang': target_lang,
                    'cached': cached_text is not None,
                    'translated_text': cached_text
                }, ensure_ascii=False)
            }
        
        # 操作 2: 保存翻译（默认模式）
        name_zh = body.get('name_zh')
        name_en = body.get('name_en')
        name_fr = body.get('name_fr')
        name_es = body.get('name_es')
        
        if not all([name_zh, name_en]):
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': 'Missing required fields: name_zh and name_en'
                }, ensure_ascii=False)
            }
        
        # 保存到数据库
        save_to_database(poi_id, name_zh, name_en, name_fr, name_es)
        
        # 写入 Redis 缓存（24小时）
        set_cached_translation(poi_id, 'en', name_en, ttl=86400)
        if name_fr:
            set_cached_translation(poi_id, 'fr', name_fr, ttl=86400)
        if name_es:
            set_cached_translation(poi_id, 'es', name_es, ttl=86400)
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'success': True,
                'poi_id': poi_id,
                'cached': True
            }, ensure_ascii=False)
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        import traceback
        traceback.print_exc()
        
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': str(e)
            }, ensure_ascii=False)
        }
```

创建文件 `requirements.txt`：

```txt
psycopg2-binary==2.9.9
redis==5.0.1
```

**部署后复制函数 URL：**

```
https://service-def456-1234567.gz.apigw.tencentcs.com/release/translate_db_write
```

**Redis 缓存策略：**

```yaml
缓存 Key 格式:
  poi:trans:{poi_id}:{lang}
  
示例:
  poi:trans:B000A8UJVW:en  → "Palace Museum"
  poi:trans:B000A8UJVW:fr  → "Musée du Palais"
  
过期时间:
  24 小时（86400 秒）
  
优势:
  ✅ 避免重复调用 DeepSeek API
  ✅ 响应速度更快（从 2-3秒 降到 <50ms）
  ✅ 节省 40-60% 的 API 成本
```

---

### 7.5 Flutter 调用示例（带 Redis 缓存优化）

完整的翻译流程：先查 Redis 缓存 → 未命中才调用 DeepSeek → 存储结果

```dart
// lib/services/translation/translation_service.dart

class TranslationService {
  // 公网函数 URL
  static const String _deepseekTranslateUrl = 
      'https://service-abc123-1234567.gz.apigw.tencentcs.com/release/deepseek_translate';
  
  // 内网函数 URL
  static const String _dbWriteUrl = 
      'https://service-def456-1234567.gz.apigw.tencentcs.com/release/translate_db_write';
  
  /// 智能翻译 POI（优先使用缓存）
  static Future<POITranslation?> translatePOI({
    required String poiId,
    required String nameZh,
  }) async {
    try {
      // Step 1: 检查 Redis 缓存
      print('Checking cache for POI: $poiId');
      
      final cacheCheck = await _checkCache(poiId);
      
      if (cacheCheck != null && cacheCheck.hasAllTranslations) {
        print('✅ Cache hit! Using cached translations');
        return cacheCheck;
      }
      
      // Step 2: 缓存未命中，调用 DeepSeek 翻译
      print('❌ Cache miss. Calling DeepSeek API...');
      
      final futures = [
        _callDeepSeek(nameZh, 'en'),
        _callDeepSeek(nameZh, 'fr'),
        _callDeepSeek(nameZh, 'es'),
      ];
      
      final results = await Future.wait(futures);
      final nameEn = results[0];
      final nameFr = results[1];
      final nameEs = results[2];
      
      // Step 3: 保存到数据库和 Redis
      print('Saving translations to database and cache...');
      
      await _saveTranslation(
        poiId: poiId,
        nameZh: nameZh,
        nameEn: nameEn,
        nameFr: nameFr,
        nameEs: nameEs,
      );
      
      return POITranslation(
        poiId: poiId,
        nameZh: nameZh,
        nameEn: nameEn,
        nameFr: nameFr,
        nameEs: nameEs,
        fromCache: false,
      );
      
    } catch (e) {
      print('Translation failed: $e');
      return null;
    }
  }
  
  /// 检查 Redis 缓存
  static Future<POITranslation?> _checkCache(String poiId) async {
    try {
      // 并行检查三种语言的缓存
      final futures = [
        http.post(
          Uri.parse(_dbWriteUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'poi_id': poiId,
            'target_lang': 'en',
            'action': 'get',
          }),
        ),
        http.post(
          Uri.parse(_dbWriteUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'poi_id': poiId,
            'target_lang': 'fr',
            'action': 'get',
          }),
        ),
        http.post(
          Uri.parse(_dbWriteUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'poi_id': poiId,
            'target_lang': 'es',
            'action': 'get',
          }),
        ),
      ];
      
      final responses = await Future.wait(futures);
      
      // 解析缓存结果
      final enData = json.decode(responses[0].body);
      final frData = json.decode(responses[1].body);
      final esData = json.decode(responses[2].body);
      
      // 检查是否所有语言都有缓存
      if (enData['cached'] == true && 
          frData['cached'] == true && 
          esData['cached'] == true) {
        return POITranslation(
          poiId: poiId,
          nameZh: '', // 缓存中没有中文名
          nameEn: enData['translated_text'],
          nameFr: frData['translated_text'],
          nameEs: esData['translated_text'],
          fromCache: true,
        );
      }
      
      return null; // 缓存不完整
      
    } catch (e) {
      print('Cache check failed: $e');
      return null;
    }
  }
  
  /// 调用 DeepSeek 翻译单个语言
  static Future<String> _callDeepSeek(String text, String targetLang) async {
    final response = await http.post(
      Uri.parse(_deepseekTranslateUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'text': text,
        'target_lang': targetLang,
      }),
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('DeepSeek timeout'),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // 记录成本信息（可选）
      if (data['cost'] != null) {
        print('Translation cost: ¥${data['cost']}');
        print('Cache hit rate: ${data['usage']?['cache_hit_rate']}%');
      }
      
      return data['translated_text'];
    }
    
    throw Exception('DeepSeek API error: ${response.statusCode}');
  }
  
  /// 保存翻译到数据库和 Redis
  static Future<void> _saveTranslation({
    required String poiId,
    required String nameZh,
    required String nameEn,
    required String nameFr,
    required String nameEs,
  }) async {
    final response = await http.post(
      Uri.parse(_dbWriteUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'poi_id': poiId,
        'name_zh': nameZh,
        'name_en': nameEn,
        'name_fr': nameFr,
        'name_es': nameEs,
        'action': 'save', // 默认值，可省略
      }),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to save translation');
    }
  }
}

// POI 翻译数据模型
class POITranslation {
  final String poiId;
  final String nameZh;
  final String nameEn;
  final String nameFr;
  final String nameEs;
  final bool fromCache;
  
  POITranslation({
    required this.poiId,
    required this.nameZh,
    required this.nameEn,
    required this.nameFr,
    required this.nameEs,
    this.fromCache = false,
  });
  
  bool get hasAllTranslations {
    return nameEn.isNotEmpty && nameFr.isNotEmpty && nameEs.isNotEmpty;
  }
}
```

**使用示例：**

```dart
// 在地图控制器中调用
void onPOITapped(String poiId, String nameZh) async {
  final translation = await TranslationService.translatePOI(
    poiId: poiId,
    nameZh: nameZh,
  );
  
  if (translation != null) {
    if (translation.fromCache) {
      print('🚀 Fast! Loaded from cache');
    } else {
      print('🔄 Translated via DeepSeek API');
    }
    
    // 更新地图标签
    updateMapMarker(
      poiId: poiId,
      label: translation.nameEn, // 根据用户语言选择
    );
  }
}
```

**性能对比：**

| 场景 | 响应时间 | 成本 | 数据来源 |
|------|---------|------|---------|
| **缓存命中** | ~50ms | ¥0 | Redis |
| **缓存未命中** | ~2-3s | ¥0.000075 | DeepSeek API |

**缓存命中率预估：**

```
首次访问热门 POI:  0%（需要翻译）
二次访问热门 POI:  100%（从缓存）
24小时内重复访问:  80-90%（缓存有效期内）
24小时后访问:      40-60%（部分缓存过期）

整体缓存命中率:     约 60%
成本节省:           约 60%
```
```

---

### 7.6 费用说明

```yaml
云函数调用费用（按实际使用计费）:
  免费额度（每月）:
    调用次数:   100 万次
    资源使用:   40 万 GB-秒
    外网流出:   1 GB
  
  超额计费:
    调用次数:   ¥0.0133/万次
    资源使用:   ¥0.00011108/GB-秒
    外网流出:   ¥0.80/GB

函数 URL 触发器费用:
  ✅ 完全免费（无额外费用）

NAT 网关费用（拆分函数方案无需此项）:
  ❌ 不需要 NAT 网关 = 节省 ¥360/月

MVP 阶段预估（1000 MAU）:
  公网函数调用:   约 7.5 万次/月（翻译：5000次/天 × 3语言 × 5天平均）
  内网函数调用:   约 5 万次/月
  总调用次数:     12.5 万次/月（远低于 100 万免费额度）
  触发器:         ¥0（函数 URL 免费）
  NAT 网关:       ¥0（不需要）
  结论:           完全免费
  
成长期（1 万 MAU）:
  总调用次数:   125 万次/月
  超额费用:     (125-100) × ¥0.0133 = ¥3.33/月
  NAT 网关:     ¥0（不需要）
  结论:         几乎可忽略

成本对比:
  传统方案（VPC + NAT 网关）:  ¥360/月 + 云函数费用
  拆分函数方案:                ¥0/月（MVP）或 ¥3.33/月（成长期）
  节省:                        ¥360/月（100%）
```

---

### 7.7 最佳实践

#### 1. 连接池复用

```python
# ✅ 正确：全局变量复用连接
_db_conn = None
_redis_client = None

def get_db_connection():
    global _db_conn
    if _db_conn is None or _db_conn.closed:
        _db_conn = psycopg2.connect(...)
    return _db_conn

# ❌ 错误：每次创建新连接
def main_handler(event, context):
    conn = psycopg2.connect(...)  # 性能差
```

#### 2. 超时控制

```python
# 所有外部 API 调用都设置超时
response = requests.post(url, json=payload, timeout=10)
```

#### 3. 错误日志

```python
# 使用 print() 输出日志，会自动记录到云函数日志
try:
    result = some_operation()
except Exception as e:
    print(f"Error in operation: {str(e)}")  # 会输出到日志
    print(f"Event data: {json.dumps(event)}")  # 调试信息
    raise
```

#### 4. 环境变量验证

```python
def main_handler(event, context):
    # 启动时检查必需的环境变量
    required_vars = ['DB_HOST', 'DB_USER', 'DB_PASSWORD']
    missing = [v for v in required_vars if not os.environ.get(v)]
    
    if missing:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': f'Missing env vars: {missing}'})
        }
```

#### 5. VPC 配置检查清单

**公网函数（不启用 VPC）：**
```
✅ deepseek_translate
✅ baidu_voice_asr
✅ baidu_voice_tts
✅ get_cos_token

配置:
  VPC: 不启用
  用途: 调用外部公网 API
```

**内网函数（启用 VPC）：**
```
✅ translate_db_write
✅ create_trip
✅ user_auth
✅ get_user_data

配置:
  VPC: wanderchina-vpc
  子网: 应用子网
  用途: 访问内网数据库/Redis
```

---

## 8. 对象存储 COS（必需）
  DB_PORT:         5432
  DB_NAME:         wanderchina
  DB_USER:         wc_scf_service
  DB_PASSWORD:     ScfService@2026#Secure
  DEEPSEEK_KEY:    sk-xxxxxxxx
  REDIS_HOST:      172.16.2.x
  REDIS_PASSWORD:  xxxxxxxx

网络配置:
  VPC:        wanderchina-vpc
  子网:       应用子网（需访问内网数据库）
```

**函数代码（Python）：**

```python
# index.py
import json
import os
import psycopg2
import redis
import requests
from hashlib import md5

# 连接池（全局变量，复用连接）
db_conn = None
redis_client = None

def get_db_connection():
    global db_conn
    if db_conn is None or db_conn.closed:
        db_conn = psycopg2.connect(
            host=os.environ['DB_HOST'],
            port=os.environ['DB_PORT'],
            database=os.environ['DB_NAME'],
            user=os.environ['DB_USER'],
            password=os.environ['DB_PASSWORD'],
            sslmode='require'
        )
    return db_conn

def get_redis_client():
    global redis_client
    if redis_client is None:
        redis_client = redis.Redis(
            host=os.environ['REDIS_HOST'],
            port=6379,
            password=os.environ['REDIS_PASSWORD'],
            decode_responses=True
        )
    return redis_client

def translate_with_deepseek(text, target_lang):
    """调用 DeepSeek 翻译"""
    url = 'https://api.deepseek.com/v1/chat/completions'
    headers = {
        'Authorization': f"Bearer {os.environ['DEEPSEEK_KEY']}",
        'Content-Type': 'application/json'
    }
    
    lang_map = {'en': 'English', 'fr': 'French', 'es': 'Spanish'}
    
    payload = {
        'model': 'deepseek-chat',
        'messages': [
            {'role': 'system', 'content': f'Translate to {lang_map[target_lang]}. Output only the translation, no explanations.'},
            {'role': 'user', 'content': text}
        ],
        'temperature': 0.3,
    }
    
    response = requests.post(url, headers=headers, json=payload, timeout=10)
    response.raise_for_status()
    
    result = response.json()
    return result['choices'][0]['message']['content'].strip()

def main_handler(event, context):
    try:
        body = json.loads(event['body'])
        poi_id = body['poi_id']
        name_zh = body['name_zh']
        
        # 1. 检查 Redis 缓存
        r = get_redis_client()
        cache_key_en = f"poi:trans:{poi_id}:en"
        cached_en = r.get(cache_key_en)
        
        if cached_en:
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'name_en': cached_en,
                    'cached': True
                })
            }
        
        # 2. 翻译（DeepSeek）
        name_en = translate_with_deepseek(name_zh, 'en')
        name_fr = translate_with_deepseek(name_zh, 'fr')
        name_es = translate_with_deepseek(name_zh, 'es')
        
        # 3. 写入数据库
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO poi_translations (gaode_poi_id, name_zh, name_en, name_fr, name_es, source)
            VALUES (%s, %s, %s, %s, %s, 'deepseek')
            ON CONFLICT (gaode_poi_id) DO UPDATE SET
                name_en = EXCLUDED.name_en,
                name_fr = EXCLUDED.name_fr,
                name_es = EXCLUDED.name_es,
                updated_at = NOW()
        """, (poi_id, name_zh, name_en, name_fr, name_es))
        conn.commit()
        
        # 4. 写入 Redis 缓存（24 小时）
        r.setex(f"poi:trans:{poi_id}:en", 86400, name_en)
        r.setex(f"poi:trans:{poi_id}:fr", 86400, name_fr)
        r.setex(f"poi:trans:{poi_id}:es", 86400, name_es)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'name_en': name_en,
                'name_fr': name_fr,
                'name_es': name_es,
                'cached': False
            })
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
```


## 8. 对象存储 COS（必需）
    required String nameZh,
  }) async {
    final response = await http.post(
      Uri.parse(_translateTextUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'poi_id': poiId,
        'name_zh': nameZh,
      }),
    );
    
    if (response.statusCode == 200) {
      return POITranslation.fromJson(json.decode(response.body));
    }
    return null;
  }
  
  /// 语音翻译
  static Future<VoiceTranslationResult?> voiceTranslate({
    required String audioBase64,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final response = await http.post(
      Uri.parse(_voiceTranslateUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'audio': audioBase64,
        'source_lang': sourceLanguage,
        'target_lang': targetLanguage,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return VoiceTranslationResult(
        originalText: data['original_text'],
        translatedText: data['translated_text'],
        audioBytes: base64Decode(data['audio_base64']),
      );
    }
    return null;
  }
}
```

---

## 8. 对象存储 COS（必需）

### 8.1 安全组规则

**数据库安全组（wanderchina-db-sg）**

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

**不要硬编码任何密钥到代码里**，统一使用以下方案：

```yaml
本地开发:
  方式:  .env 文件（加入 .gitignore）
  工具:  flutter_dotenv 包

CI/CD:
  方式:  GitHub Actions Secrets 或 腾讯云 CODING 环境变量

生产环境:
  方式:  腾讯云密钥管理系统（KMS）或直接在 SCF 环境变量里配置
```

**.env 文件模板（仅用于本地测试，生产环境通过云函数访问）：**

```env
# 腾讯云数据库（仅本地测试用，生产环境在云函数环境变量中配置）
# ⚠️ 生产环境 Flutter App 不应直连数据库，必须通过云函数 API
DB_HOST=gz-postgres-eixcpo07.sql.tencentcdb.com  # 外网地址，仅本地开发
DB_PORT=26300  # 外网端口
DB_NAME=wanderchina
DB_USER=wc_readonly  # 本地测试用只读账号
DB_PASSWORD=Readonly@2026#Safe

# 腾讯云 Redis（内网地址，仅云函数可访问）
REDIS_HOST=172.16.2.x
REDIS_PORT=6379
REDIS_PASSWORD=your_redis_password

# 腾讯云 COS
COS_SECRET_ID=AKIDxxxxxxxxxxxxxx
COS_SECRET_KEY=xxxxxxxxxxxxxxxxxx
COS_BUCKET=wanderchina-static-xxxxxxxx
COS_REGION=ap-guangzhou

# DeepSeek
DEEPSEEK_API_KEY=sk-xxxxxxxxxxxxxxxxxx

# 百度语音
BAIDU_API_KEY=xxxxxxxxxxxxxxxxxx
BAIDU_SECRET_KEY=xxxxxxxxxxxxxxxxxx

# 高德地图
AMAP_KEY_IOS=xxxxxxxxxxxxxxxxxx
AMAP_KEY_ANDROID=xxxxxxxxxxxxxxxxxx
```

### 8.3 数据库 SSL 连接

所有生产环境数据库连接必须启用 SSL：

```dart
// lib/core/config/database_config.dart
class DatabaseConfig {
  static const String host     = String.fromEnvironment('DB_HOST');
  static const int    port     = 5432;
  static const String database = 'wanderchina';
  static const String username = String.fromEnvironment('DB_USER');
  static const String password = String.fromEnvironment('DB_PASSWORD');

  static ConnectionSettings get settings => const ConnectionSettings(
    sslMode: SslMode.require,                    // 强制 SSL
    connectTimeout: Duration(seconds: 10),
    queryTimeout: Duration(seconds: 15),
  );

  static Endpoint get endpoint => Endpoint(
    host:     host,
    port:     port,
    database: database,
    username: username,
    password: password,
  );
}
```

---

## 9. 监控与告警

### 9.1 基础监控（免费）

腾讯云默认为所有产品提供基础监控，在控制台 → 云监控 → 概览 中可看到：

```
PostgreSQL 监控指标:
  - CPU 使用率（告警阈值: >80%）
  - 内存使用率（告警阈值: >85%）
  - 存储使用率（告警阈值: >75%）
  - 连接数（告警阈值: >80%最大连接数）
  - 慢查询数量（告警阈值: >10条/分钟）

Redis 监控指标:
  - 内存使用率（告警阈值: >85%）
  - 连接数
  - QPS
```

### 9.2 告警配置

**操作路径：** 云监控 → 告警策略 → 新建

```yaml
告警策略名:   wanderchina-db-alert
告警对象:     wanderchina-pg-prod, wanderchina-redis-prod
通知方式:     短信 + 邮件（添加你的手机号和邮箱）
```

### 9.3 数据库慢查询日志

```sql
-- 开启慢查询日志（> 1秒的查询会被记录）
-- 在腾讯云控制台 → 数据库 → 参数设置 中修改：
log_min_duration_statement = 1000  -- 单位毫秒
```

---

## 10. Cloudflare R2 配置

R2 作为 COS 的补充，主要承担两个角色：
1. **POI 翻译数据的全量备份**（每日同步）
2. **面向海外用户的静态资源 CDN**（景点图片等，Cloudflare 全球节点更快）

### 10.1 创建 Bucket

```yaml
登录: dash.cloudflare.com → R2 → Create bucket
Bucket 名称:  wanderchina-backup
地域:         Automatic（Cloudflare 自动选择最近节点）
```

### 10.2 API Token 配置

```yaml
操作路径: Cloudflare Dashboard → My Profile → API Tokens → Create Token

权限设置:
  Account: Cloudflare R2 Storage → Edit
  Zone:    不需要（只用 R2）

生成后保存以下信息（只显示一次）:
  Account ID:         xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  Access Key ID:      xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  Secret Access Key:  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  Endpoint:           https://{Account_ID}.r2.cloudflarestorage.com
```

### 10.3 每日备份脚本

每天凌晨自动将 PostgreSQL 的 `poi_translations` 表导出为 JSON，上传至 R2：

```python
# scripts/backup_poi_to_r2.py
import psycopg2
import boto3
import json
import os
from datetime import datetime

def backup_poi_translations():
    # 连接 PostgreSQL
    conn = psycopg2.connect(
        host=os.environ['DB_HOST'],
        port=5432,
        database='wanderchina',
        user=os.environ['DB_USER'],
        password=os.environ['DB_PASSWORD'],
        sslmode='require'
    )
    
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM poi_translations ORDER BY id")
    
    rows = cursor.fetchall()
    columns = [desc[0] for desc in cursor.description]
    data = [dict(zip(columns, row)) for row in rows]
    
    # 上传至 R2
    s3 = boto3.client(
        's3',
        endpoint_url=os.environ['R2_ENDPOINT'],
        aws_access_key_id=os.environ['R2_ACCESS_KEY'],
        aws_secret_access_key=os.environ['R2_SECRET_KEY'],
        region_name='auto'
    )
    
    filename = f"poi_translations_{datetime.now().strftime('%Y%m%d')}.json"
    
    s3.put_object(
        Bucket='wanderchina-backup',
        Key=f"backups/poi/{filename}",
        Body=json.dumps(data, ensure_ascii=False, default=str),
        ContentType='application/json'
    )
    
    print(f"✅ Backed up {len(data)} POI records to R2: {filename}")
    conn.close()

if __name__ == '__main__':
    backup_poi_translations()
```

### 10.4 离线翻译包生成

将 POI 翻译数据打包为城市维度的 JSON，供 App 离线缓存：

```python
# scripts/generate_offline_packages.py
# 为每个城市生成一个离线翻译包，上传至 R2

CITIES = ['北京', '上海', '广州', '深圳', '成都', '西安']

for city in CITIES:
    cursor.execute(
        "SELECT gaode_poi_id, name_zh, name_en, name_fr, name_es, "
        "category_en, lat, lng, priority_score "
        "FROM poi_translations WHERE city = %s ORDER BY priority_score DESC",
        (city,)
    )
    # ... 生成 JSON 并上传 R2
    # Key: offline/poi_{city_pinyin}_v{version}.json
    # 例: offline/poi_beijing_v20260213.json
```

---

## 11. Flutter 端连接配置

### 11.1 pubspec.yaml 依赖

```yaml
dependencies:
  # PostgreSQL
  postgres: ^2.6.2

  # Redis（如需直连，通常由后端代理）
  # resp_client: ^0.4.0

  # COS 上传（使用腾讯云官方插件或 http 直传）
  http: ^1.1.0
  
  # 环境变量
  flutter_dotenv: ^5.1.0
```

### 11.2 数据库连接池

```dart
// lib/core/database/db_pool.dart
import 'package:postgres/postgres.dart';
import '../config/database_config.dart';

class DBPool {
  static Pool? _pool;

  static Future<Pool> get instance async {
    _pool ??= await Pool.withEndpoints(
      [DatabaseConfig.endpoint],
      settings: PoolSettings(
        maxConnectionAge: const Duration(hours: 1),
        maxConnectionCount: 5,         // MVP阶段5个连接足够
        connectTimeout: const Duration(seconds: 10),
      ),
    );
    return _pool!;
  }

  /// 执行查询（自动从连接池获取/释放连接）
  static Future<Result> query(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    final pool = await instance;
    return pool.execute(Sql.named(sql), parameters: parameters);
  }
}
```

### 11.3 COS 图片上传

```dart
// lib/services/storage/cos_upload_service.dart
class COSUploadService {
  static const String _bucket = 'wanderchina-user-xxxxxxxx';
  static const String _region = 'ap-guangzhou';
  static const String _cdnBase = 'https://static.wanderchina.com';

  /// 上传用户头像，返回 CDN 访问 URL
  Future<String?> uploadAvatar({
    required String userId,
    required File imageFile,
  }) async {
    // 1. 从后端获取临时上传凭证
    final credentials = await _getTempCredentials(
      allowPath: 'user/avatars/$userId/',
    );
    if (credentials == null) return null;

    // 2. 直传 COS
    final key = 'user/avatars/$userId.jpg';
    final url = 'https://$_bucket.cos.$_region.myqcloud.com/$key';

    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Authorization': credentials.authorization,
        'Content-Type': 'image/jpeg',
        'x-cos-security-token': credentials.sessionToken,
      },
      body: await imageFile.readAsBytes(),
    );

    if (response.statusCode == 200) {
      return '$_cdnBase/$key';
    }
    return null;
  }

  Future<TempCredentials?> _getTempCredentials({
    required String allowPath,
  }) async {
    // 调用你的后端 API 获取 STS 临时凭证
    // 避免在 App 中暴露主 SecretKey
    final res = await http.post(
      Uri.parse('${EnvConfig.apiBase}/storage/credentials'),
      body: {'path': allowPath},
    );
    if (res.statusCode == 200) {
      return TempCredentials.fromJson(jsonDecode(res.body));
    }
    return null;
  }
}
```

---

## 12. 费用估算

### 12.1 MVP 阶段月费（0–1000 MAU）

| 服务 | 规格 | 预估月费 |
|------|------|---------|
| **云数据库 PostgreSQL** | 1核2GB 双机，20GB SSD | **¥260–324** |
| Redis 标准版 | 1GB 主从 | ¥60 |
| **云函数 SCF** | 15 万次调用/月 | **¥0**（免费额度内） |
| COS 存储 | ~10GB | ¥3 |
| CDN 流量 | ~50GB | ¥15 |
| 带宽/流量（其他） | — | ¥10 |
| **腾讯云合计** | | **¥350–410/月** |
| Cloudflare R2 | 10GB 存储 + 备份流量 | 免费（10GB 免费额度内） |
| **总计** | | **¥350–410/月** |

> **说明：** 
> - 云函数在 100 万次调用/月内完全免费，MVP 阶段无需付费
> - 按量计费稍贵但灵活，包月可节省 ¥60-70/月

### 12.2 成长阶段月费（1万 MAU）

| 服务 | 规格 | 预估月费 |
|------|------|---------|
| 云数据库 PostgreSQL | 2核4GB，100GB | ¥520–650 |
| Redis | 4GB 集群版 | ¥240 |
| **云函数 SCF** | 150 万次调用/月 | **¥7**（超出 50 万次） |
| COS 存储 | ~100GB | ¥25 |
| CDN 流量 | ~500GB | ¥125 |
| **腾讯云合计** | | **¥920–1050/月** |

> **参考：** 百度语音（ASR+TTS）约 ¥3000–5000/月，DeepSeek 翻译约 ¥200–500/月（主要成本不在云服务）

### 12.3 费用控制建议

```
1. 数据库连接池严格控制最大连接数（≤ 10），避免资源浪费
2. Redis 缓存 POI 翻译结果，TTL 24h，减少数据库查询
3. COS 静态资源开启 CDN，减少 COS 直接请求流量费
4. MVP 阶段用按量计费，测试稳定后转包月节省 20%
5. 开启腾讯云费用告警（月费超过 ¥500 时短信提醒）
6. 单机版比双机便宜 50%，开发测试环境可用单机
```

**进一步优化：**
- 包年比包月再便宜 17%（确定长期使用后可考虑）
- 凌晨 2-6 点设置数据库只读，减少写入压力
- 定期清理过期数据（如 30 天前的临时记录）

---

## 13. 上线检查清单

### 基础服务

- [ ] VPC 私有网络创建完成，子网规划到位
- [ ] 云数据库 PostgreSQL 实例创建，PostGIS 扩展已安装
- [ ] `poi_translations_init.sql` 建表脚本已执行
- [ ] `poi_translations_seed.sql` 种子数据已导入
- [ ] Redis 实例创建，连接测试通过
- [ ] COS 两个 Bucket 创建（用户内容 + 静态资源）
- [ ] CDN 域名接入，HTTPS 证书配置完成

### 云函数 SCF

**公网函数（不启用 VPC）：**
- [ ] deepseek_translate 函数已创建（调用 DeepSeek API）
- [ ] baidu_voice_asr 函数已创建（调用百度语音识别）
- [ ] baidu_voice_tts 函数已创建（调用百度语音合成）
- [ ] get_cos_token 函数已创建（生成 COS 临时凭证）
- [ ] 公网函数环境变量已配置（DEEPSEEK_KEY, BAIDU_API_KEY, COS_SECRET_ID）
- [ ] 公网函数 VPC 确认**未启用**

**内网函数（启用 VPC）：**
- [ ] translate_db_write 函数已创建（写入翻译到数据库）
- [ ] create_trip 函数已创建（创建行程记录）
- [ ] user_auth 函数已创建（用户认证）
- [ ] get_user_data 函数已创建（获取用户数据）
- [ ] 内网函数环境变量已配置（DB_HOST, DB_USER, DB_PASSWORD, REDIS_HOST）
- [ ] 内网函数已关联 VPC：wanderchina-vpc
- [ ] 内网函数子网已选择：应用子网

**通用配置：**
- [ ] 所有函数 URL 触发器已创建（每个函数独立 URL）
- [ ] 所有函数 URL 已复制并配置到 Flutter 代码
- [ ] CORS 跨域已开启（允许前端调用）
- [ ] 所有云函数已测试通过（Postman 或 curl 测试）
- [ ] Flutter 端已集成云函数 API 调用
- [ ] **确认无需 NAT 网关**（节省 ¥360/月）

### 安全

- [ ] 数据库安全组：仅开放 VPC 内网访问
- [ ] Redis 安全组：仅开放 VPC 内网访问
- [ ] 所有密钥已移入云函数环境变量，App 代码中无敏感信息
- [ ] 数据库 SSL 连接已启用（`SslMode.require`）
- [ ] 云函数已设置并发限制（防止恶意调用）

### 备份

- [ ] PostgreSQL 自动备份已启用（每天 02:00，保留 7 天）
- [ ] R2 每日备份脚本已部署并测试
- [ ] 离线翻译包已生成并上传 R2

### 监控

- [ ] 云监控告警策略已创建，通知到手机+邮件
- [ ] 费用告警已设置（月超 ¥500 触发）
- [ ] 慢查询日志已开启
- [ ] 云函数调用日志已开启（CLS 日志服务）

### Flutter 端

- [ ] `database_config.dart` 读取环境变量，无硬编码
- [ ] 云函数 API 调用测试通过
- [ ] COS 上传接口测试通过
- [ ] `VoiceTranslationService` 通过云函数调用
- [ ] `MapTranslationService` 通过云函数调用

---

**文档版本：** 1.0  
**关联文档：** `WANDERCHINA_MAP_TRANSLATION_SPEC.md` · `WANDERCHINA_TRANSLATION_DATA_SPEC.md`
