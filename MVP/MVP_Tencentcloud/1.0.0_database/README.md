# WanderChina v0.2 Schema Migrations

数据库变更脚本集合. 对应 `MEMBERSHIP_PAYMENT_PLAN.md` 和 `V0_2_OPTIMIZATION_PLAN.md` 中的所有 schema 改动.

## 文件清单

| 文件 | 用途 | 执行时机 |
|------|------|---------|
| `001_anonymous_data_cleanup.sql` | 清理 MVP 阶段匿名 trips 数据 | Phase 1 Day 1 (任何其他迁移之前) |
| `002_users_subscription_fields.sql` | users 表加 5 个订阅字段 | Phase 1 Day 1 |
| `003_transactions_table.sql` | 新增 transactions 表 | Phase 1 Day 1 |
| `004_usage_quota_table.sql` | 新增 usage_quota 表 | Phase 1 Day 1 |
| `005_feature_flags.sql` | 新增 feature_flags 表 + 7 条初始化 | Phase 1 Day 1 |
| `006_password_resets_table.sql` | 新增 password_resets 表 | Phase 1 Day 2 (与"忘记密码"功能同步) |

## 执行方式

### 方式 1: 一键执行 (推荐)

```bash
# 在腾讯云 PostgreSQL 控制台或 psql 客户端
\i run_all.sql
```

### 方式 2: 单独执行

按数字顺序逐个执行:

```bash
psql -h $PG_HOST -U $PG_USER -d wanderchina -f 001_anonymous_data_cleanup.sql
psql -h $PG_HOST -U $PG_USER -d wanderchina -f 002_users_subscription_fields.sql
# ... 以此类推
```

## 执行前必做

1. **生产 DB 快照** — 在腾讯云 PostgreSQL 控制台手动创建一次快照
   (001 涉及 DELETE, 不可回滚)

2. **检查现有 schema** — 确认以下前提条件:
   ```sql
   -- users 表存在 is_premium / premium_expires_at 字段
   SELECT column_name FROM information_schema.columns
     WHERE table_name = 'users'
       AND column_name IN ('is_premium', 'premium_expires_at');
   -- 应返回 2 行

   -- uuid-ossp extension 已启用 (uuid_generate_v4 依赖)
   SELECT * FROM pg_extension WHERE extname = 'uuid-ossp';
   -- 应返回 1 行
   ```

3. **匿名数据备份** (可选) — 如果未来可能需要分析这部分数据:
   ```sql
   CREATE TABLE _backup_anonymous_trips AS
   SELECT * FROM trips WHERE user_id IS NULL;
   CREATE TABLE _backup_anonymous_trip_days AS
   SELECT * FROM trip_days WHERE trip_id IN (
     SELECT id FROM trips WHERE user_id IS NULL
   );
   ```
   等正式版稳定 1-2 周后, 确认无需要时可删除备份表.

## 执行后验证

```sql
-- 1. users 表新字段
SELECT column_name, data_type FROM information_schema.columns
  WHERE table_name = 'users'
    AND column_name LIKE 'subscription_%' OR column_name = 'premium_source';
-- 预期 5 行

-- 2. 新表存在
SELECT table_name FROM information_schema.tables
  WHERE table_schema = 'public'
    AND table_name IN ('transactions', 'usage_quota', 'feature_flags', 'password_resets');
-- 预期 4 行

-- 3. feature_flags 初始化数据
SELECT flag_key, flag_value FROM feature_flags ORDER BY flag_key;
-- 预期 7 行

-- 4. 索引创建
SELECT indexname FROM pg_indexes
  WHERE tablename IN ('transactions', 'password_resets')
    AND indexname LIKE 'idx_%';
-- 预期至少 4 行
```

## 回滚策略

| 迁移 | 是否可回滚 | 回滚方式 |
|------|-----------|---------|
| 001 | ❌ 不可 | DELETE 不可逆, 依赖快照恢复 |
| 002 | ✅ 可 | `ALTER TABLE users DROP COLUMN ...` |
| 003 | ✅ 可 | `DROP TABLE transactions` (确认无数据) |
| 004 | ✅ 可 | `DROP TABLE usage_quota` (确认无数据) |
| 005 | ✅ 可 | `DROP TABLE feature_flags` |
| 006 | ✅ 可 | `DROP TABLE password_resets` |

⚠️ 一旦 003-006 写入了真实生产数据, 不应再 DROP. 用 `ALTER TABLE ... RENAME TO _deprecated_xxx` 替代.

## 关键决策记录

详见 `MEMBERSHIP_PAYMENT_PLAN.md` 第 2 节, 这里只列出最关键的 4 条:

1. **不引入 `tier` 字段** — 复用 `is_premium` + `premium_expires_at`, 避免双源真相
2. **`transactions ON DELETE SET NULL`** — 财务审计需要保留记录
3. **`usage_quota ON DELETE CASCADE`** — 配额数据无审计价值
4. **`feature_flags` 用 PostgreSQL** — 不引入 Redis/配置中心
