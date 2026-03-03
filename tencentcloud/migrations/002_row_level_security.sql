-- ============================================================================
-- WanderChina Row Level Security (RLS) Policies for Tencent Cloud
-- Version: 1.0.0
-- Created: 2026-01-25
-- Converted from Supabase to standard PostgreSQL
-- NOTE: auth.uid() replaced with public.current_user_id()
-- ============================================================================

-- ============================================================================
-- ENABLE ROW LEVEL SECURITY ON ALL TABLES
-- ============================================================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.itineraries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.places ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.place_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_places ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.points_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comment_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.companion_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.companion_matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.local_guides ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guide_bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.emergency_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.emergency_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.location_shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.location_updates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.safety_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.translations_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.offline_maps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_downloaded_maps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analytics_events ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- USERS TABLE POLICIES
-- ============================================================================

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
    ON public.users FOR SELECT
    USING (public.current_user_id() = id);

-- Users can view other public profiles
CREATE POLICY "Users can view public profiles"
    ON public.users FOR SELECT
    USING (is_active = true);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
    ON public.users FOR UPDATE
    USING (public.current_user_id() = id);

-- Users can insert their own profile (on signup)
CREATE POLICY "Users can insert own profile"
    ON public.users FOR INSERT
    WITH CHECK (public.current_user_id() = id);

-- ============================================================================
-- USER SESSIONS POLICIES
-- ============================================================================

-- Users can view their own sessions
CREATE POLICY "Users can view own sessions"
    ON public.user_sessions FOR SELECT
    USING (public.current_user_id() = user_id);

-- Users can delete their own sessions
CREATE POLICY "Users can delete own sessions"
    ON public.user_sessions FOR DELETE
    USING (public.current_user_id() = user_id);

-- ============================================================================
-- USER SETTINGS POLICIES
-- ============================================================================

-- Users can view their own settings
CREATE POLICY "Users can view own settings"
    ON public.user_settings FOR SELECT
    USING (public.current_user_id() = user_id);

-- Users can update their own settings
CREATE POLICY "Users can update own settings"
    ON public.user_settings FOR UPDATE
    USING (public.current_user_id() = user_id);

-- Users can insert their own settings
CREATE POLICY "Users can insert own settings"
    ON public.user_settings FOR INSERT
    WITH CHECK (public.current_user_id() = user_id);

-- ============================================================================
-- TRIPS POLICIES
-- ============================================================================

-- Users can view their own trips
CREATE POLICY "Users can view own trips"
    ON public.trips FOR SELECT
    USING (public.current_user_id() = user_id);

-- Users can view public trips
CREATE POLICY "Users can view public trips"
    ON public.trips FOR SELECT
    USING (is_public = true);

-- Users can create their own trips
CREATE POLICY "Users can create own trips"
    ON public.trips FOR INSERT
    WITH CHECK (public.current_user_id() = user_id);

-- Users can update their own trips
CREATE POLICY "Users can update own trips"
    ON public.trips FOR UPDATE
    USING (public.current_user_id() = user_id);

-- Users can delete their own trips
CREATE POLICY "Users can delete own trips"
    ON public.trips FOR DELETE
    USING (public.current_user_id() = user_id);

-- ============================================================================
-- ITINERARIES POLICIES
-- ============================================================================

-- Users can manage itineraries for their own trips
CREATE POLICY "Users can manage own itineraries"
    ON public.itineraries FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.trips
            WHERE trips.id = itineraries.trip_id
            AND trips.user_id = public.current_user_id()
        )
    );

-- Users can view itineraries for public trips
CREATE POLICY "Users can view public itineraries"
    ON public.itineraries FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.trips
            WHERE trips.id = itineraries.trip_id
            AND trips.is_public = true
        )
    );

-- ============================================================================
-- PLACES POLICIES
-- ============================================================================

-- All authenticated users can view places
CREATE POLICY "Authenticated users can view places"
    ON public.places FOR SELECT
    USING (public.is_authenticated());

-- ============================================================================
-- PLACE REVIEWS POLICIES
-- ============================================================================

-- Users can view all reviews
CREATE POLICY "Users can view all reviews"
    ON public.place_reviews FOR SELECT
    USING (public.is_authenticated());

-- Users can create their own reviews
CREATE POLICY "Users can create own reviews"
    ON public.place_reviews FOR INSERT
    WITH CHECK (public.current_user_id() = user_id);

-- Users can update their own reviews
CREATE POLICY "Users can update own reviews"
    ON public.place_reviews FOR UPDATE
    USING (public.current_user_id() = user_id);

-- Users can delete their own reviews
CREATE POLICY "Users can delete own reviews"
    ON public.place_reviews FOR DELETE
    USING (public.current_user_id() = user_id);

