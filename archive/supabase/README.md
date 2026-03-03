# WanderChina Supabase Database

**Version:** 1.0.0
**Platform:** Supabase (PostgreSQL 15+ with PostGIS)
**Created:** 2025-10-23

---

## 📚 Overview

This directory contains the complete Supabase database setup for WanderChina, including:

- **Schema migrations** - Complete database structure
- **Row Level Security (RLS) policies** - Fine-grained access control
- **Storage buckets** - File upload configuration
- **Seed data** - Initial data for testing and development

---

## 📁 File Structure

```
supabase/
├── config.toml                          # Supabase project configuration
├── migrations/
│   ├── 001_initial_schema.sql          # Core database schema (37 tables)
│   ├── 002_row_level_security.sql      # RLS policies for all tables
│   └── 003_storage_setup.sql           # Storage buckets and policies
├── seed.sql                             # Initial seed data
└── README.md                            # This file
```

---

## 🚀 Quick Start

### 1. Install Supabase CLI

```bash
# macOS
brew install supabase/tap/supabase

# Windows (with Scoop)
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase

# Linux
brew install supabase/tap/supabase
```

### 2. Initialize Local Development

```bash
# Navigate to project root
cd /path/to/WanderChina

# Start Supabase local development
supabase start

# This will start:
# - PostgreSQL database
# - Studio UI (http://localhost:54323)
# - API server (http://localhost:54321)
# - Auth server
# - Storage server
```

### 3. Apply Migrations

```bash
# Run all migrations
supabase db reset

# Or run migrations manually
psql -U postgres -d wanderchina -f supabase/migrations/001_initial_schema.sql
psql -U postgres -d wanderchina -f supabase/migrations/002_row_level_security.sql
psql -U postgres -d wanderchina -f supabase/migrations/003_storage_setup.sql
```

### 4. Load Seed Data

```bash
# Load initial data for testing
psql -U postgres -d wanderchina -f supabase/seed.sql
```

---

## 🗄️ Database Schema

### Table Count: **37 tables**

#### User Management (3 tables)
- `users` - User profiles (extends auth.users)
- `user_settings` - User preferences
- `refresh_tokens` - JWT refresh tokens (handled by Supabase Auth)

#### Travel & Trips (2 tables)
- `trips` - User travel itineraries
- `itineraries` - Day-by-day trip plans

#### Places & Discovery (3 tables)
- `places` - Attractions, restaurants, hotels (with PostGIS)
- `place_reviews` - User reviews for places
- `saved_places` - User bookmarks

#### Budget & Expenses (1 table)
- `expenses` - Financial tracking

#### Gamification (5 tables)
- `challenges` - Predefined city challenges
- `user_challenges` - User progress tracking
- `achievements` - Achievement definitions
- `user_achievements` - Unlocked achievements
- `points_history` - Points ledger

#### Community & Social (6 tables)
- `posts` - Community feed posts
- `comments` - Post comments (nested)
- `post_likes` - Like tracking
- `comment_likes` - Comment likes
- `saved_posts` - Bookmarked posts
- `follows` - User follow relationships

#### Social Matching (4 tables)
- `companion_profiles` - Travel companion profiles
- `companion_matches` - Matched travelers
- `local_guides` - Local guide profiles
- `guide_bookings` - Guide reservations

#### Safety & Emergency (5 tables)
- `emergency_contacts` - Emergency contact list
- `emergency_alerts` - SOS alerts
- `location_shares` - Live location sharing
- `location_updates` - GPS breadcrumbs
- `safety_reports` - Community safety reports

#### System & Utilities (4 tables)
- `notifications` - In-app notifications
- `translations_cache` - Translation caching
- `offline_maps` - Available offline maps
- `user_downloaded_maps` - User's downloaded maps

#### Booking & Payments (4 tables)
- `bookings` - Hotel/activity bookings
- `subscriptions` - Premium subscriptions
- `payments` - Payment history
- `analytics_events` - User behavior tracking (partitioned)

---

## 🔒 Row Level Security (RLS)

All tables have RLS **enabled** with policies for:

- ✅ **Users** - Can view/edit own profile
- ✅ **Trips** - Private by default, public if shared
- ✅ **Posts** - Public viewing, own editing
- ✅ **Expenses** - Private, user-only access
- ✅ **Emergency data** - Strict user-only access
- ✅ **Notifications** - User-only access
- ✅ **Bookings** - User-only access

### Example RLS Policies

```sql
-- Users can only view their own expenses
CREATE POLICY "Users can manage own expenses"
    ON public.expenses FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can view public trips or their own
CREATE POLICY "Users can view public trips"
    ON public.trips FOR SELECT
    USING (is_public = true OR auth.uid() = user_id);
```

---

## 📦 Storage Buckets

### Configured Buckets

| Bucket Name | Public | Max Size | Purpose |
|------------|--------|----------|---------|
| `avatars` | ✅ Yes | 5MB | User profile pictures |
| `post-images` | ✅ Yes | 10MB | Community post photos |
| `place-photos` | ✅ Yes | 10MB | Place review photos |
| `receipts` | ❌ No | 5MB | Private expense receipts |
| `badges` | ✅ Yes | 2MB | Achievement badges |
| `map-tiles` | ✅ Yes | Unlimited | Offline map packages |

### Storage Policies

- **Avatars**: Users can upload/update/delete their own avatar only
- **Post Images**: Users can upload/delete their own post images
- **Receipts**: Private access, user-only
- **Badges/Maps**: Admin upload only (service role)

