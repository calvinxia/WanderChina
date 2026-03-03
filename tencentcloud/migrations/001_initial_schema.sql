-- ============================================================================
-- WanderChina Database Schema for Tencent Cloud PostgreSQL
-- Version: 1.0.0
-- Created: 2026-01-25
-- Converted from Supabase to standard PostgreSQL
-- Platform: Tencent Cloud PostgreSQL 15+ with PostGIS
-- ============================================================================

-- ============================================================================
-- ENABLE EXTENSIONS
-- ============================================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable PostGIS for geospatial queries
CREATE EXTENSION IF NOT EXISTS "postgis";

-- Enable fuzzy text search
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Enable composite indexes
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- Enable password hashing (added for Tencent Cloud)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- CUSTOM TYPES
-- ============================================================================

CREATE TYPE membership_tier AS ENUM ('bronze', 'silver', 'gold', 'platinum');
CREATE TYPE trip_status AS ENUM ('planning', 'ongoing', 'completed');
CREATE TYPE difficulty_level AS ENUM ('beginner', 'intermediate', 'advanced', 'expert', 'master');
CREATE TYPE rarity_level AS ENUM ('common', 'rare', 'epic', 'legendary');
CREATE TYPE post_type AS ENUM ('photo', 'question', 'tip', 'check_in');
CREATE TYPE expense_category AS ENUM ('food', 'accommodation', 'transport', 'attractions', 'shopping', 'health', 'communication', 'other');
CREATE TYPE booking_type AS ENUM ('hotel', 'attraction', 'experience', 'transport');
CREATE TYPE emergency_type AS ENUM ('medical', 'police', 'lost', 'accident', 'other');
CREATE TYPE notification_type AS ENUM ('like', 'comment', 'follow', 'achievement', 'challenge', 'booking', 'safety', 'system');
CREATE TYPE verification_status AS ENUM ('pending', 'approved', 'rejected');

-- ============================================================================
-- USER MANAGEMENT TABLES
-- ============================================================================

-- Users table (standalone - no longer references auth.users)
CREATE TABLE public.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    username VARCHAR(100) UNIQUE,
    full_name VARCHAR(255),
    profile_picture TEXT,
    bio TEXT,
    nationality VARCHAR(100),
    languages JSONB DEFAULT '[]'::jsonb,
    travel_style VARCHAR(50),
    interests JSONB DEFAULT '[]'::jsonb,
    email_verified BOOLEAN DEFAULT FALSE,
    phone VARCHAR(50),
    phone_verified BOOLEAN DEFAULT FALSE,
    premium_until TIMESTAMP WITH TIME ZONE,
    total_points INTEGER DEFAULT 0 CHECK (total_points >= 0),
    membership_tier membership_tier DEFAULT 'bronze',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    CONSTRAINT chk_users_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
);

-- User sessions (for JWT/session management)
CREATE TABLE public.user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    token_hash TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    user_agent TEXT,
    ip_address INET
);

-- User settings
CREATE TABLE public.user_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
    language VARCHAR(10) DEFAULT 'en',
    currency VARCHAR(3) DEFAULT 'CNY',
    distance_unit VARCHAR(10) DEFAULT 'km',
    temperature_unit VARCHAR(10) DEFAULT 'celsius',
    notifications JSONB DEFAULT '{
        "likes": true,
        "comments": true,
        "follows": true,
        "achievements": true,
        "challenges": true,
        "safety_alerts": true,
        "marketing": false
    }'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- TRAVEL & TRIPS TABLES
-- ============================================================================

-- Trips
CREATE TABLE public.trips (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    budget NUMERIC(10, 2) DEFAULT 0 CHECK (budget >= 0),
    total_spent NUMERIC(10, 2) DEFAULT 0,
    status trip_status DEFAULT 'planning',
    cities JSONB DEFAULT '[]'::jsonb,
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT chk_trips_dates CHECK (end_date >= start_date)
);

-- Itineraries (day-by-day plans)
CREATE TABLE public.itineraries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    day_number INTEGER NOT NULL,
    date DATE NOT NULL,
    activities JSONB DEFAULT '[]'::jsonb,
    total_budget NUMERIC(10, 2),
    actual_spent NUMERIC(10, 2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE (trip_id, day_number)
);

-- ============================================================================
-- PLACES & DISCOVERY TABLES
-- ============================================================================

