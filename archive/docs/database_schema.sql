-- ============================================================================
-- WanderChina Database Schema
-- PostgreSQL 14+ with PostGIS 3.3+
-- Version: 1.0.0
-- Created: 2025-10-22
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For fuzzy text search
CREATE EXTENSION IF NOT EXISTS "btree_gin"; -- For composite indexes

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

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255),
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
    premium_until TIMESTAMP,
    total_points INTEGER DEFAULT 0 CHECK (total_points >= 0),
    membership_tier membership_tier DEFAULT 'bronze',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    last_login TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    CONSTRAINT chk_users_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
);

-- Refresh tokens for authentication
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    revoked BOOLEAN DEFAULT FALSE
);

-- User settings
CREATE TABLE user_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    language VARCHAR(10) DEFAULT 'en',
    currency VARCHAR(3) DEFAULT 'CNY',
    distance_unit VARCHAR(10) DEFAULT 'km',
    temperature_unit VARCHAR(10) DEFAULT 'celsius',
    notifications JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- TRAVEL & TRIPS TABLES
-- ============================================================================

-- Trips
CREATE TABLE trips (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    budget NUMERIC(10, 2) DEFAULT 0 CHECK (budget >= 0),
    total_spent NUMERIC(10, 2) DEFAULT 0,
    status trip_status DEFAULT 'planning',
    cities JSONB DEFAULT '[]'::jsonb,
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT chk_trips_dates CHECK (end_date >= start_date)
);

-- Itineraries (day-by-day plans)
CREATE TABLE itineraries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    day_number INTEGER NOT NULL,
    date DATE NOT NULL,
    activities JSONB DEFAULT '[]'::jsonb,
    total_budget NUMERIC(10, 2),
    actual_spent NUMERIC(10, 2),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE (trip_id, day_number)
);

-- ============================================================================
-- PLACES & DISCOVERY TABLES
-- ============================================================================

-- Places (attractions, restaurants, hotels, etc.)
CREATE TABLE places (
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
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Place reviews
CREATE TABLE place_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    place_id UUID NOT NULL REFERENCES places(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    photos JSONB DEFAULT '[]'::jsonb,
    helpful_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Saved places (user bookmarks)
CREATE TABLE saved_places (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    place_id UUID NOT NULL REFERENCES places(id) ON DELETE CASCADE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE (user_id, place_id)
);

-- ============================================================================
-- BUDGET & EXPENSES TABLES
-- ============================================================================

-- Expenses
CREATE TABLE expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    trip_id UUID REFERENCES trips(id) ON DELETE CASCADE,
    place_id UUID REFERENCES places(id) ON DELETE SET NULL,
    category expense_category NOT NULL,
    amount NUMERIC(10, 2) NOT NULL CHECK (amount >= 0),
    currency VARCHAR(3) DEFAULT 'CNY',
    description TEXT,
    receipt_photo TEXT,
    expense_date TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- GAMIFICATION TABLES
-- ============================================================================

-- Challenges
CREATE TABLE challenges (
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
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- User challenges (progress tracking)
CREATE TABLE user_challenges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    challenge_id UUID NOT NULL REFERENCES challenges(id) ON DELETE RESTRICT,
    status VARCHAR(20) DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'abandoned')),
    progress JSONB DEFAULT '{}'::jsonb,
    completion_percentage INTEGER DEFAULT 0 CHECK (completion_percentage >= 0 AND completion_percentage <= 100),
    started_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP,
    points_earned INTEGER DEFAULT 0,
    UNIQUE (user_id, challenge_id)
);

-- Achievements
CREATE TABLE achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(50),
    criteria JSONB NOT NULL,
    rarity rarity_level DEFAULT 'common',
    badge_image TEXT,
    points_reward INTEGER DEFAULT 0,
    is_hidden BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- User achievements (unlocked achievements)
CREATE TABLE user_achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    achievement_id UUID NOT NULL REFERENCES achievements(id) ON DELETE RESTRICT,
    unlocked_at TIMESTAMP DEFAULT NOW(),
    UNIQUE (user_id, achievement_id)
);