-- ============================================================================
-- SAVED PLACES POLICIES
-- ============================================================================

-- Users can manage their own saved places
CREATE POLICY "Users can manage own saved places"
    ON public.saved_places FOR ALL
    USING (public.current_user_id() = user_id)
    WITH CHECK (public.current_user_id() = user_id);

-- ============================================================================
-- EXPENSES POLICIES
-- ============================================================================

-- Users can manage their own expenses
CREATE POLICY "Users can manage own expenses"
    ON public.expenses FOR ALL
    USING (public.current_user_id() = user_id)
    WITH CHECK (public.current_user_id() = user_id);

-- ============================================================================
-- CHALLENGES POLICIES
-- ============================================================================

-- All authenticated users can view active challenges
CREATE POLICY "Users can view active challenges"
    ON public.challenges FOR SELECT
    USING (is_active = true AND public.is_authenticated());

-- ============================================================================
-- USER CHALLENGES POLICIES
-- ============================================================================

-- Users can view their own challenge progress
CREATE POLICY "Users can view own challenges"
    ON public.user_challenges FOR SELECT
    USING (public.current_user_id() = user_id);

-- Users can create their own challenge progress
CREATE POLICY "Users can create own challenges"
    ON public.user_challenges FOR INSERT
    WITH CHECK (public.current_user_id() = user_id);

-- Users can update their own challenge progress
CREATE POLICY "Users can update own challenges"
    ON public.user_challenges FOR UPDATE
    USING (public.current_user_id() = user_id);

-- ============================================================================
-- ACHIEVEMENTS POLICIES
-- ============================================================================

-- All authenticated users can view non-hidden achievements
CREATE POLICY "Users can view achievements"
    ON public.achievements FOR SELECT
    USING (
        public.is_authenticated() AND
        (is_hidden = false OR EXISTS (
            SELECT 1 FROM public.user_achievements
            WHERE user_achievements.achievement_id = achievements.id
            AND user_achievements.user_id = public.current_user_id()
        ))
    );

-- ============================================================================
-- USER ACHIEVEMENTS POLICIES
-- ============================================================================

-- Users can view their own achievements
CREATE POLICY "Users can view own achievements"
    ON public.user_achievements FOR SELECT
    USING (public.current_user_id() = user_id);

-- Users can view others' achievements
CREATE POLICY "Users can view others achievements"
    ON public.user_achievements FOR SELECT
    USING (public.is_authenticated());

-- ============================================================================
-- POINTS HISTORY POLICIES
-- ============================================================================

-- Users can view their own points history
CREATE POLICY "Users can view own points history"
    ON public.points_history FOR SELECT
    USING (public.current_user_id() = user_id);

-- ============================================================================
-- POSTS POLICIES
-- ============================================================================

-- All authenticated users can view posts
CREATE POLICY "Users can view all posts"
    ON public.posts FOR SELECT
    USING (public.is_authenticated());

-- Users can create their own posts
CREATE POLICY "Users can create own posts"
    ON public.posts FOR INSERT
    WITH CHECK (public.current_user_id() = user_id);

-- Users can update their own posts
CREATE POLICY "Users can update own posts"
    ON public.posts FOR UPDATE
    USING (public.current_user_id() = user_id);

-- Users can delete their own posts
CREATE POLICY "Users can delete own posts"
    ON public.posts FOR DELETE
    USING (public.current_user_id() = user_id);

-- ============================================================================
-- COMMENTS POLICIES
-- ============================================================================

-- All authenticated users can view comments
CREATE POLICY "Users can view all comments"
    ON public.comments FOR SELECT
    USING (public.is_authenticated());

-- Users can create comments
CREATE POLICY "Users can create comments"
    ON public.comments FOR INSERT
    WITH CHECK (public.current_user_id() = user_id);

-- Users can update their own comments
CREATE POLICY "Users can update own comments"
    ON public.comments FOR UPDATE
    USING (public.current_user_id() = user_id);

-- Users can delete their own comments
CREATE POLICY "Users can delete own comments"
    ON public.comments FOR DELETE
    USING (public.current_user_id() = user_id);

-- ============================================================================
-- POST LIKES POLICIES
-- ============================================================================

-- Users can view all post likes
CREATE POLICY "Users can view all post likes"
    ON public.post_likes FOR SELECT
    USING (public.is_authenticated());

-- Users can manage their own post likes
CREATE POLICY "Users can manage own post likes"
    ON public.post_likes FOR ALL
    USING (public.current_user_id() = user_id)
    WITH CHECK (public.current_user_id() = user_id);

-- ============================================================================
-- COMMENT LIKES POLICIES
-- ============================================================================

-- Users can view all comment likes
CREATE POLICY "Users can view all comment likes"
    ON public.comment_likes FOR SELECT
    USING (public.is_authenticated());

