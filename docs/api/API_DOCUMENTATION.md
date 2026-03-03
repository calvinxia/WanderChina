# WanderChina API Documentation

**Version:** 1.0.0
**Base URL:** `https://api.wanderchina.com/v1`
**Authentication:** Bearer Token (JWT)

---

## Table of Contents

### WanderChina Backend APIs
1. [Authentication](#authentication)
2. [User Management](#user-management)
3. [Travel & Trips](#travel--trips)
4. [Places & Discovery](#places--discovery)
5. [Maps & Navigation](#maps--navigation)
6. [Translation](#translation)
7. [Budget & Expenses](#budget--expenses)
8. [Community & Social](#community--social)
9. [Gamification](#gamification)
10. [Safety & Emergency](#safety--emergency)
11. [Error Codes](#error-codes)

### Third-Party Integrations
12. [Third-Party API Integration Guide](#third-party-api-integration-guide)
    - [Maps & Navigation APIs](#-maps--navigation-apis) (高德地图 Amap)
    - [Translation APIs](#-translation-apis) (百度翻译 Baidu)
    - [OCR APIs](#-ocr-optical-character-recognition-apis) (百度 OCR)
    - [Weather APIs](#-weather-apis) (和风天气 QWeather)
    - [Payment APIs](#-payment-apis) (WeChat Pay, Alipay, Stripe)
    - [Analytics APIs](#-analytics-apis) (Google Analytics, 友盟+)
    - [Cost Estimation](#-cost-estimation)
    - [Implementation Priority](#-implementation-priority)
    - [API Keys Management](#-api-keys-management)

---

## Authentication

### Register New User

**Endpoint:** `POST /auth/register`

**Description:** Create a new user account

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123!",
  "full_name": "John Doe",
  "nationality": "USA",
  "language": "en"
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "user@example.com",
      "full_name": "John Doe",
      "created_at": "2025-10-22T10:30:00Z"
    },
    "tokens": {
      "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "expires_in": 900
    }
  }
}
```

**Errors:**
- `400 Bad Request` - Invalid input
- `409 Conflict` - Email already exists

---

### Login

**Endpoint:** `POST /auth/login`

**Description:** Authenticate user and get tokens

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123!"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "user@example.com",
      "full_name": "John Doe",
      "profile_picture": "https://cdn.wanderchina.com/avatars/user123.jpg",
      "premium_until": null,
      "total_points": 1250
    },
    "tokens": {
      "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "expires_in": 900
    }
  }
}
```

**Errors:**
- `401 Unauthorized` - Invalid credentials
- `403 Forbidden` - Account suspended

---

### Social Login

**Endpoint:** `POST /auth/social-login`

**Description:** Authenticate using social providers

**Request Body:**
```json
{
  "provider": "google",
  "id_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6Ijg5M..."
}
```

**Supported Providers:** `google`, `facebook`

**Response:** `200 OK` (same as login)

---

### Refresh Token

**Endpoint:** `POST /auth/refresh`

**Description:** Get new access token using refresh token

**Request Body:**
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 900
  }
}
```

---

### Logout

**Endpoint:** `POST /auth/logout`

**Authentication:** Required

**Description:** Invalidate refresh token

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

---

## User Management

### Get Current User Profile

**Endpoint:** `GET /users/me`

**Authentication:** Required

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "username": "traveler123",
    "full_name": "John Doe",
    "profile_picture": "https://cdn.wanderchina.com/avatars/user123.jpg",
    "bio": "Backpacker exploring Asia",
    "nationality": "USA",
    "languages": ["en", "zh"],
    "travel_style": "backpacker",
    "interests": ["food", "hiking", "photography"],
    "premium_until": null,
    "total_points": 1250,
    "membership_tier": "bronze",
    "stats": {
      "places_visited": 12,
      "achievements_unlocked": 8,
      "challenges_completed": 5,
      "posts_count": 23
    },
    "created_at": "2025-06-15T10:30:00Z",
    "last_login": "2025-10-22T08:15:00Z"
  }
}
```

---

### Update User Profile

**Endpoint:** `PATCH /users/me`

**Authentication:** Required

**Request Body:**
```json
{
  "full_name": "John Smith",
  "bio": "Adventure seeker and food lover",
  "interests": ["food", "culture", "nightlife"],
  "languages": ["en", "zh", "es"]
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "full_name": "John Smith",
    "bio": "Adventure seeker and food lover",
    "updated_at": "2025-10-22T10:45:00Z"
  }
}
```

---

### Upload Profile Picture

**Endpoint:** `POST /users/me/avatar`

**Authentication:** Required

**Content-Type:** `multipart/form-data`

**Request:**
```
FormData:
  - file: [image file]
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "profile_picture": "https://cdn.wanderchina.com/avatars/user123_new.jpg"
  }
}
```

---

### Get User by ID

**Endpoint:** `GET /users/{user_id}`

**Authentication:** Required

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "username": "traveler123",
    "full_name": "John Doe",
    "profile_picture": "https://cdn.wanderchina.com/avatars/user123.jpg",
    "bio": "Backpacker exploring Asia",
    "stats": {
      "places_visited": 12,
      "achievements_unlocked": 8,
      "followers_count": 45,
      "following_count": 32
    },
    "is_following": false,
    "is_premium": false
  }
}
```

---

## Travel & Trips

### Create Trip

**Endpoint:** `POST /trips`

**Authentication:** Required

**Request Body:**
```json
{
  "title": "Beijing Adventure",
  "description": "3-day exploration of Beijing",
  "start_date": "2025-11-01",
  "end_date": "2025-11-03",
  "budget": 3000,
  "cities": [
    {
      "name": "Beijing",
      "days": 3
    }
  ],
  "is_public": false
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "data": {
    "id": "660e8400-e29b-41d4-a716-446655440001",
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "Beijing Adventure",
    "description": "3-day exploration of Beijing",
    "start_date": "2025-11-01",
    "end_date": "2025-11-03",
    "budget": 3000.00,
    "total_spent": 0.00,
    "status": "planning",
    "cities": [
      {
        "name": "Beijing",
        "days": 3
      }
    ],
    "created_at": "2025-10-22T11:00:00Z"
  }
}
```

---

### Get User's Trips

**Endpoint:** `GET /trips`

**Authentication:** Required

**Query Parameters:**
- `status` (optional): `planning`, `ongoing`, `completed`
- `limit` (optional): Default 20
- `offset` (optional): Default 0

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "trips": [
      {
        "id": "660e8400-e29b-41d4-a716-446655440001",
        "title": "Beijing Adventure",
        "start_date": "2025-11-01",
        "end_date": "2025-11-03",
        "status": "planning",
        "budget": 3000.00,
        "total_spent": 0.00,
        "cities": ["Beijing"],
        "created_at": "2025-10-22T11:00:00Z"
      }
    ],
    "pagination": {
      "total": 5,
      "limit": 20,
      "offset": 0
    }
  }
}
```

---

### Get Trip by ID

**Endpoint:** `GET /trips/{trip_id}`

**Authentication:** Required

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "id": "660e8400-e29b-41d4-a716-446655440001",
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "Beijing Adventure",
    "description": "3-day exploration of Beijing",
    "start_date": "2025-11-01",
    "end_date": "2025-11-03",
    "budget": 3000.00,
    "total_spent": 150.00,
    "status": "planning",
    "cities": [
      {
        "name": "Beijing",
        "days": 3
      }
    ],
    "itineraries": [
      {
        "day_number": 1,
        "date": "2025-11-01",
        "activities": [
          {
            "time": "09:00",
            "activity": "Visit Forbidden City",
            "location": "Forbidden City",
            "cost": 60.00,
            "notes": "Buy tickets in advance"
          }
        ]
      }
    ],
    "created_at": "2025-10-22T11:00:00Z",
    "updated_at": "2025-10-22T11:30:00Z"
  }
}
```

---

### Update Trip

**Endpoint:** `PATCH /trips/{trip_id}`

**Authentication:** Required

**Request Body:**
```json
{
  "title": "Beijing & Great Wall Adventure",
  "budget": 3500,
  "status": "ongoing"
}
```

**Response:** `200 OK`

---

### Delete Trip

**Endpoint:** `DELETE /trips/{trip_id}`

**Authentication:** Required

**Response:** `204 No Content`

---

### Generate AI Itinerary

**Endpoint:** `POST /trips/{trip_id}/generate-itinerary`

**Authentication:** Required

**Request Body:**
```json
{
  "interests": ["history", "food", "culture"],
  "budget_per_day": 500,
  "pace": "moderate"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "itinerary": [
      {
        "day": 1,
        "date": "2025-11-01",
        "activities": [
          {
            "time": "09:00",
            "title": "Forbidden City",
            "duration": 180,
            "cost": 60,
            "type": "attraction"
          },
          {
            "time": "12:30",
            "title": "Peking Duck Lunch",
            "duration": 90,
            "cost": 200,
            "type": "food"
          }
        ],
        "total_cost": 560
      }
    ]
  }
}
```

---

## Places & Discovery

### Search Places

**Endpoint:** `GET /places`

**Authentication:** Optional (better recommendations if authenticated)

**Query Parameters:**
- `query` (optional): Search text
- `category` (optional): `attraction`, `restaurant`, `hotel`, etc.
- `lat` (required): Latitude
- `lng` (required): Longitude
- `radius` (optional): In meters, default 5000
- `rating_min` (optional): Minimum rating (1-5)
- `price_level` (optional): 1-4
- `limit` (optional): Default 20
- `offset` (optional): Default 0

**Example:** `GET /places?lat=39.9&lng=116.4&radius=5000&category=restaurant&rating_min=4`

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "places": [
      {
        "id": "770e8400-e29b-41d4-a716-446655440002",
        "name": "Forbidden City",
        "name_chinese": "故宫",
        "category": "attraction",
        "subcategory": "historical_site",
        "description": "Former Chinese imperial palace...",
        "address": "4 Jingshan Front St, Dongcheng, Beijing",
        "city": "Beijing",
        "location": {
          "lat": 39.9163,
          "lng": 116.3972
        },
        "distance": 1250,
        "photos": [
          "https://cdn.wanderchina.com/places/forbidden-city-1.jpg"
        ],
        "rating": 4.8,
        "review_count": 1250,
        "price_level": 2,
        "opening_hours": {
          "monday": "08:30-17:00",
          "tuesday": "08:30-17:00"
        },
        "tags": ["UNESCO", "must-see", "historical"],
        "is_saved": false
      }
    ],
    "pagination": {
      "total": 45,
      "limit": 20,
      "offset": 0
    }
  }
}
```

---

### Get Place Details

**Endpoint:** `GET /places/{place_id}`

**Authentication:** Optional

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "id": "770e8400-e29b-41d4-a716-446655440002",
    "name": "Forbidden City",
    "name_chinese": "故宫",
    "category": "attraction",
    "subcategory": "historical_site",
    "description": "Detailed description...",
    "address": "4 Jingshan Front St, Dongcheng, Beijing",
    "city": "Beijing",
    "province": "Beijing",
    "location": {
      "lat": 39.9163,
      "lng": 116.3972
    },
    "photos": [
      "https://cdn.wanderchina.com/places/forbidden-city-1.jpg",
      "https://cdn.wanderchina.com/places/forbidden-city-2.jpg"
    ],
    "rating": 4.8,
    "review_count": 1250,
    "price_level": 2,
    "estimated_cost": 60,
    "opening_hours": {
      "monday": "08:30-17:00",
      "tuesday": "08:30-17:00",
      "closed": ["monday"]
    },
    "tags": ["UNESCO", "must-see", "historical"],
    "tips": [
      "Buy tickets online in advance",
      "Visit early to avoid crowds",
      "Allow 3-4 hours for full tour"
    ],
    "best_time_to_visit": "Morning (9-11am) or late afternoon",
    "reviews": [
      {
        "user": {
          "id": "550e8400-e29b-41d4-a716-446655440000",
          "username": "traveler123",
          "avatar": "https://cdn.wanderchina.com/avatars/user123.jpg"
        },
        "rating": 5,
        "comment": "Absolutely stunning!",
        "photos": ["url1", "url2"],
        "created_at": "2025-10-15T14:20:00Z"
      }
    ],
    "nearby_places": [
      {
        "id": "770e8400-e29b-41d4-a716-446655440003",
        "name": "Tiananmen Square",
        "distance": 500,
        "rating": 4.5
      }
    ],
    "is_saved": false,
    "check_in_count": 3245
  }
}
```

---

### Get Recommendations

**Endpoint:** `GET /discover/recommendations`

**Authentication:** Required

**Query Parameters:**
- `lat` (required): Current latitude
- `lng` (required): Current longitude
- `type` (optional): `for_you`, `nearby`, `trending`
- `limit` (optional): Default 10

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "recommendations": [
      {
        "place": {
          "id": "770e8400-e29b-41d4-a716-446655440002",
          "name": "Forbidden City",
          "category": "attraction",
          "rating": 4.8,
          "distance": 1250,
          "photo": "https://cdn.wanderchina.com/places/forbidden-city-1.jpg"
        },
        "reason": "Matches your interest in history",
        "score": 0.95
      }
    ]
  }
}
```

---

## Maps & Navigation

### Get Offline Map List

**Endpoint:** `GET /maps/cities`

**Authentication:** Required

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "cities": [
      {
        "id": "city_beijing",
        "name": "Beijing",
        "name_chinese": "北京",
        "sizes": {
          "small": {
            "name": "City Center",
            "size_mb": 50,
            "bounds": {
              "north": 39.99,
              "south": 39.85,
              "east": 116.50,
              "west": 116.30
            }
          },
          "medium": {
            "name": "Full City",
            "size_mb": 200,
            "bounds": {
              "north": 40.15,
              "south": 39.70,
              "east": 116.70,
              "west": 116.10
            }
          },
          "large": {
            "name": "Metro Area",
            "size_mb": 500
          }
        },
        "version": "2025.10",
        "last_updated": "2025-10-15T00:00:00Z"
      }
    ]
  }
}
```

---

### Download Offline Map

**Endpoint:** `GET /maps/{city_id}/tiles`

**Authentication:** Required

**Query Parameters:**
- `size`: `small`, `medium`, `large`
- `version` (optional): Specific version

**Response:** Binary data (compressed tiles)

---

### Get Directions

**Endpoint:** `POST /maps/directions`

**Authentication:** Required

**Request Body:**
```json
{
  "origin": {
    "lat": 39.9163,
    "lng": 116.3972
  },
  "destination": {
    "lat": 39.9042,
    "lng": 116.4074
  },
  "mode": "walking",
  "alternatives": true
}
```

**Modes:** `walking`, `driving`, `transit`, `bicycling`

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "routes": [
      {
        "distance": 5200,
        "duration": 720,
        "mode": "walking",
        "steps": [
          {
            "distance": 450,
            "duration": 80,
            "instruction": "Head south on Jingshan Front St",
            "polyline": "encoded_polyline_string",
            "start_location": {
              "lat": 39.9163,
              "lng": 116.3972
            },
            "end_location": {
              "lat": 39.9120,
              "lng": 116.3975
            }
          }
        ],
        "overview_polyline": "encoded_overview_polyline"
      }
    ]
  }
}
```

---

## Translation

### Translate Text

**Endpoint:** `POST /translation/text`

**Authentication:** Required

**Request Body:**
```json
{
  "text": "你好，请问洗手间在哪里?",
  "source_lang": "zh",
  "target_lang": "en"
}
```

**Languages:** `zh` (Chinese), `en` (English), `es` (Spanish), `fr` (French), etc.

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "translation": "Hello, where is the restroom?",
    "source_lang": "zh",
    "target_lang": "en",
    "source_lang_detected": "zh",
    "confidence": 0.98
  }
}
```

---

### OCR Translation (Camera)

**Endpoint:** `POST /translation/ocr`

**Authentication:** Required

**Content-Type:** `multipart/form-data`

**Request:**
```
FormData:
  - image: [image file]
  - source_lang: zh
  - target_lang: en
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "detections": [
      {
        "text": "北京烤鸭",
        "translation": "Beijing Roast Duck",
        "bounding_box": {
          "x": 120,
          "y": 450,
          "width": 200,
          "height": 50
        },
        "confidence": 0.95
      },
      {
        "text": "¥188",
        "translation": "¥188",
        "bounding_box": {
          "x": 120,
          "y": 510,
          "width": 80,
          "height": 40
        },
        "confidence": 0.99
      }
    ]
  }
}
```

---

### Get Phrasebook

**Endpoint:** `GET /translation/phrasebook`

**Authentication:** Optional

**Query Parameters:**
- `category` (optional): `restaurant`, `hotel`, `transport`, etc.
- `lang` (optional): Target language code, default `en`

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "categories": [
      {
        "id": "restaurant",
        "name": "Restaurant & Food",
        "icon": "🍴",
        "phrases": [
          {
            "id": "rest_001",
            "english": "I'd like to order",
            "chinese": "我想点菜",
            "pinyin": "wǒ xiǎng diǎn cài",
            "audio_url": "https://cdn.wanderchina.com/phrases/rest_001.mp3"
          }
        ]
      }
    ]
  }
}
```

---

## Budget & Expenses

### Add Expense

**Endpoint:** `POST /expenses`

**Authentication:** Required

**Request Body:**
```json
{
  "trip_id": "660e8400-e29b-41d4-a716-446655440001",
  "category": "food",
  "amount": 150.00,
  "currency": "CNY",
  "description": "Lunch at noodle shop",
  "place_id": "770e8400-e29b-41d4-a716-446655440005",
  "expense_date": "2025-10-22T12:30:00Z",
  "receipt_photo": "base64_encoded_image"
}
```

**Categories:** `food`, `accommodation`, `transport`, `attractions`, `shopping`, `health`, `communication`, `other`

**Response:** `201 Created`
```json
{
  "success": true,
  "data": {
    "id": "880e8400-e29b-41d4-a716-446655440006",
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "trip_id": "660e8400-e29b-41d4-a716-446655440001",
    "category": "food",
    "amount": 150.00,
    "currency": "CNY",
    "amount_usd": 21.48,
    "description": "Lunch at noodle shop",
    "receipt_photo": "https://cdn.wanderchina.com/receipts/receipt123.jpg",
    "expense_date": "2025-10-22T12:30:00Z",
    "created_at": "2025-10-22T12:35:00Z"
  }
}
```

---

### Get Expenses

**Endpoint:** `GET /expenses`

**Authentication:** Required

**Query Parameters:**
- `trip_id` (optional): Filter by trip
- `category` (optional): Filter by category
- `start_date` (optional): YYYY-MM-DD
- `end_date` (optional): YYYY-MM-DD
- `limit` (optional): Default 50
- `offset` (optional): Default 0

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "expenses": [
      {
        "id": "880e8400-e29b-41d4-a716-446655440006",
        "category": "food",
        "amount": 150.00,
        "currency": "CNY",
        "description": "Lunch at noodle shop",
        "expense_date": "2025-10-22T12:30:00Z"
      }
    ],
    "summary": {
      "total": 2250.00,
      "currency": "CNY",
      "total_usd": 322.20,
      "by_category": {
        "food": 900.00,
        "accommodation": 800.00,
        "transport": 350.00,
        "attractions": 200.00
      }
    },
    "pagination": {
      "total": 23,
      "limit": 50,
      "offset": 0
    }
  }
}
```

---

### Get Budget Summary

**Endpoint:** `GET /expenses/summary`

**Authentication:** Required

**Query Parameters:**
- `trip_id` (optional): Filter by trip
- `period`: `today`, `week`, `month`, `trip`

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "period": "week",
    "total_budget": 3000.00,
    "total_spent": 2250.00,
    "remaining": 750.00,
    "percentage_used": 75,
    "daily_average": 321.43,
    "days_left": 7,
    "breakdown": {
      "food": {
        "amount": 900.00,
        "percentage": 40
      },
      "accommodation": {
        "amount": 800.00,
        "percentage": 35.6
      }
    }
  }
}
```

---

### Currency Exchange Rates

**Endpoint:** `GET /currency/rates`

**Authentication:** Optional

**Query Parameters:**
- `base`: Base currency code (default: CNY)
- `symbols`: Comma-separated target currencies

**Example:** `GET /currency/rates?base=CNY&symbols=USD,EUR,GBP`

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "base": "CNY",
    "date": "2025-10-22",
    "rates": {
      "USD": 0.1432,
      "EUR": 0.1321,
      "GBP": 0.1156
    },
    "last_updated": "2025-10-22T00:00:00Z"
  }
}
```

---

## Community & Social

### Get Community Feed

**Endpoint:** `GET /community/feed`

**Authentication:** Required

**Query Parameters:**
- `type`: `for_you`, `following`, `nearby`, `trending`
- `lat` (optional): For `nearby` type
- `lng` (optional): For `nearby` type
- `limit` (optional): Default 20
- `offset` (optional): Default 0

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "posts": [
      {
        "id": "990e8400-e29b-41d4-a716-446655440007",
        "user": {
          "id": "550e8400-e29b-41d4-a716-446655440000",
          "username": "traveler123",
          "full_name": "John Doe",
          "avatar": "https://cdn.wanderchina.com/avatars/user123.jpg"
        },
        "content": "Just had amazing Peking duck at this place! 🦆",
        "images": [
          "https://cdn.wanderchina.com/posts/post123_1.jpg"
        ],
        "location": {
          "id": "770e8400-e29b-41d4-a716-446655440002",
          "name": "Quanjude Roast Duck",
          "city": "Beijing"
        },
        "tags": ["beijing", "food"],
        "post_type": "photo",
        "likes_count": 24,
        "comments_count": 5,
        "is_liked": false,
        "is_saved": false,
        "created_at": "2025-10-22T14:30:00Z"
      }
    ],
    "pagination": {
      "total": 145,
      "limit": 20,
      "offset": 0
    }
  }
}
```