-- Points history (ledger)
CREATE TABLE points_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    points_change INTEGER NOT NULL,
    reason VARCHAR(100),
    reference_id UUID,
    reference_type VARCHAR(50),
    balance_after INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- COMMUNITY & SOCIAL TABLES
-- ============================================================================

-- Posts
CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    location_id UUID REFERENCES places(id) ON DELETE SET NULL,
    trip_id UUID REFERENCES trips(id) ON DELETE SET NULL,
    content TEXT NOT NULL,
    images JSONB DEFAULT '[]'::jsonb,
    tags JSONB DEFAULT '[]'::jsonb,
    post_type post_type DEFAULT 'photo',
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    is_pinned BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Comments
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    parent_comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    likes_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Post likes
CREATE TABLE post_likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE (user_id, post_id)
);

-- Comment likes
CREATE TABLE comment_likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    comment_id UUID NOT NULL REFERENCES comments(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE (user_id, comment_id)
);

-- Saved posts
CREATE TABLE saved_posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE (user_id, post_id)
);

-- Follows (user relationships)
CREATE TABLE follows (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    follower_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE (follower_id, following_id),
    CHECK (follower_id != following_id)
);

-- ============================================================================
-- SOCIAL MATCHING TABLES
-- ============================================================================

-- Companion profiles
CREATE TABLE companion_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
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
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Companion matches
CREATE TABLE companion_matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user1_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user2_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    match_score NUMERIC(3, 2),
    status VARCHAR(20) DEFAULT 'pending',
    matched_at TIMESTAMP DEFAULT NOW(),
    accepted_at TIMESTAMP,
    UNIQUE (user1_id, user2_id),
    CHECK (user1_id < user2_id)
);

-- Local guides
CREATE TABLE local_guides (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
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
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Guide bookings
CREATE TABLE guide_bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    guide_id UUID NOT NULL REFERENCES local_guides(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    booking_date DATE NOT NULL,
    start_time TIME NOT NULL,
    duration_hours INTEGER NOT NULL,
    total_cost NUMERIC(10, 2),
    status VARCHAR(20) DEFAULT 'pending',
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    review TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- SAFETY & EMERGENCY TABLES
-- ============================================================================

-- Emergency contacts
CREATE TABLE emergency_contacts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(50) NOT NULL,
    relationship VARCHAR(100),
    notification_type VARCHAR(20) DEFAULT 'both',
    priority INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Emergency alerts
CREATE TABLE emergency_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    location GEOGRAPHY(POINT, 4326),
    emergency_type emergency_type NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT NOW(),
    resolved_at TIMESTAMP
);

-- Location sharing sessions
CREATE TABLE location_shares (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    share_code VARCHAR(50) UNIQUE NOT NULL,
    recipients JSONB DEFAULT '[]'::jsonb,
    duration_hours INTEGER NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Location updates (GPS breadcrumbs)
CREATE TABLE location_updates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    share_id UUID NOT NULL REFERENCES location_shares(id) ON DELETE CASCADE,
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    accuracy NUMERIC(6, 2),
    battery_level INTEGER,
    timestamp TIMESTAMP DEFAULT NOW()
);

-- Safety reports
CREATE TABLE safety_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    incident_type VARCHAR(50) NOT NULL,
    severity VARCHAR(20),
    description TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- SYSTEM & UTILITIES TABLES
-- ============================================================================

-- Notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type notification_type NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT,
    data JSONB DEFAULT '{}'::jsonb,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Translation cache
CREATE TABLE translations_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    text_hash VARCHAR(64) NOT NULL,
    source_lang VARCHAR(10) NOT NULL,
    target_lang VARCHAR(10) NOT NULL,
    translation TEXT NOT NULL,
    confidence NUMERIC(3, 2),
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP,
    UNIQUE (text_hash, source_lang, target_lang)
);

