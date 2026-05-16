-- ====================================================================
-- 001_anonymous_data_cleanup.sql
--
-- 用途: 正式版 schema migration 前清理 MVP 阶段的匿名用户数据
-- 执行时机: Phase 1 Day 1, 任何其他迁移之前
-- 来源: MEMBERSHIP_PAYMENT_PLAN.md 第 2 节 "数据库变更"
--
-- 决策依据:
--   - 正式版取消匿名访问核心功能, 旧的匿名 trips 数据没有归属用户
--   - 不加 trips.user_id NOT NULL 约束, 保持向前兼容
--   - 应用层强制登录即可
--
-- 影响范围:
--   - trips 表: 删除 user_id IS NULL 的所有记录
--   - trip_days 表: 删除孤儿记录 (parent trip 已删除或 user_id 为空)
--
-- 回滚:
--   不可回滚. 执行前必须备份生产 DB.
--   建议在腾讯云 PostgreSQL 控制台先做一次手动快照.
-- ====================================================================

BEGIN;

-- 1. 先删孤儿 trip_days (parent trip 的 user_id IS NULL)
DELETE FROM trip_days WHERE trip_id IN (
  SELECT id FROM trips WHERE user_id IS NULL
);

-- 2. 删匿名 trips
DELETE FROM trips WHERE user_id IS NULL;

-- 3. 兜底: 清理任何残留的孤儿 trip_days
--    (理论上 1 已经覆盖, 但防御性写法)
DELETE FROM trip_days WHERE trip_id NOT IN (SELECT id FROM trips);

-- 验证清理结果 (可选, 执行后人工核对)
-- SELECT COUNT(*) FROM trips WHERE user_id IS NULL;          -- 应为 0
-- SELECT COUNT(*) FROM trip_days td                          -- 应为 0
--   WHERE NOT EXISTS (SELECT 1 FROM trips WHERE id = td.trip_id);

COMMIT;
