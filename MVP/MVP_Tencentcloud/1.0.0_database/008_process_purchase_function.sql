-- ====================================================================
-- 008_process_purchase_function.sql
--
-- 用途: 创建 process_purchase() SQL function, 供 purchase_verify 云函数调用
-- 执行时机: Phase 2 Day 4 (5/14), 在 purchase_verify 部署前
-- 来源: cloud_functions_inventory.md "#13 purchase_verify" 设计
--
-- 设计原则:
--   1. 原子操作: 一次调用同时完成 INSERT transactions + UPDATE users.premium_*
--   2. 累加模式: premium_expires_at = MAX(NOW(), 现有 expires_at) + 产品时长
--      理由: 用户在订阅未到期时再次购买, 不应该覆盖, 应该叠加
--   3. 价格映射: 函数内部硬编码 product_id → amount_cents / duration_days
--   4. transaction_id UNIQUE 保证幂等 (重复调用同一 transaction_id 抛异常)
--   5. premium_source = 'purchase' (与 002.sql COMMENT 一致, 区分 complimentary/promo)
--   6. subscription_started_at:
--      - 首次订阅 (现有 expires NULL): 设为 NOW()
--      - 重新订阅 (现有 expires 已过期): 视为新一轮订阅, 设为 NOW()
--      - 续订 (订阅未到期累加): 不更新, 保持首次订阅时间
--
-- 调用方: cloud_functions/purchase_verify/index.py
--
-- 返回: 新的 premium_expires_at (调用方返回给客户端)
-- ====================================================================

-- ⚠️ 重要: 不要加 `BEGIN; ... COMMIT;` 外层包裹.
--   腾讯云控制台执行 CREATE FUNCTION 会自动进入 transaction, 
--   如果加外层 BEGIN 会冲突报 "syntax error at or near CASE".
--   验证 (2026-05-13): 去掉外层 BEGIN/COMMIT 后执行成功.

CREATE OR REPLACE FUNCTION process_purchase(
    p_user_id          UUID,
    p_product_id       VARCHAR(64),
    p_transaction_id   TEXT,
    p_platform         VARCHAR(32),
    p_receipt_data     TEXT
)
RETURNS TIMESTAMP AS $$
DECLARE
    v_duration_days       INTEGER;
    v_amount_cents        INTEGER;
    v_new_expires_at      TIMESTAMP;
    v_current_expires     TIMESTAMP;
    v_is_new_subscription BOOLEAN;
BEGIN
    -- 1. product_id → 价格 / 时长 映射
    CASE p_product_id
        WHEN 'wanderchina.trip_pass.7d' THEN
            v_duration_days := 7;
            v_amount_cents := 999;  -- $9.99
        WHEN 'wanderchina.trip_pass.14d' THEN
            v_duration_days := 14;
            v_amount_cents := 1499;  -- $14.99
        WHEN 'wanderchina.trip_pass.30d' THEN
            v_duration_days := 30;
            v_amount_cents := 2499;  -- $24.99
        ELSE
            RAISE EXCEPTION 'Unknown product_id: %', p_product_id;
    END CASE;

    -- 2. 查现有 premium_expires_at (用于累加 + 判断是否新订阅周期)
    SELECT premium_expires_at INTO v_current_expires
    FROM users WHERE id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User not found: %', p_user_id;
    END IF;

    -- 3. 计算新的过期时间 (累加模式) + 判断是否新订阅周期
    --    新订阅周期: 现有 expires 为 NULL 或已过期 → 从今天起 +duration_days
    --    续订: 现有 expires 未过期 → 从原过期时间 +duration_days (累加)
    IF v_current_expires IS NULL OR v_current_expires < NOW() THEN
        v_new_expires_at := NOW() + (v_duration_days || ' days')::INTERVAL;
        v_is_new_subscription := TRUE;
    ELSE
        v_new_expires_at := v_current_expires + (v_duration_days || ' days')::INTERVAL;
        v_is_new_subscription := FALSE;
    END IF;

    -- 4. INSERT transactions 记录 (UNIQUE transaction_id 保证幂等)
    --    重复调用会抛 unique_violation, 由调用方捕获返回幂等响应
    INSERT INTO transactions (
        user_id, product_id, platform, transaction_id,
        amount_cents, currency, status, receipt_data, verified_at
    ) VALUES (
        p_user_id, p_product_id, p_platform, p_transaction_id,
        v_amount_cents, 'USD', 'completed', p_receipt_data, NOW()
    );

    -- 5. UPDATE users 订阅状态
    UPDATE users SET
        is_premium = TRUE,
        premium_expires_at = v_new_expires_at,
        subscription_product_id = p_product_id,
        subscription_platform = p_platform,
        subscription_transaction_id = p_transaction_id,
        subscription_started_at = CASE
            WHEN v_is_new_subscription THEN NOW()
            ELSE subscription_started_at  -- 续订保持原值
        END,
        premium_source = 'purchase',  -- 与 002.sql COMMENT 一致: purchase/complimentary/promo
        updated_at = NOW()
    WHERE id = p_user_id;

    -- 6. 返回新的过期时间
    RETURN v_new_expires_at;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION process_purchase IS
    'Atomic purchase processing: INSERT transactions + UPDATE users.
     Premium expiry is ADDITIVE (stacks if user already has active subscription).
     subscription_started_at preserved across renewals (reset only on new subscription cycle).
     Raises unique_violation if transaction_id already exists (idempotency guard).';

-- ====================================================================
-- 验证查询 (执行后用 psql 跑一遍确认 function 已创建):
--
-- \df process_purchase
-- 期望输出: process_purchase(uuid, character varying, text, character varying, text) → timestamp
--
-- SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 'process_purchase';
-- 期望输出: 完整的 function 定义
--
-- ====================================================================
-- 测试 (用 dry-run 验证逻辑, 不真实执行 INSERT — 在 ROLLBACK 块里跑):
--
-- BEGIN;
-- -- 假设 user_id='<existing-uuid>'  (要先查一个真实 user_id)
-- SELECT process_purchase(
--     '<existing-uuid>'::UUID,
--     'wanderchina.trip_pass.7d',
--     'test_tx_' || extract(epoch from now())::text,  -- 唯一 transaction_id
--     'apple',
--     '{"test": "receipt"}'
-- );
-- -- 检查 users 表 + transactions 表
-- SELECT is_premium, premium_expires_at, subscription_product_id, premium_source 
-- FROM users WHERE id = '<existing-uuid>';
-- SELECT * FROM transactions WHERE user_id = '<existing-uuid>' ORDER BY created_at DESC LIMIT 1;
-- ROLLBACK;  -- 不真实写入
-- ====================================================================