-- Offline maps
CREATE TABLE offline_maps (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    city_id VARCHAR(50) UNIQUE NOT NULL,
    city_name VARCHAR(100) NOT NULL,
    version VARCHAR(20) NOT NULL,
    size_mb INTEGER NOT NULL,
    bounds JSONB NOT NULL,
    tile_count INTEGER,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- User downloaded maps
CREATE TABLE user_downloaded_maps (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    map_id UUID NOT NULL REFERENCES offline_maps(id) ON DELETE CASCADE,
    downloaded_at TIMESTAMP DEFAULT NOW(),
    last_used TIMESTAMP,
    UNIQUE (user_id, map_id)
);

-- ============================================================================
-- BOOKING & PAYMENTS TABLES
-- ============================================================================

-- Bookings
CREATE TABLE bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    place_id UUID REFERENCES places(id) ON DELETE SET NULL,
    booking_type booking_type NOT NULL,
    check_in_date DATE,
    check_out_date DATE,
    guests_count INTEGER,
    total_cost NUMERIC(10, 2),
    currency VARCHAR(3) DEFAULT 'CNY',
    status VARCHAR(20) DEFAULT 'pending',
    confirmation_code VARCHAR(100),
    partner_name VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Subscriptions
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan_type VARCHAR(20) NOT NULL CHECK (plan_type IN ('monthly', 'yearly')),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'expired')),
    started_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP NOT NULL,
    auto_renew BOOLEAN DEFAULT TRUE,
    payment_method VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Payments
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subscription_id UUID REFERENCES subscriptions(id) ON DELETE RESTRICT,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount NUMERIC(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'CNY',
    payment_method VARCHAR(50),
    payment_provider VARCHAR(50),
    transaction_id VARCHAR(255),
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- ANALYTICS TABLES
-- ============================================================================

-- Analytics events (partitioned by month)
CREATE TABLE analytics_events (
    id UUID DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    event_type VARCHAR(100) NOT NULL,
    event_data JSONB DEFAULT '{}'::jsonb,
    platform VARCHAR(20),
    app_version VARCHAR(20),
    created_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

-- Create initial partitions (example for 2025-2026)
CREATE TABLE analytics_events_2025_10 PARTITION OF analytics_events
    FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');

CREATE TABLE analytics_events_2025_11 PARTITION OF analytics_events
    FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');

CREATE TABLE analytics_events_2025_12 PARTITION OF analytics_events
    FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Users indexes
CREATE UNIQUE INDEX idx_users_email ON users(email);
CREATE UNIQUE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_created_at ON users(created_at DESC);
CREATE INDEX idx_users_premium ON users(premium_until) WHERE premium_until > NOW();

-- Places indexes (including geospatial)
CREATE INDEX idx_places_location ON places USING GIST(location);
CREATE INDEX idx_places_city ON places(city);
CREATE INDEX idx_places_category ON places(category);
CREATE INDEX idx_places_rating ON places(rating DESC);
CREATE INDEX idx_places_city_category ON places(city, category);
CREATE INDEX idx_places_tags ON places USING GIN(tags);

-- Trips indexes
CREATE INDEX idx_trips_user_id ON trips(user_id);
CREATE INDEX idx_trips_status ON trips(status);
CREATE INDEX idx_trips_dates ON trips(start_date, end_date);

-- Expenses indexes
CREATE INDEX idx_expenses_user_id ON expenses(user_id);
CREATE INDEX idx_expenses_trip_id ON expenses(trip_id);
CREATE INDEX idx_expenses_date ON expenses(expense_date DESC);
CREATE INDEX idx_expenses_user_trip ON expenses(user_id, trip_id);

-- Posts indexes
CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX idx_posts_location_id ON posts(location_id);
CREATE INDEX idx_posts_tags ON posts USING GIN(tags);

-- Comments indexes
CREATE INDEX idx_comments_post_id ON comments(post_id);
CREATE INDEX idx_comments_user_id ON comments(user_id);
CREATE INDEX idx_comments_parent_id ON comments(parent_comment_id);

-- Challenges indexes
CREATE INDEX idx_challenges_city ON challenges(city);
CREATE INDEX idx_challenges_category ON challenges(category);
CREATE INDEX idx_challenges_active ON challenges(is_active) WHERE is_active = true;

-- User challenges indexes
CREATE UNIQUE INDEX idx_user_challenges_unique ON user_challenges(user_id, challenge_id);
CREATE INDEX idx_user_challenges_status ON user_challenges(status);

-- Notifications indexes
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_unread ON notifications(user_id) WHERE is_read = false;

-- Emergency indexes
CREATE INDEX idx_emergency_alerts_user_id ON emergency_alerts(user_id);
CREATE INDEX idx_emergency_alerts_active ON emergency_alerts(status) WHERE status = 'active';

-- Safety reports indexes
CREATE INDEX idx_safety_reports_location ON safety_reports USING GIST(location);
CREATE INDEX idx_safety_reports_verified ON safety_reports(verified);

-- Analytics indexes (on partitions)
CREATE INDEX idx_analytics_user_id ON analytics_events(user_id);
CREATE INDEX idx_analytics_event_type ON analytics_events(event_type);
CREATE INDEX idx_analytics_created_at ON analytics_events(created_at DESC);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to relevant tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_trips_updated_at BEFORE UPDATE ON trips
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON posts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_challenges_updated_at BEFORE UPDATE ON challenges
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Denormalized counts update triggers
CREATE OR REPLACE FUNCTION update_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        UPDATE posts SET likes_count = likes_count + 1 WHERE id = NEW.post_id;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE posts SET likes_count = likes_count - 1 WHERE id = OLD.post_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER post_likes_count_trigger
AFTER INSERT OR DELETE ON post_likes
FOR EACH ROW EXECUTE FUNCTION update_post_likes_count();

CREATE OR REPLACE FUNCTION update_post_comments_count()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        UPDATE posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE posts SET comments_count = comments_count - 1 WHERE id = OLD.post_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER post_comments_count_trigger
AFTER INSERT OR DELETE ON comments
FOR EACH ROW EXECUTE FUNCTION update_post_comments_count();

-- Points history trigger
CREATE OR REPLACE FUNCTION track_points_change()
RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.total_points != OLD.total_points) THEN
        INSERT INTO points_history (user_id, points_change, balance_after, reason)
        VALUES (NEW.id, NEW.total_points - OLD.total_points, NEW.total_points, 'Manual update');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER track_user_points
AFTER UPDATE OF total_points ON users
FOR EACH ROW EXECUTE FUNCTION track_points_change();

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Calculate distance between two points (in meters)
CREATE OR REPLACE FUNCTION calculate_distance(
    lat1 NUMERIC, lng1 NUMERIC,
    lat2 NUMERIC, lng2 NUMERIC
) RETURNS NUMERIC AS $$
BEGIN
    RETURN ST_Distance(
        ST_SetSRID(ST_MakePoint(lng1, lat1), 4326)::geography,
        ST_SetSRID(ST_MakePoint(lng2, lat2), 4326)::geography
    );
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Get nearby places
CREATE OR REPLACE FUNCTION get_nearby_places(
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
    FROM places p
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
-- INITIAL DATA (SEED)
-- ============================================================================

-- Insert default achievements
INSERT INTO achievements (name, description, category, criteria, rarity, badge_image, points_reward, is_hidden) VALUES
    ('First Steps', 'Visit your first place in China', 'explorer', '{"type": "visit_places", "count": 1}', 'common', '/badges/first-steps.png', 50, false),
    ('City Explorer', 'Visit 5 places in one city', 'explorer', '{"type": "visit_places", "count": 5, "same_city": true}', 'common', '/badges/city-explorer.png', 100, false),
    ('Foodie', 'Try 10 different Chinese dishes', 'foodie', '{"type": "try_dishes", "count": 10}', 'common', '/badges/foodie.png', 150, false),
    ('Temple Seeker', 'Visit 10 temples or religious sites', 'explorer', '{"type": "visit_category", "category": "temple", "count": 10}', 'rare', '/badges/temple-seeker.png', 200, false),
    ('Social Butterfly', 'Help 10 other travelers', 'social', '{"type": "help_travelers", "count": 10}', 'rare', '/badges/social-butterfly.png', 200, false),
    ('Budget Master', 'Stay under budget for 30 days', 'budget', '{"type": "budget_streak", "days": 30}', 'epic', '/badges/budget-master.png', 500, false),
    ('China Master', 'Visit all 34 provinces', 'explorer', '{"type": "visit_provinces", "count": 34}', 'legendary', '/badges/china-master.png', 5000, false);

-- Create sample challenges
INSERT INTO challenges (title, description, city, category, difficulty, checkpoints, total_points, estimated_time_hours, badge_image) VALUES
    (
        'Beijing Heritage Challenge',
        'Explore the historical treasures of Beijing',
        'Beijing',
        'heritage',
        'intermediate',
        '[
            {"order": 1, "place_name": "Forbidden City", "points": 100},
            {"order": 2, "place_name": "Temple of Heaven", "points": 100},
            {"order": 3, "place_name": "Summer Palace", "points": 100},
            {"order": 4, "place_name": "Lama Temple", "points": 100},
            {"order": 5, "place_name": "Great Wall (Mutianyu)", "points": 100}
        ]'::jsonb,
        500,
        8,
        '/badges/beijing-heritage.png'
    ),
    (
        'Chengdu Food Quest',
        'Sample the spicy delights of Sichuan cuisine',
        'Chengdu',
        'food',
        'beginner',
        '[
            {"order": 1, "place_name": "Hotpot Restaurant", "points": 50},
            {"order": 2, "place_name": "Dan Dan Noodles", "points": 50},
            {"order": 3, "place_name": "Mapo Tofu", "points": 50}
        ]'::jsonb,
        150,
        4,
        '/badges/chengdu-food.png'
    );

