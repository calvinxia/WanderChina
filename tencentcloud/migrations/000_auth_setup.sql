-- ============================================================================
-- WanderChina Authentication Setup for Tencent Cloud PostgreSQL
-- Version: 1.0.0
-- Created: 2026-01-25
-- Platform: Tencent Cloud PostgreSQL (replacing Supabase Auth)
-- ============================================================================

-- ============================================================================
-- CUSTOM AUTH FUNCTIONS
-- ============================================================================

-- Custom function to replace auth.uid()
-- This function retrieves the current user ID from session settings
CREATE OR REPLACE FUNCTION public.current_user_id()
RETURNS UUID AS $$
DECLARE
    user_id_text TEXT;
BEGIN
    -- Get user_id from session variable set by application
    user_id_text := current_setting('app.current_user_id', true);

    -- Return NULL if not set (for service operations)
    IF user_id_text IS NULL OR user_id_text = '' THEN
        RETURN NULL;
    END IF;

    -- Cast and return UUID
    RETURN user_id_text::UUID;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Function to set current user in session
CREATE OR REPLACE FUNCTION public.set_current_user(user_uuid UUID)
RETURNS VOID AS $$
BEGIN
    PERFORM set_config('app.current_user_id', user_uuid::text, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- AUTH ROLES AND PERMISSIONS
-- ============================================================================

-- Create role for authenticated users (if not exists)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'authenticated') THEN
        CREATE ROLE authenticated;
    END IF;
END
$$;

-- Create role for anonymous users (if not exists)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'anon') THEN
        CREATE ROLE anon;
    END IF;
END
$$;

-- Grant basic permissions to authenticated role
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT EXECUTE ON FUNCTIONS TO authenticated;

-- ============================================================================
-- PASSWORD HASHING FUNCTIONS
-- ============================================================================

-- Install pgcrypto extension for password hashing
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Function to hash password using bcrypt
CREATE OR REPLACE FUNCTION public.hash_password(password TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN crypt(password, gen_salt('bf', 10));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to verify password
CREATE OR REPLACE FUNCTION public.verify_password(password TEXT, password_hash TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN password_hash = crypt(password, password_hash);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- AUTH HELPER FUNCTIONS
-- ============================================================================

-- Function to check if user is authenticated
CREATE OR REPLACE FUNCTION public.is_authenticated()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN public.current_user_id() IS NOT NULL;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Function to check if current user matches target user
CREATE OR REPLACE FUNCTION public.is_owner(target_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN public.current_user_id() = target_user_id;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON FUNCTION public.current_user_id() IS 'Returns the UUID of the currently authenticated user from session settings. Replaces Supabase auth.uid().';
COMMENT ON FUNCTION public.set_current_user(UUID) IS 'Sets the current user ID in the session. Must be called by application after authentication.';
COMMENT ON FUNCTION public.hash_password(TEXT) IS 'Hashes a password using bcrypt.';
COMMENT ON FUNCTION public.verify_password(TEXT, TEXT) IS 'Verifies a password against its hash.';
COMMENT ON FUNCTION public.is_authenticated() IS 'Returns true if a user is currently authenticated.';
COMMENT ON FUNCTION public.is_owner(UUID) IS 'Returns true if the current user matches the target user ID.';

-- ============================================================================
-- END OF AUTH SETUP
-- ============================================================================