-- Users can manage their own comment likes
CREATE POLICY "Users can manage own comment likes"
    ON public.comment_likes FOR ALL
    USING (public.current_user_id() = user_id)
    WITH CHECK (public.current_user_id() = user_id);

-- ============================================================================
-- SAVED POSTS POLICIES
-- ============================================================================

-- Users can manage their own saved posts
CREATE POLICY "Users can manage own saved posts"
    ON public.saved_posts FOR ALL
    USING (public.current_user_id() = user_id)
    WITH CHECK (public.current_user_id() = user_id);

-- ============================================================================
-- FOLLOWS POLICIES
-- ============================================================================

-- Users can view all follows
CREATE POLICY "Users can view all follows"
    ON public.follows FOR SELECT
    USING (public.is_authenticated());

-- Users can manage their own follows
CREATE POLICY "Users can manage own follows"
    ON public.follows FOR ALL
    USING (public.current_user_id() = follower_id)
    WITH CHECK (public.current_user_id() = follower_id);

-- ============================================================================
-- COMPANION PROFILES POLICIES
-- ============================================================================

-- Users can view seeking companion profiles
CREATE POLICY "Users can view seeking profiles"
    ON public.companion_profiles FOR SELECT
    USING (public.is_authenticated() AND is_seeking_companions = true AND verification_status = 'approved');

-- Users can view their own profile
CREATE POLICY "Users can view own companion profile"
    ON public.companion_profiles FOR SELECT
    USING (public.current_user_id() = user_id);

-- Users can manage their own companion profile
CREATE POLICY "Users can manage own companion profile"
    ON public.companion_profiles FOR ALL
    USING (public.current_user_id() = user_id)
    WITH CHECK (public.current_user_id() = user_id);

-- ============================================================================
-- COMPANION MATCHES POLICIES
-- ============================================================================

-- Users can view their own matches
CREATE POLICY "Users can view own matches"
    ON public.companion_matches FOR SELECT
    USING (public.current_user_id() = user1_id OR public.current_user_id() = user2_id);

-- Users can update their own matches
CREATE POLICY "Users can update own matches"
    ON public.companion_matches FOR UPDATE
    USING (public.current_user_id() = user1_id OR public.current_user_id() = user2_id);

-- ============================================================================
-- LOCAL GUIDES POLICIES
-- ============================================================================

-- Users can view approved guides
CREATE POLICY "Users can view approved guides"
    ON public.local_guides FOR SELECT
    USING (public.is_authenticated() AND verification_status = 'approved');

-- Users can view their own guide profile
CREATE POLICY "Users can view own guide profile"
    ON public.local_guides FOR SELECT
    USING (public.current_user_id() = user_id);

-- Users can manage their own guide profile
CREATE POLICY "Users can manage own guide profile"
    ON public.local_guides FOR ALL
    USING (public.current_user_id() = user_id)
    WITH CHECK (public.current_user_id() = user_id);

-- ============================================================================
-- GUIDE BOOKINGS POLICIES
-- ============================================================================

-- Users can view their own bookings (as customer)
CREATE POLICY "Users can view own bookings"
    ON public.guide_bookings FOR SELECT
    USING (public.current_user_id() = user_id);

-- Guides can view their bookings
CREATE POLICY "Guides can view their bookings"
    ON public.guide_bookings FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.local_guides
            WHERE local_guides.id = guide_bookings.guide_id
            AND local_guides.user_id = public.current_user_id()
        )
    );

-- Users can create bookings
CREATE POLICY "Users can create bookings"
    ON public.guide_bookings FOR INSERT
    WITH CHECK (public.current_user_id() = user_id);

-- Users can update their own bookings
CREATE POLICY "Users can update own bookings"
    ON public.guide_bookings FOR UPDATE
    USING (public.current_user_id() = user_id);

-- ============================================================================
-- EMERGENCY CONTACTS POLICIES
-- ============================================================================

-- Users can manage their own emergency contacts
CREATE POLICY "Users can manage own emergency contacts"
    ON public.emergency_contacts FOR ALL
    USING (public.current_user_id() = user_id)
    WITH CHECK (public.current_user_id() = user_id);

-- ============================================================================
-- EMERGENCY ALERTS POLICIES
-- ============================================================================

-- Users can view their own emergency alerts
CREATE POLICY "Users can view own emergency alerts"
    ON public.emergency_alerts FOR SELECT
    USING (public.current_user_id() = user_id);

-- Users can create their own emergency alerts
CREATE POLICY "Users can create emergency alerts"
    ON public.emergency_alerts FOR INSERT
    WITH CHECK (public.current_user_id() = user_id);

