# WanderChina - Tencent Cloud PostgreSQL Migration

This directory contains the converted database schema and migrations for deploying WanderChina on **Tencent Cloud PostgreSQL** instead of Supabase.

## 📋 Overview

**Migration Status:** Database scripts ready for deployment
**Target Platform:** Tencent Cloud PostgreSQL 15+
**Storage:** Cloudflare R2 (S3-compatible)
**Cost:** ¥93/month (¥90 database + ¥3 storage)

## 🗂️ File Structure

```
tencentcloud/
├── README.md                           # This file
├── migrations/
│   ├── 000_auth_setup.sql             # Custom authentication functions
│   ├── 001_initial_schema.sql         # Complete database schema
│   └── 002_row_level_security.sql     # RLS policies
└── seed.sql                            # Sample data for testing
```

## 🔄 Key Changes from Supabase

### 1. **Authentication System**
- **Removed:** `auth.users` schema dependency
- **Added:** Custom `current_user_id()` function replaces `auth.uid()`
- **Added:** `user_sessions` table for JWT/session management
- **Added:** Password hashing functions using `pgcrypto`

### 2. **Row Level Security (RLS)**
- All `auth.uid()` calls replaced with `public.current_user_id()`
- All `TO authenticated` policies updated to use `public.is_authenticated()`
- Custom helper functions for common auth checks

### 3. **Storage**
- **Removed:** Supabase Storage buckets (003_storage_setup.sql)
- **Replaced with:** Cloudflare R2 (configured in application code)
- See `TENCENTCLOUD_MIGRATION_GUIDE.md` for R2 setup

### 4. **Users Table**
- Now self-contained (no longer references `auth.users`)
- Added `password_hash` column
- ID generated with `uuid_generate_v4()` instead of FK to auth schema

## 🚀 Deployment Steps

### Step 1: Provision Tencent Cloud PostgreSQL

```bash
# Tencent Cloud Console Configuration:
# - Region: China (Guangzhou recommended)
# - Specification: 1核2GB
# - Storage: 50GB SSD
# - PostgreSQL Version: 15.x
# - Network: VPC (记录 VPC ID for later)
```

### Step 2: Run Migrations

```bash
# Connect to your Tencent Cloud PostgreSQL instance
psql "postgresql://username:password@your-tencentcloud-host:5432/wanderchina?sslmode=require"

# Run migrations in order
\i migrations/000_auth_setup.sql
\i migrations/001_initial_schema.sql
\i migrations/002_row_level_security.sql

# (Optional) Load seed data for testing
\i seed.sql
```

### Step 3: Verify Installation

```sql
-- Check extensions
SELECT * FROM pg_extension;

-- Verify tables created
SELECT tablename FROM pg_tables WHERE schemaname = 'public';

-- Test auth functions
SELECT public.current_user_id();  -- Should return NULL when not set

-- Test setting user
SELECT public.set_current_user('550e8400-e29b-41d4-a716-446655440000'::uuid);
SELECT public.current_user_id();  -- Should return the UUID
```

### Step 4: Create Partitions for Future Months

```sql
-- Create analytics partitions for upcoming months
CREATE TABLE public.analytics_events_2026_04 PARTITION OF public.analytics_events
    FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');

CREATE TABLE public.analytics_events_2026_05 PARTITION OF public.analytics_events
    FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');

-- Add more as needed...
```

## 🔐 Authentication Flow

### How It Works

1. **User Login:**
   ```dart
   // Application authenticates user
   final user = await authService.login(email, password);

   // Set session in database
   await db.execute("SELECT set_current_user('${user.id}')");
   ```

2. **RLS Enforcement:**
   - All queries now run with the user context set
   - RLS policies automatically filter data based on `current_user_id()`
   - No need to manually filter by user_id in queries

3. **Logout:**
   ```dart
   // Clear session
   await db.execute("SELECT set_current_user(NULL)");
   ```

### Session Management

```dart
// Create session after login
final token = generateJWT(user.id);
await db.execute("""
  INSERT INTO user_sessions (user_id, token_hash, expires_at, user_agent, ip_address)
  VALUES ('${user.id}', '${hashToken(token)}', NOW() + INTERVAL '7 days',
          '${userAgent}', '${ipAddress}')
""");
```

## 📊 Database Configuration

### Recommended Settings

```sql
-- Performance tuning for 1核2GB instance
ALTER SYSTEM SET shared_buffers = '512MB';
ALTER SYSTEM SET effective_cache_size = '1536MB';
ALTER SYSTEM SET maintenance_work_mem = '128MB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET default_statistics_target = 100;
ALTER SYSTEM SET random_page_cost = 1.1;
ALTER SYSTEM SET effective_io_concurrency = 200;
ALTER SYSTEM SET work_mem = '5242kB';
ALTER SYSTEM SET min_wal_size = '1GB';
ALTER SYSTEM SET max_wal_size = '4GB';

-- Reload configuration
SELECT pg_reload_conf();
```

