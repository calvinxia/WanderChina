# WanderChina MVP — 腾讯云 PostgreSQL 数据库脚本

## 概述

MVP v2.0 数据库初始化脚本，替代旧版 `tencentcloud/migrations/` 下的全部 SQL 文件。

## 文件清单

| 文件 | 用途 | 执行身份 |
|------|------|---------|
| `000_extensions.sql` | 安装 4 个 PG 扩展 (uuid-ossp, postgis, pgcrypto, pg_trgm) | wanderchina_pg_prod |
| `001_functions.sql` | 公共函数: 密码哈希、updated_at 触发器、空间字段同步 | wanderchina_pg_prod |
| `002_tables.sql` | 5 张业务表 + 索引 + 触发器 + 约束 | wanderchina_pg_prod |
| `003_permissions.sql` | 创建 wc_scf_service / wc_readonly 用户，配置权限 | wanderchina_pg_prod |
| `004_seed_data.sql` | 种子数据: 6 城市景点 + 地铁站 + 导航指令翻译 | wanderchina_pg_prod |
| `005_verify.sql` | 部署后验证脚本（11 项检查） | wanderchina_pg_prod |

## 执行顺序

```bash
# 连接腾讯云 PG（外网临时开启）
psql -h gz-cdb-xxx.sql.tencentcdb.com -p 26300 -U wanderchina_pg_prod -d wanderchina

# 按编号顺序执行
\i 000_extensions.sql
\i 001_functions.sql
\i 002_tables.sql
\i 003_permissions.sql
\i 004_seed_data.sql
\i 005_verify.sql

# 验证通过后关闭外网访问
```

## 数据库架构

```
wanderchina (PostgreSQL 16 + PostGIS)
│
├── poi_translations    — 地图翻译蒙层核心表（BIGSERIAL PK, geohash + PostGIS 空间索引）
├── users               — 用户表（支持匿名 device_id + 邮箱注册）
├── user_sessions       — JWT 会话管理（refresh_token + token_family 防重放）
├── trips               — 行程表（AI 生成内容存 itinerary_json JSONB）
├── trip_days           — 行程天数详情（activities JSONB 数组）
├── nav_instructions_i18n — 导航指令中英翻译参考表（客户端加载）
│
├── wc_scf_service      — 云函数用户（仅 DML）
└── wc_readonly         — 只读用户（数据分析）
```

## 与旧版差异

| 旧版 (tencentcloud/migrations/) | MVP v2.0 |
|--------------------------------|----------|
| 37 张表 (001_initial_schema.sql) | 5+1 张表 |
| 10 个 enum 类型 | VARCHAR + 应用层校验 |
| 6 张翻译分表 (map_translation_schema.sql) | 统一为 poi_translations |
| Supabase RLS 策略 (002_row_level_security.sql) | 云函数 + 应用层权限 |
| Supabase auth 函数 (000_auth_setup.sql) | 仅保留 hash/verify_password |
| achievements/challenges 种子数据 | 景点 + 地铁站种子数据 |

## 注意事项

1. **密码**: `003_permissions.sql` 中的密码为占位符，生产部署时必须替换
2. **种子数据**: `gaode_poi_id` 使用 `SEED_XX_NNN` 格式，Phase 6 高德 API 导入时会用真实 ID 替换
3. **坐标系**: 所有坐标为 GCJ-02（高德原始坐标），PostGIS 以 SRID 4326 存储
4. **道路翻译**: 旧版道路/区域翻译无坐标，未导入 poi_translations，需后续通过高德 API 补充坐标后导入