---

### Create Post

**Endpoint:** `POST /community/posts`

**Authentication:** Required

**Content-Type:** `multipart/form-data`

**Request:**
```
FormData:
  - content: "Just had amazing Peking duck!"
  - images[]: [image file 1]
  - images[]: [image file 2]
  - location_id: "770e8400-e29b-41d4-a716-446655440002"
  - tags: ["beijing", "food"]
  - post_type: "photo"
```

**Response:** `201 Created`
```json
{
  "success": true,
  "data": {
    "id": "990e8400-e29b-41d4-a716-446655440007",
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "content": "Just had amazing Peking duck!",
    "images": [
      "https://cdn.wanderchina.com/posts/post123_1.jpg"
    ],
    "location_id": "770e8400-e29b-41d4-a716-446655440002",
    "tags": ["beijing", "food"],
    "post_type": "photo",
    "created_at": "2025-10-22T14:30:00Z"
  }
}
```

---

### Like Post

**Endpoint:** `POST /community/posts/{post_id}/like`

**Authentication:** Required

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "post_id": "990e8400-e29b-41d4-a716-446655440007",
    "is_liked": true,
    "likes_count": 25
  }
}
```

---

### Unlike Post

**Endpoint:** `DELETE /community/posts/{post_id}/like`

**Authentication:** Required

**Response:** `200 OK`

---

### Comment on Post

**Endpoint:** `POST /community/posts/{post_id}/comments`

**Authentication:** Required

**Request Body:**
```json
{
  "content": "Looks delicious! Where is this place?",
  "parent_comment_id": null
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "data": {
    "id": "aa0e8400-e29b-41d4-a716-446655440008",
    "post_id": "990e8400-e29b-41d4-a716-446655440007",
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "username": "traveler123",
      "avatar": "https://cdn.wanderchina.com/avatars/user123.jpg"
    },
    "content": "Looks delicious! Where is this place?",
    "likes_count": 0,
    "created_at": "2025-10-22T14:35:00Z"
  }
}
```

---

### Get Comments

**Endpoint:** `GET /community/posts/{post_id}/comments`

**Authentication:** Optional

**Query Parameters:**
- `limit` (optional): Default 20
- `offset` (optional): Default 0

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "comments": [
      {
        "id": "aa0e8400-e29b-41d4-a716-446655440008",
        "user": {
          "id": "550e8400-e29b-41d4-a716-446655440000",
          "username": "traveler123",
          "avatar": "https://cdn.wanderchina.com/avatars/user123.jpg"
        },
        "content": "Looks delicious!",
        "likes_count": 2,
        "replies_count": 1,
        "created_at": "2025-10-22T14:35:00Z"
      }
    ],
    "pagination": {
      "total": 5,
      "limit": 20,
      "offset": 0
    }
  }
}
```