-- Places (attractions, restaurants, hotels, etc.)
CREATE TABLE public.places (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    name_chinese VARCHAR(255),
    category VARCHAR(50) NOT NULL,
    subcategory VARCHAR(50),
    description TEXT,
    address TEXT,
    city VARCHAR(100),
    province VARCHAR(100),
    country VARCHAR(100) DEFAULT 'China',
    location GEOGRAPHY(POINT, 4326),
    photos JSONB DEFAULT '[]'::jsonb,
    rating NUMERIC(2, 1) CHECK (rating >= 0 AND rating <= 5),
    review_count INTEGER DEFAULT 0,
    price_level INTEGER CHECK (price_level >= 1 AND price_level <= 4),
    opening_hours JSONB,
    tags JSONB DEFAULT '[]'::jsonb,
    external_ids JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Place reviews
CREATE TABLE public.place_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    place_id UUID NOT NULL REFERENCES public.places(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    photos JSONB DEFAULT '[]'::jsonb,
    helpful_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Saved places (user bookmarks)
CREATE TABLE public.saved_places (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    place_id UUID NOT NULL REFERENCES public.places(id) ON DELETE CASCADE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE (user_id, place_id)
);

-- ============================================================================
-- BUDGET & EXPENSES TABLES
-- ============================================================================

-- Expenses
CREATE TABLE public.expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    trip_id UUID REFERENCES public.trips(id) ON DELETE CASCADE,
    place_id UUID REFERENCES public.places(id) ON DELETE SET NULL,
    category expense_category NOT NULL,
    amount NUMERIC(10, 2) NOT NULL CHECK (amount >= 0),
    currency VARCHAR(3) DEFAULT 'CNY',
    description TEXT,
    receipt_photo TEXT,
    expense_date TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- GAMIFICATION TABLES
-- ============================================================================

-- Challenges
CREATE TABLE public.challenges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    city VARCHAR(100),
    category VARCHAR(50),
    difficulty difficulty_level DEFAULT 'beginner',
    checkpoints JSONB NOT NULL DEFAULT '[]'::jsonb,
    total_points INTEGER NOT NULL CHECK (total_points > 0),
    estimated_time_hours INTEGER,
    is_seasonal BOOLEAN DEFAULT FALSE,
    season VARCHAR(20),
    badge_image TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User challenges (progress tracking)
CREATE TABLE public.user_challenges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    challenge_id UUID NOT NULL REFERENCES public.challenges(id) ON DELETE RESTRICT,
    status VARCHAR(20) DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'abandoned')),
    progress JSONB DEFAULT '{}'::jsonb,
    completion_percentage INTEGER DEFAULT 0 CHECK (completion_percentage >= 0 AND completion_percentage <= 100),
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    points_earned INTEGER DEFAULT 0,
    UNIQUE (user_id, challenge_id)
);

-- Achievements
CREATE TABLE public.achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(50),
    criteria JSONB NOT NULL,
    rarity rarity_level DEFAULT 'common',
    badge_image TEXT,
    points_reward INTEGER DEFAULT 0,
    is_hidden BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User achievements (unlocked achievements)
CREATE TABLE public.user_achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    achievement_id UUID NOT NULL REFERENCES public.achievements(id) ON DELETE RESTRICT,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE (user_id, achievement_id)
);

-- Points history (ledger)
CREATE TABLE public.points_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    points_change INTEGER NOT NULL,
    reason VARCHAR(100),
    reference_id UUID,
    reference_type VARCHAR(50),
    balance_after INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- COMMUNITY & SOCIAL TABLES
-- ============================================================================

-- Posts
CREATE TABLE public.posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    location_id UUID REFERENCES public.places(id) ON DELETE SET NULL,
    trip_id UUID REFERENCES public.trips(id) ON DELETE SET NULL,
    content TEXT NOT NULL,
    images JSONB DEFAULT '[]'::jsonb,
    tags JSONB DEFAULT '[]'::jsonb,
    post_type post_type DEFAULT 'photo',
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    is_pinned BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Comments
CREATE TABLE public.comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    parent_comment_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    likes_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Post likes
CREATE TABLE public.post_likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE (user_id, post_id)
);

-- Comment likes
CREATE TABLE public.comment_likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    comment_id UUID NOT NULL REFERENCES public.comments(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE (user_id, comment_id)
);

-- Saved posts
CREATE TABLE public.saved_posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE (user_id, post_id)
);

