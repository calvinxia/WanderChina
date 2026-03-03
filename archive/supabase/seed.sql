-- ============================================================================
-- WanderChina Seed Data
-- Version: 1.0.0
-- Created: 2025-10-23
-- Purpose: Initial data for development and testing
-- ============================================================================

-- ============================================================================
-- SEED ACHIEVEMENTS
-- ============================================================================

INSERT INTO public.achievements (id, name, description, category, criteria, rarity, badge_image, points_reward, is_hidden) VALUES
    (uuid_generate_v4(), 'First Steps', 'Visit your first place in China', 'explorer', '{"type": "visit_places", "count": 1}', 'common', '/badges/first-steps.png', 50, false),
    (uuid_generate_v4(), 'City Explorer', 'Visit 5 places in one city', 'explorer', '{"type": "visit_places", "count": 5, "same_city": true}', 'common', '/badges/city-explorer.png', 100, false),
    (uuid_generate_v4(), 'Foodie Beginner', 'Try your first Chinese dish', 'foodie', '{"type": "try_dishes", "count": 1}', 'common', '/badges/foodie-beginner.png', 50, false),
    (uuid_generate_v4(), 'Foodie Master', 'Try 20 different Chinese dishes', 'foodie', '{"type": "try_dishes", "count": 20}', 'rare', '/badges/foodie-master.png', 300, false),
    (uuid_generate_v4(), 'Temple Seeker', 'Visit 10 temples or religious sites', 'explorer', '{"type": "visit_category", "category": "temple", "count": 10}', 'rare', '/badges/temple-seeker.png', 200, false),
    (uuid_generate_v4(), 'Social Butterfly', 'Help 10 other travelers', 'social', '{"type": "help_travelers", "count": 10}', 'rare', '/badges/social-butterfly.png', 200, false),
    (uuid_generate_v4(), 'Budget Master', 'Stay under budget for 30 days', 'budget', '{"type": "budget_streak", "days": 30}', 'epic', '/badges/budget-master.png', 500, false),
    (uuid_generate_v4(), 'Great Wall Walker', 'Visit the Great Wall of China', 'explorer', '{"type": "visit_landmark", "landmark": "Great Wall"}', 'common', '/badges/great-wall.png', 150, false),
    (uuid_generate_v4(), 'Province Hopper', 'Visit 5 different provinces', 'explorer', '{"type": "visit_provinces", "count": 5}', 'rare', '/badges/province-hopper.png', 250, false),
    (uuid_generate_v4(), 'China Master', 'Visit all 34 provinces', 'explorer', '{"type": "visit_provinces", "count": 34}', 'legendary', '/badges/china-master.png', 5000, false),
    (uuid_generate_v4(), 'Early Bird', 'Start a trip before 6 AM', 'lifestyle', '{"type": "early_start", "hour": 6}', 'common', '/badges/early-bird.png', 75, false),
    (uuid_generate_v4(), 'Night Owl', 'Visit a place after 10 PM', 'lifestyle', '{"type": "late_visit", "hour": 22}', 'common', '/badges/night-owl.png', 75, false),
    (uuid_generate_v4(), 'Photo Enthusiast', 'Upload 50 photos', 'social', '{"type": "upload_photos", "count": 50}', 'rare', '/badges/photographer.png', 200, false),
    (uuid_generate_v4(), 'Community Helper', 'Receive 100 helpful votes on reviews', 'social', '{"type": "helpful_votes", "count": 100}', 'epic', '/badges/community-helper.png', 400, false),
    (uuid_generate_v4(), 'Hidden Gem Finder', 'Discover a place with less than 10 reviews', 'explorer', '{"type": "discover_hidden", "max_reviews": 10}', 'rare', '/badges/hidden-gem.png', 150, true);

-- ============================================================================
-- SEED CHALLENGES
-- ============================================================================