---

## Gamification

### Get Challenges

**Endpoint:** `GET /challenges`

**Authentication:** Required

**Query Parameters:**
- `city` (optional): Filter by city
- `category` (optional): `heritage`, `food`, `nature`, `culture`
- `difficulty` (optional): `beginner`, `intermediate`, `advanced`
- `status` (optional): `available`, `in_progress`, `completed`

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "challenges": [
      {
        "id": "bb0e8400-e29b-41d4-a716-446655440009",
        "title": "Beijing Heritage Challenge",
        "description": "Visit 5 key historical landmarks in Beijing",
        "city": "Beijing",
        "category": "heritage",
        "difficulty": "intermediate",
        "total_points": 500,
        "estimated_time_hours": 8,
        "checkpoints": [
          {
            "order": 1,
            "place": {
              "id": "770e8400-e29b-41d4-a716-446655440002",
              "name": "Forbidden City",
              "photo": "url"
            },
            "points": 100
          }
        ],
        "badge_image": "https://cdn.wanderchina.com/badges/beijing-heritage.png",
        "completion_count": 3245,
        "user_status": {
          "status": "in_progress",
          "progress": 60,
          "checkpoints_completed": 3,
          "points_earned": 300
        }
      }
    ]
  }
}
```

---

### Start Challenge

**Endpoint:** `POST /challenges/{challenge_id}/start`

**Authentication:** Required

**Response:** `201 Created`
```json
{
  "success": true,
  "data": {
    "user_challenge_id": "cc0e8400-e29b-41d4-a716-446655440010",
    "challenge_id": "bb0e8400-e29b-41d4-a716-446655440009",
    "status": "in_progress",
    "started_at": "2025-10-22T15:00:00Z"
  }
}
```

---

### Check-in at Checkpoint

**Endpoint:** `POST /challenges/{challenge_id}/checkin`

**Authentication:** Required

**Request Body:**
```json
{
  "checkpoint_id": "checkpoint_001",
  "lat": 39.9163,
  "lng": 116.3972,
  "photo": "base64_encoded_image"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "checkpoint_completed": true,
    "points_earned": 100,
    "total_points": 300,
    "progress": 60,
    "next_checkpoint": {
      "name": "Temple of Heaven",
      "distance": 3200
    }
  }
}
```

---

### Get Achievements

**Endpoint:** `GET /achievements`

**Authentication:** Required

**Query Parameters:**
- `category` (optional): `explorer`, `foodie`, `social`, etc.
- `status` (optional): `locked`, `unlocked`

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "achievements": [
      {
        "id": "dd0e8400-e29b-41d4-a716-446655440011",
        "name": "First Steps",
        "description": "Visit your first place in China",
        "category": "explorer",
        "rarity": "common",
        "badge_image": "https://cdn.wanderchina.com/badges/first-steps.png",
        "points_reward": 50,
        "is_unlocked": true,
        "unlocked_at": "2025-10-15T10:20:00Z"
      },
      {
        "id": "dd0e8400-e29b-41d4-a716-446655440012",
        "name": "Temple Seeker",
        "description": "Visit 10 temples",
        "category": "explorer",
        "rarity": "rare",
        "badge_image": "https://cdn.wanderchina.com/badges/temple-seeker.png",
        "points_reward": 200,
        "is_unlocked": false,
        "progress": {
          "current": 7,
          "target": 10
        }
      }
    ]
  }
}
```

