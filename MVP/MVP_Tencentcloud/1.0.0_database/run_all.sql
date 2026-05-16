-- ====================================================================
-- run_all.sql — WanderChina v0.2 完整 schema migration 入口
--
-- 执行顺序固定. 不要跳过任何一个文件.
-- 详见 README.md
--
-- 使用方式:
--   psql -h $PG_HOST -U $PG_USER -d wanderchina -f run_all.sql
--
-- 或在 psql 交互模式下:
--   \i run_all.sql
-- ====================================================================

\echo '========================================'
\echo 'WanderChina v0.2 Schema Migration'
\echo '========================================'
\echo ''

\echo '[1/7] Cleaning anonymous data...'
\i 001_anonymous_data_cleanup.sql

\echo '[2/7] Adding users subscription fields...'
\i 002_users_subscription_fields.sql

\echo '[3/7] Creating transactions table...'
\i 003_transactions_table.sql

\echo '[4/7] Creating usage_quota table...'
\i 004_usage_quota_table.sql

\echo '[5/7] Creating feature_flags table + initialization...'
\i 005_feature_flags.sql

\echo '[6/7] Creating password_resets table...'
\i 006_password_resets_table.sql

\echo '[7/7] Adding OAuth user IDs + email_verified + deleted_at...'
\i 007_users_oauth_fields.sql

\echo ''
\echo '========================================'
\echo 'Migration complete. Run verification queries:'
\echo ''
\echo '  -- Feature flags (expect 7 rows):'
\echo '  SELECT flag_key, flag_value FROM feature_flags ORDER BY flag_key;'
\echo ''
\echo '  -- New tables (expect 4 rows):'
\echo '  SELECT table_name FROM information_schema.tables'
\echo '    WHERE table_schema = ''public'''
\echo '      AND table_name IN ('
\echo '        ''transactions'', ''usage_quota'',' 
\echo '        ''feature_flags'', ''password_resets'''
\echo '      );'
\echo ''
\echo '  -- OAuth fields (expect 4 rows):'
\echo '  SELECT column_name FROM information_schema.columns'
\echo '    WHERE table_name = ''users'''
\echo '      AND column_name IN ('
\echo '        ''apple_user_id'', ''google_user_id'','
\echo '        ''email_verified'', ''deleted_at'''
\echo '      );'
\echo '========================================'
