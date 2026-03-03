# WanderChina - MVP Feature Specifications

**Version:** 1.0
**Phase:** MVP (Months 1-3)
**Target:** Beta Launch
**Last Updated:** 2025-10-22

---

## Table of Contents
1. [Authentication & Onboarding](#authentication--onboarding)
2. [Offline Maps](#offline-maps)
3. [Translation Tools](#translation-tools)
4. [Budget Tracker](#budget-tracker)
5. [Safety Features](#safety-features)
6. [Discovery & Recommendations](#discovery--recommendations)
7. [Community Feed](#community-feed)
8. [User Profile](#user-profile)

---

## 1. Authentication & Onboarding

### 1.1 Splash Screen

**User Story:**
> As a new user, I want to see an engaging splash screen so that I know the app is loading and get excited about using it.

**Requirements:**

**Visual Design:**
- WanderChina logo animation (fade in)
- Background: Subtle map of China with gradient overlay
- Loading indicator at bottom
- Duration: 2-3 seconds max

**Technical Specs:**
- Check authentication status (JWT token in secure storage)
- If authenticated → Navigate to Home Screen
- If not authenticated → Navigate to Onboarding Screen 1
- Preload critical assets during splash

**Acceptance Criteria:**
- [ ] Logo animation plays smoothly (60fps)
- [ ] Background image loads progressively
- [ ] Auth check completes within 1 second
- [ ] Navigation happens automatically
- [ ] Works offline (uses cached assets)

---

### 1.2 Onboarding Screens

**User Story:**
> As a new user, I want to understand what the app offers so that I can decide to sign up.

**Screen 1: Welcome**
- **Headline:** "Discover China Your Way"
- **Subheading:** "Your AI-powered travel companion for exploring China"
- **Visual:** Hero image carousel:
  - Great Wall of China
  - Guilin mountains
  - Chengdu pandas
  - Shanghai skyline
- **CTA:** "Next" button

**Screen 2: Features Highlight**
- **Headline:** "Travel Smarter, Not Harder"
- **Features (Icons + Text):**
  - Offline Maps - "Navigate without internet"
  - Instant Translation - "Break the language barrier"
  - Safety First - "Emergency support 24/7"
  - Save Money - "Smart budget tracking"
- **CTA:** "Next" button

**Screen 3: Permissions**
- **Headline:** "We Need Your Permission"
- **Permissions List:**
  - 📍 Location - "For maps and nearby recommendations"
  - 📷 Camera - "For translation and check-ins"
  - 📂 Storage - "For offline maps and photos"
  - 🔔 Notifications - "For important updates and alerts"
- **CTA:** "Grant Permissions" → "Get Started"

**Technical Specs:**
- Swipeable carousel (left/right)
- Skip button on top-right
- Progress dots at bottom
- Permissions use native dialogs
- Can request permissions later if skipped

**Acceptance Criteria:**
- [ ] Smooth swipe transitions
- [ ] Images load without flickering
- [ ] Skip button works on all screens
- [ ] Permissions gracefully handle denial
- [ ] "Get Started" navigates to Login/Signup

---

### 1.3 Login & Signup

**User Story:**
> As a user, I want to create an account quickly so that I can start using the app.

**Login Screen:**

**Layout:**
```
┌─────────────────────────────┐
│      WanderChina Logo       │
│                             │
│  ┌───────────────────────┐  │
│  │ Email                 │  │
│  └───────────────────────┘  │
│                             │
│  ┌───────────────────────┐  │
│  │ Password              │  │
│  └───────────────────────┘  │
│                             │
│  [Forgot Password?]         │
│                             │
│  ┌───────────────────────┐  │
│  │      Login            │  │
│  └───────────────────────┘  │
│                             │
│  ──────── OR ────────       │
│                             │
│  [Continue with Google]     │
│  [Continue with Facebook]   │
│                             │
│  Don't have an account?     │
│  [Sign Up]                  │
└─────────────────────────────┘
```

**Signup Screen:**

**Fields:**
- Email (with validation)
- Password (min 8 chars, strength indicator)
- Confirm Password
- Full Name
- Nationality (dropdown)
- [Terms & Privacy] checkbox

**Social Login:**
- Google OAuth 2.0
- Facebook Login

**Technical Specs:**
- Email validation (regex)
- Password strength meter (weak/medium/strong)
- Error messages inline (red text below field)
- Loading state on submit button
- Auto-fill support
- Remember me (checkbox)

**API Endpoints:**
```
POST /api/v1/auth/signup
POST /api/v1/auth/login
POST /api/v1/auth/social-login (Google, Facebook)
POST /api/v1/auth/forgot-password
```

**Validation Rules:**
- Email: Valid format, unique
- Password: Min 8 chars, 1 uppercase, 1 number
- Full Name: Min 2 chars
- Nationality: Required

**Acceptance Criteria:**
- [ ] Email validation shows real-time feedback
- [ ] Password strength indicator updates as user types
- [ ] Social login works with existing accounts
- [ ] Error messages are clear and helpful
- [ ] "Forgot Password" sends reset email
- [ ] Successful login navigates to Home Screen
- [ ] JWT token stored securely
- [ ] User object cached locally

---

### 1.4 Initial Profile Setup

**User Story:**
> As a new user, I want to set up my profile so that I get personalized recommendations.

**Profile Setup Wizard (3 Steps):**

**Step 1: Travel Preferences**
- **Question:** "What type of traveler are you?"
- **Options (Select 1):**
  - 🎒 Backpacker (budget-friendly)
  - 💼 Business Traveler (efficient)
  - 🏖️ Leisure (relaxed)
  - 🎨 Culture Enthusiast (museums, history)
  - 🏔️ Adventurer (hiking, extreme sports)
- **CTA:** "Next"

**Step 2: Interests**
- **Question:** "What interests you most?"
- **Options (Multi-select up to 5):**
  - 🍜 Food & Cuisine
  - 🏛️ History & Culture
  - 🌄 Nature & Hiking
  - 🎭 Arts & Performance
  - 📸 Photography
  - 🍺 Nightlife
  - 🛍️ Shopping
  - 🐼 Wildlife
  - ⛩️ Temples & Religion
  - 🏃 Sports & Fitness
- **CTA:** "Next"

**Step 3: Languages**
- **Question:** "What languages do you speak?"
- **Options (Multi-select):**
  - 🇬🇧 English
  - 🇨🇳 Chinese (Mandarin)
  - 🇪🇸 Spanish
  - 🇫🇷 French
  - 🇩🇪 German
  - 🇯🇵 Japanese
  - 🇰🇷 Korean
  - [+ Add more]
- **CTA:** "Finish Setup"

**Technical Specs:**
- Save preferences to backend
- Update user profile locally
- Navigate to Home Screen
- Show welcome message

**API Endpoint:**
```
PATCH /api/v1/users/me/profile
```

**Acceptance Criteria:**
- [ ] Can skip wizard (use defaults)
- [ ] Selections are saved
- [ ] Can edit preferences later in settings
- [ ] Recommendations reflect preferences immediately

---

## 2. Offline Maps

### 2.1 Map Viewer

**User Story:**
> As a traveler, I want to view a map of my current location so that I can navigate around.

**Features:**

**Map Display:**
- Interactive map (pinch to zoom, pan)
- Current location indicator (blue dot with accuracy circle)
- Compass indicator
- Zoom controls (+/- buttons)
- "Center on my location" button

**Map Layers:**
- Standard (default)
- Satellite
- Terrain
- Public Transport

**Points of Interest (POI):**
- Attractions (red pin)
- Restaurants (orange pin)
- Hotels (blue pin)
- Metro stations (purple pin)
- Emergency (red cross)

**UI Elements:**
```
┌─────────────────────────────┐
│ ☰  WanderChina     🔍  👤  │
├─────────────────────────────┤
│                             │
│         [  MAP  ]           │
│                             │
│  [Layers]          [+]      │
│                    [-]      │
│  [Current Location] 🎯      │
│                             │
└─────────────────────────────┘
```

**Technical Specs:**
- Map SDK: Baidu Maps (China), Google Maps (backup)
- Tile caching for offline usage
- GPS accuracy: 10-50 meters
- Auto-rotate based on compass (optional)

**API Integration:**
```
Baidu Maps SDK:
- MapView component
- LocationManager
- Marker/Overlay system
- Geocoding API
```

**Acceptance Criteria:**
- [ ] Map loads within 2 seconds
- [ ] Smooth panning and zooming (60fps)
- [ ] Current location updates every 5 seconds
- [ ] POI markers clickable (show info)
- [ ] Works offline with downloaded tiles
- [ ] Battery usage optimized

---

### 2.2 Offline Map Download

**User Story:**
> As a traveler, I want to download maps for offline use so that I can navigate without internet.

**Download Flow:**

**Step 1: Select City**
- Search bar to find city
- Popular cities list
- Map preview with download area highlighted

**Step 2: Choose Area Size**
- Small (city center, ~50MB)
- Medium (full city, ~200MB)
- Large (metro area, ~500MB)
- Custom (draw on map)

**Step 3: Download**
- Show estimated size and time
- "Download Now" or "Download on WiFi Only"
- Progress bar with percentage
- Pause/Resume/Cancel options

**Downloaded Maps Management:**
- List of downloaded maps
- Storage usage (e.g., "1.2 GB / 5 GB")
- Update available indicator
- Delete option

**UI Mock:**
```
┌─────────────────────────────┐
│  Offline Maps               │
├─────────────────────────────┤
│  [Search cities...]         │
│                             │
│  Popular Cities:            │
│  ┌─────────────────────┐   │
│  │ Beijing       [↓]   │   │
│  │ 250 MB    Updated   │   │
│  └─────────────────────┘   │
│  ┌─────────────────────┐   │
│  │ Shanghai   [Download]│  │
│  │ 200 MB              │   │
│  └─────────────────────┘   │
│                             │
│  Storage: 1.2 GB / 5 GB     │
│  [Manage Storage]           │
└─────────────────────────────┘
```

**Technical Specs:**
- Download in background
- Resume support (if interrupted)
- Compression: Gzip tiles
- Storage: Local SQLite database
- Automatic cleanup of old tiles

**API Endpoints:**
```
GET /api/v1/maps/cities (list available cities)
GET /api/v1/maps/{city_id}/tiles (download tiles)
GET /api/v1/maps/{city_id}/metadata (size, version)
```

**Acceptance Criteria:**
- [ ] Download works on WiFi and cellular
- [ ] WiFi-only option respected
- [ ] Download survives app close/reopen
- [ ] Downloaded maps work completely offline
- [ ] Update notification when new version available
- [ ] Storage limit warning (if approaching max)

---

### 2.3 Navigation & Directions

**User Story:**
> As a traveler, I want to get directions to a place so that I can navigate there.

**Features:**

**Search Destination:**
- Search bar (place name, address, coordinates)
- Recent searches
- Saved places
- Nearby suggestions

**Route Options:**
- Walking (default for short distances)
- Public Transport (metro, bus)
- Taxi/Ride-hailing
- Biking

**Route Details:**
- Total distance (km)
- Estimated time
- Step-by-step directions
- Alternative routes (up to 3)

**Turn-by-Turn Navigation:**
- Voice guidance (text-to-speech)
- Visual arrow overlay on map
- Distance to next turn
- Automatic re-routing if off course
- ETA update

**UI During Navigation:**
```
┌─────────────────────────────┐
│  [X]  Beijing Temple  [⋮]  │
├─────────────────────────────┤
│                             │
│       ↑ 200m                │
│   Turn right at             │
│   Dongcheng Street          │
│                             │
│  [ MAP WITH ROUTE ]         │
│                             │
│  ────────────────────────   │
│  5.2 km  |  12 min  | 🚶   │
└─────────────────────────────┘
```

**Technical Specs:**
- Route calculation: Dijkstra's algorithm (offline) or API (online)
- GPS polling: Every 3 seconds during navigation
- Voice: Text-to-speech in user's language
- Battery saver: Reduce GPS frequency when stable

**API Endpoints:**
```
POST /api/v1/maps/directions
{
  "origin": {"lat": 39.9, "lng": 116.4},
  "destination": "Forbidden City",
  "mode": "walking"
}

Response:
{
  "routes": [
    {
      "distance": 5200,
      "duration": 720,
      "steps": [...]
    }
  ]
}
```

**Acceptance Criteria:**
- [ ] Search finds destinations accurately
- [ ] Route calculation < 3 seconds
- [ ] Turn-by-turn navigation works offline
- [ ] Voice guidance clear and timely
- [ ] Re-routing happens within 5 seconds
- [ ] Destination reached notification

---

## 3. Translation Tools

### 3.1 Camera Translation (OCR)

**User Story:**
> As a traveler who doesn't read Chinese, I want to point my camera at text and see instant translation so that I can understand signs, menus, etc.

**Features:**

**Camera View:**
- Live camera feed
- Capture button (take photo) or Live mode (real-time overlay)
- Language selector (Chinese → English default)
- Flash toggle
- Gallery button (translate from photo)

**Translation Modes:**

**1. Live Translation (AR Overlay)**
- Real-time text detection
- Overlay translated text on original position
- Highlight detected text boxes
- 2-3 second processing delay

**2. Photo Translation**
- Take photo → Process → Show result
- Original + Translation side-by-side
- Tap to hear pronunciation
- Save translation

**UI Mock (Live Mode):**
```
┌─────────────────────────────┐
│ [X]  ZH → EN   [Flash]      │
├─────────────────────────────┤
│                             │
│   [ LIVE CAMERA VIEW ]      │
│                             │
│   ┌───────────────┐         │
│   │ 北京烤鸭      │         │
│   │ Beijing Duck  │ ← Overlay
│   └───────────────┘         │
│                             │
│  [Gallery] [●] [Live/Photo] │
└─────────────────────────────┘
```

**Technical Specs:**
- **OCR Engine:** Google ML Kit (on-device, fast) + Baidu OCR (cloud, accurate)
- **Translation:** Google Translate API + Baidu Translate API
- **Processing:**
  - On-device: < 1 second
  - Cloud: < 3 seconds
- **Languages:** Chinese ↔ English (MVP), expand later
- **Image Requirements:**
  - Min resolution: 640x480
  - Good lighting
  - Text size: > 12pt

**API Endpoints:**
```
POST /api/v1/translation/ocr
{
  "image_base64": "...",
  "source_lang": "zh",
  "target_lang": "en"
}

Response:
{
  "detections": [
    {
      "text": "北京烤鸭",
      "translation": "Beijing Roast Duck",
      "bounding_box": {...},
      "confidence": 0.95
    }
  ]
}
```

**Acceptance Criteria:**
- [ ] Camera permissions requested
- [ ] Live translation updates smoothly
- [ ] Photo translation < 3 seconds
- [ ] Translations are accurate (>85%)
- [ ] Works in low light (with flash)
- [ ] Can save translations
- [ ] Works partially offline (on-device OCR)

---

### 3.2 Text Translator

**User Story:**
> As a traveler, I want to type or paste text and get instant translation so that I can communicate.

**Features:**

**Input Methods:**
- Type text manually
- Paste from clipboard
- Voice input (speech-to-text)

**Translation:**
- Source language auto-detect or manual select
- Target language selector
- Real-time translation as you type (debounced)
- Character count (limit: 5000 chars)

**Output:**
- Translated text
- Copy button
- Share button
- Text-to-speech (hear pronunciation)
- Save to history

**UI Mock:**
```
┌─────────────────────────────┐
│  Text Translator            │
├─────────────────────────────┤
│  ┌──────────┐  ┌──────────┐│
│  │ Chinese ▾│ ⇄│ English ▾││
│  └──────────┘  └──────────┘│
│                             │
│  ┌───────────────────────┐ │
│  │ Type or paste text... │ │
│  │                       │ │
│  │ [🎤 Voice]            │ │
│  └───────────────────────┘ │
│                             │
│  ───────────────────────    │
│                             │
│  Translation:               │
│  ┌───────────────────────┐ │
│  │ Translated text here  │ │
│  │                       │ │
│  │ [🔊] [📋 Copy] [Share]│ │
│  └───────────────────────┘ │
└─────────────────────────────┘
```

**Technical Specs:**
- Translation API: Google Translate + Baidu Translate
- Caching: Redis (common phrases, 30-day TTL)
- Offline: Basic phrase dictionary (10,000 common phrases)
- Voice Input: Speech-to-text (Google Speech API)
- Voice Output: Text-to-speech (Google TTS)

**API Endpoint:**
```
POST /api/v1/translation/text
{
  "text": "你好，请问洗手间在哪里?",
  "source_lang": "zh",
  "target_lang": "en"
}

Response:
{
  "translation": "Hello, where is the restroom?",
  "source_lang_detected": "zh",
  "confidence": 0.98
}
```

**Acceptance Criteria:**
- [ ] Translation appears < 1 second
- [ ] Auto-detect language works accurately
- [ ] Voice input recognizes speech
- [ ] Text-to-speech pronunciation clear
- [ ] Copy/Share functions work
- [ ] Translation history saved (last 50)
- [ ] Offline mode has basic phrases

---

### 3.3 Phrasebook

**User Story:**
> As a traveler, I want access to common phrases in Chinese so that I can communicate in various situations.

**Categories:**
- 🍴 Restaurant & Food
- 🏨 Hotel & Accommodation
- 🚇 Transportation
- 🛍️ Shopping
- 🏥 Emergency & Health
- 💬 Basic Conversation
- 🔢 Numbers & Time
- ❓ Questions

**Phrase Structure:**
- English phrase
- Chinese characters (Simplified)
- Pinyin (romanization)
- Audio pronunciation (tap to play)
- Slow playback option

**Example Entry:**
```
┌─────────────────────────────┐
│  Restaurant                 │
├─────────────────────────────┤
│  ┌───────────────────────┐ │
│  │ I'd like to order     │ │
│  │ 我想点菜               │ │
│  │ wǒ xiǎng diǎn cài     │ │
│  │ [🔊 Play] [★ Favorite]│ │
│  └───────────────────────┘ │
│                             │
│  ┌───────────────────────┐ │
│  │ How much is this?     │ │
│  │ 这个多少钱?            │ │
│  │ zhège duōshǎo qián?   │ │
│  │ [🔊 Play] [★ Favorite]│ │
│  └───────────────────────┘ │
└─────────────────────────────┘
```

**Features:**
- **Search:** Find phrases by keyword
- **Favorites:** Star important phrases for quick access
- **Offline:** All phrases available offline
- **Practice Mode:** Quiz yourself
- **Share:** Share phrases with companions

**Technical Specs:**
- **Storage:** Local JSON file (~5MB)
- **Audio:** MP3 files (native speaker recordings)
- **Total Phrases:** 200-300 essential phrases (MVP)
- **Audio Compression:** 64kbps (small file size)

**Data Structure:**
```json
{
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
          "audio_url": "phrases/rest_001.mp3"
        }
      ]
    }
  ]
}
```

**Acceptance Criteria:**
- [ ] All phrases load instantly (offline)
- [ ] Audio plays smoothly
- [ ] Search finds relevant phrases
- [ ] Favorites persist
- [ ] Categories are well-organized
- [ ] Pinyin helps with pronunciation

---

## 4. Budget Tracker

### 4.1 Add Expense

**User Story:**
> As a budget-conscious traveler, I want to quickly log expenses so that I can track my spending.

**Quick Add Flow:**
- Tap "+" button on Budget tab
- Select category (icons)
- Enter amount
- Optional: Add description, attach receipt photo
- Save

**Categories:**
- 🍜 Food & Drinks
- 🏨 Accommodation
- 🚇 Transportation
- 🎭 Attractions & Entertainment
- 🛍️ Shopping
- 💊 Health & Medical
- 📞 Communication (SIM, internet)
- 🎁 Other

**UI Mock:**
```
┌─────────────────────────────┐
│  Add Expense          [X]   │
├─────────────────────────────┤
│  Category:                  │
│  [🍜] [🏨] [🚇] [🎭]        │
│  [🛍️] [💊] [📞] [🎁]        │
│                             │
│  Amount:                    │
│  ┌──────────────────────┐  │
│  │ ¥ 150.00            │  │
│  └──────────────────────┘  │
│  = $21.50 USD              │
│                             │
│  Description (optional):    │
│  ┌──────────────────────┐  │
│  │ Lunch at noodle shop │  │
│  └──────────────────────┘  │
│                             │
│  [📷 Add Receipt Photo]     │
│                             │
│  [Save]                     │
└─────────────────────────────┘
```

**Technical Specs:**
- **Currency:** Default CNY, convert to user's home currency
- **Exchange Rate:** Update daily, cache for offline
- **Photo:** Compress to < 1MB before upload
- **Local Storage:** SQLite for offline access

**API Endpoint:**
```
POST /api/v1/expenses
{
  "category": "food",
  "amount": 150.00,
  "currency": "CNY",
  "description": "Lunch at noodle shop",
  "receipt_photo": "base64...",
  "expense_date": "2025-10-22T12:30:00Z",
  "trip_id": "uuid"
}
```

**Acceptance Criteria:**
- [ ] Can add expense in < 10 seconds
- [ ] Currency conversion accurate
- [ ] Receipt photo optional
- [ ] Works offline (syncs later)
- [ ] Date defaults to "now"

---

### 4.2 Budget Dashboard

**User Story:**
> As a traveler, I want to see a summary of my spending so that I know if I'm within budget.

**Dashboard Elements:**

**Budget vs. Actual:**
- Progress bar (% of budget used)
- Color coding:
  - Green: < 75% used
  - Yellow: 75-90% used
  - Red: > 90% used

**Time Period Selector:**
- Today
- This Week
- This Month
- This Trip
- All Time

**Breakdown by Category:**
- Pie chart or bar chart
- Top 3 categories highlighted

**Quick Stats:**
- Total spent
- Daily average
- Remaining budget
- Days left in trip

**Recent Transactions:**
- Last 5 expenses
- Tap to view/edit/delete

**UI Mock:**
```
┌─────────────────────────────┐
│  Budget Tracker       [+]   │
├─────────────────────────────┤
│  Trip Budget: ¥3000         │
│  ████████░░░ 75% used       │
│  ¥2250 spent | ¥750 left    │
│                             │
│  [Today] [Week] [Month]     │
│                             │
│  Today: ¥150                │
│  Avg/Day: ¥180              │
│                             │
│  Spending by Category:      │
│  🍜 Food        ¥900  40%   │
│  🏨 Hotel       ¥800  35%   │
│  🚇 Transport   ¥350  15%   │
│  [View All]                 │
│                             │
│  Recent:                    │
│  🍜 Lunch        ¥150       │
│  🚇 Metro        ¥5         │
│  [View All Expenses]        │
└─────────────────────────────┘
```

**Technical Specs:**
- Charts: fl_chart (Flutter)
- Data: Aggregate from expenses table
- Caching: Calculate once per day, cache in Redis
- Export: CSV, PDF options

**API Endpoints:**
```
GET /api/v1/expenses/summary?period=week&trip_id=uuid
GET /api/v1/expenses/breakdown?trip_id=uuid
GET /api/v1/expenses?trip_id=uuid&limit=5
```

**Acceptance Criteria:**
- [ ] Dashboard loads < 1 second
- [ ] Charts render smoothly
- [ ] Budget calculation accurate
- [ ] Time period filter works
- [ ] Recent transactions clickable

---

### 4.3 Currency Converter

**User Story:**
> As a traveler, I want to convert between currencies quickly so that I know how much I'm spending in my home currency.

**Features:**
- **Amount Input:** Enter value to convert
- **From Currency:** CNY (default in China)
- **To Currency:** User's home currency (auto-detect)
- **Swap Button:** Switch currencies
- **Exchange Rate:** Display current rate + last updated time
- **Offline Mode:** Use cached rates (updated daily)

**UI Mock:**
```
┌─────────────────────────────┐
│  Currency Converter         │
├─────────────────────────────┤
│  ┌──────────────────────┐  │
│  │ 100.00              │  │
│  └──────────────────────┘  │
│  CNY (Chinese Yuan) ▾       │
│                             │
│        [⇅ Swap]             │
│                             │
│  ┌──────────────────────┐  │
│  │ 14.32               │  │
│  └──────────────────────┘  │
│  USD (US Dollar) ▾          │
│                             │
│  Rate: 1 CNY = 0.1432 USD   │
│  Updated: 2 hours ago       │
└─────────────────────────────┘
```

**Technical Specs:**
- **API:** Exchange Rates API (free tier) or Open Exchange Rates
- **Update Frequency:** Every 24 hours
- **Offline:** Cache last 7 days of rates
- **Supported Currencies:** 30+ major currencies

**API Endpoint:**
```
GET /api/v1/currency/rates?base=CNY&symbols=USD,EUR,GBP
```

**Acceptance Criteria:**
- [ ] Conversion instant (< 100ms)
- [ ] Exchange rates accurate
- [ ] Works offline with cached data
- [ ] Supports major currencies
- [ ] Swap button toggles currencies

---

## 5. Safety Features

### 5.1 SOS Emergency Button

**User Story:**
> As a solo traveler, I want a quick way to call for help in an emergency so that I feel safe.

**Button Location:**
- **Home Screen:** Floating red button (bottom-right)
- **Accessible from:** All screens (global overlay)

**Activation:**
- **Long Press (3 seconds):** Prevents accidental activation
- **Confirmation Modal:** "Are you sure? This will alert emergency contacts and services."
- **Cancel:** Tap "X" within 5 seconds
- **Activate:** After 5 seconds or tap "Send Alert"

**Emergency Actions:**

**1. Send Alerts:**
- **Emergency Contacts** (pre-configured, up to 5 people)
  - SMS with GPS coordinates
  - Push notification if they have the app
- **Local Emergency Services:**
  - Display phone numbers: 110 (Police), 120 (Ambulance), 122 (Traffic)
  - One-tap call buttons

**2. Location Sharing:**
- Share real-time GPS location
- Update every 30 seconds
- Broadcast to emergency contacts

**3. Display Emergency Info:**
- **Nearest Hospitals:** Map view with distance
- **Nearest Police Stations:** Map view
- **Embassy/Consulate:** Location and phone

**4. Emergency Phrase Card:**
- Display in large Chinese characters:
  - "我需要帮助" (I need help)
  - "请叫救护车" (Please call an ambulance)
  - "我迷路了" (I'm lost)
  - "请叫警察" (Please call the police)

**5. Flashlight & Siren:**
- Flashing screen (red/white)
- Optional: Siren sound

**UI During Emergency:**
```
┌─────────────────────────────┐
│  🚨 EMERGENCY MODE 🚨        │
├─────────────────────────────┤
│  Alert sent to contacts     │
│  Location sharing: Active   │
│                             │
│  Your Location:             │
│  [MAP]                      │
│                             │
│  Emergency Numbers:         │
│  [📞 110 Police]            │
│  [📞 120 Ambulance]         │
│  [📞 122 Traffic]           │
│                             │
│  Nearest Hospital:          │
│  Beijing United Hospital    │
│  1.2 km away [Directions]   │
│                             │
│  [Cancel Emergency]         │
└─────────────────────────────┘
```

**Technical Specs:**
- **GPS Accuracy:** High-accuracy mode
- **SMS:** Twilio API
- **Push Notifications:** FCM
- **Offline:** Emergency numbers stored locally
- **Battery:** Prevent sleep mode during emergency

**Emergency Contact Setup:**
```
Settings → Safety → Emergency Contacts
- Name
- Phone Number
- Relationship
- SMS/Push/Both
```

**API Endpoints:**
```
POST /api/v1/emergency/alert
{
  "user_id": "uuid",
  "location": {"lat": 39.9, "lng": 116.4},
  "timestamp": "2025-10-22T15:30:00Z"
}

GET /api/v1/emergency/nearby?type=hospital&lat=39.9&lng=116.4
```

**Acceptance Criteria:**
- [ ] SOS button accessible from all screens
- [ ] Long press prevents accidental activation
- [ ] Alerts sent within 5 seconds
- [ ] GPS location accurate
- [ ] Emergency numbers correct for country
- [ ] Phrase cards in local language
- [ ] Cancel option available
- [ ] Works offline (SMS fallback)

---

### 5.2 Live Location Sharing

**User Story:**
> As a solo traveler, I want to share my real-time location with trusted friends/family so they can see where I am.

**Features:**

**Sharing Options:**
- Share with app users (push notification + in-app map)
- Share with non-users (SMS link to web map)
- Duration: 1 hour, 8 hours, 24 hours, Until I stop

**Privacy Controls:**
- Only share with selected contacts
- Can stop sharing anytime
- Battery-efficient tracking (updates every 1-5 minutes)

**Recipient View:**
- See user's location on map
- Last updated timestamp
- Battery level
- Movement trail (breadcrumbs)

**UI Mock (Sender):**
```
┌─────────────────────────────┐
│  Share My Location          │
├─────────────────────────────┤
│  Share with:                │
│  [✓] Mom (App User)         │
│  [✓] Sarah (SMS Link)       │
│  [ ] Tom (App User)         │
│  [+ Add Contact]            │
│                             │
│  Duration:                  │
│  ● 1 hour                   │
│  ○ 8 hours                  │
│  ○ 24 hours                 │
│  ○ Until I stop             │
│                             │
│  [Start Sharing]            │
│                             │
│  ──────────────────────     │
│  Active Shares:             │
│  Mom - 23 min left [Stop]   │
└─────────────────────────────┘
```

**Technical Specs:**
- **GPS Polling:** Adaptive (moving: 1 min, stationary: 5 min)
- **Battery Impact:** < 5% per hour
- **Data Usage:** ~ 1MB per hour
- **Backend:** WebSocket for real-time updates
- **Web View:** Public map page (no login required)

**API Endpoints:**
```
POST /api/v1/location/share
{
  "contacts": ["user_id", "+86123456789"],
  "duration_hours": 8
}

GET /api/v1/location/shared/{share_id} (for recipients)

DELETE /api/v1/location/share/{share_id} (stop sharing)
```

**Acceptance Criteria:**
- [ ] Location sharing starts immediately
- [ ] Recipients receive notification
- [ ] Map updates in real-time
- [ ] Can stop sharing anytime
- [ ] Battery usage acceptable
- [ ] Works with non-app users (web link)

---

### 5.3 Safety Scores & Alerts

**User Story:**
> As a traveler, I want to know if an area is safe so that I can avoid dangerous areas.

**Safety Score:**
- **1-5 Star Rating** for neighborhoods/areas
- **Based on:**
  - Crime statistics (government data)
  - User reports (scams, pickpockets, harassment)
  - Time of day (safer during day)
  - Tourist traffic (crowded = safer)

**Color Coding:**
- 🟢 Green (4-5 stars): Safe
- 🟡 Yellow (3 stars): Caution
- 🔴 Red (1-2 stars): Avoid

**Alerts:**
- **Entering Unsafe Area:** "You're entering a medium-risk area. Stay alert."
- **Nighttime Warning:** "This area is less safe after dark. Consider alternative routes."
- **Scam Alert:** "High scam activity reported here. Common scam: [description]"

**Scam Database:**
- **Common Tourist Scams:**
  - Tea house scam
  - Fake monks
  - Overpriced taxis
  - Counterfeit money
  - Art student scam
- **Location-based warnings**
- **Community-reported incidents**

**UI Mock:**
```
┌─────────────────────────────┐
│  Safety Info                │
├─────────────────────────────┤
│  Current Area:              │
│  Dongcheng District         │
│  Safety: ★★★★☆ (Safe)       │
│                             │
│  [MAP with color overlay]   │
│                             │
│  Recent Alerts:             │
│  ⚠️ Pickpocket reports      │
│     near Metro Station      │
│     2 hours ago             │
│                             │
│  Common Scams Here:         │
│  • Tea house scam           │
│    [Learn More]             │
│                             │
│  [Report Safety Issue]      │
└─────────────────────────────┘
```

**Technical Specs:**
- **Data Sources:**
  - Government crime stats API
  - User reports (moderated)
  - Third-party safety indexes
- **Update Frequency:** Weekly for stats, real-time for user reports
- **Geofencing:** Trigger alerts when entering/exiting zones

**API Endpoints:**
```
GET /api/v1/safety/score?lat=39.9&lng=116.4
GET /api/v1/safety/alerts?city=beijing&limit=10
POST /api/v1/safety/report (user-submitted incident)
```

**Acceptance Criteria:**
- [ ] Safety score visible on map
- [ ] Alerts timely and relevant
- [ ] Scam descriptions helpful
- [ ] User reports moderated
- [ ] Color coding clear
- [ ] Works offline (cached data)

---

## 6. Discovery & Recommendations

### 6.1 Home Screen

**User Story:**
> As a user, I want to see personalized recommendations when I open the app so that I can discover things to do.

**Home Screen Layout:**

```
┌─────────────────────────────┐
│  ☰  WanderChina     🔍  👤 │
├─────────────────────────────┤
│  📍 Beijing · 23°C ☀️       │
│  ────────────────────────   │
│                             │
│  Good Morning, Alex!        │
│                             │
│  [🗺️ Map] [🔤 Translate]   │
│  [💰 Budget] [🎯 Challenges]│
│                             │
│  Nearby Highlights:         │
│  ┌─────────────────────┐   │
│  │ [Image]             │   │
│  │ Forbidden City      │   │
│  │ 0.8 km · ★★★★☆      │   │
│  └─────────────────────┘   │
│  → Swipe for more           │
│                             │
│  Recommended for You:       │
│  ┌─────────────────────┐   │
│  │ [Image] Hutong Tour │   │
│  └─────────────────────┘   │
│                             │
│  [View All]                 │
└─────────────────────────────┘
```

**Sections:**

**1. Weather Widget:**
- Current location
- Temperature and condition icon
- Air quality index (important for China)

**2. Quick Access Tools:**
- Map, Translate, Budget, Challenges
- 2x2 grid with icons

**3. Nearby Highlights:**
- Horizontal carousel (swipeable)
- Top 5 attractions/restaurants within 5km
- Image, name, distance, rating

**4. Recommended for You:**
- Personalized based on interests
- 3-5 cards
- Categories: Places, Events, Food, Challenges

**Technical Specs:**
- **Location:** GPS (foreground) or Last Known Location
- **Weather API:** OpenWeatherMap or AccuWeather
- **Recommendations:** ML model + rule-based
- **Image Loading:** Progressive JPEG, cached

**API Endpoints:**
```
GET /api/v1/home/feed?lat=39.9&lng=116.4
GET /api/v1/weather?city=beijing
```

**Acceptance Criteria:**
- [ ] Home screen loads < 2 seconds
- [ ] Location accurate within 100m
- [ ] Recommendations relevant to interests
- [ ] Images load progressively
- [ ] Pull-to-refresh updates content
- [ ] Works partially offline (cached data)

---

### 6.2 Discover Tab

**User Story:**
> As a user, I want to explore content by category so that I can find things that interest me.

**Tabs:**
- 🗺️ Places
- 🍜 Food
- 🎉 Events
- 💡 Tips

**Places Tab:**
- **Filters:**
  - Category: Attractions, Museums, Temples, Parks, etc.
  - Distance: < 1km, < 5km, < 10km, Any
  - Rating: 4+ stars, 3+ stars, Any
  - Price: Free, $, $$, $$$, $$$$
- **Sort:**
  - Distance (nearest first)
  - Rating (highest first)
  - Popularity
- **View:**
  - List view (default)
  - Map view
  - Grid view

**Food Tab:**
- **Cuisines:**
  - Chinese (sub-categories: Sichuan, Cantonese, Beijing, etc.)
  - Western
  - Asian (Japanese, Korean, Thai, etc.)
  - Vegetarian/Vegan
  - Halal
- **Meal Type:** Breakfast, Lunch, Dinner, Snacks
- **Price Range**
- **Dietary Filters:** Vegetarian, Vegan, Gluten-Free, Halal, etc.

**Events Tab:**
- **Categories:**
  - Festivals (Spring Festival, Mid-Autumn, etc.)
  - Concerts & Performances
  - Art Exhibitions
  - Sports Events
  - Meetups & Social
- **Time Filter:**
  - Today, This Week, This Month, Later
- **RSVP/Booking** option

**Tips Tab:**
- **Categories:**
  - Cultural Etiquette
  - Language Lessons (basic phrases)
  - Travel Hacks
  - Safety Tips
  - Money Saving Tips
- **Format:**
  - Articles (short, 2-3 min read)
  - Videos (1-2 min)
  - Infographics

**UI Mock (Places Tab):**
```
┌─────────────────────────────┐
│  Discover         [Filter]  │
├─────────────────────────────┤
│  [Places][Food][Events][Tips]│
│  ────────                    │
│  Sort: Distance ▾            │
│                             │
│  ┌───────────────────────┐ │
│  │ [Image]  Forbidden City│ │
│  │ ★★★★☆ (1250 reviews)  │ │
│  │ 0.8 km · $$            │ │
│  │ Historical · UNESCO    │ │
│  └───────────────────────┘ │
│                             │
│  ┌───────────────────────┐ │
│  │ [Image]  Temple of     │ │
│  │          Heaven        │ │
│  │ ★★★★★ (890 reviews)   │ │
│  │ 3.2 km · $             │ │
│  └───────────────────────┘ │
└─────────────────────────────┘
```

**Technical Specs:**
- **Data Source:** Places database + third-party APIs (Google Places, Baidu)
- **Filtering:** Elasticsearch
- **Caching:** Redis (popular queries)
- **Images:** CDN (CloudFlare)

**API Endpoints:**
```
GET /api/v1/discover/places?category=attraction&lat=39.9&lng=116.4&radius=5000&sort=distance
GET /api/v1/discover/food?cuisine=sichuan&dietary=vegetarian
GET /api/v1/discover/events?city=beijing&start_date=2025-10-22
GET /api/v1/discover/tips?category=etiquette
```

**Acceptance Criteria:**
- [ ] Filters work correctly
- [ ] Results load < 2 seconds
- [ ] Images load progressively
- [ ] Can switch between list/map view
- [ ] Tap on item shows details
- [ ] Bookmark/save functionality

---

## 7. Community Feed

### 7.1 Feed View

**User Story:**
> As a traveler, I want to see posts from other travelers so that I can get tips and connect with people.

**Feed Types:**
- **For You:** Personalized (interests, location)
- **Following:** Users you follow
- **Nearby:** Posts from people in your area
- **Trending:** Popular posts this week

**Post Types:**
- Text + Photos
- Question (tagged with ❓)
- Tip/Advice (tagged with 💡)
- Check-in (location tagged)
- Trip Report (longer post with itinerary)

**Post Card:**
```
┌─────────────────────────────┐
│  [@avatar] Alex Chen        │
│  📍 Beijing · 2 hours ago   │
├─────────────────────────────┤
│  Just had amazing Peking    │
│  duck at this place! 🦆     │
│                             │
│  [Photo Carousel]           │
│                             │
│  ❤️ 24  💬 5  🔗 2          │
│                             │
│  👁️ View 5 comments          │
└─────────────────────────────┘
```

**Actions:**
- ❤️ Like
- 💬 Comment
- 🔗 Share
- 🔖 Bookmark
- ⚠️ Report

**Technical Specs:**
- **Feed Algorithm:**
  - Personalized: User interests + engagement
  - Nearby: Geofencing (< 50km)
  - Trending: Engagement score (likes + comments)
- **Pagination:** Infinite scroll, 20 posts per page
- **Image Loading:** Lazy loading, thumbnail → full res

**API Endpoints:**
```
GET /api/v1/community/feed?type=for_you&page=1&limit=20
POST /api/v1/community/posts (create post)
POST /api/v1/community/posts/{id}/like
POST /api/v1/community/posts/{id}/comment
```

**Acceptance Criteria:**
- [ ] Feed loads < 2 seconds
- [ ] Smooth scrolling
- [ ] Images load progressively
- [ ] Like/comment actions instant
- [ ] Can filter by feed type
- [ ] Pull-to-refresh updates

---

### 7.2 Create Post

**User Story:**
> As a traveler, I want to share my experiences so that I can help other travelers and get feedback.

**Create Post Flow:**

**1. Tap "+" button**
**2. Select post type:**
   - 📷 Photo Post
   - ❓ Ask Question
   - 💡 Share Tip
   - 📍 Check-in

**3. Compose:**
   - Add photos (up to 5)
   - Write caption (max 500 characters)
   - Tag location (optional)
   - Add hashtags (e.g., #Beijing #Food)

**4. Post**

**UI Mock:**
```
┌─────────────────────────────┐
│  New Post            [Post] │
├─────────────────────────────┤
│  [+ Add Photos (0/5)]       │
│                             │
│  ┌───────────────────────┐ │
│  │ What's on your mind?  │ │
│  │                       │ │
│  │                       │ │
│  └───────────────────────┘ │
│  500 characters left        │
│                             │
│  📍 Add Location            │
│  #  Add Tags                │
│                             │
│  Post Type:                 │
│  ● Photo  ○ Question        │
│  ○ Tip    ○ Check-in        │
└─────────────────────────────┘
```

**Technical Specs:**
- **Photo Upload:**
  - Compress to < 1MB each
  - Resize to max 1920x1080
  - Progress indicator
- **Location:**
  - Current GPS or search
  - Attach place_id
- **Hashtags:**
  - Auto-suggest popular tags
  - Max 5 tags

**API Endpoint:**
```
POST /api/v1/community/posts
{
  "content": "Just had amazing Peking duck!",
  "images": ["url1", "url2"],
  "location_id": "uuid",
  "tags": ["beijing", "food"],
  "post_type": "photo"
}
```

**Acceptance Criteria:**
- [ ] Can add/remove photos easily
- [ ] Photo upload shows progress
- [ ] Location search works
- [ ] Hashtag autocomplete helpful
- [ ] Post publishes < 3 seconds
- [ ] Works offline (queued for upload)

---

## 8. User Profile

### 8.1 Profile View

**User Story:**
> As a user, I want to view my profile so that I can see my activity and achievements.

**Profile Sections:**

**1. Header:**
- Profile photo (editable)
- Username
- Bio (short description)
- Location (current city)
- Member since date

**2. Stats:**
- 📍 Places Visited (count)
- 🏆 Achievements Unlocked (count)
- ⭐ Total Points
- 👥 Followers / Following

**3. Tabs:**
- **Posts:** My posts
- **Trips:** Saved trips
- **Achievements:** Badges and progress
- **Saved:** Bookmarked places/posts

**UI Mock:**
```
┌─────────────────────────────┐
│  [← Back]          [⚙️]     │
├─────────────────────────────┤
│      [Profile Photo]        │
│      Alex Chen              │
│      "Backpacker from NYC"  │
│      📍 Beijing             │
│                             │
│  📍 12   🏆 8   ⭐ 3,450    │
│  👥 45 followers · 32 following
│                             │
│  [Edit Profile]             │
│                             │
│  [Posts][Trips][Badges][Saved]│
│  ──────                      │
│                             │
│  ┌───────────────────────┐ │
│  │ [Post thumbnail]      │ │
│  └───────────────────────┘ │
└─────────────────────────────┘
```

**Technical Specs:**
- **Profile Photo:** Upload, crop, compress
- **Stats:** Real-time from database
- **Tabs:** Lazy load content

**API Endpoints:**
```
GET /api/v1/users/{user_id}/profile
PATCH /api/v1/users/me/profile (update profile)
GET /api/v1/users/{user_id}/posts
GET /api/v1/users/{user_id}/trips
GET /api/v1/users/{user_id}/achievements
```

**Acceptance Criteria:**
- [ ] Profile loads < 1 second
- [ ] Photo upload works
- [ ] Stats accurate
- [ ] Tabs switch smoothly
- [ ] Can view other users' profiles

---

### 8.2 Settings

**User Story:**
> As a user, I want to customize my app settings so that it works best for me.

**Settings Categories:**

**Account:**
- Edit Profile
- Change Password
- Email Notifications
- Push Notifications
- Privacy Settings

**Preferences:**
- Language (App Interface)
- Default Currency
- Distance Units (km/miles)
- Temperature (°C/°F)
- Travel Style

**Safety:**
- Emergency Contacts (up to 5)
- Share Location
- Safety Alerts

**Data & Storage:**
- Downloaded Maps (manage)
- Clear Cache
- Data Usage Settings

**About:**
- Terms of Service
- Privacy Policy
- Help & Support
- App Version
- Log Out

**UI Mock:**
```
┌─────────────────────────────┐
│  Settings          [X]      │
├─────────────────────────────┤
│  Account                    │
│  › Edit Profile             │
│  › Change Password          │
│  › Notifications            │
│  › Privacy                  │
│                             │
│  Preferences                │
│  › Language: English ▾      │
│  › Currency: USD ▾          │
│  › Units: Kilometers ▾      │
│                             │
│  Safety                     │
│  › Emergency Contacts       │
│  › Location Sharing         │
│                             │
│  Data & Storage             │
│  › Downloaded Maps (1.2 GB) │
│  › Clear Cache (250 MB)     │
│                             │
│  About                      │
│  › Help & Support           │
│  › Terms of Service         │
│  › Version 1.0.0            │
│                             │
│  [Log Out]                  │
└─────────────────────────────┘
```

**Technical Specs:**
- **Settings Storage:** Local (shared_preferences) + Backend
- **Sync:** Push settings to backend on change
- **Validation:** Email format, password strength

**API Endpoints:**
```
GET /api/v1/users/me/settings
PATCH /api/v1/users/me/settings
```

**Acceptance Criteria:**
- [ ] Settings save instantly
- [ ] Changes reflected in app immediately
- [ ] Validation prevents errors
- [ ] Log out clears local data

---

## Summary: MVP Feature Checklist

### Must-Have (P0) - Blocking Beta Launch
- [ ] Authentication (Email, Social Login)
- [ ] Onboarding flow
- [ ] Offline maps (view, download)
- [ ] Camera translation (OCR)
- [ ] Text translator
- [ ] Phrasebook
- [ ] Budget tracker (add expense, view summary)
- [ ] SOS emergency button
- [ ] Live location sharing
- [ ] Home screen with recommendations
- [ ] Discover tab (places, food)
- [ ] Community feed (view, create post)
- [ ] User profile

### Should-Have (P1) - Nice to have for Beta
- [ ] Navigation (turn-by-turn)
- [ ] Currency converter
- [ ] Safety scores
- [ ] Events tab
- [ ] Tips content
- [ ] Comment on posts
- [ ] Follow users

### Could-Have (P2) - Post-Beta
- [ ] Trip planner (Phase 2)
- [ ] Challenges (Phase 2)
- [ ] AI assistant (Phase 2)

---

**Next Steps:**
1. Review and approve feature specs
2. Create detailed UI mockups in Figma
3. Define API contracts for each endpoint
4. Prioritize features for Sprint 1
5. Begin development!

---

**Document Version:** 1.0
**Last Updated:** 2025-10-22
**Next Review:** Weekly during Sprint Planning