---

### Get Leaderboard

**Endpoint:** `GET /leaderboard`

**Authentication:** Required

**Query Parameters:**
- `scope`: `global`, `friends`, `city`
- `period`: `weekly`, `monthly`, `all_time`
- `city` (required if scope=city): City name
- `limit` (optional): Default 50

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "leaderboard": [
      {
        "rank": 1,
        "user": {
          "id": "550e8400-e29b-41d4-a716-446655440000",
          "username": "traveler123",
          "avatar": "https://cdn.wanderchina.com/avatars/user123.jpg"
        },
        "points": 5420,
        "challenges_completed": 12,
        "badges_count": 23
      }
    ],
    "current_user": {
      "rank": 45,
      "points": 1250
    }
  }
}
```

---

## Safety & Emergency

### Send SOS Alert

**Endpoint:** `POST /emergency/alert`

**Authentication:** Required

**Request Body:**
```json
{
  "location": {
    "lat": 39.9163,
    "lng": 116.3972
  },
  "emergency_type": "medical"
}
```

**Emergency Types:** `medical`, `police`, `lost`, `other`

**Response:** `201 Created`
```json
{
  "success": true,
  "data": {
    "alert_id": "ee0e8400-e29b-41d4-a716-446655440013",
    "sent_to_contacts": 3,
    "nearest_hospital": {
      "name": "Beijing United Family Hospital",
      "distance": 1200,
      "phone": "+86-10-5927-7000"
    },
    "nearest_police": {
      "name": "Dongcheng Police Station",
      "distance": 800,
      "phone": "110"
    },
    "embassy": {
      "name": "U.S. Embassy Beijing",
      "distance": 3500,
      "phone": "+86-10-8531-3000"
    }
  }
}
```

---

### Start Location Sharing

**Endpoint:** `POST /location/share`

**Authentication:** Required

**Request Body:**
```json
{
  "contacts": [
    "user_id_1",
    "+86-123-4567-8900"
  ],
  "duration_hours": 8
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "data": {
    "share_id": "ff0e8400-e29b-41d4-a716-446655440014",
    "share_url": "https://wanderchina.com/share/location/ff0e8400",
    "expires_at": "2025-10-22T23:00:00Z",
    "recipients": [
      {
        "type": "app_user",
        "user_id": "user_id_1",
        "notified": true
      },
      {
        "type": "sms",
        "phone": "+86-123-4567-8900",
        "sent": true
      }
    ]
  }
}
```

---

### Get Safety Score

**Endpoint:** `GET /safety/score`

**Authentication:** Optional

**Query Parameters:**
- `lat` (required): Latitude
- `lng` (required): Longitude
- `time` (optional): ISO timestamp, default now

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "location": {
      "lat": 39.9163,
      "lng": 116.3972,
      "area": "Dongcheng District"
    },
    "safety_score": 4.5,
    "rating": "safe",
    "factors": {
      "crime_rate": "low",
      "tourist_traffic": "high",
      "time_of_day": "day",
      "lighting": "good"
    },
    "alerts": [
      {
        "type": "scam_alert",
        "severity": "medium",
        "title": "Tea House Scam",
        "description": "Be cautious of friendly strangers inviting you to tea houses",
        "reported_at": "2025-10-20T14:00:00Z"
      }
    ],
    "recommendations": [
      "This area is generally safe during daytime",
      "Keep valuables secure in crowded areas"
    ]
  }
}
```