INSERT INTO public.challenges (id, title, description, city, category, difficulty, checkpoints, total_points, estimated_time_hours, badge_image, is_seasonal, season) VALUES
    (
        uuid_generate_v4(),
        'Beijing Heritage Challenge',
        'Explore the historical treasures of Beijing, from ancient palaces to sacred temples',
        'Beijing',
        'heritage',
        'intermediate',
        '[
            {"order": 1, "place_name": "Forbidden City", "lat": 39.9163, "lng": 116.3972, "points": 100},
            {"order": 2, "place_name": "Temple of Heaven", "lat": 39.8829, "lng": 116.4073, "points": 100},
            {"order": 3, "place_name": "Summer Palace", "lat": 39.9995, "lng": 116.2753, "points": 100},
            {"order": 4, "place_name": "Lama Temple", "lat": 39.9476, "lng": 116.4195, "points": 100},
            {"order": 5, "place_name": "Great Wall (Mutianyu)", "lat": 40.4319, "lng": 116.5704, "points": 100}
        ]'::jsonb,
        500,
        10,
        '/badges/beijing-heritage.png',
        false,
        NULL
    ),
    (
        uuid_generate_v4(),
        'Chengdu Food Quest',
        'Sample the spicy delights of authentic Sichuan cuisine',
        'Chengdu',
        'food',
        'beginner',
        '[
            {"order": 1, "place_name": "Traditional Hotpot", "description": "Try authentic Sichuan hotpot", "points": 50},
            {"order": 2, "place_name": "Dan Dan Noodles", "description": "Taste this classic street food", "points": 50},
            {"order": 3, "place_name": "Mapo Tofu", "description": "Experience the famous spicy tofu dish", "points": 50},
            {"order": 4, "place_name": "Kung Pao Chicken", "description": "Try the original recipe", "points": 50}
        ]'::jsonb,
        200,
        4,
        '/badges/chengdu-food.png',
        false,
        NULL
    ),
    (
        uuid_generate_v4(),
        'Shanghai Skyline Quest',
        'Discover the modern marvels and historic landmarks of Shanghai',
        'Shanghai',
        'modern',
        'beginner',
        '[
            {"order": 1, "place_name": "The Bund", "lat": 31.2416, "lng": 121.4900, "points": 75},
            {"order": 2, "place_name": "Oriental Pearl Tower", "lat": 31.2398, "lng": 121.4995, "points": 75},
            {"order": 3, "place_name": "Yu Garden", "lat": 31.2276, "lng": 121.4917, "points": 75},
            {"order": 4, "place_name": "Nanjing Road", "lat": 31.2345, "lng": 121.4759, "points": 75}
        ]'::jsonb,
        300,
        6,
        '/badges/shanghai-skyline.png',
        false,
        NULL
    ),
    (
        uuid_generate_v4(),
        'Xi''an Ancient Wonders',
        'Journey through the ancient capital and discover its treasures',
        'Xi''an',
        'heritage',
        'intermediate',
        '[
            {"order": 1, "place_name": "Terracotta Army", "lat": 34.3848, "lng": 109.2787, "points": 150},
            {"order": 2, "place_name": "Ancient City Wall", "lat": 34.2659, "lng": 108.9541, "points": 100},
            {"order": 3, "place_name": "Big Wild Goose Pagoda", "lat": 34.2194, "lng": 108.9642, "points": 100},
            {"order": 4, "place_name": "Muslim Quarter", "lat": 34.2658, "lng": 108.9398, "points": 50}
        ]'::jsonb,
        400,
        8,
        '/badges/xian-ancient.png',
        false,
        NULL
    ),
    (
        uuid_generate_v4(),
        'Guilin Nature Explorer',
        'Experience the breathtaking karst landscapes and rivers',
        'Guilin',
        'nature',
        'advanced',
        '[
            {"order": 1, "place_name": "Li River Cruise", "description": "Take the scenic cruise", "points": 100},
            {"order": 2, "place_name": "Reed Flute Cave", "lat": 25.3090, "lng": 110.2660, "points": 75},
            {"order": 3, "place_name": "Elephant Trunk Hill", "lat": 25.2711, "lng": 110.2829, "points": 75},
            {"order": 4, "place_name": "Longji Rice Terraces", "lat": 25.9267, "lng": 110.1481, "points": 150}
        ]'::jsonb,
        400,
        12,
        '/badges/guilin-nature.png',
        false,
        NULL
    ),
    (
        uuid_generate_v4(),
        'Spring Blossom Tour',
        'See the beautiful cherry blossoms across Beijing parks',
        'Beijing',
        'nature',
        'beginner',
        '[
            {"order": 1, "place_name": "Yuyuantan Park", "description": "Cherry blossom viewing", "points": 100},
            {"order": 2, "place_name": "Jingshan Park", "description": "Peach blossom festival", "points": 100},
            {"order": 3, "place_name": "Beijing Botanical Garden", "description": "Various spring flowers", "points": 100}
        ]'::jsonb,
        300,
        5,
        '/badges/spring-blossoms.png',
        true,
        'spring'
    );

-- ============================================================================
-- SEED SAMPLE PLACES (Major Tourist Attractions)
-- ============================================================================

