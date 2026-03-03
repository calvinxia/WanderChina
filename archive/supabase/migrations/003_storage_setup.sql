-- ============================================================================
-- WanderChina Storage Buckets Setup
-- Version: 1.0.0
-- Created: 2025-10-23
-- Platform: Supabase Storage
-- ============================================================================

-- ============================================================================
-- CREATE STORAGE BUCKETS
-- ============================================================================

-- Bucket for user profile pictures
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'avatars',
    'avatars',
    true,
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
);

-- Bucket for post images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'post-images',
    'post-images',
    true,
    10485760, -- 10MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic']
);

-- Bucket for place photos
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'place-photos',
    'place-photos',
    true,
    10485760, -- 10MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp']
);

-- Bucket for receipt photos (expenses)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'receipts',
    'receipts',
    false, -- Private bucket
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/pdf']
);

-- Bucket for challenge badges
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'badges',
    'badges',
    true,
    2097152, -- 2MB limit
    ARRAY['image/png', 'image/svg+xml']
);

-- Bucket for offline map tiles
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'map-tiles',
    'map-tiles',
    true,
    NULL, -- No file size limit for map packages
    ARRAY['application/zip', 'application/x-gzip']
);

-- ============================================================================
-- STORAGE POLICIES FOR AVATARS
-- ============================================================================

-- Anyone can view avatars
CREATE POLICY "Avatars are publicly accessible"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'avatars');

-- Users can upload their own avatar
CREATE POLICY "Users can upload own avatar"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'avatars' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Users can update their own avatar
CREATE POLICY "Users can update own avatar"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'avatars' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Users can delete their own avatar
CREATE POLICY "Users can delete own avatar"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'avatars' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- ============================================================================
-- STORAGE POLICIES FOR POST IMAGES
-- ============================================================================

-- Anyone can view post images
CREATE POLICY "Post images are publicly accessible"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'post-images');

-- Users can upload their own post images
CREATE POLICY "Users can upload own post images"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'post-images' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Users can delete their own post images
CREATE POLICY "Users can delete own post images"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'post-images' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- ============================================================================
-- STORAGE POLICIES FOR PLACE PHOTOS
-- ============================================================================

-- Anyone can view place photos
CREATE POLICY "Place photos are publicly accessible"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'place-photos');

-- Authenticated users can upload place photos
CREATE POLICY "Authenticated users can upload place photos"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'place-photos');

-- ============================================================================
-- STORAGE POLICIES FOR RECEIPTS
-- ============================================================================

-- Users can view their own receipts
CREATE POLICY "Users can view own receipts"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'receipts' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Users can upload their own receipts
CREATE POLICY "Users can upload own receipts"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'receipts' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Users can delete their own receipts
CREATE POLICY "Users can delete own receipts"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'receipts' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- ============================================================================
-- STORAGE POLICIES FOR BADGES
-- ============================================================================

-- Anyone can view badges
CREATE POLICY "Badges are publicly accessible"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'badges');

-- Only service role can upload badges (admin only)

-- ============================================================================
-- STORAGE POLICIES FOR MAP TILES
-- ============================================================================

-- Authenticated users can view map tiles
CREATE POLICY "Authenticated users can view map tiles"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (bucket_id = 'map-tiles');

-- Only service role can upload map tiles (admin only)

-- ============================================================================
-- HELPER FUNCTIONS FOR STORAGE
-- ============================================================================

-- Function to get user's storage usage
CREATE OR REPLACE FUNCTION public.get_user_storage_usage(user_uuid UUID)
RETURNS TABLE (
    bucket_name TEXT,
    file_count BIGINT,
    total_size_bytes BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        bucket_id AS bucket_name,
        COUNT(*) AS file_count,
        SUM(metadata->>'size')::BIGINT AS total_size_bytes
    FROM storage.objects
    WHERE (storage.foldername(name))[1] = user_uuid::text
    GROUP BY bucket_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- END OF STORAGE SETUP
-- ============================================================================