---

## Error Codes

### HTTP Status Codes

| Code | Meaning | Description |
|------|---------|-------------|
| 200 | OK | Request succeeded |
| 201 | Created | Resource created successfully |
| 204 | No Content | Request succeeded, no content to return |
| 400 | Bad Request | Invalid request parameters |
| 401 | Unauthorized | Authentication required or failed |
| 403 | Forbidden | Authenticated but not authorized |
| 404 | Not Found | Resource not found |
| 409 | Conflict | Resource conflict (e.g., duplicate) |
| 422 | Unprocessable Entity | Validation error |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server error |
| 503 | Service Unavailable | Temporary server issue |

### Error Response Format

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format"
      },
      {
        "field": "password",
        "message": "Password must be at least 8 characters"
      }
    ]
  }
}
```

### Common Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `INVALID_REQUEST` | 400 | Malformed request |
| `VALIDATION_ERROR` | 422 | Input validation failed |
| `UNAUTHORIZED` | 401 | Not authenticated |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `CONFLICT` | 409 | Resource already exists |
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Server error |
| `SERVICE_UNAVAILABLE` | 503 | Temporary unavailability |
| `INVALID_TOKEN` | 401 | JWT token invalid or expired |
| `EMAIL_EXISTS` | 409 | Email already registered |
| `WEAK_PASSWORD` | 422 | Password doesn't meet requirements |
| `INSUFFICIENT_POINTS` | 403 | Not enough points for redemption |
| `LOCATION_REQUIRED` | 400 | GPS location needed |
| `SUBSCRIPTION_REQUIRED` | 403 | Premium feature, subscription needed |

---

## Rate Limiting

**Free Tier:**
- 100 requests per minute per IP
- 1,000 requests per hour per user

**Premium Tier:**
- 300 requests per minute per IP
- 5,000 requests per hour per user

**Rate Limit Headers:**
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640000000
```