INSERT INTO public.places (id, name, name_chinese, category, subcategory, description, address, city, province, location, rating, review_count, price_level, tags, opening_hours) VALUES
    (
        uuid_generate_v4(),
        'Forbidden City',
        '紫禁城',
        'attraction',
        'historical_site',
        'The Forbidden City is a large palace complex in central Beijing that served as the imperial palace for 24 emperors during the Ming and Qing dynasties.',
        '4 Jingshan Front St, Dongcheng District',
        'Beijing',
        'Beijing',
        ST_SetSRID(ST_MakePoint(116.3972, 39.9163), 4326)::geography,
        4.7,
        15234,
        2,
        '["UNESCO World Heritage", "Palace", "Museum", "Historical"]'::jsonb,
        '{"monday": "08:30-17:00", "tuesday": "08:30-17:00", "wednesday": "08:30-17:00", "thursday": "08:30-17:00", "friday": "08:30-17:00", "saturday": "08:30-17:00", "sunday": "08:30-17:00", "closed": "Monday in low season"}'::jsonb
    ),
    (
        uuid_generate_v4(),
        'The Great Wall at Mutianyu',
        '慕田峪长城',
        'attraction',
        'historical_site',
        'One of the best-preserved sections of the Great Wall, offering stunning views and fewer crowds than Badaling.',
        'Mutianyu Village, Huairou District',
        'Beijing',
        'Beijing',
        ST_SetSRID(ST_MakePoint(116.5704, 40.4319), 4326)::geography,
        4.8,
        8932,
        2,
        '["Great Wall", "UNESCO World Heritage", "Hiking", "Photography"]'::jsonb,
        '{"everyday": "07:30-18:00"}'::jsonb
    ),
    (
        uuid_generate_v4(),
        'Temple of Heaven',
        '天坛',
        'attraction',
        'temple',
        'An imperial complex of religious buildings where emperors of the Ming and Qing dynasties would pray for good harvests.',
        'Tiantan Road, Dongcheng District',
        'Beijing',
        'Beijing',
        ST_SetSRID(ST_MakePoint(116.4073, 39.8829), 4326)::geography,
        4.6,
        11245,
        1,
        '["Temple", "UNESCO World Heritage", "Park", "Historical"]'::jsonb,
        '{"everyday": "06:00-22:00"}'::jsonb
    ),
    (
        uuid_generate_v4(),
        'The Bund',
        '外滩',
        'attraction',
        'landmark',
        'Famous waterfront area in central Shanghai with colonial-era buildings and stunning views of the Pudong skyline.',
        'Zhongshan East 1st Road, Huangpu District',
        'Shanghai',
        'Shanghai',
        ST_SetSRID(ST_MakePoint(121.4900, 31.2416), 4326)::geography,
        4.7,
        22341,
        1,
        '["Waterfront", "Architecture", "Photography", "Night View"]'::jsonb,
        '{"everyday": "00:00-24:00"}'::jsonb
    ),
    (
        uuid_generate_v4(),
        'Terracotta Army',
        '兵马俑',
        'attraction',
        'museum',
        'Collection of terracotta sculptures depicting the armies of Qin Shi Huang, the first Emperor of China.',
        'Lintong District',
        'Xi''an',
        'Shaanxi',
        ST_SetSRID(ST_MakePoint(109.2787, 34.3848), 4326)::geography,
        4.9,
        19876,
        3,
        '["UNESCO World Heritage", "Museum", "Archaeological Site", "Historical"]'::jsonb,
        '{"everyday": "08:30-18:00"}'::jsonb
    ),
    (
        uuid_generate_v4(),
        'Chengdu Research Base of Giant Panda Breeding',
        '成都大熊猫繁育研究基地',
        'attraction',
        'zoo',
        'World-famous conservation center where you can see giant pandas in a naturalistic habitat.',
        'Chenghua District',
        'Chengdu',
        'Sichuan',
        ST_SetSRID(ST_MakePoint(104.1480, 30.7326), 4326)::geography,
        4.8,
        16543,
        2,
        '["Pandas", "Wildlife", "Conservation", "Family-Friendly"]'::jsonb,
        '{"everyday": "07:30-18:00"}'::jsonb
    ),
    (
        uuid_generate_v4(),
        'West Lake',
        '西湖',
        'attraction',
        'natural_site',
        'Famous freshwater lake in Hangzhou, renowned for its scenic beauty and cultural significance.',
        'West Lake Scenic Area',
        'Hangzhou',
        'Zhejiang',
        ST_SetSRID(ST_MakePoint(120.1485, 30.2559), 4326)::geography,
        4.7,
        14256,
        1,
        '["UNESCO World Heritage", "Lake", "Scenic", "Photography"]'::jsonb,
        '{"everyday": "00:00-24:00"}'::jsonb
    ),
    (
        uuid_generate_v4(),
        'Yu Garden',
        '豫园',
        'attraction',
        'garden',
        'Extensive Chinese garden located beside the City God Temple in the northeast of the Old City of Shanghai.',
        '218 Anren Street, Huangpu District',
        'Shanghai',
        'Shanghai',
        ST_SetSRID(ST_MakePoint(121.4917, 31.2276), 4326)::geography,
        4.5,
        9876,
        2,
        '["Garden", "Historical", "Architecture", "Cultural"]'::jsonb,
        '{"everyday": "08:45-17:15"}'::jsonb
    );