-- Follows (user relationships)
CREATE TABLE public.follows (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    follower_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE (follower_id, following_id),
    CHECK (follower_id != following_id)
);

-- ============================================================================
-- SOCIAL MATCHING TABLES
-- ============================================================================

-- Companion profiles
CREATE TABLE public.companion_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
    is_seeking_companions BOOLEAN DEFAULT FALSE,
    travel_dates JSONB DEFAULT '[]'::jsonb,
    preferred_age_range JSONB,
    preferred_gender VARCHAR(20),
    budget_level VARCHAR(20),
    interests JSONB DEFAULT '[]'::jsonb,
    languages_spoken JSONB DEFAULT '[]'::jsonb,
    bio TEXT,
    verification_status verification_status DEFAULT 'pending',
    trust_score NUMERIC(3, 2) DEFAULT 5.0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Companion matches
CREATE TABLE public.companion_matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user1_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    user2_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    match_score NUMERIC(3, 2),
    status VARCHAR(20) DEFAULT 'pending',
    matched_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    accepted_at TIMESTAMP WITH TIME ZONE,
    UNIQUE (user1_id, user2_id),
    CHECK (user1_id < user2_id)
);

-- Local guides
CREATE TABLE public.local_guides (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
    city VARCHAR(100) NOT NULL,
    specializations JSONB DEFAULT '[]'::jsonb,
    hourly_rate NUMERIC(10, 2),
    is_free BOOLEAN DEFAULT FALSE,
    languages JSONB DEFAULT '[]'::jsonb,
    bio TEXT,
    verification_status verification_status DEFAULT 'pending',
    rating NUMERIC(2, 1),
    total_bookings INTEGER DEFAULT 0,
    availability JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Guide bookings
CREATE TABLE public.guide_bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    guide_id UUID NOT NULL REFERENCES public.local_guides(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    booking_date DATE NOT NULL,
    start_time TIME NOT NULL,
    duration_hours INTEGER NOT NULL,
    total_cost NUMERIC(10, 2),
    status VARCHAR(20) DEFAULT 'pending',
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    review TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- SAFETY & EMERGENCY TABLES
-- ============================================================================

-- Emergency contacts
CREATE TABLE public.emergency_contacts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(50) NOT NULL,
    relationship VARCHAR(100),
    notification_type VARCHAR(20) DEFAULT 'both',
    priority INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Emergency alerts
CREATE TABLE public.emergency_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    location GEOGRAPHY(POINT, 4326),
    emergency_type emergency_type NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE
);

-- Location sharing sessions
CREATE TABLE public.location_shares (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    share_code VARCHAR(50) UNIQUE NOT NULL,
    recipients JSONB DEFAULT '[]'::jsonb,
    duration_hours INTEGER NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Location updates (GPS breadcrumbs)
CREATE TABLE public.location_updates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    share_id UUID NOT NULL REFERENCES public.location_shares(id) ON DELETE CASCADE,
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    accuracy NUMERIC(6, 2),
    battery_level INTEGER,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Safety reports
CREATE TABLE public.safety_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    incident_type VARCHAR(50) NOT NULL,
    severity VARCHAR(20),
    description TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- SYSTEM & UTILITIES TABLES
-- ============================================================================

-- Notifications
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    type notification_type NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT,
    data JSONB DEFAULT '{}'::jsonb,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Translation cache
CREATE TABLE public.translations_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    text_hash VARCHAR(64) NOT NULL,
    source_lang VARCHAR(10) NOT NULL,
    target_lang VARCHAR(10) NOT NULL,
    translation TEXT NOT NULL,
    confidence NUMERIC(3, 2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    UNIQUE (text_hash, source_lang, target_lang)
);

-- Offline maps
CREATE TABLE public.offline_maps (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    city_id VARCHAR(50) UNIQUE NOT NULL,
    city_name VARCHAR(100) NOT NULL,
    version VARCHAR(20) NOT NULL,
    size_mb INTEGER NOT NULL,
    bounds JSONB NOT NULL,
    tile_count INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User downloaded maps
CREATE TABLE public.user_downloaded_maps (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    map_id UUID NOT NULL REFERENCES public.offline_maps(id) ON DELETE CASCADE,
    downloaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_used TIMESTAMP WITH TIME ZONE,
    UNIQUE (user_id, map_id)
);

-- ============================================================================
-- BOOKING & PAYMENTS TABLES
-- ============================================================================

-- Bookings
CREATE TABLE public.bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    place_id UUID REFERENCES public.places(id) ON DELETE SET NULL,
    booking_type booking_type NOT NULL,
    check_in_date DATE,
    check_out_date DATE,
    guests_count INTEGER,
    total_cost NUMERIC(10, 2),
    currency VARCHAR(3) DEFAULT 'CNY',
    status VARCHAR(20) DEFAULT 'pending',
    confirmation_code VARCHAR(100),
    partner_name VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Subscriptions
CREATE TABLE public.subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    plan_type VARCHAR(20) NOT NULL CHECK (plan_type IN ('monthly', 'yearly')),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'expired')),
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    auto_renew BOOLEAN DEFAULT TRUE,
    payment_method VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Payments
CREATE TABLE public.payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subscription_id UUID REFERENCES public.subscriptions(id) ON DELETE RESTRICT,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    amount NUMERIC(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'CNY',
    payment_method VARCHAR(50),
    payment_provider VARCHAR(50),
    transaction_id VARCHAR(255),
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- ANALYTICS TABLES
-- ============================================================================

-- Analytics events (partitioned by month)
CREATE TABLE public.analytics_events (
    id UUID DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    event_type VARCHAR(100) NOT NULL,
    event_data JSONB DEFAULT '{}'::jsonb,
    platform VARCHAR(20),
    app_version VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

-- Create initial partitions (2026)
CREATE TABLE public.analytics_events_2026_01 PARTITION OF public.analytics_events
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

CREATE TABLE public.analytics_events_2026_02 PARTITION OF public.analytics_events
    FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');

CREATE TABLE public.analytics_events_2026_03 PARTITION OF public.analytics_events
    FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Users indexes
CREATE UNIQUE INDEX idx_users_email ON public.users(email);
CREATE UNIQUE INDEX idx_users_username ON public.users(username);
CREATE INDEX idx_users_created_at ON public.users(created_at DESC);
CREATE INDEX idx_users_premium ON public.users(premium_until) WHERE premium_until > NOW();

-- User sessions indexes
CREATE INDEX idx_sessions_user_id ON public.user_sessions(user_id);
CREATE INDEX idx_sessions_expires ON public.user_sessions(expires_at);
CREATE UNIQUE INDEX idx_sessions_token ON public.user_sessions(token_hash);

-- Places indexes (including geospatial)
CREATE INDEX idx_places_location ON public.places USING GIST(location);
CREATE INDEX idx_places_city ON public.places(city);
CREATE INDEX idx_places_category ON public.places(category);
CREATE INDEX idx_places_rating ON public.places(rating DESC);
CREATE INDEX idx_places_city_category ON public.places(city, category);
CREATE INDEX idx_places_tags ON public.places USING GIN(tags);

-- Trips indexes
CREATE INDEX idx_trips_user_id ON public.trips(user_id);
CREATE INDEX idx_trips_status ON public.trips(status);
CREATE INDEX idx_trips_dates ON public.trips(start_date, end_date);

-- Expenses indexes
CREATE INDEX idx_expenses_user_id ON public.expenses(user_id);
CREATE INDEX idx_expenses_trip_id ON public.expenses(trip_id);
CREATE INDEX idx_expenses_date ON public.expenses(expense_date DESC);
CREATE INDEX idx_expenses_user_trip ON public.expenses(user_id, trip_id);

-- Posts indexes
CREATE INDEX idx_posts_user_id ON public.posts(user_id);
CREATE INDEX idx_posts_created_at ON public.posts(created_at DESC);
CREATE INDEX idx_posts_location_id ON public.posts(location_id);
CREATE INDEX idx_posts_tags ON public.posts USING GIN(tags);

-- Comments indexes
CREATE INDEX idx_comments_post_id ON public.comments(post_id);
CREATE INDEX idx_comments_user_id ON public.comments(user_id);
CREATE INDEX idx_comments_parent_id ON public.comments(parent_comment_id);

-- Challenges indexes
CREATE INDEX idx_challenges_city ON public.challenges(city);
CREATE INDEX idx_challenges_category ON public.challenges(category);
CREATE INDEX idx_challenges_active ON public.challenges(is_active) WHERE is_active = true;

-- User challenges indexes
CREATE UNIQUE INDEX idx_user_challenges_unique ON public.user_challenges(user_id, challenge_id);
CREATE INDEX idx_user_challenges_status ON public.user_challenges(status);

-- Notifications indexes
CREATE INDEX idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX idx_notifications_unread ON public.notifications(user_id) WHERE is_read = false;

-- Emergency indexes
CREATE INDEX idx_emergency_alerts_user_id ON public.emergency_alerts(user_id);
CREATE INDEX idx_emergency_alerts_active ON public.emergency_alerts(status) WHERE status = 'active';

-- Safety reports indexes
CREATE INDEX idx_safety_reports_location ON public.safety_reports USING GIST(location);
CREATE INDEX idx_safety_reports_verified ON public.safety_reports(verified);

-- Analytics indexes
CREATE INDEX idx_analytics_user_id ON public.analytics_events(user_id);
CREATE INDEX idx_analytics_event_type ON public.analytics_events(event_type);
CREATE INDEX idx_analytics_created_at ON public.analytics_events(created_at DESC);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Updated_at trigger function
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to relevant tables
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_trips_updated_at
    BEFORE UPDATE ON public.trips
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_posts_updated_at
    BEFORE UPDATE ON public.posts
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_challenges_updated_at
    BEFORE UPDATE ON public.challenges
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_user_settings_updated_at
    BEFORE UPDATE ON public.user_settings
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Denormalized counts update triggers
CREATE OR REPLACE FUNCTION public.update_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        UPDATE public.posts SET likes_count = likes_count + 1 WHERE id = NEW.post_id;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE public.posts SET likes_count = likes_count - 1 WHERE id = OLD.post_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER post_likes_count_trigger
    AFTER INSERT OR DELETE ON public.post_likes
    FOR EACH ROW EXECUTE FUNCTION public.update_post_likes_count();

CREATE OR REPLACE FUNCTION public.update_post_comments_count()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        UPDATE public.posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE public.posts SET comments_count = comments_count - 1 WHERE id = OLD.post_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER post_comments_count_trigger
    AFTER INSERT OR DELETE ON public.comments
    FOR EACH ROW EXECUTE FUNCTION public.update_post_comments_count();

-- Points history trigger
CREATE OR REPLACE FUNCTION public.track_points_change()
RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.total_points != OLD.total_points) THEN
        INSERT INTO public.points_history (user_id, points_change, balance_after, reason)
        VALUES (NEW.id, NEW.total_points - OLD.total_points, NEW.total_points, 'Manual update');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER track_user_points
    AFTER UPDATE OF total_points ON public.users
    FOR EACH ROW EXECUTE FUNCTION public.track_points_change();

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Get nearby places
CREATE OR REPLACE FUNCTION public.get_nearby_places(
    user_lat NUMERIC,
    user_lng NUMERIC,
    radius_meters INTEGER DEFAULT 5000,
    limit_count INTEGER DEFAULT 20
) RETURNS TABLE (
    id UUID,
    name VARCHAR,
    distance NUMERIC,
    rating NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        p.name,
        ST_Distance(
            p.location,
            ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
        ) AS distance,
        p.rating
    FROM public.places p
    WHERE ST_DWithin(
        p.location,
        ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography,
        radius_meters
    )
    ORDER BY distance
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- VIEWS
-- ============================================================================

-- User profile summary view
CREATE VIEW public.user_profile_summary AS
SELECT
    u.id,
    u.username,
    u.full_name,
    u.profile_picture,
    u.bio,
    u.total_points,
    u.membership_tier,
    COUNT(DISTINCT t.id) AS trips_count,
    COUNT(DISTINCT p.id) AS posts_count,
    COUNT(DISTINCT ua.id) AS achievements_count,
    (SELECT COUNT(*) FROM public.follows WHERE following_id = u.id) AS followers_count,
    (SELECT COUNT(*) FROM public.follows WHERE follower_id = u.id) AS following_count
FROM public.users u
LEFT JOIN public.trips t ON t.user_id = u.id
LEFT JOIN public.posts p ON p.user_id = u.id
LEFT JOIN public.user_achievements ua ON ua.user_id = u.id
GROUP BY u.id;

-- Popular places view
CREATE VIEW public.popular_places AS
SELECT
    p.*,
    COUNT(DISTINCT pr.id) AS total_reviews,
    COUNT(DISTINCT sp.id) AS saves_count,
    AVG(pr.rating) AS avg_rating
FROM public.places p
LEFT JOIN public.place_reviews pr ON pr.place_id = p.id
LEFT JOIN public.saved_places sp ON sp.place_id = p.id
GROUP BY p.id;

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================