**Rate Limit Exceeded Response:**
```json
{
  "success": false,
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests. Please try again later.",
    "retry_after": 60
  }
}
```

---

## Pagination

**Query Parameters:**
- `limit`: Items per page (max 100, default 20)
- `offset`: Number of items to skip (default 0)

**Response Format:**
```json
{
  "success": true,
  "data": {
    "items": [...],
    "pagination": {
      "total": 245,
      "limit": 20,
      "offset": 0,
      "has_more": true
    }
  }
}
```

---

## Versioning

API versioning is done through the URL path:
- Current: `/v1/`
- Future: `/v2/`, `/v3/`, etc.

---

## Changelog

### Version 1.0.0 (2025-10-22)
- Initial API release
- All MVP endpoints implemented

---

## Third-Party API Integration Guide

WanderChina integrates with various third-party APIs to provide comprehensive travel services. This section documents all external API dependencies and their usage.

### Overview

| Service Category | Provider | Usage | Status |
|-----------------|----------|-------|--------|
| Maps & Navigation | 高德地图 (Amap) | Primary map provider for China | ⭐ Recommended |
| Translation | 百度翻译 (Baidu Translate) | Text and OCR translation | ⭐ Recommended |
| OCR | 百度 OCR | Image text recognition | ⭐ Recommended |
| Weather | 和风天气 (QWeather) | Real-time weather data | ⭐ Recommended |
| Authentication | Supabase Auth | User authentication | ✅ Implemented |
| Payment (China) | WeChat Pay / Alipay | China payment processing | 🔜 Planned |
| Payment (Global) | Stripe | International payments | 🔜 Planned |
| Analytics | Google Analytics / 友盟+ | User behavior tracking | 🔜 Planned |

---

### 🗺️ Maps & Navigation APIs

#### **高德地图 (Amap/AutoNavi)** - Primary Choice for China

**Use Cases:**
- Map display and interaction
- POI search (attractions, restaurants, hotels)
- Route planning (walking, driving, transit, cycling)
- Geocoding and reverse geocoding
- Offline map downloads
- Real-time traffic information

**API Documentation:** https://lbs.amap.com/api/

**Flutter Integration:**
```yaml
dependencies:
  amap_flutter_map: ^3.0.0
  amap_flutter_location: ^3.0.0
```

**Key Endpoints:**
- **POI Search:** `https://restapi.amap.com/v3/place/text`
  ```
  GET /v3/place/text?key={key}&keywords={keywords}&city={city}
  ```

- **Route Planning:** `https://restapi.amap.com/v3/direction/walking`
  ```
  GET /v3/direction/walking?key={key}&origin={lng,lat}&destination={lng,lat}
  ```

- **Geocoding:** `https://restapi.amap.com/v3/geocode/geo`
  ```
  GET /v3/geocode/geo?key={key}&address={address}
  ```

**Rate Limits:**
- Free tier: 300,000 requests/day
- Personal developer: 100 requests/minute

**Pricing:**
- Free: ¥0 (up to 300k/day)
- Standard: ¥100-500/month
- Enterprise: Custom pricing

**Configuration:**
```dart
// lib/config/api_keys.dart
class ApiKeys {
  static const String amapApiKey = 'YOUR_AMAP_KEY';
  static const String amapSecurityCode = 'YOUR_SECURITY_CODE';
}
```

**Alternative: Google Maps** (for international users)
- Use when user location is outside China
- Flutter plugin: `google_maps_flutter`
- Free tier: $200/month credit

---

### 🈯 Translation APIs

#### **百度翻译 API (Baidu Translate)** - Primary Choice

**Use Cases:**
- Text translation (200+ language pairs)
- Auto language detection
- Batch translation
- Domain-specific translation (travel, food, medical)

**API Documentation:** https://fanyi-api.baidu.com/doc/21

**Request Example:**
```http
POST https://fanyi-api.baidu.com/api/trans/vip/translate
Content-Type: application/x-www-form-urlencoded

q=你好&from=zh&to=en&appid={appid}&salt={salt}&sign={sign}
```

**Response:**
```json
{
  "from": "zh",
  "to": "en",
  "trans_result": [
    {
      "src": "你好",
      "dst": "Hello"
    }
  ]
}
```

**Rate Limits:**
- Free tier: 50,000 characters/month
- Standard: 1 million characters/month (¥49)
- Advanced: Unlimited (¥0.004/character)

