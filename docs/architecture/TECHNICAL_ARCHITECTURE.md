# WanderChina - Technical Architecture

**Version:** 1.0
**Last Updated:** 2025-10-22
**Status:** Design Phase

---

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [System Architecture](#system-architecture)
3. [Mobile Application](#mobile-application)
4. [Backend Services](#backend-services)
5. [Database Design](#database-design)
6. [AI/ML Pipeline](#aiml-pipeline)
7. [Third-Party Integrations](#third-party-integrations)
8. [Security](#security)
9. [DevOps & Infrastructure](#devops--infrastructure)
10. [Scalability Strategy](#scalability-strategy)

---

## Architecture Overview

### High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENT LAYER                             │
├─────────────────────────────────────────────────────────────────┤
│  iOS App          Android App        Web App (Future)            │
│  (Swift/SwiftUI)  (Kotlin/Compose)   (React)                    │
└────────────┬────────────────┬─────────────────────┬─────────────┘
             │                │                     │
             └────────────────┴─────────────────────┘
                              │
                    ┌─────────▼──────────┐
                    │   CDN / CloudFlare  │
                    │   (Static Assets)   │
                    └─────────┬──────────┘
                              │
             ┌────────────────┴─────────────────┐
             │                                  │
    ┌────────▼─────────┐            ┌──────────▼──────────┐
    │  Load Balancer   │            │   API Gateway       │
    │  (NGINX/AWS ALB) │            │   (Kong/AWS API GW) │
    └────────┬─────────┘            └──────────┬──────────┘
             │                                  │
             │                                  │
┌────────────▼──────────────────────────────────▼────────────────┐
│                     APPLICATION LAYER                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │   User       │  │   Travel     │  │  Community   │         │
│  │   Service    │  │   Service    │  │  Service     │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │   AI/ML      │  │   Booking    │  │  Notification│         │
│  │   Service    │  │   Service    │  │  Service     │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │   Map/Route  │  │   Translation│  │  Gamification│         │
│  │   Service    │  │   Service    │  │  Service     │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
└──────────────────────────┬──────────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────────┐
│                      DATA LAYER                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │  PostgreSQL  │  │    Redis     │  │  Elasticsearch│         │
│  │  (Primary)   │  │   (Cache)    │  │   (Search)   │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │    S3/OSS    │  │   MongoDB    │  │  RabbitMQ    │         │
│  │   (Files)    │  │   (Logs)     │  │   (Queue)    │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
└─────────────────────────────────────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────────┐
│                   EXTERNAL SERVICES                              │
├─────────────────────────────────────────────────────────────────┤
│  Baidu Maps  │  Google APIs │  Payment Gateways │  Analytics   │
│  Translation │  Weather APIs│  Booking Partners │  Monitoring  │
└─────────────────────────────────────────────────────────────────┘
```

### Architecture Principles

1. **Microservices Architecture** - Loosely coupled, independently deployable services
2. **API-First Design** - Well-defined API contracts for all services
3. **Offline-First** - Core functionality works without internet
4. **Scalability** - Horizontal scaling for high traffic
5. **Security** - End-to-end encryption, secure authentication
6. **Performance** - Sub-second response times, optimized mobile experience
7. **Reliability** - 99.9% uptime SLA, fault tolerance

---

## System Architecture

### Architecture Style: Microservices

**Why Microservices?**
- Independent scaling of different services
- Technology flexibility (Node.js, Python, Go)
- Faster development with parallel teams
- Fault isolation (one service down doesn't crash entire app)
- Easier maintenance and updates

### Service Breakdown

#### 1. User Service
**Responsibilities:**
- User registration and authentication
- Profile management
- Preferences and settings
- Session management

**Tech Stack:**
- Language: Node.js (Express) or Python (FastAPI)
- Database: PostgreSQL
- Cache: Redis
- Auth: JWT tokens

#### 2. Travel Service
**Responsibilities:**
- Itinerary planning and management
- Trip recommendations
- Destination information
- Route optimization

**Tech Stack:**
- Language: Python (for ML integration)
- Database: PostgreSQL
- Cache: Redis
- Search: Elasticsearch

#### 3. Community Service
**Responsibilities:**
- Social feed (posts, comments, likes)
- Travel companion matching
- Local guide platform
- Messaging and chat

**Tech Stack:**
- Language: Node.js
- Database: PostgreSQL + MongoDB (for chat history)
- Real-time: Socket.io
- Cache: Redis

#### 4. AI/ML Service
**Responsibilities:**
- Recommendation engine
- Natural language processing (chatbot)
- Image recognition (food, landmarks)
- Voice assistant (speech-to-text, text-to-speech)

**Tech Stack:**
- Language: Python (TensorFlow, PyTorch)
- Framework: FastAPI
- ML Models: TensorFlow Lite, Hugging Face
- GPU: AWS EC2 GPU instances or SageMaker

#### 5. Booking Service
**Responsibilities:**
- Accommodation search and booking
- Attraction ticket booking
- Experience marketplace
- Commission tracking

**Tech Stack:**
- Language: Node.js or Python
- Database: PostgreSQL
- Cache: Redis
- External APIs: Booking.com, Agoda, Ctrip

#### 6. Map/Route Service
**Responsibilities:**
- Map data management
- Route planning and navigation
- Offline map downloads
- GPS tracking

**Tech Stack:**
- Language: Go (for performance)
- Database: PostgreSQL + PostGIS
- Map APIs: Baidu Maps, OpenStreetMap
- Tile Server: MapBox or custom

#### 7. Translation Service
**Responsibilities:**
- Text translation
- OCR (camera translation)
- Speech-to-text
- Text-to-speech

**Tech Stack:**
- Language: Python
- APIs: Google Translate, Baidu Translate
- OCR: Google Vision API, Baidu OCR
- Cache: Redis (translation cache)

#### 8. Gamification Service
**Responsibilities:**
- Challenges and missions
- Achievements and badges
- Leaderboards
- Points and rewards

**Tech Stack:**
- Language: Node.js
- Database: PostgreSQL + Redis (leaderboards)
- Cache: Redis

#### 9. Notification Service
**Responsibilities:**
- Push notifications (iOS, Android)
- Email notifications
- In-app notifications
- SMS (emergency alerts)

**Tech Stack:**
- Language: Node.js
- Queue: RabbitMQ or AWS SQS
- Push: Firebase Cloud Messaging (FCM), APNs
- Email: SendGrid or AWS SES

---

## Mobile Application

### Cross-Platform Decision: React Native vs Flutter

| Criteria | React Native | Flutter | Winner |
|----------|-------------|---------|--------|
| **Performance** | Good (JS bridge) | Excellent (native compilation) | Flutter |
| **Developer Pool** | Large (JavaScript) | Growing (Dart) | React Native |
| **UI Flexibility** | Good | Excellent | Flutter |
| **Third-Party Libraries** | Extensive | Growing | React Native |
| **Hot Reload** | Yes | Yes | Tie |
| **Native Features** | Requires bridges | Direct access | Flutter |
| **App Size** | Moderate | Larger | React Native |
| **Learning Curve** | Low (JS devs) | Medium (Dart) | React Native |

**Recommendation: Flutter**
- Better performance for map-heavy app
- Smoother animations for gamification
- Easier camera/AR integration
- Single codebase for iOS/Android
- Growing ecosystem suitable for 18-month project

### Mobile App Architecture

```
┌─────────────────────────────────────────┐
│           Presentation Layer             │
│  (Flutter Widgets / UI Components)       │
└───────────────┬─────────────────────────┘
                │
┌───────────────▼─────────────────────────┐
│          State Management                │
│  (Provider / Riverpod / Bloc)            │
└───────────────┬─────────────────────────┘
                │
┌───────────────▼─────────────────────────┐
│           Business Logic                 │
│  (Use Cases / Interactors)               │
└───────────────┬─────────────────────────┘
                │
┌───────────────▼─────────────────────────┐
│          Repository Layer                │
│  (Data abstraction)                      │
└───┬───────────┬─────────────┬───────────┘
    │           │             │
┌───▼────┐  ┌───▼────┐   ┌───▼─────┐
│ Remote │  │ Local  │   │ Cache   │
│  API   │  │Database│   │ Layer   │
└────────┘  └────────┘   └─────────┘
```

### Key Mobile Technologies

#### State Management
- **Primary:** Riverpod (for complex state)
- **Alternative:** Provider (simpler state)
- **Local State:** StatefulWidget (for simple UI state)

#### Local Database
- **Primary:** Drift (formerly Moor) - SQL database
- **Alternative:** Hive (NoSQL, faster for simple data)
- **Use Case:** Offline data, cache, user preferences

#### Networking
- **HTTP Client:** Dio (with interceptors, retries)
- **GraphQL:** graphql_flutter (if using GraphQL)
- **Websockets:** socket_io_client (for real-time chat)

#### Maps & Location
- **Maps:** google_maps_flutter, flutter_baidu_map
- **Location:** geolocator
- **Geocoding:** geocoding
- **Offline Maps:** Custom tile caching

#### Camera & OCR
- **Camera:** camera plugin
- **OCR:** google_ml_kit (on-device), Cloud Vision API (server)
- **Image Picker:** image_picker
- **Image Compression:** flutter_image_compress

#### Voice & Speech
- **Speech-to-Text:** speech_to_text
- **Text-to-Speech:** flutter_tts
- **Voice Recording:** record

#### Offline & Storage
- **Local Storage:** shared_preferences (key-value)
- **Secure Storage:** flutter_secure_storage (tokens)
- **File Storage:** path_provider
- **Download Manager:** flutter_downloader

#### UI/UX
- **Animations:** flutter_animate, rive
- **Charts:** fl_chart
- **Icons:** flutter_svg, font_awesome_flutter
- **Image Caching:** cached_network_image
- **Shimmer Loading:** shimmer

#### Analytics & Monitoring
- **Analytics:** firebase_analytics, mixpanel_flutter
- **Crash Reporting:** sentry_flutter, firebase_crashlytics
- **Performance:** firebase_performance

#### Push Notifications
- **FCM:** firebase_messaging
- **Local Notifications:** flutter_local_notifications

#### Authentication
- **Firebase Auth:** firebase_auth
- **Social Login:** google_sign_in, flutter_facebook_auth
- **Biometric:** local_auth

---

## Backend Services

### Technology Stack

#### Primary Language: Node.js (TypeScript)

**Why Node.js?**
- Fast development with large ecosystem
- Great for real-time features (Socket.io)
- JSON-native (matches mobile app)
- Strong async/await support
- Good for microservices

**Alternative for ML Service: Python (FastAPI)**
- Better ML/AI library support
- TensorFlow, PyTorch, scikit-learn
- Fast API performance
- Type hints (similar to TypeScript)

#### API Style: GraphQL + REST Hybrid

**GraphQL for:**
- Complex, nested data queries
- Reduce over-fetching
- Single endpoint for mobile app
- Real-time subscriptions

**REST for:**
- Simple CRUD operations
- Third-party integrations
- Webhooks
- File uploads

#### Framework
- **Node.js:** Express + Apollo Server (GraphQL)
- **Python:** FastAPI
- **API Gateway:** Kong or AWS API Gateway

### Backend Architecture Pattern: Clean Architecture

```
┌─────────────────────────────────────────┐
│        Presentation Layer               │
│  (Controllers, GraphQL Resolvers)       │
└───────────────┬─────────────────────────┘
                │
┌───────────────▼─────────────────────────┐
│         Application Layer               │
│  (Use Cases, Business Logic)            │
└───────────────┬─────────────────────────┘
                │
┌───────────────▼─────────────────────────┐
│          Domain Layer                   │
│  (Entities, Domain Services)            │
└───────────────┬─────────────────────────┘
                │
┌───────────────▼─────────────────────────┐
│      Infrastructure Layer               │
│  (Database, External APIs, Messaging)   │
└─────────────────────────────────────────┘
```

### Key Backend Libraries (Node.js)

#### Core Framework
- **express** - Web framework
- **apollo-server-express** - GraphQL server
- **typescript** - Type safety

#### Database & ORM
- **pg** - PostgreSQL client
- **typeorm** or **prisma** - ORM
- **redis** - Caching
- **mongoose** - MongoDB (for logs/chat)

#### Authentication & Security
- **jsonwebtoken** - JWT tokens
- **bcrypt** - Password hashing
- **helmet** - Security headers
- **cors** - CORS handling
- **rate-limiter-flexible** - Rate limiting

#### Validation
- **joi** or **zod** - Schema validation
- **class-validator** - DTO validation

#### Utilities
- **axios** - HTTP client
- **moment** or **date-fns** - Date handling
- **lodash** - Utility functions
- **winston** - Logging
- **bull** - Job queue (Redis-based)

#### Testing
- **jest** - Testing framework
- **supertest** - API testing
- **faker** - Test data generation

---

## Database Design

### Primary Database: PostgreSQL

**Why PostgreSQL?**
- ACID compliance (data integrity)
- Rich data types (JSON, arrays, PostGIS)
- Excellent performance and scalability
- Strong community and tooling
- Open source

### Database Schema (High-Level)

#### Core Tables

**users**
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255),
  username VARCHAR(100) UNIQUE,
  full_name VARCHAR(255),
  profile_picture TEXT,
  bio TEXT,
  nationality VARCHAR(100),
  languages JSONB, -- ["en", "zh", "es"]
  travel_style VARCHAR(50), -- backpacker, luxury, culture, etc.
  interests JSONB, -- ["food", "hiking", "photography"]
  email_verified BOOLEAN DEFAULT FALSE,
  phone VARCHAR(50),
  phone_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  last_login TIMESTAMP,
  is_active BOOLEAN DEFAULT TRUE,
  premium_until TIMESTAMP,
  total_points INTEGER DEFAULT 0,
  membership_tier VARCHAR(20) DEFAULT 'bronze'
);
```

**trips**
```sql
CREATE TABLE trips (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  budget DECIMAL(10, 2),
  total_spent DECIMAL(10, 2) DEFAULT 0,
  status VARCHAR(20) DEFAULT 'planning', -- planning, ongoing, completed
  cities JSONB, -- [{"name": "Beijing", "days": 3}, ...]
  is_public BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

**itineraries**
```sql
CREATE TABLE itineraries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  trip_id UUID REFERENCES trips(id) ON DELETE CASCADE,
  day_number INTEGER NOT NULL,
  date DATE NOT NULL,
  activities JSONB, -- [{time, activity, location, cost, notes}, ...]
  total_budget DECIMAL(10, 2),
  actual_spent DECIMAL(10, 2),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(trip_id, day_number)
);
```

**places**
```sql
CREATE TABLE places (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(255) NOT NULL,
  name_chinese VARCHAR(255),
  category VARCHAR(50), -- attraction, restaurant, hotel, etc.
  subcategory VARCHAR(50), -- museum, temple, chinese_food, etc.
  description TEXT,
  address TEXT,
  city VARCHAR(100),
  province VARCHAR(100),
  country VARCHAR(100) DEFAULT 'China',
  location GEOGRAPHY(POINT, 4326), -- PostGIS for geospatial queries
  photos JSONB, -- [url1, url2, ...]
  rating DECIMAL(2, 1), -- 0.0 to 5.0
  price_level INTEGER, -- 1-4 ($, $$, $$$, $$$$)
  opening_hours JSONB,
  tags JSONB, -- ["family-friendly", "instagram-worthy", "halal"]
  external_ids JSONB, -- {"google_place_id": "...", "baidu_id": "..."}
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_places_location ON places USING GIST (location);
CREATE INDEX idx_places_city ON places(city);
CREATE INDEX idx_places_category ON places(category);
```

**challenges**
```sql
CREATE TABLE challenges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title VARCHAR(255) NOT NULL,
  description TEXT,
  city VARCHAR(100),
  category VARCHAR(50), -- heritage, food, nature, culture
  difficulty VARCHAR(20), -- beginner, intermediate, advanced, expert
  checkpoints JSONB, -- [{place_id, order, points}, ...]
  total_points INTEGER NOT NULL,
  estimated_time_hours INTEGER,
  is_seasonal BOOLEAN DEFAULT FALSE,
  season VARCHAR(20), -- spring, summer, autumn, winter
  badge_image TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

**user_challenges**
```sql
CREATE TABLE user_challenges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  challenge_id UUID REFERENCES challenges(id) ON DELETE CASCADE,
  status VARCHAR(20) DEFAULT 'in_progress', -- in_progress, completed, abandoned
  progress JSONB, -- {checkpoint_id: {completed: true, timestamp, photo}}
  completion_percentage INTEGER DEFAULT 0,
  started_at TIMESTAMP DEFAULT NOW(),
  completed_at TIMESTAMP,
  points_earned INTEGER DEFAULT 0,
  UNIQUE(user_id, challenge_id)
);
```

**achievements**
```sql
CREATE TABLE achievements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  category VARCHAR(50), -- explorer, foodie, social, culture, etc.
  criteria JSONB, -- {type: "visit_places", count: 10, category: "temple"}
  rarity VARCHAR(20), -- common, rare, epic, legendary
  badge_image TEXT,
  points_reward INTEGER,
  is_hidden BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);
```

**user_achievements**
```sql
CREATE TABLE user_achievements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  achievement_id UUID REFERENCES achievements(id) ON DELETE CASCADE,
  unlocked_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, achievement_id)
);
```

**posts**
```sql
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  images JSONB, -- [url1, url2, ...]
  location_id UUID REFERENCES places(id),
  trip_id UUID REFERENCES trips(id),
  tags JSONB, -- ["beijing", "food", "tips"]
  likes_count INTEGER DEFAULT 0,
  comments_count INTEGER DEFAULT 0,
  is_pinned BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);
```

**comments**
```sql
CREATE TABLE comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  parent_comment_id UUID REFERENCES comments(id),
  likes_count INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

**companion_profiles**
```sql
CREATE TABLE companion_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,
  is_seeking_companions BOOLEAN DEFAULT FALSE,
  travel_dates JSONB, -- [{start: "2025-06-01", end: "2025-06-15", cities: ["Beijing"]}]
  preferred_age_range JSONB, -- {min: 25, max: 35}
  preferred_gender VARCHAR(20), -- any, male, female
  budget_level VARCHAR(20), -- budget, moderate, luxury
  interests JSONB,
  languages_spoken JSONB,
  bio TEXT,
  verification_status VARCHAR(20) DEFAULT 'unverified',
  trust_score DECIMAL(3, 2) DEFAULT 5.0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

**local_guides**
```sql
CREATE TABLE local_guides (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,
  city VARCHAR(100) NOT NULL,
  specializations JSONB, -- ["food", "history", "photography"]
  hourly_rate DECIMAL(10, 2),
  is_free BOOLEAN DEFAULT FALSE,
  languages JSONB,
  bio TEXT,
  verification_status VARCHAR(20) DEFAULT 'pending',
  rating DECIMAL(2, 1),
  total_bookings INTEGER DEFAULT 0,
  availability JSONB, -- calendar data
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

**expenses**
```sql
CREATE TABLE expenses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  trip_id UUID REFERENCES trips(id) ON DELETE CASCADE,
  category VARCHAR(50), -- food, transport, accommodation, shopping, etc.
  amount DECIMAL(10, 2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'CNY',
  description TEXT,
  receipt_image TEXT,
  place_id UUID REFERENCES places(id),
  expense_date TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_expenses_user_trip ON expenses(user_id, trip_id);
CREATE INDEX idx_expenses_date ON expenses(expense_date);
```

### Redis Cache Strategy

**What to Cache:**
1. **User sessions** (TTL: 7 days)
2. **API responses** (popular endpoints, TTL: 5-60 minutes)
3. **Translation results** (TTL: 30 days)
4. **Place information** (TTL: 24 hours)
5. **Leaderboards** (sorted sets, real-time updates)
6. **Rate limiting counters** (TTL: 1 hour)
7. **Offline map metadata** (TTL: 7 days)

**Cache Keys Pattern:**
```
user:session:{user_id}
translation:{source_lang}:{target_lang}:{hash(text)}
place:{place_id}
leaderboard:global:{date}
leaderboard:city:{city}:{date}
ratelimit:{user_id}:{endpoint}
```

### Elasticsearch (Search Index)

**Indexed Documents:**
- Places (full-text search on name, description, tags)
- Posts (community feed search)
- Users (search for companions, guides)
- Challenges (search challenges by city, category)

**Example Place Index:**
```json
{
  "mappings": {
    "properties": {
      "id": { "type": "keyword" },
      "name": { "type": "text", "analyzer": "standard" },
      "name_chinese": { "type": "text", "analyzer": "ik_max_word" },
      "description": { "type": "text" },
      "category": { "type": "keyword" },
      "city": { "type": "keyword" },
      "location": { "type": "geo_point" },
      "rating": { "type": "float" },
      "tags": { "type": "keyword" },
      "price_level": { "type": "integer" }
    }
  }
}
```

---

## AI/ML Pipeline

### ML Models & Use Cases

#### 1. Recommendation Engine
**Goal:** Personalized place and activity recommendations

**Algorithm:** Collaborative Filtering + Content-Based

**Features:**
- User preferences (interests, past visits)
- Place attributes (category, tags, rating)
- Contextual (location, time, weather, budget)
- Social (what similar users liked)

**Tech Stack:**
- **Library:** Surprise (Python), TensorFlow Recommenders
- **Training:** Offline batch training (daily)
- **Serving:** FastAPI endpoint, cached results

#### 2. Natural Language Processing (Chatbot)
**Goal:** Conversational AI assistant "Xiao You"

**Approach:**
- **Intent Classification:** Fine-tuned BERT model
- **Entity Recognition:** spaCy NER
- **Response Generation:** OpenAI GPT-4 API or fine-tuned LLaMA

**Use Cases:**
- Travel Q&A
- Restaurant recommendations
- Navigation help
- Translation assistance

**Tech Stack:**
- **Framework:** Hugging Face Transformers
- **Deployment:** FastAPI + Docker
- **Inference:** GPU (AWS EC2 g4dn instances)

#### 3. Image Recognition
**Goal:** Identify food dishes, landmarks, Chinese text

**Models:**
- **Food Recognition:** EfficientNet fine-tuned on Chinese food dataset
- **Landmark Recognition:** ResNet + transfer learning
- **OCR:** PaddleOCR or Tesseract

**Pipeline:**
```
Mobile App → Upload Image → S3 Storage
    ↓
ML Service receives image URL
    ↓
Download & Preprocess (resize, normalize)
    ↓
Run inference (TensorFlow Serving)
    ↓
Post-process results (confidence filtering)
    ↓
Return JSON response
```

**Tech Stack:**
- **Framework:** TensorFlow / PyTorch
- **Serving:** TensorFlow Serving or TorchServe
- **Pre-processing:** Pillow, OpenCV

#### 4. Sentiment Analysis
**Goal:** Analyze user feedback, post sentiment

**Use Case:**
- Detect frustrated users → offer help
- Analyze place reviews → calculate sentiment score

**Model:** DistilBERT fine-tuned on travel reviews

**Tech Stack:**
- **Library:** Hugging Face Transformers
- **Training:** Google Colab or AWS SageMaker
- **Serving:** FastAPI

### ML Infrastructure

```
┌─────────────────────────────────────────┐
│         Data Collection Layer           │
│  (User interactions, feedback, logs)    │
└───────────────┬─────────────────────────┘
                │
┌───────────────▼─────────────────────────┐
│         Data Processing (ETL)           │
│  (Apache Airflow, AWS Glue)             │
└───────────────┬─────────────────────────┘
                │
┌───────────────▼─────────────────────────┐
│         Feature Engineering             │
│  (Pandas, scikit-learn)                 │
└───────────────┬─────────────────────────┘
                │
┌───────────────▼─────────────────────────┐
│         Model Training                  │
│  (TensorFlow, PyTorch, Jupyter)         │
└───────────────┬─────────────────────────┘
                │
┌───────────────▼─────────────────────────┐
│         Model Evaluation                │
│  (A/B testing, metrics tracking)        │
└───────────────┬─────────────────────────┘
                │
┌───────────────▼─────────────────────────┐
│         Model Deployment                │
│  (TensorFlow Serving, Docker, K8s)      │
└───────────────┬─────────────────────────┘
                │
┌───────────────▼─────────────────────────┐
│         Monitoring & Feedback           │
│  (MLflow, Prometheus, Grafana)          │
└─────────────────────────────────────────┘
```

---

## Third-Party Integrations

### Maps & Location
- **Baidu Maps API** - Primary for China
- **Google Maps API** - Backup, international
- **OpenStreetMap** - Offline map tiles

### Translation
- **Google Translate API** - Text translation
- **Baidu Translate API** - Chinese specialization
- **Google Cloud Vision API** - OCR
- **Baidu OCR** - Chinese text recognition

### Payment
- **Stripe** - International credit cards
- **WeChat Pay** - In-China payments
- **Alipay** - Alternative payment
- **Apple Pay / Google Pay** - Mobile wallets

### Booking Partners
- **Booking.com Affiliate API**
- **Agoda API**
- **Ctrip/Trip.com API**
- **Airbnb API** (if available)

### Weather
- **OpenWeatherMap API**
- **AccuWeather API**
- **China Meteorological Administration** (official data)

### Communication
- **Firebase Cloud Messaging** - Push notifications
- **Twilio** - SMS (emergency alerts)
- **SendGrid** - Email notifications

### Analytics
- **Firebase Analytics** - Mobile analytics
- **Mixpanel** - User behavior tracking
- **Google Analytics** - Web traffic (future)

### Monitoring
- **Sentry** - Error tracking
- **DataDog** - Infrastructure monitoring
- **New Relic** - APM

---

## Security

### Authentication & Authorization

#### JWT Token Strategy
```javascript
// Access Token (short-lived)
{
  "sub": "user_id",
  "email": "user@example.com",
  "role": "premium",
  "exp": 1640000000, // 15 minutes
  "iat": 1639999100
}

// Refresh Token (long-lived, stored in DB)
{
  "sub": "user_id",
  "type": "refresh",
  "exp": 1672000000, // 7 days
  "jti": "unique_token_id"
}
```

**Flow:**
1. User logs in → Receive access token + refresh token
2. Access token expires → Use refresh token to get new access token
3. Refresh token expires → User must log in again

#### Password Security
- **Hashing:** bcrypt (cost factor: 12)
- **Minimum Requirements:** 8 characters, 1 uppercase, 1 number
- **Rate Limiting:** 5 failed login attempts → 15-minute lockout
- **2FA (Optional):** TOTP (Google Authenticator)

### Data Protection

#### Encryption
- **In Transit:** TLS 1.3 (HTTPS)
- **At Rest:** AES-256 for sensitive data
- **Database:** PostgreSQL encryption at rest
- **Secrets Management:** AWS Secrets Manager or HashiCorp Vault

#### Personal Data (GDPR/CCPA Compliance)
- **Data Minimization:** Collect only necessary data
- **Right to Access:** API endpoint for user data export
- **Right to Deletion:** Full data deletion within 30 days
- **Consent Management:** Clear opt-in for data usage
- **Data Retention:** 2 years for inactive accounts

### API Security

#### Rate Limiting
```
Free Tier:
- 100 requests/minute per IP
- 1000 requests/hour per user

Premium Tier:
- 300 requests/minute per IP
- 5000 requests/hour per user
```

#### Input Validation
- **Schema Validation:** Joi/Zod for all inputs
- **SQL Injection:** Use parameterized queries (ORM)
- **XSS Prevention:** Sanitize all user inputs
- **File Upload:**
  - Max size: 10MB
  - Allowed types: jpg, png, heic
  - Virus scanning (ClamAV)

#### CORS Policy
```javascript
{
  origin: ['https://wanderchina.com', 'https://app.wanderchina.com'],
  credentials: true,
  maxAge: 86400
}
```

### Security Best Practices
- **Principle of Least Privilege:** Minimal database permissions
- **Regular Security Audits:** Quarterly penetration testing
- **Dependency Scanning:** Dependabot, Snyk
- **Secret Rotation:** Every 90 days
- **Logging & Monitoring:** All authentication events logged

---

## DevOps & Infrastructure

### Cloud Provider: AWS (Primary)

**Why AWS?**
- Comprehensive service offerings
- Global infrastructure
- Strong China region support (AWS China operated by Sinnet/NWCD)
- Good pricing for startups
- Extensive documentation

**Alternative:** Alibaba Cloud (for China-only deployment)

### Infrastructure as Code

**Tool:** Terraform

**Repository Structure:**
```
infrastructure/
├── modules/
│   ├── networking/
│   ├── compute/
│   ├── database/
│   └── monitoring/
├── environments/
│   ├── dev/
│   ├── staging/
│   └── production/
└── terraform.tfvars
```

### Containerization: Docker + Kubernetes

**Docker:**
- All services containerized
- Multi-stage builds (smaller images)
- Docker Compose for local development

**Kubernetes (EKS):**
- Auto-scaling based on CPU/memory
- Rolling deployments (zero downtime)
- Health checks and self-healing
- Resource limits and quotas

**Example Deployment:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
    spec:
      containers:
      - name: user-service
        image: wanderchina/user-service:v1.0.0
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-secrets
              key: url
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
```

### CI/CD Pipeline

**Tool:** GitHub Actions

**Workflow:**
```
Code Push → GitHub
    ↓
Run Tests (Jest, PyTest)
    ↓
Lint & Format Check (ESLint, Black)
    ↓
Build Docker Image
    ↓
Push to Container Registry (ECR)
    ↓
Deploy to Staging (Auto)
    ↓
Run Integration Tests
    ↓
Manual Approval
    ↓
Deploy to Production (Rolling)
    ↓
Health Check
    ↓
Rollback if Failed
```

**Example GitHub Action:**
```yaml
name: Deploy Backend Services

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-node@v2
      - run: npm install
      - run: npm test
      - run: npm run lint

  build-and-deploy:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build Docker image
        run: docker build -t user-service .
      - name: Push to ECR
        run: |
          aws ecr get-login-password | docker login --username AWS --password-stdin
          docker push user-service:latest
      - name: Deploy to EKS
        run: kubectl apply -f k8s/user-service.yaml
```

### Monitoring & Observability

#### Application Performance Monitoring (APM)
- **Tool:** DataDog or New Relic
- **Metrics:** Response time, error rate, throughput
- **Alerts:** Slack/PagerDuty for critical issues

#### Logging
- **Tool:** ELK Stack (Elasticsearch, Logstash, Kibana) or CloudWatch
- **Log Levels:** ERROR, WARN, INFO, DEBUG
- **Structured Logging:** JSON format
- **Retention:** 30 days for INFO, 90 days for ERROR

#### Metrics
- **Tool:** Prometheus + Grafana
- **System Metrics:** CPU, memory, disk, network
- **Application Metrics:** Request count, latency, errors
- **Business Metrics:** User signups, challenge completions, revenue

#### Distributed Tracing
- **Tool:** Jaeger or AWS X-Ray
- **Use Case:** Trace requests across microservices

### Backup & Disaster Recovery

**Database Backups:**
- **Frequency:** Daily full backup + continuous WAL archiving
- **Retention:** 30 days
- **Storage:** S3 with versioning
- **Testing:** Monthly restore drills

**Disaster Recovery Plan:**
- **RTO (Recovery Time Objective):** 4 hours
- **RPO (Recovery Point Objective):** 1 hour
- **Multi-Region:** Standby database in different region
- **Failover:** Automated DNS failover

---

## Scalability Strategy

### Horizontal Scaling

**Services:**
- All stateless services scale horizontally
- Load balancer distributes traffic
- Kubernetes auto-scaling based on metrics

**Database:**
- Read replicas for heavy read operations
- Sharding if single DB exceeds 500GB
- Connection pooling (PgBouncer)

**Cache:**
- Redis Cluster for high availability
- Consistent hashing for even distribution

### Performance Optimization

**Backend:**
- **Database Indexing:** Critical queries indexed
- **Query Optimization:** EXPLAIN ANALYZE for slow queries
- **Caching Strategy:** Multi-level (application, database, CDN)
- **Async Processing:** Background jobs for heavy tasks (RabbitMQ)

**Mobile App:**
- **Lazy Loading:** Load data as needed
- **Image Optimization:** WebP format, progressive loading
- **Bundle Size:** Code splitting, tree shaking
- **Offline-First:** Local database for instant access

**API:**
- **GraphQL DataLoader:** Batch and cache database queries
- **Response Compression:** Gzip/Brotli
- **Pagination:** Limit 20-50 items per request
- **CDN:** CloudFlare for static assets

### Load Testing

**Tool:** k6, Apache JMeter, or Gatling

**Scenarios:**
- **Normal Load:** 1,000 concurrent users
- **Peak Load:** 5,000 concurrent users
- **Stress Test:** 10,000+ concurrent users (find breaking point)
- **Spike Test:** Sudden traffic surge

**Acceptance Criteria:**
- 95th percentile response time < 500ms
- Error rate < 0.1%
- Successful auto-scaling

---

## Technology Decision Summary

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| **Mobile App** | Flutter | Cross-platform, performance, smooth animations |
| **Backend API** | Node.js (TypeScript) | Fast development, real-time support, ecosystem |
| **ML Service** | Python (FastAPI) | ML library support, async performance |
| **API Style** | GraphQL + REST | Flexibility, mobile-optimized, simple integrations |
| **Primary Database** | PostgreSQL | ACID, geospatial, JSON support |
| **Cache** | Redis | In-memory speed, rich data structures |
| **Search** | Elasticsearch | Full-text search, geospatial queries |
| **Message Queue** | RabbitMQ | Reliability, async processing |
| **Container** | Docker + Kubernetes | Portability, orchestration, auto-scaling |
| **Cloud** | AWS | Comprehensive, reliable, China support |
| **CI/CD** | GitHub Actions | Integrated, easy to use, cost-effective |
| **Monitoring** | DataDog + Sentry | APM, error tracking, alerting |
| **Maps** | Baidu Maps | Best for China, accurate data |
| **Translation** | Google + Baidu | Quality, language coverage |
| **Analytics** | Firebase + Mixpanel | Mobile-first, user behavior insights |

---

## Next Steps

1. **Approve Architecture:** Review and finalize this document
2. **Set Up Environments:** Dev, Staging, Production
3. **Create Proof of Concept:**
   - Simple Flutter app with API call
   - Basic authentication flow
   - Offline map demo
4. **Database Setup:** PostgreSQL + Redis instances
5. **Repository Structure:** Monorepo vs. multi-repo decision
6. **Developer Onboarding:** Environment setup guide

---

**Document Version:** 1.0
**Last Updated:** 2025-10-22
**Next Review:** Monthly during development
