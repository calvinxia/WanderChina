# WanderChina - Screen Specifications & Wireframes

**Version:** 1.0
**Platform:** iOS & Android Mobile
**Last Updated:** 2025-10-22

---

## 📋 Table of Contents

1. [Onboarding Flow](#onboarding-flow)
2. [Authentication](#authentication)
3. [Home Screen](#home-screen)
4. [Discovery](#discovery)
5. [Maps & Navigation](#maps--navigation)
6. [Community](#community)
7. [Profile & Settings](#profile--settings)
8. [Additional Screens](#additional-screens)

---

## 🌟 Onboarding Flow

### Screen 1: Splash Screen

**Purpose:** Brand introduction and loading

**Layout (ASCII Mock):**
```
┌──────────────────────────────────────┐
│                                       │
│                                       │
│          [WanderChina Logo]           │
│                                       │
│         Discover China                │
│          Your Way                     │
│                                       │
│                                       │
│      [Loading Indicator]              │
│                                       │
│                                       │
└──────────────────────────────────────┘
```

**Elements:**
1. Logo: 120×120px, centered
2. Tagline: H2, centered, Gray 800
3. Loading spinner: 24×24px, Jade 500

**Animation:**
- Logo fades in (0.5s)
- Tagline fades in (0.3s delay)
- Spinner appears (1s delay)
- Auto-navigate after 2-3s

**Specifications:**
```yaml
Background: White or Gradient (Jade 100 → White)
Logo Position: Center, vertical offset -60px
Tagline: Below logo, 24px gap
Loading: Bottom center, 80px from bottom
Duration: 2-3 seconds (or until auth check complete)
```

---

### Screen 2: Onboarding Welcome

**Purpose:** Showcase app value proposition

**Layout:**
```
┌──────────────────────────────────────┐
│                                       │
│         [Hero Illustration]           │
│        (Great Wall vista)             │
│                                       │
│      Discover China Your Way          │
│                                       │
│    Your AI-powered companion for      │
│    exploring China's wonders          │
│                                       │
│        • • • ○ (Page indicators)      │
│                                       │
│   [      Skip      ]  [    Next    ]  │
└──────────────────────────────────────┘
```

**Elements:**
1. Illustration: 343×240px, centered
2. Title: H1, centered, Gray 900
3. Description: Body, centered, Gray 700
4. Page indicators: 4 dots, Jade 500 (active), Gray 300 (inactive)
5. Skip button: Text button, top-right
6. Next button: Primary button, bottom-center

**Content:**
- **Slide 1:** Discover China Your Way
  - Illustration: Great Wall + mountains
  - Features: Offline maps, AI assistant

- **Slide 2:** Break Language Barriers
  - Illustration: Camera translating menu
  - Features: Real-time translation, phrasebook

- **Slide 3:** Stay Safe, Explore Confidently
  - Illustration: SOS button + location sharing
  - Features: Emergency support, safety tips

- **Slide 4:** Join the Community
  - Illustration: Travelers connecting
  - Features: Find companions, local guides

---

### Screen 3: Permissions

**Purpose:** Request necessary app permissions

**Layout:**
```
┌──────────────────────────────────────┐
│  [X]                                  │
│                                       │
│      We Need Your Permission          │
│                                       │
│   To give you the best experience     │
│                                       │
│  ┌─────────────────────────────────┐ │
│  │ 📍 Location                     │ │
│  │ For maps and nearby places      │ │
│  │                  [Allow] ───────│ │
│  └─────────────────────────────────┘ │
│                                       │
│  ┌─────────────────────────────────┐ │
│  │ 📷 Camera                       │ │
│  │ For translation and check-ins   │ │
│  │                  [Allow] ───────│ │
│  └─────────────────────────────────┘ │
│                                       │
│  ┌─────────────────────────────────┐ │
│  │ 📂 Storage                      │ │
│  │ For offline maps and photos     │ │
│  │                  [Allow] ───────│ │
│  └─────────────────────────────────┘ │
│                                       │
│  ┌─────────────────────────────────┐ │
│  │ 🔔 Notifications                │ │
│  │ For important updates           │ │
│  │                  [Allow] ───────│ │
│  └─────────────────────────────────┘ │
│                                       │
│        [Continue to App]              │
└──────────────────────────────────────┘
```

**Specifications:**
```yaml
Title: H2, Gray 900, centered
Subtitle: Body, Gray 700, centered
Permission Card:
  Height: 80px
  Padding: 16px
  Background: Gray 50
  Border Radius: 12px
  Gap between cards: 12px
Icon: 32×32px, left
Text: Body, Gray 800 (title), Caption Gray 600 (description)
Allow Button: Secondary button, small, right
CTA Button: Primary, full-width, bottom, fixed
```

---

## 🔐 Authentication

### Screen 4: Login

**Layout:**
```
┌──────────────────────────────────────┐
│  [← Back]                             │
│                                       │
│         Welcome Back                  │
│                                       │
│   ┌───────────────────────────────┐  │
│   │ Email                         │  │
│   │ [user@example.com          ]  │  │
│   └───────────────────────────────┘  │
│                                       │
│   ┌───────────────────────────────┐  │
│   │ Password                      │  │
│   │ [••••••••••             ] 👁  │  │
│   └───────────────────────────────┘  │
│                                       │
│          [Forgot Password?]           │
│                                       │
│        ┌─────────────────────┐        │
│        │       Login         │        │
│        └─────────────────────┘        │
│                                       │
│          ───── OR ─────               │
│                                       │
│   [  Continue with Google   ]         │
│   [  Continue with Facebook ]         │
│                                       │
│     Don't have an account?            │
│           [Sign Up]                   │
└──────────────────────────────────────┘
```

**Specifications:**
```yaml
Layout:
  Padding: 24px (sides), 48px (top)
  Background: White

Title: H1, Gray 900, centered

Input Fields:
  Gap: 16px
  Label: Body Small, Gray 700, 8px above
  Input: 48px height, full width

Password Field:
  Toggle icon: 24×24px, Gray 500, right side

Forgot Password:
  Text button, Body Small, Jade 500, right-aligned

Login Button:
  Primary, large, full-width
  Margin: 24px top

Divider:
  Text: Caption, Gray 500
  Lines: 1px, Gray 200

Social Buttons:
  Secondary, medium, full-width
  Icon: 24×24px, left
  Gap: 12px

Sign Up Link:
  Caption, Gray 700
  "Sign Up" text: Jade 500, semibold
```

---

### Screen 5: Sign Up

**Layout:**
```
┌──────────────────────────────────────┐
│  [← Back]                             │
│                                       │
│         Create Account                │
│                                       │
│   ┌───────────────────────────────┐  │
│   │ Full Name *                   │  │
│   │ [                          ]  │  │
│   └───────────────────────────────┘  │
│                                       │
│   ┌───────────────────────────────┐  │
│   │ Email *                       │  │
│   │ [                          ]  │  │
│   └───────────────────────────────┘  │
│                                       │
│   ┌───────────────────────────────┐  │
│   │ Password *                    │  │
│   │ [••••••••              ] 👁   │  │
│   │ Password strength: [████░░]   │  │
│   └───────────────────────────────┘  │
│                                       │
│   ┌───────────────────────────────┐  │
│   │ Nationality                   │  │
│   │ [Select country         ] ▾   │  │
│   └───────────────────────────────┘  │
│                                       │
│   ☐ I agree to Terms & Privacy       │
│      Policy                           │
│                                       │
│        ┌─────────────────────┐        │
│        │     Sign Up         │        │
│        └─────────────────────┘        │
│                                       │
│    Already have an account?           │
│            [Login]                    │
└──────────────────────────────────────┘
```

**Validation:**
- Email: Real-time validation, show error icon
- Password: Strength meter (Weak/Medium/Strong)
- Required fields: Show error on blur if empty

---

## 🏠 Home Screen

### Screen 6: Home Dashboard

**Layout:**
```
┌──────────────────────────────────────┐
│  ☰  WanderChina          🔍  👤      │
├──────────────────────────────────────┤
│  📍 Beijing · 23°C ☀️  AQI: 45      │
├──────────────────────────────────────┤
│                                       │
│        Good Morning, Alex!            │
│                                       │
│  ┌──────────┬──────────┬──────────┐  │
│  │ 🗺️ Map  │ 🔤 Trans │ 💰Budget │  │
│  ├──────────┼──────────┼──────────┤  │
│  │ 📖 Phrase│ 🎯 Chall │ 👥 Comm  │  │
│  └──────────┴──────────┴──────────┘  │
│                                       │
│  Nearby Highlights          [View All]│
│  ┌───────────────────────────────┐   │
│  │ [Photo] Forbidden City        │   │
│  │ ★★★★☆ 0.8 km · $$            │   │
│  └───────────────────────────────┘   │
│  → Swipe for more                     │
│                                       │
│  Recommended for You        [View All]│
│  ┌───────────────────────────────┐   │
│  │ [Photo] Hutong Food Tour      │   │
│  │ 3 hours · Local guide         │   │
│  └───────────────────────────────┘   │
│                                       │
│  Your Active Challenge                │
│  ┌───────────────────────────────┐   │
│  │ Beijing Heritage Challenge    │   │
│  │ ████████░░ 60%  3/5 completed │   │
│  └───────────────────────────────┘   │
│                                       │
├──────────────────────────────────────┤
│ [Home][Planner][Discover][Chat][Me]  │
└──────────────────────────────────────┘
```

**Specifications:**
```yaml
Top Bar:
  Height: 56px
  Background: White
  Elements:
    - Menu icon: 24×24px, left (16px padding)
    - Title: H4, center or left
    - Search icon: 24×24px, right-16px
    - Profile icon: 32×32px, right-8px

Weather Widget:
  Height: 48px
  Background: Jade 100
  Padding: 12px 16px
  Layout: Location | Temperature | Weather | AQI

Greeting:
  Text: H2, Gray 900
  Padding: 24px 16px 16px

Quick Tools Grid:
  Columns: 3
  Rows: 2
  Gap: 12px
  Item:
    Height: 80px
    Background: White
    Border: 1px Gray 200
    Border Radius: 12px
    Icon: 32×32px, centered
    Label: Caption, Gray 800

Section Header:
  Text: H4, Gray 900
  "View All": Caption, Jade 500
  Padding: 24px 16px 12px

Nearby Card (Horizontal Scroll):
  Width: 280px
  Height: 120px
  Margin: 0 8px
  First card: 16px left margin

Active Challenge Card:
  Full width - 32px
  Height: 120px
  Background: Gradient (Jade 500 → Jade 700)
  Text: White
```

---

## 🧭 Discovery

### Screen 7: Discover Places

**Layout:**
```
┌──────────────────────────────────────┐
│  Discover                    [Filter] │
├──────────────────────────────────────┤
│  [        Search places...        ]🔍│
├──────────────────────────────────────┤
│  < [All][Food][Culture][Nature] >    │
├──────────────────────────────────────┤
│  Sort: Distance ▾         [Map View] │
├──────────────────────────────────────┤
│                                       │
│  ┌─────────────────────────────────┐ │
│  │ [Photo]  Forbidden City        │ │
│  │          ★★★★☆ (1,250)         │ │
│  │          0.8 km · $$  [♡]      │ │
│  └─────────────────────────────────┘ │
│                                       │
│  ┌─────────────────────────────────┐ │
│  │ [Photo]  Temple of Heaven      │ │
│  │          ★★★★★ (890)           │ │
│  │          3.2 km · $   [♡]      │ │
│  └─────────────────────────────────┘ │
│                                       │
│  ┌─────────────────────────────────┐ │
│  │ [Photo]  Summer Palace         │ │
│  │          ★★★★☆ (2,100)         │ │
│  │          12.5 km · $$  [♡]     │ │
│  └─────────────────────────────────┘ │
│                                       │
├──────────────────────────────────────┤
│ [Home][Planner][Discover][Chat][Me]  │
└──────────────────────────────────────┘
```

**Specifications:**
```yaml
Search Bar:
  Height: 44px
  Margin: 16px
  Placeholder: "Search places..."
  Icon: 24×24px, left

Filter Chips:
  Height: 32px
  Horizontal scroll
  Padding: 8px 16px
  Active: Jade 500 background, White text
  Inactive: Gray 100 background, Gray 800 text

Sort Dropdown:
  Height: 36px
  Text: Body Small
  Icon: Chevron down

Place Card:
  Height: 120px
  Margin: 16px (sides), 8px (vertical)
  Layout:
    - Image: 100×100px, left, rounded 12px
    - Content: Right side, padding 12px
      - Title: H4, Gray 900, max 2 lines
      - Rating: Caption, Gray 700, star icon
      - Meta: Caption, Gray 600 (distance, price)
    - Bookmark: Icon button, top-right
```

---

### Screen 8: Filter Modal (Bottom Sheet)

**Layout:**
```
┌──────────────────────────────────────┐
│         ────                          │
│                                       │
│  Filters                    [Reset]   │
│                                       │
│  Category                             │
│  ☑ Attractions  ☐ Restaurants         │
│  ☐ Hotels       ☐ Nightlife           │
│  ☐ Shopping     ☐ Nature              │
│                                       │
│  Distance                             │
│  ○ < 1 km       ● < 5 km              │
│  ○ < 10 km      ○ Any                 │
│                                       │
│  Rating                               │
│  [─────●───────────] 4+ stars         │
│                                       │
│  Price Level                          │
│  ☑ $   ☑ $$   ☐ $$$   ☐ $$$$        │
│                                       │
│  Special Features                     │
│  ☐ Wheelchair accessible              │
│  ☐ English speaking staff             │
│  ☐ Open now                           │
│                                       │
│        ┌─────────────────────┐        │
│        │   Apply Filters     │        │
│        └─────────────────────┘        │
└──────────────────────────────────────┘
```

---

## 🗺️ Maps & Navigation

### Screen 9: Map View

**Layout:**
```
┌──────────────────────────────────────┐
│  [    Search places or address... ]🔍│
│                                       │
│          [Full Screen Map]            │
│         • • • • (Place markers)       │
│                                       │
│                                   [🎯]│
│                                   [+] │
│                                   [-] │
│                                       │
│  ┌───── Draggable Bottom Sheet ────┐ │
│  │ ────                             │ │
│  │                                  │ │
│  │ [Photo] Forbidden City           │ │
│  │ ★★★★☆ · 0.8 km away              │ │
│  │ [Directions]  [Details]          │ │
│  └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

**Map Elements:**
- Current location: Blue dot with pulsing circle
- Place markers: Custom pin icons (color by category)
- User route: Jade 500 polyline (if navigating)
- Offline area: Shaded overlay (available offline)

**Bottom Sheet States:**
1. **Collapsed:** Peek (64px) - Shows place name
2. **Half:** Preview (240px) - Shows photo + quick info
3. **Full:** Detail (80% screen) - Full place details

---

### Screen 10: Turn-by-Turn Navigation

**Layout:**
```
┌──────────────────────────────────────┐
│                                       │
│           ↑  200m                     │
│      Turn right at                    │
│     Dongcheng Street                  │
│                                       │
│                                       │
│         [Route on Map]                │
│                                       │
│                                       │
│  ┌───────────────────────────────┐   │
│  │ 5.2 km  │  12 min  │  🚶     │   │
│  ├───────────────────────────────┤   │
│  │ [End Navigation]              │   │
│  └───────────────────────────────┘   │
└──────────────────────────────────────┘
```

**Elements:**
- Distance to next turn: H1, White, top
- Instruction: H3, White
- Street name: H4, White
- ETA panel: Fixed bottom, 80px height
- End button: Text button, center

**Voice Guidance:**
- "In 200 meters, turn right onto Dongcheng Street"
- Trigger at: 400m, 200m, 100m, 50m

---

## 👥 Community

### Screen 11: Community Feed

**Layout:**
```
┌──────────────────────────────────────┐
│  Community                      [+]   │
├──────────────────────────────────────┤
│  [For You][Following][Nearby][Trend]  │
├──────────────────────────────────────┤
│                                       │
│  ┌─────────────────────────────────┐ │
│  │ [@photo] Alex · Beijing · 2h   │ │
│  │                           [⋮]   │ │
│  │ Just had amazing Peking duck   │ │
│  │ at this place! 🦆              │ │
│  │                                 │ │
│  │ [Photo - Roast Duck]            │ │
│  │                                 │ │
│  │ ❤️ 24   💬 5   🔗 2            │ │
│  └─────────────────────────────────┘ │
│                                       │
│  ┌─────────────────────────────────┐ │
│  │ [@photo] Sarah · Xi'an · 5h    │ │
│  │                           [⋮]   │ │
│  │ Terra Cotta Warriors were      │ │
│  │ incredible! 😍                 │ │
│  │                                 │ │
│  │ [2 Photos - Swipe >]            │ │
│  │                                 │ │
│  │ ❤️ 47   💬 12  🔗 8            │ │
│  └─────────────────────────────────┘ │
│                                       │
├──────────────────────────────────────┤
│ [Home][Planner][Discover][Chat][Me]  │
└──────────────────────────────────────┘
```

**Post Card Specifications:**
```yaml
Card:
  Margin: 16px (sides), 8px (vertical)
  Padding: 16px
  Background: White
  Border Radius: 16px
  Shadow: 0px 2px 8px rgba(0,0,0,0.08)

Header:
  Avatar: 40×40px, left
  Name: Body, Gray 900, semibold
  Location + Time: Caption, Gray 600
  More icon: 24×24px, right

Content:
  Text: Body, Gray 800
  Max lines: 5 (show "Read more")

Images:
  Single: Full width, 16:9 ratio
  Multiple: Carousel, swipeable
  Border radius: 12px
  Gap: 8px (top)

Actions:
  Height: 40px
  Buttons: Icon + text, Gray 700
  Active (liked): Jade 500
  Gap: 24px
```

---

### Screen 12: Create Post

**Layout:**
```
┌──────────────────────────────────────┐
│  [Cancel]  New Post           [Post] │
├──────────────────────────────────────┤
│  ┌─────────────────────────────────┐ │
│  │ [@photo] Alex Chen              │ │
│  └─────────────────────────────────┘ │
│                                       │
│  ┌─────────────────────────────────┐ │
│  │ What's on your mind?            │ │
│  │                                 │ │
│  │                                 │ │
│  │ [Cursor]                        │ │
│  │                                 │ │
│  └─────────────────────────────────┘ │
│  500 characters left                  │
│                                       │
│  ┌───┬───┬───┬───┐ Add more...      │
│  │ + │ + │ + │ + │ [Camera Icon]    │
│  └───┴───┴───┴───┘                   │
│                                       │
│  📍 Forbidden City          [Change]  │
│  #  Add tags (optional)               │
│                                       │
│  Post Type:                           │
│  ● Photo  ○ Question  ○ Tip           │
│                                       │
└──────────────────────────────────────┘
```

---

## 👤 Profile & Settings

### Screen 13: My Profile

**Layout:**
```
┌──────────────────────────────────────┐
│  [← Back]                      [⚙️]  │
├──────────────────────────────────────┤
│         [@Photo - Large]              │
│          Alex Chen                    │
│      "Backpacker from NYC"            │
│         📍 Beijing                    │
│                                       │
│  📍 12   🏆 8   ⭐ 3,450              │
│  Places  Badges  Points               │
│                                       │
│  👥 45 followers · 32 following       │
│                                       │
│        [Edit Profile]                 │
│                                       │
├──────────────────────────────────────┤
│  [Posts][Trips][Badges][Saved]        │
│  ──────                               │
│                                       │
│  ┌─────────────────────────────────┐ │
│  │ [Post Thumbnail 1]              │ │
│  └─────────────────────────────────┘ │
│                                       │
│  ┌─────────────────────────────────┐ │
│  │ [Post Thumbnail 2]              │ │
│  └─────────────────────────────────┘ │
│                                       │
├──────────────────────────────────────┤
│ [Home][Planner][Discover][Chat][Me]  │
└──────────────────────────────────────┘
```

---

### Screen 14: Settings

**Layout:**
```
┌──────────────────────────────────────┐
│  [← Back]  Settings                   │
├──────────────────────────────────────┤
│                                       │
│  Account                              │
│  › Edit Profile                       │
│  › Change Password                    │
│  › Notifications                      │
│  › Privacy                            │
│                                       │
│  Preferences                          │
│  › Language: English ▾                │
│  › Currency: USD ▾                    │
│  › Units: Kilometers ▾                │
│  › Theme: Light ▾                     │
│                                       │
│  Safety                               │
│  › Emergency Contacts (3)             │
│  › Location Sharing                   │
│  › Safety Alerts            [●]       │
│                                       │
│  Data & Storage                       │
│  › Downloaded Maps (1.2 GB)           │
│  › Clear Cache (250 MB)               │
│  › Data Usage Settings                │
│                                       │
│  About                                │
│  › Help & Support                     │
│  › Terms of Service                   │
│  › Privacy Policy                     │
│  › Version 1.0.0                      │
│                                       │
│         [Log Out]                     │
│                                       │
└──────────────────────────────────────┘
```

---

## 🎯 Additional Screens

### Screen 15: SOS Emergency

**Layout:**
```
┌──────────────────────────────────────┐
│                                       │
│           🚨 EMERGENCY 🚨             │
│                                       │
│     Alert sent to 3 contacts          │
│     Location sharing: Active          │
│                                       │
│  Your Location:                       │
│  Dongcheng District, Beijing          │
│  [Mini Map]                           │
│                                       │
│  Emergency Numbers:                   │
│  ┌─────────────────────────────────┐ │
│  │ [📞]  110 - Police              │ │
│  └─────────────────────────────────┘ │
│  ┌─────────────────────────────────┐ │
│  │ [📞]  120 - Ambulance           │ │
│  └─────────────────────────────────┘ │
│  ┌─────────────────────────────────┐ │
│  │ [📞]  122 - Traffic Accident    │ │
│  └─────────────────────────────────┘ │
│                                       │
│  Nearest Hospital:                    │
│  Beijing United Hospital              │
│  1.2 km away  [Directions]            │
│                                       │
│         [Cancel Emergency]            │
│                                       │
└──────────────────────────────────────┘
```

**Color Scheme:**
- Background: Error 100 (light red tint)
- Title: Error 700
- Buttons: Error 500 (call buttons)

---

### Screen 16: Challenge Detail

**Layout:**
```
┌──────────────────────────────────────┐
│  [←]  Beijing Heritage          [♡]  │
├──────────────────────────────────────┤
│       [Hero Image - Forbidden City]   │
│       [Difficulty Badge: Intermediate]│
├──────────────────────────────────────┤
│                                       │
│  Beijing Heritage Challenge           │
│  ★ 500 points · 8 hours · 15 km      │
│                                       │
│  Visit 5 historical landmarks and     │
│  learn about Beijing's rich history   │
│                                       │
│  Progress: 3 / 5 completed            │
│  ████████░░░░ 60%                     │
│                                       │
│  Checkpoints:                         │
│  ┌─────────────────────────────────┐ │
│  │ ✓ 1. Forbidden City       +100  │ │
│  │   Completed 2 days ago          │ │
│  └─────────────────────────────────┘ │
│  ┌─────────────────────────────────┐ │
│  │ ✓ 2. Temple of Heaven     +100  │ │
│  │   Completed 1 day ago           │ │
│  └─────────────────────────────────┘ │
│  ┌─────────────────────────────────┐ │
│  │ ✓ 3. Summer Palace        +100  │ │
│  │   Completed today               │ │
│  └─────────────────────────────────┘ │
│  ┌─────────────────────────────────┐ │
│  │ ○ 4. Lama Temple          +100  │ │
│  │   1.2 km away  [Navigate]       │ │
│  └─────────────────────────────────┘ │
│  ┌─────────────────────────────────┐ │
│  │ ○ 5. Great Wall (Mutianyu) +100 │ │
│  │   72 km away  [Navigate]        │ │
│  └─────────────────────────────────┘ │
│                                       │
│  3,245 travelers completed            │
│                                       │
│        [Start Challenge]              │
│                                       │
└──────────────────────────────────────┘
```

---

## 📐 Component States Matrix

### Button States

| State | Background | Text | Border | Shadow | Scale |
|-------|-----------|------|--------|--------|-------|
| Default | Jade 500 | White | None | Yes | 1.0 |
| Hover | Jade 700 | White | None | Yes | 1.0 |
| Pressed | Jade 900 | White | None | None | 0.98 |
| Disabled | Gray 200 | Gray 400 | None | None | 1.0 |
| Loading | Jade 500 | Hidden | None | Yes | 1.0 |

---

## 🎨 Dark Mode Variants

**Key Changes:**
- Background: #121212 (instead of White)
- Cards: #1E1E1E (elevated surfaces)
- Text: White with 87% opacity (primary)
- Borders: White with 12% opacity
- Shadows: Increase elevation, reduce opacity

**Colors that stay the same:**
- Jade 500 (brand color)
- Semantic colors (success, error, warning)
- Icons (adjust to White when needed)

---

## ✅ Design Handoff Checklist

**For Each Screen:**
- [ ] All states designed (default, loading, error, empty)
- [ ] Dark mode variant created
- [ ] Responsive breakpoints (if applicable)
- [ ] Animation specs documented
- [ ] Copy finalized (no Lorem Ipsum)
- [ ] Assets exported (@1x, @2x, @3x)
- [ ] Accessibility annotations added
- [ ] Developer notes included

---

**Last Updated:** 2025-10-22
**Version:** 1.0
**Next Review:** Sprint Planning