**Flutter Implementation:**
```dart
// lib/services/translation_service.dart
import 'package:crypto/crypto.dart';
import 'dart:convert';

class BaiduTranslationService {
  static const String appId = 'YOUR_APP_ID';
  static const String secretKey = 'YOUR_SECRET_KEY';
  static const String apiUrl = 'https://fanyi-api.baidu.com/api/trans/vip/translate';

  Future<String> translate(String text, String from, String to) async {
    final salt = DateTime.now().millisecondsSinceEpoch.toString();
    final sign = _generateSign(text, salt);

    final response = await http.post(
      Uri.parse(apiUrl),
      body: {
        'q': text,
        'from': from,
        'to': to,
        'appid': appId,
        'salt': salt,
        'sign': sign,
      },
    );

    // Parse and return translation
  }

  String _generateSign(String query, String salt) {
    final str = '$appId$query$salt$secretKey';
    return md5.convert(utf8.encode(str)).toString();
  }
}
```

**Alternative: Google Cloud Translation**
- Better for non-Chinese languages
- Price: $20/million characters
- API: `https://translation.googleapis.com/language/translate/v2`

---

### 📸 OCR (Optical Character Recognition) APIs

#### **百度 OCR API** - Primary Choice

**Use Cases:**
- Menu translation (photo to text to translation)
- Sign translation
- Document recognition
- Receipt scanning for expense tracking
- Business card recognition

**API Documentation:** https://ai.baidu.com/ai-doc/OCR

**Key APIs:**
- **General OCR:** Recognize any text
- **High Accuracy OCR:** Better for complex scenarios
- **Menu Recognition:** Specialized for restaurant menus
- **Table Recognition:** Extract structured data

**Request Example:**
```http
POST https://aip.baidubce.com/rest/2.0/ocr/v1/general_basic
Content-Type: application/x-www-form-urlencoded

access_token={token}&image={base64_image}
```

**Response:**
```json
{
  "words_result_num": 2,
  "words_result": [
    {
      "words": "北京烤鸭",
      "location": {
        "left": 10,
        "top": 20,
        "width": 100,
        "height": 30
      }
    },
    {
      "words": "¥188"
    }
  ]
}
```

**Rate Limits:**
- Free tier: 500 calls/day
- Paid: ¥0.002-0.02 per call (depending on API type)

**Flutter Implementation:**
```dart
// lib/services/ocr_service.dart
class BaiduOcrService {
  static const String apiKey = 'YOUR_API_KEY';
  static const String secretKey = 'YOUR_SECRET_KEY';

  Future<List<OcrResult>> recognizeImage(File imageFile) async {
    // 1. Get access token
    final token = await _getAccessToken();

    // 2. Convert image to base64
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    // 3. Call OCR API
    final response = await http.post(
      Uri.parse('https://aip.baidubce.com/rest/2.0/ocr/v1/general_basic'),
      body: {
        'access_token': token,
        'image': base64Image,
      },
    );

    // 4. Parse results
    final data = json.decode(response.body);
    return data['words_result']
        .map((item) => OcrResult.fromJson(item))
        .toList();
  }
}
```

**Alternative: Google Cloud Vision API**
- Better multilingual support
- Price: $1.5/1000 images (first 1000/month free)

---

### ☁️ Weather APIs

#### **和风天气 (QWeather)** - Primary Choice for China

**Use Cases:**
- Real-time weather conditions
- 7-day/15-day forecast
- Hourly forecast
- Weather warnings and alerts
- Air quality index (AQI)
- Life index (UV, clothing suggestions, etc.)

**API Documentation:** https://dev.qweather.com/docs/api/

**Request Example:**
```http
GET https://devapi.qweather.com/v7/weather/now?location=116.41,39.92&key={key}
```

**Response:**
```json
{
  "code": "200",
  "now": {
    "temp": "24",
    "feelsLike": "26",
    "text": "Sunny",
    "windDir": "Northwest",
    "windScale": "3",
    "humidity": "65",
    "precip": "0.0",
    "pressure": "1013",
    "vis": "10"
  },
  "updateTime": "2025-10-27T14:30+08:00"
}
```

**Rate Limits:**
- Free tier: 1,000 calls/day
- Standard: 10,000 calls/day (¥50/month)
- Professional: 100,000 calls/day (¥300/month)

**Flutter Implementation:**
```dart
// lib/services/weather_service.dart
class QWeatherService {
  static const String apiKey = 'YOUR_QWEATHER_KEY';
  static const String baseUrl = 'https://devapi.qweather.com/v7';

  Future<WeatherData> getCurrentWeather(double lat, double lng) async {
    final location = '$lng,$lat'; // QWeather uses lng,lat format

    final response = await http.get(
      Uri.parse('$baseUrl/weather/now')
          .replace(queryParameters: {
        'location': location,
        'key': apiKey,
      }),
    );

    final data = json.decode(response.body);
    return WeatherData.fromJson(data['now']);
  }

  Future<List<WeatherForecast>> get7DayForecast(double lat, double lng) async {
    final response = await http.get(
      Uri.parse('$baseUrl/weather/7d')
          .replace(queryParameters: {
        'location': '$lng,$lat',
        'key': apiKey,
      }),
    );

    final data = json.decode(response.body);
    return (data['daily'] as List)
        .map((item) => WeatherForecast.fromJson(item))
        .toList();
  }
}
```

**Alternative: OpenWeatherMap**
- Better for international locations
- Free tier: 1,000 calls/day
- API: `https://api.openweathermap.org/data/2.5/weather`

---

### 💳 Payment APIs

#### **WeChat Pay (微信支付)** - For China Market

**Use Cases:**
- In-app purchases
- Premium subscription
- Tour booking payments
- Digital wallet top-up

**API Documentation:** https://pay.weixin.qq.com/wiki/doc/api/index.html

**Integration Requirements:**
- Registered business entity in China
- WeChat Merchant account
- SSL certificate
- ICP filing (for China-hosted apps)

**Transaction Fee:** 0.6% per transaction

**Flutter Plugin:**
```yaml
dependencies:
  fluwx: ^4.1.0  # WeChat SDK wrapper
```

**Implementation:**
```dart
// lib/services/payment_service.dart
class WeChatPaymentService {
  Future<bool> processPayment(double amount, String orderId) async {
    // 1. Request prepay_id from your backend
    final prepayId = await _requestPrepayId(amount, orderId);

    // 2. Launch WeChat payment
    final result = await fluwx.pay(
      appId: 'YOUR_WECHAT_APP_ID',
      partnerId: 'YOUR_PARTNER_ID',
      prepayId: prepayId,
      packageValue: 'Sign=WXPay',
      nonceStr: _generateNonce(),
      timeStamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      sign: _generateSign(...),
    );

    return result.isSuccess;
  }
}
```