-- Sample restaurants
INSERT INTO public.places (id, name, name_chinese, category, subcategory, description, address, city, province, location, rating, price_level, tags) VALUES
    (
        uuid_generate_v4(),
        'Din Tai Fung',
        '鼎泰丰',
        'restaurant',
        'chinese',
        'World-renowned restaurant chain famous for its xiaolongbao (soup dumplings).',
        'Multiple locations',
        'Shanghai',
        'Shanghai',
        ST_SetSRID(ST_MakePoint(121.4737, 31.2304), 4326)::geography,
        4.6,
        3,
        '["Dumplings", "Taiwanese", "Fine Dining"]'::jsonb
    ),
    (
        uuid_generate_v4(),
        'Haidilao Hot Pot',
        '海底捞',
        'restaurant',
        'hotpot',
        'Popular hot pot chain known for excellent service and quality ingredients.',
        'Multiple locations',
        'Beijing',
        'Beijing',
        ST_SetSRID(ST_MakePoint(116.4074, 39.9042), 4326)::geography,
        4.5,
        2,
        '["Hot Pot", "Sichuan", "Chain Restaurant"]'::jsonb
    );

-- ============================================================================
-- SEED OFFLINE MAPS
-- ============================================================================

INSERT INTO public.offline_maps (id, city_id, city_name, version, size_mb, bounds, tile_count) VALUES
    (
        uuid_generate_v4(),
        'beijing',
        'Beijing',
        '2025.10',
        245,
        '{"min_lat": 39.4428, "max_lat": 41.0608, "min_lng": 115.4167, "max_lng": 117.5145}'::jsonb,
        12500
    ),
    (
        uuid_generate_v4(),
        'shanghai',
        'Shanghai',
        '2025.10',
        198,
        '{"min_lat": 30.6828, "max_lat": 31.8728, "min_lng": 120.8520, "max_lng": 122.1200}'::jsonb,
        10200
    ),
    (
        uuid_generate_v4(),
        'guangzhou',
        'Guangzhou',
        '2025.10',
        167,
        '{"min_lat": 22.6260, "max_lat": 23.5602, "min_lng": 112.9253, "max_lng": 114.0253}'::jsonb,
        8900
    ),
    (
        uuid_generate_v4(),
        'chengdu',
        'Chengdu',
        '2025.10',
        143,
        '{"min_lat": 30.0520, "max_lat": 31.4129, "min_lng": 102.9549, "max_lng": 104.9219}'::jsonb,
        7600
    ),
    (
        uuid_generate_v4(),
        'xian',
        'Xi''an',
        '2025.10',
        134,
        '{"min_lat": 33.7094, "max_lat": 34.7453, "min_lng": 107.7400, "max_lng": 109.6312}'::jsonb,
        7100
    ),
    (
        uuid_generate_v4(),
        'hangzhou',
        'Hangzhou',
        '2025.10',
        156,
        '{"min_lat": 29.1986, "max_lat": 30.5786, "min_lng": 118.8740, "max_lng": 120.5700}'::jsonb,
        8300
    );

-- ============================================================================
-- END OF SEED DATA
-- ============================================================================

-- ============================================================================
-- HELPFUL QUERIES FOR TESTING
-- ============================================================================

-- Get all challenges for a city
-- SELECT * FROM public.challenges WHERE city = 'Beijing' AND is_active = true;

-- Get all achievements by rarity
-- SELECT * FROM public.achievements WHERE rarity = 'legendary' ORDER BY points_reward DESC;

-- Find nearby places (example: within 5km of Forbidden City)
-- SELECT * FROM public.get_nearby_places(39.9163, 116.3972, 5000, 20);

-- Get user profile summary
-- SELECT * FROM public.user_profile_summary WHERE id = 'user-uuid-here';

-- Get popular places with most saves
-- SELECT * FROM public.popular_places ORDER BY saves_count DESC LIMIT 10;

-- ============================================================================