---

## 🔗 Connecting to Supabase

### Environment Variables

```bash
# .env.local
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

### Client Initialization (JavaScript/TypeScript)

```typescript
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY

export const supabase = createClient(supabaseUrl, supabaseAnonKey)
```

### Flutter Client

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

await Supabase.initialize(
  url: 'https://your-project.supabase.co',
  anonKey: 'your-anon-key',
);

final supabase = Supabase.instance.client;
```

---

## 📊 Key Features

### 1. PostGIS Geospatial Queries

```sql
-- Find nearby places (within 5km)
SELECT * FROM public.get_nearby_places(39.9163, 116.3972, 5000, 20);

-- Custom distance calculation
SELECT
    name,
    ST_Distance(
        location,
        ST_SetSRID(ST_MakePoint(116.3972, 39.9163), 4326)::geography
    ) / 1000 as distance_km
FROM public.places
WHERE ST_DWithin(
    location,
    ST_SetSRID(ST_MakePoint(116.3972, 39.9163), 4326)::geography,
    5000
)
ORDER BY distance_km;
```

### 2. Real-time Subscriptions

```typescript
// Subscribe to new posts
const subscription = supabase
  .channel('public:posts')
  .on('postgres_changes',
    { event: 'INSERT', schema: 'public', table: 'posts' },
    (payload) => {
      console.log('New post!', payload.new)
    }
  )
  .subscribe()
```

### 3. Automatic Denormalized Counts

Triggers automatically update:
- `posts.likes_count` when likes added/removed
- `posts.comments_count` when comments added/removed
- `users.total_points` tracked in `points_history`

### 4. Partitioned Analytics

The `analytics_events` table is partitioned by month for performance:

```sql
-- Automatically routes to correct partition
INSERT INTO public.analytics_events (user_id, event_type, event_data)
VALUES ('user-uuid', 'page_view', '{"page": "/home"}');
```

---

## 🧪 Testing Queries

```sql
-- Get all active challenges for Beijing
SELECT * FROM public.challenges
WHERE city = 'Beijing' AND is_active = true;

-- Get user's achievement progress
SELECT
    a.name,
    a.description,
    a.points_reward,
    ua.unlocked_at
FROM public.achievements a
LEFT JOIN public.user_achievements ua ON ua.achievement_id = a.id
WHERE ua.user_id = 'user-uuid-here'
ORDER BY ua.unlocked_at DESC;

-- Get popular places by saves
SELECT
    name,
    city,
    rating,
    saves_count
FROM public.popular_places
ORDER BY saves_count DESC
LIMIT 20;

-- Get user profile summary
SELECT * FROM public.user_profile_summary
WHERE id = 'user-uuid-here';
```

---

## 🔄 Migration Management

### Create New Migration

```bash
# Create a new migration file
supabase migration new your_migration_name

# This creates: supabase/migrations/YYYYMMDDHHMMSS_your_migration_name.sql
```

### Run Migrations

```bash
# Run all pending migrations
supabase db push

# Reset database (drops and recreates)
supabase db reset
```

### Pull Remote Changes

```bash
# Pull schema changes from remote Supabase project
supabase db pull
```

---

## 🚨 Important Notes

### Authentication

- Users table `public.users` references `auth.users(id)`
- User signup automatically creates entry in `auth.users`
- You need to create `public.users` entry via trigger or manually
- Example trigger:

```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name)
  VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'full_name');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

### Service Role vs Anon Key

- **Anon Key**: Public client-side use, RLS enforced
- **Service Role Key**: Backend only, bypasses RLS
- Never expose service role key to client

### PostGIS Performance

- Always use `GIST` indexes for geography columns
- Use `ST_DWithin` for distance queries (faster than `ST_Distance`)
- Store locations as `GEOGRAPHY(POINT, 4326)` for accurate distance

---

## 📈 Performance Optimization

### Indexes Created

- **80+ indexes** covering common queries
- Geospatial GIST indexes on all location columns
- GIN indexes for JSONB columns (tags, metadata)
- Composite indexes for frequent joins

### Partitioning

- `analytics_events` partitioned by month
- Add new partitions monthly:

```sql
CREATE TABLE public.analytics_events_2026_01 PARTITION OF public.analytics_events
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
```

---

## 🛠️ Development Workflow

### Local Development

1. Start Supabase: `supabase start`
2. Access Studio UI: http://localhost:54323
3. Make schema changes in SQL files
4. Test changes locally
5. Create migration: `supabase migration new feature_name`
6. Push to remote: `supabase db push`

### Production Deployment

1. Link project: `supabase link --project-ref your-project-ref`
2. Push migrations: `supabase db push`
3. Verify in Supabase Dashboard
4. Run seed data if needed (be careful in production!)

---

## 🔗 Useful Links

- **Supabase Docs**: https://supabase.com/docs
- **PostGIS Docs**: https://postgis.net/docs/
- **SQL Reference**: https://www.postgresql.org/docs/15/
- **Supabase CLI**: https://github.com/supabase/cli

---

## 📞 Support

For questions or issues:
1. Check Supabase Dashboard logs
2. Review RLS policies if permission errors
3. Verify indexes for slow queries
4. Check storage policies for upload issues

---

**Last Updated:** 2025-10-23
**Database Version:** PostgreSQL 15+
**PostGIS Version:** 3.3+
**Status:** 🟢 Ready for Development