### Connection Pooling

Use PgBouncer or application-level connection pooling:

```yaml
# Example connection pool config
database:
  host: your-tencentcloud-host
  port: 5432
  database: wanderchina
  username: your-username
  password: your-password
  ssl_mode: require
  pool:
    min_size: 2
    max_size: 10
    timeout: 30
```

## 🔍 Monitoring Queries

```sql
-- Check database size
SELECT pg_size_pretty(pg_database_size('wanderchina'));

-- Monitor active connections
SELECT count(*) FROM pg_stat_activity;

-- Check table sizes
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;

-- Monitor slow queries
SELECT query, mean_exec_time, calls
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;
```

## 🛠️ Maintenance Tasks

### Weekly Maintenance

```sql
-- Vacuum analyze for query optimization
VACUUM ANALYZE;

-- Reindex if needed
REINDEX DATABASE wanderchina;
```

### Monthly Tasks

```sql
-- Create next month's analytics partition
CREATE TABLE public.analytics_events_2026_XX PARTITION OF public.analytics_events
    FOR VALUES FROM ('2026-XX-01') TO ('2026-XX+1-01');

-- Archive old session data
DELETE FROM user_sessions WHERE expires_at < NOW() - INTERVAL '30 days';
```

## 🔄 Migration from Existing Supabase

If you have existing Supabase data:

```bash
# 1. Export from Supabase
pg_dump "postgresql://postgres:[PASSWORD]@db.[PROJECT].supabase.co:5432/postgres" \
  --schema=public --no-owner --no-acl > supabase_dump.sql

# 2. Clean Supabase-specific syntax
sed -i.bak '/supabase_admin/d' supabase_dump.sql
sed -i.bak '/auth\.users/d' supabase_dump.sql
sed -i.bak 's/auth\.uid()/public.current_user_id()/g' supabase_dump.sql

# 3. Import schema first
psql "postgresql://user:pass@tencentcloud-host:5432/wanderchina" -f migrations/000_auth_setup.sql
psql "postgresql://user:pass@tencentcloud-host:5432/wanderchina" -f migrations/001_initial_schema.sql

# 4. Import data (without schema)
pg_restore --data-only --disable-triggers supabase_dump.sql

# 5. Apply RLS policies
psql "postgresql://user:pass@tencentcloud-host:5432/wanderchina" -f migrations/002_row_level_security.sql
```

## 📝 Application Code Changes

Update your Flutter/Dart code:

```dart
// Before (Supabase)
import 'package:supabase_flutter/supabase_flutter.dart';
final supabase = Supabase.instance.client;
final user = supabase.auth.currentUser;

// After (Tencent Cloud)
import 'package:postgres/postgres.dart';
import 'package:minio/minio.dart';

final db = await Connection.open(Endpoint(...));
final storage = Minio(...);
```

See `TENCENTCLOUD_MIGRATION_GUIDE.md` for complete code examples.

## 🆘 Troubleshooting

### Issue: RLS policies not working

```sql
-- Check if RLS is enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public' AND rowsecurity = false;

-- Re-enable if needed
ALTER TABLE public.table_name ENABLE ROW LEVEL SECURITY;
```

### Issue: PostGIS functions not found

```sql
-- Verify PostGIS installation
SELECT PostGIS_version();

-- Reinstall if needed
CREATE EXTENSION IF NOT EXISTS postgis;
```

### Issue: Connection timeout

```sql
-- Check connection limits
SHOW max_connections;

-- Monitor current connections
SELECT count(*) FROM pg_stat_activity WHERE state = 'active';
```

## 📚 Related Documentation

- [TENCENTCLOUD_MIGRATION_GUIDE.md](../TENCENTCLOUD_MIGRATION_GUIDE.md) - Complete migration strategy
- [SUPABASE_DATABASE_COMPLETE.md](../SUPABASE_DATABASE_COMPLETE.md) - Original Supabase schema
- [Tencent Cloud PostgreSQL Docs](https://cloud.tencent.com/document/product/409)
- [Cloudflare R2 Docs](https://developers.cloudflare.com/r2/)

## 💰 Cost Optimization

- **Database:** ¥90/month (1核2GB, 50GB SSD)
- **Storage:** ¥3/month (Cloudflare R2)
- **Total:** ¥93/month
- **Savings:** 44-63% vs Supabase Pro (¥180-250/month)

## 🎯 Next Steps

1. ✅ Database migrations created
2. ⏳ Deploy to Tencent Cloud
3. ⏳ Set up Cloudflare R2 storage
4. ⏳ Update application code
5. ⏳ Test thoroughly in staging
6. ⏳ Production deployment

---

**Questions or Issues?**
Refer to the main migration guide: `TENCENTCLOUD_MIGRATION_GUIDE.md`