-- Users can update their own emergency alerts
CREATE POLICY "Users can update own emergency alerts"
    ON public.emergency_alerts FOR UPDATE
    USING (public.current_user_id() = user_id);

-- ============================================================================
-- LOCATION SHARES POLICIES
-- ============================================================================

-- Users can manage their own location shares
CREATE POLICY "Users can manage own location shares"
    ON public.location_shares FOR ALL
    USING (public.current_user_id() = user_id)
    WITH CHECK (public.current_user_id() = user_id);

-- ============================================================================
-- LOCATION UPDATES POLICIES
-- ============================================================================

-- Users can view location updates for shares they own
CREATE POLICY "Users can view own location updates"
    ON public.location_updates FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.location_shares
            WHERE location_shares.id = location_updates.share_id
            AND location_shares.user_id = public.current_user_id()
        )
    );

-- Users can insert location updates for their own shares
CREATE POLICY "Users can insert own location updates"
    ON public.location_updates FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.location_shares
            WHERE location_shares.id = share_id
            AND location_shares.user_id = public.current_user_id()
        )
    );

-- ============================================================================
-- SAFETY REPORTS POLICIES
-- ============================================================================

-- All authenticated users can view verified safety reports
CREATE POLICY "Users can view verified safety reports"
    ON public.safety_reports FOR SELECT
    USING (public.is_authenticated() AND verified = true);

-- Users can view their own safety reports
CREATE POLICY "Users can view own safety reports"
    ON public.safety_reports FOR SELECT
    USING (public.current_user_id() = user_id);

-- Users can create safety reports
CREATE POLICY "Users can create safety reports"
    ON public.safety_reports FOR INSERT
    WITH CHECK (public.current_user_id() = user_id OR user_id IS NULL);

-- ============================================================================
-- NOTIFICATIONS POLICIES
-- ============================================================================

-- Users can view their own notifications
CREATE POLICY "Users can view own notifications"
    ON public.notifications FOR SELECT
    USING (public.current_user_id() = user_id);

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update own notifications"
    ON public.notifications FOR UPDATE
    USING (public.current_user_id() = user_id);

-- Users can delete their own notifications
CREATE POLICY "Users can delete own notifications"
    ON public.notifications FOR DELETE
    USING (public.current_user_id() = user_id);

-- ============================================================================
-- TRANSLATIONS CACHE POLICIES
-- ============================================================================

-- All authenticated users can view and use translation cache
CREATE POLICY "Users can view translation cache"
    ON public.translations_cache FOR SELECT
    USING (public.is_authenticated());

-- ============================================================================
-- OFFLINE MAPS POLICIES
-- ============================================================================

-- All authenticated users can view available offline maps
CREATE POLICY "Users can view offline maps"
    ON public.offline_maps FOR SELECT
    USING (public.is_authenticated());

-- ============================================================================
-- USER DOWNLOADED MAPS POLICIES
-- ============================================================================

-- Users can manage their own downloaded maps
CREATE POLICY "Users can manage own downloaded maps"
    ON public.user_downloaded_maps FOR ALL
    USING (public.current_user_id() = user_id)
    WITH CHECK (public.current_user_id() = user_id);

-- ============================================================================
-- BOOKINGS POLICIES
-- ============================================================================

-- Users can view their own bookings
CREATE POLICY "Users can view own bookings"
    ON public.bookings FOR SELECT
    USING (public.current_user_id() = user_id);

-- Users can create their own bookings
CREATE POLICY "Users can create own bookings"
    ON public.bookings FOR INSERT
    WITH CHECK (public.current_user_id() = user_id);

-- Users can update their own bookings
CREATE POLICY "Users can update own bookings"
    ON public.bookings FOR UPDATE
    USING (public.current_user_id() = user_id);

-- ============================================================================
-- SUBSCRIPTIONS POLICIES
-- ============================================================================

-- Users can view their own subscriptions
CREATE POLICY "Users can view own subscriptions"
    ON public.subscriptions FOR SELECT
    USING (public.current_user_id() = user_id);

-- Users can update their own subscriptions
CREATE POLICY "Users can update own subscriptions"
    ON public.subscriptions FOR UPDATE
    USING (public.current_user_id() = user_id);

-- ============================================================================
-- PAYMENTS POLICIES
-- ============================================================================

-- Users can view their own payments
CREATE POLICY "Users can view own payments"
    ON public.payments FOR SELECT
    USING (public.current_user_id() = user_id);

-- ============================================================================
-- ANALYTICS EVENTS POLICIES
-- ============================================================================

-- Users can insert their own analytics events
CREATE POLICY "Users can insert own analytics events"
    ON public.analytics_events FOR INSERT
    WITH CHECK (public.current_user_id() = user_id OR user_id IS NULL);

-- ============================================================================
-- END OF RLS POLICIES
-- ============================================================================
