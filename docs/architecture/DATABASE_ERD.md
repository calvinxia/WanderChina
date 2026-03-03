# WanderChina - Database Entity Relationship Diagram (ERD)

**Version:** 1.0
**Database:** PostgreSQL 14+
**Last Updated:** 2025-10-22

---

## Table of Contents
1. [ER Diagram](#er-diagram)
2. [Table Descriptions](#table-descriptions)
3. [Relationships](#relationships)
4. [Indexes](#indexes)
5. [Constraints](#constraints)

---

## ER Diagram

### Complete Database Schema

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          WANDERCHINA DATABASE SCHEMA                         │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────┐
│      USERS           │
├──────────────────────┤
│ PK id (UUID)         │
│    email (UNIQUE)    │
│    password_hash     │
│    username (UNIQUE) │
│    full_name         │
│    profile_picture   │
│    bio               │
│    nationality       │
│    languages (JSONB) │
│    travel_style      │
│    interests (JSONB) │
│    email_verified    │
│    phone             │
│    phone_verified    │
│    premium_until     │
│    total_points      │
│    membership_tier   │
│    created_at        │
│    updated_at        │
│    last_login        │
│    is_active         │
└──────────────────────┘
         │
         │ 1:N
         │
         ├─────────────────────────────────────────────────────────┐
         │                                                         │
         ▼                                                         │
┌──────────────────────┐                                         │
│    REFRESH_TOKENS    │                                         │
├──────────────────────┤                                         │
│ PK id (UUID)         │                                         │
│ FK user_id           │                                         │
│    token_hash        │                                         │
│    expires_at        │                                         │
│    created_at        │                                         │
│    revoked           │                                         │
└──────────────────────┘                                         │
                                                                 │
         ┌───────────────────────────────────────────────────────┤
         │                                                       │
         │                                                       │
         ▼                                                       ▼
┌──────────────────────┐                              ┌──────────────────────┐
│       TRIPS          │                              │   USER_SETTINGS      │
├──────────────────────┤                              ├──────────────────────┤
│ PK id (UUID)         │                              │ PK id (UUID)         │
│ FK user_id           │                              │ FK user_id (UNIQUE)  │
│    title             │                              │    language          │
│    description       │                              │    currency          │
│    start_date        │                              │    distance_unit     │
│    end_date          │                              │    temperature_unit  │
│    budget            │                              │    notifications     │
│    total_spent       │                              │    created_at        │
│    status            │                              │    updated_at        │
│    cities (JSONB)    │                              └──────────────────────┘
│    is_public         │
│    created_at        │
│    updated_at        │
└──────────────────────┘
         │
         │ 1:N
         ├──────────────────────────────────────┐
         │                                      │
         ▼                                      ▼
┌──────────────────────┐            ┌──────────────────────┐
│    ITINERARIES       │            │      EXPENSES        │
├──────────────────────┤            ├──────────────────────┤
│ PK id (UUID)         │            │ PK id (UUID)         │
│ FK trip_id           │            │ FK user_id           │
│    day_number        │            │ FK trip_id           │
│    date              │            │ FK place_id          │
│    activities (JSONB)│            │    category          │
│    total_budget      │            │    amount            │
│    actual_spent      │            │    currency          │
│    created_at        │            │    description       │
│    updated_at        │            │    receipt_photo     │
└──────────────────────┘            │    expense_date      │
                                    │    created_at        │
                                    └──────────────────────┘


┌──────────────────────┐
│       PLACES         │
├──────────────────────┤
│ PK id (UUID)         │
│    name              │
│    name_chinese      │
│    category          │
│    subcategory       │
│    description       │
│    address           │
│    city              │
│    province          │
│    country           │
│    location (GEOG)   │◄──────┐
│    photos (JSONB)    │       │
│    rating            │       │
│    price_level       │       │
│    opening_hours     │       │
│    tags (JSONB)      │       │
│    external_ids      │       │
│    created_at        │       │
│    updated_at        │       │
└──────────────────────┘       │
         │                      │
         │ 1:N                  │
         │                      │
         ▼                      │
┌──────────────────────┐       │
│   PLACE_REVIEWS      │       │
├──────────────────────┤       │
│ PK id (UUID)         │       │
│ FK place_id          │       │
│ FK user_id           │       │
│    rating            │       │
│    comment           │       │
│    photos (JSONB)    │       │
│    helpful_count     │       │
│    created_at        │       │
│    updated_at        │       │
└──────────────────────┘       │
                                │
                                │
┌──────────────────────┐       │
│    SAVED_PLACES      │       │
├──────────────────────┤       │
│ PK id (UUID)         │       │
│ FK user_id           │       │
│ FK place_id          │───────┘
│    notes             │
│    created_at        │
└──────────────────────┘


┌──────────────────────┐
│     CHALLENGES       │
├──────────────────────┤
│ PK id (UUID)         │
│    title             │
│    description       │
│    city              │
│    category          │
│    difficulty        │
│    checkpoints(JSONB)│◄────────┐
│    total_points      │         │
│    estimated_time    │         │
│    is_seasonal       │         │
│    season            │         │
│    badge_image       │         │
│    is_active         │         │
│    created_at        │         │
│    updated_at        │         │
└──────────────────────┘         │
         │                        │
         │ 1:N                    │
         │                        │
         ▼                        │
┌──────────────────────┐         │
│  USER_CHALLENGES     │         │
├──────────────────────┤         │
│ PK id (UUID)         │         │
│ FK user_id           │         │
│ FK challenge_id      │         │
│    status            │         │
│    progress (JSONB)  │─────────┘
│    completion_%      │
│    started_at        │
│    completed_at      │
│    points_earned     │
└──────────────────────┘


┌──────────────────────┐
│    ACHIEVEMENTS      │
├──────────────────────┤
│ PK id (UUID)         │
│    name              │
│    description       │
│    category          │
│    criteria (JSONB)  │
│    rarity            │
│    badge_image       │
│    points_reward     │
│    is_hidden         │
│    created_at        │
└──────────────────────┘
         │
         │ 1:N
         │
         ▼
┌──────────────────────┐
│ USER_ACHIEVEMENTS    │
├──────────────────────┤
│ PK id (UUID)         │
│ FK user_id           │
│ FK achievement_id    │
│    unlocked_at       │
└──────────────────────┘


┌──────────────────────┐
│        POSTS         │
├──────────────────────┤
│ PK id (UUID)         │
│ FK user_id           │
│ FK location_id       │
│ FK trip_id           │
│    content           │
│    images (JSONB)    │
│    tags (JSONB)      │
│    post_type         │
│    likes_count       │
│    comments_count    │
│    is_pinned         │
│    created_at        │
│    updated_at        │
└──────────────────────┘
         │
         │ 1:N
         ├────────────────────────────────┐
         │                                │
         ▼                                ▼
┌──────────────────────┐      ┌──────────────────────┐
│     POST_LIKES       │      │      COMMENTS        │
├──────────────────────┤      ├──────────────────────┤
│ PK id (UUID)         │      │ PK id (UUID)         │
│ FK user_id           │      │ FK post_id           │
│ FK post_id           │      │ FK user_id           │
│    created_at        │      │ FK parent_comment_id │
└──────────────────────┘      │    content           │
                               │    likes_count       │
┌──────────────────────┐      │    created_at        │
│   SAVED_POSTS        │      │    updated_at        │
├──────────────────────┤      └──────────────────────┘
│ PK id (UUID)         │                │
│ FK user_id           │                │
│ FK post_id           │                │ 1:N
│    created_at        │                │
└──────────────────────┘                ▼
                               ┌──────────────────────┐
                               │   COMMENT_LIKES      │
                               ├──────────────────────┤
                               │ PK id (UUID)         │
                               │ FK user_id           │
                               │ FK comment_id        │
                               │    created_at        │
                               └──────────────────────┘


┌──────────────────────┐
│   COMPANION_PROFILES │
├──────────────────────┤
│ PK id (UUID)         │
│ FK user_id (UNIQUE)  │
│    is_seeking        │
│    travel_dates      │
│    preferred_age     │
│    preferred_gender  │
│    budget_level      │
│    interests (JSONB) │
│    languages (JSONB) │
│    bio               │
│    verification_stat │
│    trust_score       │
│    created_at        │
│    updated_at        │
└──────────────────────┘
         │
         │ N:N
         │
         ▼
┌──────────────────────┐
│  COMPANION_MATCHES   │
├──────────────────────┤
│ PK id (UUID)         │
│ FK user1_id          │
│ FK user2_id          │
│    match_score       │
│    status            │
│    matched_at        │
│    accepted_at       │
└──────────────────────┘


┌──────────────────────┐
│    LOCAL_GUIDES      │
├──────────────────────┤
│ PK id (UUID)         │
│ FK user_id (UNIQUE)  │
│    city              │
│    specializations   │
│    hourly_rate       │
│    is_free           │
│    languages (JSONB) │
│    bio               │
│    verification_stat │
│    rating            │
│    total_bookings    │
│    availability      │
│    created_at        │
│    updated_at        │
└──────────────────────┘
         │
         │ 1:N
         │
         ▼
┌──────────────────────┐
│   GUIDE_BOOKINGS     │
├──────────────────────┤
│ PK id (UUID)         │
│ FK guide_id          │
│ FK user_id           │
│    booking_date      │
│    start_time        │
│    duration_hours    │
│    total_cost        │
│    status            │
│    rating            │
│    review            │
│    created_at        │
│    updated_at        │
└──────────────────────┘


┌──────────────────────┐
│   FOLLOWS            │
├──────────────────────┤
│ PK id (UUID)         │
│ FK follower_id       │
│ FK following_id      │
│    created_at        │
└──────────────────────┘


┌──────────────────────┐
│ EMERGENCY_CONTACTS   │
├──────────────────────┤
│ PK id (UUID)         │
│ FK user_id           │
│    name              │
│    phone             │
│    relationship      │
│    notification_type │
│    priority          │
│    created_at        │
│    updated_at        │
└──────────────────────┘


┌──────────────────────┐
│  EMERGENCY_ALERTS    │
├──────────────────────┤
│ PK id (UUID)         │
│ FK user_id           │
│    location (GEOG)   │
│    emergency_type    │
│    status            │
│    created_at        │
│    resolved_at       │
└──────────────────────┘


┌──────────────────────┐
│  LOCATION_SHARES     │
├──────────────────────┤
│ PK id (UUID)         │
│ FK user_id           │
│    share_code        │
│    recipients (JSONB)│
│    duration_hours    │
│    expires_at        │
│    is_active         │
│    created_at        │
└──────────────────────┘
         │
         │ 1:N
         │
         ▼
┌──────────────────────┐
│ LOCATION_UPDATES     │
├──────────────────────┤
│ PK id (UUID)         │
│ FK share_id          │
│    location (GEOG)   │
│    accuracy          │
│    battery_level     │
│    timestamp         │
└──────────────────────┘


┌──────────────────────┐
│   SAFETY_REPORTS     │
├──────────────────────┤
│ PK id (UUID)         │
│ FK user_id           │
│    location (GEOG)   │
│    incident_type     │
│    severity          │
│    description       │
│    status            │
│    verified          │
│    created_at        │
│    updated_at        │
└──────────────────────┘


┌──────────────────────┐
│  NOTIFICATIONS       │
├──────────────────────┤
│ PK id (UUID)         │
│ FK user_id           │
│    type              │
│    title             │
│    message           │
│    data (JSONB)      │
│    is_read           │
│    created_at        │
└──────────────────────┘


┌──────────────────────┐
│   TRANSLATIONS_CACHE │
├──────────────────────┤
│ PK id (UUID)         │
│    text_hash         │
│    source_lang       │
│    target_lang       │
│    translation       │
│    confidence        │
│    created_at        │
│    expires_at        │
└──────────────────────┘


┌──────────────────────┐
│  OFFLINE_MAPS        │
├──────────────────────┤
│ PK id (UUID)         │
│    city_id           │
│    city_name         │
│    version           │
│    size_mb           │
│    bounds (JSONB)    │
│    tile_count        │
│    created_at        │
│    updated_at        │
└──────────────────────┘
         │
         │ 1:N
         │
         ▼
┌──────────────────────┐
│ USER_DOWNLOADED_MAPS │
├──────────────────────┤
│ PK id (UUID)         │
│ FK user_id           │
│ FK map_id            │
│    downloaded_at     │
│    last_used         │
└──────────────────────┘


┌──────────────────────┐
│     BOOKINGS         │
├──────────────────────┤
│ PK id (UUID)         │
│ FK user_id           │
│ FK place_id          │
│    booking_type      │
│    check_in_date     │
│    check_out_date    │
│    guests_count      │
│    total_cost        │
│    currency          │
│    status            │
│    confirmation_code │
│    partner_name      │
│    created_at        │
│    updated_at        │
└──────────────────────┘


┌──────────────────────┐
│    POINTS_HISTORY    │
├──────────────────────┤
│ PK id (UUID)         │
│ FK user_id           │
│    points_change     │
│    reason            │
│    reference_id      │
│    reference_type    │
│    balance_after     │
│    created_at        │
└──────────────────────┘


┌──────────────────────┐
│   SUBSCRIPTIONS      │
├──────────────────────┤
│ PK id (UUID)         │
│ FK user_id           │
│    plan_type         │
│    status            │
│    started_at        │
│    expires_at        │
│    auto_renew        │
│    payment_method    │
│    created_at        │
│    updated_at        │
└──────────────────────┘
         │
         │ 1:N
         │
         ▼
┌──────────────────────┐
│      PAYMENTS        │
├──────────────────────┤
│ PK id (UUID)         │
│ FK subscription_id   │
│ FK user_id           │
│    amount            │
│    currency          │
│    payment_method    │
│    payment_provider  │
│    transaction_id    │
│    status            │
│    created_at        │
└──────────────────────┘


┌──────────────────────┐
│    ANALYTICS_EVENTS  │
├──────────────────────┤
│ PK id (UUID)         │
│ FK user_id           │
│    event_type        │
│    event_data (JSONB)│
│    platform          │
│    app_version       │
│    created_at        │
└──────────────────────┘
```

---

## Table Descriptions

### User Management

#### 1. users
Primary user accounts table.

**Key Fields:**
- `id`: Unique user identifier (UUID)
- `email`: User email (unique, for login)
- `password_hash`: bcrypt hashed password
- `premium_until`: Premium subscription expiry date
- `total_points`: Gamification points balance
- `membership_tier`: bronze, silver, gold, platinum

**Indexes:**
- `idx_users_email` (UNIQUE)
- `idx_users_username` (UNIQUE)
- `idx_users_created_at`

---

#### 2. refresh_tokens
JWT refresh tokens for authentication.

**Key Fields:**
- `token_hash`: SHA-256 hash of refresh token
- `expires_at`: Token expiry timestamp
- `revoked`: Token revocation flag

**Cascade:** DELETE user → DELETE tokens

---

#### 3. user_settings
User preferences and app settings.

**Key Fields:**
- `language`: App interface language
- `currency`: Default currency for budgeting
- `notifications`: JSONB notification preferences

---

### Travel & Trips

#### 4. trips
User-created travel itineraries.

**Key Fields:**
- `status`: planning, ongoing, completed
- `cities`: JSONB array of cities and days
- `is_public`: Visibility setting

**Cascade:** DELETE user → DELETE trips

---

#### 5. itineraries
Day-by-day trip plans.

**Key Fields:**
- `day_number`: Sequential day number
- `activities`: JSONB array of activities with time, location, cost
- `actual_spent`: Tracked spending for the day

**Cascade:** DELETE trip → DELETE itineraries

**Unique Constraint:** (trip_id, day_number)

---

### Places & Discovery

#### 6. places
Database of attractions, restaurants, hotels, etc.

**Key Fields:**
- `location`: PostGIS GEOGRAPHY point (lat/lng)
- `category`: attraction, restaurant, hotel, etc.
- `rating`: 0.0 to 5.0 stars
- `price_level`: 1-4 ($, $$, $$$, $$$$)
- `opening_hours`: JSONB with days and hours

**Indexes:**
- `idx_places_location` (GIST for geospatial queries)
- `idx_places_city`
- `idx_places_category`
- `idx_places_rating`

---

#### 7. place_reviews
User reviews for places.

**Cascade:** DELETE place → DELETE reviews, DELETE user → DELETE reviews

---

#### 8. saved_places
User bookmarks/favorites.

**Unique Constraint:** (user_id, place_id)

---

### Budget & Expenses

#### 9. expenses
Financial tracking for trips.

**Key Fields:**
- `category`: food, accommodation, transport, etc.
- `receipt_photo`: URL to uploaded receipt
- `expense_date`: When expense occurred

**Cascade:** DELETE trip → DELETE expenses

---

### Gamification

#### 10. challenges
Predefined city challenges.

**Key Fields:**
- `checkpoints`: JSONB array of places to visit
- `difficulty`: beginner, intermediate, advanced, expert
- `is_seasonal`: Flag for seasonal availability

---

#### 11. user_challenges
User progress on challenges.

**Key Fields:**
- `status`: in_progress, completed, abandoned
- `progress`: JSONB tracking checkpoint completions
- `completion_percentage`: 0-100

**Unique Constraint:** (user_id, challenge_id)

---

#### 12. achievements
Achievement definitions.

**Key Fields:**
- `criteria`: JSONB rules for unlocking
- `rarity`: common, rare, epic, legendary
- `is_hidden`: Secret achievements

---

#### 13. user_achievements
Unlocked achievements per user.

**Unique Constraint:** (user_id, achievement_id)

---

### Community & Social

#### 14. posts
Community feed posts.

**Key Fields:**
- `post_type`: photo, question, tip, check_in
- `likes_count`: Denormalized for performance
- `comments_count`: Denormalized for performance

---

#### 15. comments
Post comments (supports nested replies).

**Key Fields:**
- `parent_comment_id`: For threaded comments

**Cascade:** DELETE post → DELETE comments

---

#### 16. post_likes
Track who liked each post.

**Unique Constraint:** (user_id, post_id)

---

#### 17. comment_likes
Track who liked each comment.

**Unique Constraint:** (user_id, comment_id)

---

#### 18. saved_posts
Bookmarked posts.

**Unique Constraint:** (user_id, post_id)

---

#### 19. follows
User follow relationships.

**Unique Constraint:** (follower_id, following_id)

**Check Constraint:** follower_id ≠ following_id

---

### Social Matching

#### 20. companion_profiles
Travel companion seeking profiles.

**Key Fields:**
- `travel_dates`: JSONB array of date ranges
- `preferred_age`: JSONB min/max age
- `trust_score`: 0.0 to 5.0

---

#### 21. companion_matches
Matched travel companions.

**Key Fields:**
- `match_score`: AI-calculated compatibility (0-1)
- `status`: pending, accepted, rejected

**Unique Constraint:** (user1_id, user2_id) where user1_id < user2_id

---

#### 22. local_guides
Certified local guide profiles.

**Key Fields:**
- `verification_status`: pending, approved, rejected
- `hourly_rate`: Guide fee (null if free)
- `availability`: JSONB calendar data

---

#### 23. guide_bookings
Guide booking records.

**Key Fields:**
- `status`: pending, confirmed, completed, cancelled
- `rating`: Post-service rating

---

### Safety & Emergency

#### 24. emergency_contacts
User's emergency contact list.

**Key Fields:**
- `notification_type`: sms, push, both
- `priority`: 1-5 (call order)

**Cascade:** DELETE user → DELETE contacts

---

#### 25. emergency_alerts
SOS alert history.

**Key Fields:**
- `location`: PostGIS point of emergency
- `emergency_type`: medical, police, lost, other
- `status`: active, resolved

---

#### 26. location_shares
Active location sharing sessions.

**Key Fields:**
- `share_code`: Public share link code
- `recipients`: JSONB array of contacts
- `is_active`: Active/stopped flag

---

#### 27. location_updates
GPS breadcrumb trail.

**Key Fields:**
- `accuracy`: GPS accuracy in meters
- `battery_level`: Device battery percentage

**Cascade:** DELETE share → DELETE updates

---

#### 28. safety_reports
Community-submitted safety incidents.

**Key Fields:**
- `incident_type`: scam, theft, harassment, etc.
- `verified`: Moderator approval flag

---

### System & Utilities

#### 29. notifications
In-app notifications.

**Key Fields:**
- `type`: like, comment, achievement, alert, etc.
- `data`: JSONB payload for notification

**Cascade:** DELETE user → DELETE notifications

---

#### 30. translations_cache
Translation result caching.

**Key Fields:**
- `text_hash`: SHA-256 hash of source text
- `expires_at`: Cache expiry (30 days)

**Index:** (text_hash, source_lang, target_lang) UNIQUE

---

#### 31. offline_maps
Available offline map packages.

**Key Fields:**
- `bounds`: JSONB geographic boundaries
- `version`: Map data version (YYYY.MM)

---

#### 32. user_downloaded_maps
Track user's downloaded maps.

**Unique Constraint:** (user_id, map_id)

---

### Booking & Payments

#### 33. bookings
Hotel, activity, ticket bookings.

**Key Fields:**
- `booking_type`: hotel, attraction, experience
- `partner_name`: Booking.com, Ctrip, etc.
- `status`: pending, confirmed, cancelled

---

#### 34. subscriptions
Premium subscription records.

**Key Fields:**
- `plan_type`: monthly, yearly
- `auto_renew`: Auto-renewal flag

---

#### 35. payments
Payment transaction history.

**Key Fields:**
- `payment_provider`: stripe, wechat, alipay
- `transaction_id`: External provider ID

---

#### 36. points_history
Points earning/spending ledger.

**Key Fields:**
- `points_change`: Positive (earn) or negative (spend)
- `reason`: check_in, challenge, purchase, etc.
- `reference_type`: challenge, achievement, booking

---

### Analytics

#### 37. analytics_events
User behavior tracking.

**Key Fields:**
- `event_type`: page_view, button_click, etc.
- `event_data`: JSONB event properties
- `platform`: ios, android, web

**Partitioned by:** created_at (monthly partitions)

---

## Relationships

### One-to-Many (1:N)

| Parent | Child | Cascade |
|--------|-------|---------|
| users | trips | DELETE |
| users | expenses | DELETE |
| users | posts | DELETE |
| users | comments | DELETE |
| users | emergency_contacts | DELETE |
| trips | itineraries | DELETE |
| trips | expenses | DELETE |
| posts | comments | DELETE |
| posts | post_likes | DELETE |
| comments | comment_likes | DELETE |
| challenges | user_challenges | RESTRICT |
| achievements | user_achievements | RESTRICT |
| places | place_reviews | DELETE |
| location_shares | location_updates | DELETE |
| subscriptions | payments | RESTRICT |

### Many-to-Many (N:N)

| Table 1 | Junction Table | Table 2 | Notes |
|---------|---------------|---------|-------|
| users | follows | users | Self-referential |
| users | companion_matches | users | Self-referential |
| users | saved_places | places | Bookmarks |
| users | saved_posts | posts | Bookmarks |
| users | post_likes | posts | Likes |
| users | comment_likes | comments | Likes |
| users | user_downloaded_maps | offline_maps | Downloads |

### One-to-One (1:1)

| Table 1 | Table 2 | Notes |
|---------|---------|-------|
| users | user_settings | User preferences |
| users | companion_profiles | Optional profile |
| users | local_guides | Optional guide profile |

---

## Indexes

### Performance-Critical Indexes

```sql
-- Users
CREATE UNIQUE INDEX idx_users_email ON users(email);
CREATE UNIQUE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_created_at ON users(created_at DESC);
CREATE INDEX idx_users_premium ON users(premium_until) WHERE premium_until > NOW();

-- Places (Geospatial)
CREATE INDEX idx_places_location ON places USING GIST(location);
CREATE INDEX idx_places_city ON places(city);
CREATE INDEX idx_places_category ON places(category);
CREATE INDEX idx_places_rating ON places(rating DESC);
CREATE INDEX idx_places_city_category ON places(city, category);

-- Trips
CREATE INDEX idx_trips_user_id ON trips(user_id);
CREATE INDEX idx_trips_status ON trips(status);
CREATE INDEX idx_trips_dates ON trips(start_date, end_date);

-- Expenses
CREATE INDEX idx_expenses_user_id ON expenses(user_id);
CREATE INDEX idx_expenses_trip_id ON expenses(trip_id);
CREATE INDEX idx_expenses_date ON expenses(expense_date DESC);
CREATE INDEX idx_expenses_user_trip ON expenses(user_id, trip_id);

-- Posts
CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX idx_posts_location_id ON posts(location_id);
CREATE INDEX idx_posts_tags ON posts USING GIN(tags);

-- Comments
CREATE INDEX idx_comments_post_id ON comments(post_id);
CREATE INDEX idx_comments_user_id ON comments(user_id);
CREATE INDEX idx_comments_parent_id ON comments(parent_comment_id);

-- Challenges
CREATE INDEX idx_challenges_city ON challenges(city);
CREATE INDEX idx_challenges_category ON challenges(category);
CREATE INDEX idx_challenges_active ON challenges(is_active) WHERE is_active = true;

-- User Challenges
CREATE UNIQUE INDEX idx_user_challenges_unique ON user_challenges(user_id, challenge_id);
CREATE INDEX idx_user_challenges_status ON user_challenges(status);

-- Notifications
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_unread ON notifications(user_id) WHERE is_read = false;

-- Emergency
CREATE INDEX idx_emergency_alerts_user_id ON emergency_alerts(user_id);
CREATE INDEX idx_emergency_alerts_active ON emergency_alerts(status) WHERE status = 'active';

-- Safety Reports
CREATE INDEX idx_safety_reports_location ON safety_reports USING GIST(location);
CREATE INDEX idx_safety_reports_verified ON safety_reports(verified);

-- Analytics (Partitioned)
CREATE INDEX idx_analytics_user_id ON analytics_events(user_id);
CREATE INDEX idx_analytics_event_type ON analytics_events(event_type);
CREATE INDEX idx_analytics_created_at ON analytics_events(created_at DESC);
```

---

## Constraints

### Foreign Key Constraints

```sql
-- Users relationships
ALTER TABLE refresh_tokens ADD CONSTRAINT fk_refresh_tokens_user
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE trips ADD CONSTRAINT fk_trips_user
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE expenses ADD CONSTRAINT fk_expenses_user
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE expenses ADD CONSTRAINT fk_expenses_trip
  FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE;

ALTER TABLE expenses ADD CONSTRAINT fk_expenses_place
  FOREIGN KEY (place_id) REFERENCES places(id) ON DELETE SET NULL;

-- Itineraries
ALTER TABLE itineraries ADD CONSTRAINT fk_itineraries_trip
  FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE;

-- Posts
ALTER TABLE posts ADD CONSTRAINT fk_posts_user
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE posts ADD CONSTRAINT fk_posts_location
  FOREIGN KEY (location_id) REFERENCES places(id) ON DELETE SET NULL;

-- Comments
ALTER TABLE comments ADD CONSTRAINT fk_comments_post
  FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE;

ALTER TABLE comments ADD CONSTRAINT fk_comments_user
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE comments ADD CONSTRAINT fk_comments_parent
  FOREIGN KEY (parent_comment_id) REFERENCES comments(id) ON DELETE CASCADE;

-- Challenges
ALTER TABLE user_challenges ADD CONSTRAINT fk_user_challenges_user
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE user_challenges ADD CONSTRAINT fk_user_challenges_challenge
  FOREIGN KEY (challenge_id) REFERENCES challenges(id) ON DELETE RESTRICT;

-- Achievements
ALTER TABLE user_achievements ADD CONSTRAINT fk_user_achievements_user
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE user_achievements ADD CONSTRAINT fk_user_achievements_achievement
  FOREIGN KEY (achievement_id) REFERENCES achievements(id) ON DELETE RESTRICT;
```

### Check Constraints

```sql
-- Users
ALTER TABLE users ADD CONSTRAINT chk_users_email_format
  CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$');

ALTER TABLE users ADD CONSTRAINT chk_users_total_points
  CHECK (total_points >= 0);

ALTER TABLE users ADD CONSTRAINT chk_users_membership_tier
  CHECK (membership_tier IN ('bronze', 'silver', 'gold', 'platinum'));

-- Trips
ALTER TABLE trips ADD CONSTRAINT chk_trips_dates
  CHECK (end_date >= start_date);

ALTER TABLE trips ADD CONSTRAINT chk_trips_budget
  CHECK (budget >= 0);

ALTER TABLE trips ADD CONSTRAINT chk_trips_status
  CHECK (status IN ('planning', 'ongoing', 'completed'));

-- Expenses
ALTER TABLE expenses ADD CONSTRAINT chk_expenses_amount
  CHECK (amount >= 0);

ALTER TABLE expenses ADD CONSTRAINT chk_expenses_category
  CHECK (category IN ('food', 'accommodation', 'transport', 'attractions', 'shopping', 'health', 'communication', 'other'));

-- Places
ALTER TABLE places ADD CONSTRAINT chk_places_rating
  CHECK (rating >= 0 AND rating <= 5);

ALTER TABLE places ADD CONSTRAINT chk_places_price_level
  CHECK (price_level >= 1 AND price_level <= 4);

-- Reviews
ALTER TABLE place_reviews ADD CONSTRAINT chk_place_reviews_rating
  CHECK (rating >= 1 AND rating <= 5);

-- Challenges
ALTER TABLE challenges ADD CONSTRAINT chk_challenges_difficulty
  CHECK (difficulty IN ('beginner', 'intermediate', 'advanced', 'expert', 'master'));

ALTER TABLE challenges ADD CONSTRAINT chk_challenges_points
  CHECK (total_points > 0);

-- User Challenges
ALTER TABLE user_challenges ADD CONSTRAINT chk_user_challenges_status
  CHECK (status IN ('in_progress', 'completed', 'abandoned'));

ALTER TABLE user_challenges ADD CONSTRAINT chk_user_challenges_percentage
  CHECK (completion_percentage >= 0 AND completion_percentage <= 100);

-- Achievements
ALTER TABLE achievements ADD CONSTRAINT chk_achievements_rarity
  CHECK (rarity IN ('common', 'rare', 'epic', 'legendary'));

-- Follows (no self-follows)
ALTER TABLE follows ADD CONSTRAINT chk_follows_no_self
  CHECK (follower_id != following_id);

-- Companion Matches (user1_id < user2_id to prevent duplicates)
ALTER TABLE companion_matches ADD CONSTRAINT chk_companion_matches_order
  CHECK (user1_id < user2_id);

-- Subscriptions
ALTER TABLE subscriptions ADD CONSTRAINT chk_subscriptions_plan
  CHECK (plan_type IN ('monthly', 'yearly'));

ALTER TABLE subscriptions ADD CONSTRAINT chk_subscriptions_status
  CHECK (status IN ('active', 'cancelled', 'expired'));
```

### Unique Constraints

```sql
-- Prevent duplicate user challenges
ALTER TABLE user_challenges ADD CONSTRAINT uniq_user_challenge
  UNIQUE (user_id, challenge_id);

-- Prevent duplicate achievements
ALTER TABLE user_achievements ADD CONSTRAINT uniq_user_achievement
  UNIQUE (user_id, achievement_id);

-- Prevent duplicate likes
ALTER TABLE post_likes ADD CONSTRAINT uniq_post_like
  UNIQUE (user_id, post_id);

ALTER TABLE comment_likes ADD CONSTRAINT uniq_comment_like
  UNIQUE (user_id, comment_id);

-- Prevent duplicate saves
ALTER TABLE saved_places ADD CONSTRAINT uniq_saved_place
  UNIQUE (user_id, place_id);

ALTER TABLE saved_posts ADD CONSTRAINT uniq_saved_post
  UNIQUE (user_id, post_id);

-- Prevent duplicate follows
ALTER TABLE follows ADD CONSTRAINT uniq_follow
  UNIQUE (follower_id, following_id);

-- Prevent duplicate companion matches
ALTER TABLE companion_matches ADD CONSTRAINT uniq_companion_match
  UNIQUE (user1_id, user2_id);

-- Prevent duplicate itinerary days
ALTER TABLE itineraries ADD CONSTRAINT uniq_trip_day
  UNIQUE (trip_id, day_number);

-- One settings per user
ALTER TABLE user_settings ADD CONSTRAINT uniq_user_settings
  UNIQUE (user_id);

-- One companion profile per user
ALTER TABLE companion_profiles ADD CONSTRAINT uniq_companion_profile
  UNIQUE (user_id);

-- One guide profile per user
ALTER TABLE local_guides ADD CONSTRAINT uniq_local_guide
  UNIQUE (user_id);

-- Unique translation cache
ALTER TABLE translations_cache ADD CONSTRAINT uniq_translation
  UNIQUE (text_hash, source_lang, target_lang);
```

---

## Data Types

### Custom Types (ENUMs)

```sql
-- User membership tiers
CREATE TYPE membership_tier AS ENUM ('bronze', 'silver', 'gold', 'platinum');

-- Trip status
CREATE TYPE trip_status AS ENUM ('planning', 'ongoing', 'completed');

-- Challenge difficulty
CREATE TYPE difficulty_level AS ENUM ('beginner', 'intermediate', 'advanced', 'expert', 'master');

-- Achievement rarity
CREATE TYPE rarity_level AS ENUM ('common', 'rare', 'epic', 'legendary');

-- Post types
CREATE TYPE post_type AS ENUM ('photo', 'question', 'tip', 'check_in');

-- Expense categories
CREATE TYPE expense_category AS ENUM ('food', 'accommodation', 'transport', 'attractions', 'shopping', 'health', 'communication', 'other');

-- Booking types
CREATE TYPE booking_type AS ENUM ('hotel', 'attraction', 'experience', 'transport');

-- Emergency types
CREATE TYPE emergency_type AS ENUM ('medical', 'police', 'lost', 'accident', 'other');
```

---

## Database Statistics

**Total Tables:** 37
**Total Indexes:** ~80+
**Estimated Size (1M users):**
- Users & Auth: ~500 MB
- Places & Reviews: ~2 GB
- Posts & Community: ~5 GB
- Challenges & Achievements: ~1 GB
- Analytics: ~10 GB (partitioned)
- **Total: ~18-20 GB**

---

## Backup & Maintenance

### Backup Strategy
- **Full Backup:** Daily at 2:00 AM UTC
- **Incremental Backup:** Every 6 hours
- **WAL Archiving:** Continuous
- **Retention:** 30 days

### Maintenance Tasks
- **VACUUM ANALYZE:** Weekly on Sunday 3:00 AM
- **REINDEX:** Monthly (first Sunday)
- **Partition Management:** Automatic (analytics_events)

---

**Last Updated:** 2025-10-22
**Database Version:** PostgreSQL 14+
**PostGIS Version:** 3.3+