#### **Alipay (支付宝)** - Alternative for China

**Documentation:** https://opendocs.alipay.com/

**Flutter Plugin:**
```yaml
dependencies:
  tobias: ^3.0.0  # Alipay SDK wrapper
```

**Transaction Fee:** 0.6% per transaction

#### **Stripe** - For International Market

**Use Cases:**
- International credit card payments
- Subscription management
- Multi-currency support

**API Documentation:** https://stripe.com/docs/api

**Flutter Plugin:**
```yaml
dependencies:
  flutter_stripe: ^10.0.0
```

**Transaction Fee:** 2.9% + $0.30 per transaction

**Implementation:**
```dart
// lib/services/stripe_service.dart
class StripePaymentService {
  Future<void> initStripe() async {
    Stripe.publishableKey = 'YOUR_PUBLISHABLE_KEY';
    await Stripe.instance.applySettings();
  }

  Future<bool> processPayment(double amount, String currency) async {
    // 1. Create payment intent on backend
    final paymentIntent = await _createPaymentIntent(amount, currency);

    // 2. Confirm payment
    await Stripe.instance.confirmPayment(
      paymentIntentClientSecret: paymentIntent['client_secret'],
    );

    return true;
  }
}
```

---

### 📊 Analytics APIs

#### **Google Analytics 4** - International Market

**Documentation:** https://developers.google.com/analytics

**Flutter Plugin:**
```yaml
dependencies:
  firebase_analytics: ^10.0.0
```

**Events to Track:**
- Screen views
- User actions (search, booking, check-in)
- Trip creation and completion
- In-app purchases
- User engagement metrics

#### **友盟+ (Umeng)** - China Market

**Documentation:** https://developer.umeng.com/

**Flutter Plugin:**
```yaml
dependencies:
  umeng_common_sdk: ^2.0.0
```

**Use Cases:**
- User behavior analysis
- Crash reporting
- Push notifications
- A/B testing

---

### 🔐 Authentication APIs

#### **Supabase Auth** ✅ Currently Implemented

**Use Cases:**
- Email/password authentication
- OAuth login (Google, Apple, Facebook)
- Magic link authentication
- JWT token management

**API Documentation:** https://supabase.com/docs/guides/auth

**Configuration:**
```dart
// lib/config/supabase_config.dart
final supabase = Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

**OAuth Providers Available:**
- Google
- Apple
- Facebook
- GitHub
- WeChat (via custom provider)

---

### 💰 Cost Estimation

#### Development Phase (Free Tier):
```
Maps (Amap):           ¥0 (300k calls/day)
Translation (Baidu):   ¥0 (50k chars/month)
OCR (Baidu):          ¥0 (500 calls/day)
Weather (QWeather):    ¥0 (1k calls/day)
Backend (Supabase):    $0 (500MB DB, 1GB storage)
-------------------------------------------
Total:                 $0/month
```

#### Production Phase (10,000 MAU):
```
Maps (Amap):           ¥200-500/month
Translation (Baidu):   ¥200/month
OCR (Baidu):          ¥100/month
Weather (QWeather):    ¥50/month
Backend (Supabase):    $25/month (Pro plan)
Analytics (Umeng):     ¥0 (free)
Payment Processing:    0.6% per transaction
-------------------------------------------
Estimated Total:       ~$150-200/month + transaction fees
```

---

### 🔧 Implementation Priority

**Phase 1: Core Features** (Week 1-2)
1. ✅ Supabase Auth - Authentication
2. 🔜 高德地图 - Map display and POI search
3. 🔜 和风天气 - Weather data

**Phase 2: Essential Services** (Week 3-4)
4. 🔜 百度翻译 - Text translation
5. 🔜 百度 OCR - Image recognition
6. 🔜 Supabase Storage - Image uploads

**Phase 3: Enhanced Features** (Week 5-6)
7. 🔜 WeChat/Alipay - Payment integration
8. 🔜 友盟+ - Analytics and crash reporting
9. 🔜 Push notifications

**Phase 4: Optimization** (Week 7-8)
10. 🔜 Offline map caching
11. 🔜 API response caching
12. 🔜 Performance monitoring

---

### 📝 API Keys Management

**Security Best Practices:**

1. **Never commit API keys to version control**
   ```dart
   // ❌ Bad - Don't hardcode keys
   const apiKey = 'your_api_key_here';

   // ✅ Good - Use environment variables
   final apiKey = Platform.environment['AMAP_API_KEY'];
   ```

2. **Use separate keys for development and production**
   ```dart
   // lib/config/environment.dart
   enum Environment { dev, staging, prod }

   class Config {
     static Environment get env {
       const envString = String.fromEnvironment('ENV', defaultValue: 'dev');
       return Environment.values.firstWhere(
         (e) => e.name == envString,
         orElse: () => Environment.dev,
       );
     }

     static String get amapKey {
       switch (env) {
         case Environment.prod:
           return 'prod_amap_key';
         default:
           return 'dev_amap_key';
       }
     }
   }
   ```

3. **Store sensitive keys in secure storage**
   ```yaml
   dependencies:
     flutter_secure_storage: ^9.0.0
   ```

4. **Use backend proxy for sensitive operations**
   - Don't expose payment API keys in mobile app
   - Route sensitive requests through your Supabase Edge Functions

---

### 🔗 Useful Resources

**Chinese Developer Platforms:**
- 高德开放平台: https://lbs.amap.com/
- 百度AI开放平台: https://ai.baidu.com/
- 和风天气开发平台: https://dev.qweather.com/
- 微信开放平台: https://open.weixin.qq.com/
- 支付宝开放平台: https://open.alipay.com/

**International Platforms:**
- Google Cloud Platform: https://console.cloud.google.com/
- Stripe Dashboard: https://dashboard.stripe.com/
- Supabase Dashboard: https://app.supabase.com/

**Flutter Resources:**
- Pub.dev Packages: https://pub.dev/
- Flutter Plugins: https://flutter.dev/docs/development/packages-and-plugins

---

**Last Updated:** 2025-10-27
**API Version:** 1.0.0
**Status:** 🟡 Draft - Under Development