-- ============================================================================
-- VIEWS
-- ============================================================================

-- User profile summary view
CREATE VIEW user_profile_summary AS
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
    (SELECT COUNT(*) FROM follows WHERE following_id = u.id) AS followers_count,
    (SELECT COUNT(*) FROM follows WHERE follower_id = u.id) AS following_count
FROM users u
LEFT JOIN trips t ON t.user_id = u.id
LEFT JOIN posts p ON p.user_id = u.id
LEFT JOIN user_achievements ua ON ua.user_id = u.id
GROUP BY u.id;

-- Popular places view
CREATE VIEW popular_places AS
SELECT
    p.*,
    COUNT(DISTINCT pr.id) AS total_reviews,
    COUNT(DISTINCT sp.id) AS saves_count,
    AVG(pr.rating) AS avg_rating
FROM places p
LEFT JOIN place_reviews pr ON pr.place_id = p.id
LEFT JOIN saved_places sp ON sp.place_id = p.id
GROUP BY p.id;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE users IS 'Primary user accounts';
COMMENT ON TABLE places IS 'Attractions, restaurants, hotels, and other points of interest';
COMMENT ON TABLE challenges IS 'Gamified city exploration challenges';
COMMENT ON TABLE expenses IS 'User expense tracking for budget management';
COMMENT ON TABLE posts IS 'Community feed posts';
COMMENT ON TABLE safety_reports IS 'Community-reported safety incidents';

-- ============================================================================
-- GRANTS (Adjust based on your user roles)
-- ============================================================================

-- Create application user role
-- CREATE ROLE wanderchina_app WITH LOGIN PASSWORD 'change_me_in_production';
-- GRANT CONNECT ON DATABASE wanderchina TO wanderchina_app;
-- GRANT USAGE ON SCHEMA public TO wanderchina_app;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO wanderchina_app;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO wanderchina_app;

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================
