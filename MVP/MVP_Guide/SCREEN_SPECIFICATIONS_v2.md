# WanderChina — Screen Specifications & Wireframes

**Version:** 2.0
**Platform:** iOS & Android Mobile
**Last Updated:** 2026-02-13
**Previous Version:** 1.0 (2025-10-22)

---

## 📝 v2.0 变更说明

本次更新基于MVP范围收缩决策，主要变更如下：

| 类别 | 变更内容 |
|------|---------|
| **删除** | Community Feed、Create Post（社区功能延后至v2） |
| **删除** | Discover / Filter Modal（探索页合并入地图） |
| **删除** | Challenge Detail（gamification延后至v2） |
| **新增** | 地图翻译蒙层（高德底图 + 英/法/西文标注） |
| **新增** | 语音翻译悬浮按钮（百度ASR + DeepSeek + 百度TTS） |
| **新增** | AI行程规划器（DeepSeek驱动，支持单城市1-5天） |
| **更新** | 底部导航：`[Home][Map][Planner][Voice][Me]` |
| **更新** | Onboarding：3张slide（删除Community slide） |
| **更新** | 权限申请：新增麦克风权限 |
| **更新** | 城市范围：明确锁定北京、上海、广州、深圳、成都、西安 |
| **更新** | 语言支持：EN / FR / ES（地图翻译蒙层三语切换） |
| **更新** | Home快捷工具：替换Community和Challenge入口 |

---

## 📋 目录

1. [Onboarding Flow](#onboarding-flow)
2. [Authentication](#authentication)
3. [Home Screen](#home-screen)
4. [Map & Translation Overlay](#map--translation-overlay)
5. [AI Trip Planner](#ai-trip-planner)
6. [Voice Translation](#voice-translation)
7. [Profile & Settings](#profile--settings)
8. [Additional Screens](#additional-screens)
9. [Post-MVP Screens (v2)](#post-mvp-screens-v2)
10. [Component States Matrix](#component-states-matrix)
11. [Dark Mode Variants](#dark-mode-variants)
12. [Design Handoff Checklist](#design-handoff-checklist)

---

## 🌟 Onboarding Flow

### Screen 1: Splash Screen

**Purpose:** Brand introduction and loading

**Layout:**
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

**Purpose:** Showcase app value proposition（3 slides，删除原版 Community slide）

**Layout:**
```
┌──────────────────────────────────────┐
│                                       │
│         [Hero Illustration]           │
│                                       │
│      Discover China Your Way          │
│                                       │
│    Your AI-powered companion for      │
│    exploring China's wonders          │
│                                       │
│        • • ○  (Page indicators)       │
│                                       │
│   [      Skip      ]  [    Next    ]  │
└──────────────────────────────────────┘
```

**Elements:**
1. Illustration: 343×240px, centered
2. Title: H1, centered, Gray 900
3. Description: Body, centered, Gray 700
4. Page indicators: 3 dots, Jade 500 (active), Gray 300 (inactive)
5. Skip button: Text button, top-right
6. Next button: Primary button, bottom-center

**Content (3 Slides):**

- **Slide 1: Discover China Your Way**
  - Illustration: Great Wall + mountains
  - Subtext: AI trip planner for 6 major cities — Beijing, Shanghai, Guangzhou, Shenzhen, Chengdu, Xi'an

- **Slide 2: Break Language Barriers**
  - Illustration: Map with bilingual labels + voice bubble
  - Subtext: Translated maps & real-time voice translation in English, French and Spanish

- **Slide 3: Navigate with Confidence**
  - Illustration: Phone showing map with English labels
  - Subtext: Chinese maps in your language — no more getting lost

> ~~Slide 4: Join the Community~~ — 已移除，社区功能推迟至v2

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
│  │ 🎙️ Microphone                   │ │
│  │ For voice translation           │ │
│  │                  [Allow] ───────│ │
│  └─────────────────────────────────┘ │
│                                       │
│  ┌─────────────────────────────────┐ │
│  │ 📷 Camera                       │ │
│  │ For check-ins and photos        │ │
│  │                  [Allow] ───────│ │
│  └─────────────────────────────────┘ │
│                                       │
│  ┌─────────────────────────────────┐ │
│  │ 📂 Storage                      │ │
│  │ For offline maps and cache      │ │
│  │                  [Allow] ───────│ │
│  └─────────────────────────────────┘ │
│                                       │
│  ┌─────────────────────────────────┐ │
│  │ 🔔 Notifications                │ │
│  │ For important travel updates    │ │
│  │                  [Allow] ───────│ │
│  └─────────────────────────────────┘ │
│                                       │
│        [Continue to App]              │
└──────────────────────────────────────┘
```

**v2.0 变更：** 新增 🎙️ Microphone 权限卡片（语音翻译必需）

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
│   [  Continue with Apple    ]         │
│                                       │
│     Don't have an account?            │
│           [Sign Up]                   │
└──────────────────────────────────────┘
```

> **v2.0 变更：** Facebook 替换为 Apple（iOS 审核要求）

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
│   ┌───────────────────────────────┐  │
│   │ Preferred Language            │  │
│   │ ● English  ○ Français  ○ ES  │  │
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

> **v2.0 变更：** 新增 Preferred Language 字段（EN / FR / ES），同步设置地图翻译语言

**Validation:**
- Email: Real-time validation, show error icon
- Password: Strength meter (Weak / Medium / Strong)
- Required fields: Show error on blur if empty
- Language selection: Sets default map overlay language

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
│  │ 🗺️ Map  │ 🎙️ Voice │ 📅 Plan  │  │
│  ├──────────┼──────────┼──────────┤  │
│  │ 📖 Phrase│ 💰Budget │ 🚨 SOS   │  │
│  └──────────┴──────────┴──────────┘  │
│                                       │
│  Nearby Highlights          [View All]│
│  ┌───────────────────────────────┐   │
│  │ [Photo] Forbidden City        │   │
│  │ ★★★★☆ 0.8 km · Free          │   │
│  └───────────────────────────────┘   │
│  → Swipe for more                     │
│                                       │
│  Plan Your Next Trip        [Start]  │
│  ┌───────────────────────────────┐   │
│  │ ✨ Ask AI: "3 days in Chengdu │   │
│  │    for food lovers"           │   │
│  └───────────────────────────────┘   │
│                                       │
│  Supported Cities                     │
│  [BJ] [SH] [GZ] [SZ] [CD] [XA]      │
│                                       │
├──────────────────────────────────────┤
│   [Home]  [Map]  [Plan]  [🎙️] [Me]   │
└──────────────────────────────────────┘
```

> **v2.0 变更：**
> - 快捷工具：替换 `Challenge` → `Voice Translation`，替换 `Community` → `SOS`
> - 底部导航：`[Home][Map][Planner][Voice][Me]` (5 tabs)
> - 删除 "Your Active Challenge" 卡片
> - 新增 "Plan Your Next Trip" AI入口卡片
> - 新增 "Supported Cities" 6城市快速入口

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
  Background: Jade 50
  Padding: 12px 16px

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

Quick Tools (v2):
  Row 1: Map | Voice Translation | AI Planner
  Row 2: Phrasebook | Budget | SOS Emergency

AI Planner Card:
  Full width - 32px
  Height: 80px
  Background: Gradient (Jade 50 → White)
  Border: 1px Jade 200
  Input hint: Body, Gray 500

City Pills:
  Height: 32px
  Horizontal scroll
  Background: Jade 100
  Active: Jade 500
  Label: Caption, Gray 800

Bottom Navigation:
  Height: 56px + safe area
  Background: White
  Border top: 1px Gray 200
  Active icon: Jade 500
  Inactive icon: Gray 400
  Tabs: Home · Map · Planner · Voice · Me
```

---

## 🗺️ Map & Translation Overlay

### Screen 7: Map View with Translation Overlay

**Purpose:** 高德底图 + 英/法/西文翻译蒙层 + 语音翻译入口

**Layout:**
```
┌──────────────────────────────────────┐
│  [    Search places or address... ]🔍│
│  ┌──────────────────────────────┐    │
│  │ EN · FR · ES              [●]│    │  ← Language switcher + overlay toggle
│  └──────────────────────────────┘    │
│                                       │
│         [Gaode Map - Full Screen]     │
│                                       │
│   [Palace Museum]   [Tiananmen Sq]   │  ← Translation labels (badges)
│         ·                ·           │
│   [Qianmen St]      [Temple ...]     │
│                                       │
│                           [🎯 GPS]   │
│                           [+]        │
│                           [-]        │
│                                       │
│                     ┌──────────────┐ │
│                     │  🎙️          │ │  ← Voice translation button
│                     │ EN → 中      │ │
│                     └──────────────┘ │
│                                       │
│  ┌───── Draggable Bottom Sheet ────┐ │
│  │ ────                             │ │
│  │ [Photo] Palace Museum (故宫)     │ │
│  │ ★★★★☆ · 0.8 km away             │ │
│  │ [Directions]     [Details]       │ │
│  └─────────────────────────────────┘ │
├──────────────────────────────────────┤
│   [Home]  [Map]  [Plan]  [🎙️] [Me]   │
└──────────────────────────────────────┘
```

**Translation Overlay Behavior:**
```yaml
Trigger:
  Min zoom to show labels: 14.0
  Max labels on screen: 12
  Debounce after camera stops: 300ms

Label Priority:
  High (orange badge): Attraction, Museum, Park, Transport Hub
  Normal (white badge): Restaurant, Shopping, Other

Label Styles:
  Default (zoom ≥ 14): Badge with pointer triangle
  Detail (zoom ≥ 15.5): Badge + category caption
  Minimal (zoom ≥ 17): Text only, no background

Deduplication:
  Min distance between labels: 80px (screen coordinates)
  
Language Toggle:
  Position: Top bar, right of search bar
  Cycles: EN → FR → ES → EN
  Persists in user preferences
```

**Voice Button (悬浮):**
```yaml
Position: Right side, 90px above bottom nav + safe area
Size: 64×64px circle

States:
  Idle:      #FF6B35 orange, mic icon — "Tap & hold to speak"
  Recording: Red, pulsing scale 1.0→1.15, mic icon — "Listening..."
  Processing: Orange, spinner — "Translating..."
  Playing:   Green #4CAF50, volume icon — "Tap to stop"
  Error:     Auto-reset after 2s

Direction toggle (above mic button):
  "EN → 中" or "中 → EN" pill
  Tap to switch direction
  Size: 80px wide, 30px height

Translation result bubble (above direction toggle):
  Max width: 240px
  Shows: original text / translated text / processing time
  Auto-dismiss: 10s or on next recording
```

**Map Elements:**
- Current location: Blue dot with pulsing circle
- Custom markers: Color-coded by category (Jade = attraction, Orange = restaurant, Blue = transport)
- Route polyline: Jade 500
- Translation labels: `IgnorePointer` — does not intercept map gestures

**Bottom Sheet States:**
1. **Collapsed (64px):** Place name + distance
2. **Half (240px):** Photo + bilingual name + quick actions
3. **Full (80% screen):** Full details, opening hours, how to get there

---

### Screen 8: Turn-by-Turn Navigation

**Layout:**
```
┌──────────────────────────────────────┐
│                                       │
│           ↑  200m                     │
│      Turn right at                    │
│     Dongcheng Street                  │
│    (东城路)                            │
│                                       │
│         [Route on Map]                │
│                                       │
│  ┌───────────────────────────────┐   │
│  │ 5.2 km  │  12 min  │  🚶     │   │
│  ├───────────────────────────────┤   │
│  │ [End Navigation]              │   │
│  └───────────────────────────────┘   │
└──────────────────────────────────────┘
```

> **v2.0 变更：** 路口名称同时显示英文 + 中文（括号内）

**Elements:**
- Distance to next turn: H1, White, top
- Instruction: H3, White (English)
- Street name: H4, White + Gray 400 Chinese in brackets
- ETA panel: Fixed bottom, 80px height
- End button: Text button, center

**Voice Guidance:**
- "In 200 meters, turn right onto Dongcheng Street"
- Trigger at: 400m, 200m, 100m, 50m

---

## 📅 AI Trip Planner

### Screen 9: Planner Home

**Purpose:** DeepSeek驱动的AI行程规划入口

**Layout:**
```
┌──────────────────────────────────────┐
│  Plan Your Trip                  [?]  │
├──────────────────────────────────────┤
│                                       │
│  Which city?                          │
│  ┌──────┬──────┬──────┐              │
│  │ 北京  │ 上海  │ 广州  │              │
│  │  BJ  │  SH  │  GZ  │              │
│  ├──────┼──────┼──────┤              │
│  │ 深圳  │ 成都  │ 西安  │              │
│  │  SZ  │  CD  │  XA  │              │
│  └──────┴──────┴──────┘              │
│                                       │
│  How many days?                       │
│  [1]  [2]  [3]  [4]  [5]            │
│                                       │
│  What's your focus?                   │
│  ☑ Culture    ☑ Food                  │
│  ☐ Nature     ☐ Shopping              │
│  ☐ Nightlife  ☐ History               │
│                                       │
│  ─── Or describe in your words ────  │
│  ┌───────────────────────────────┐   │
│  │ e.g. "3 days in Chengdu,      │   │
│  │ love pandas and spicy food,   │   │
│  │ budget traveller"             │   │
│  └───────────────────────────────┘   │
│                                       │
│        ┌─────────────────────┐        │
│        │  ✨ Generate Plan   │        │
│        └─────────────────────┘        │
│                                       │
│  My Saved Trips (2)        [View All] │
│  ┌───────────────────────────────┐   │
│  │ 📅 Beijing · 5 days · Culture  │   │
│  │    Created Jan 12              │   │
│  └───────────────────────────────┘   │
│                                       │
├──────────────────────────────────────┤
│   [Home]  [Map]  [Plan]  [🎙️] [Me]   │
└──────────────────────────────────────┘
```

**Specifications:**
```yaml
City Grid:
  Columns: 3
  Gap: 8px
  Item:
    Height: 64px
    Background: White
    Active: Jade 500 bg, White text
    Border Radius: 12px
    Label: Chinese name + English abbreviation

Day Selector:
  Horizontal pills
  Active: Jade 500
  Range: 1–5 days

Interest Tags:
  Checkbox style chips
  2 columns
  Active: Jade 100 bg, Jade 700 text

Freetext Input:
  Height: 80px
  Placeholder: italic, Gray 400
  Max characters: 200

Generate Button:
  Primary, full-width
  Icon: sparkle ✨
  Loading state: "Generating your itinerary..."

Saved Trips:
  Card height: 64px
  Meta: city · duration · focus tag · date
```

---

### Screen 10: AI-Generated Itinerary

**Layout:**
```
┌──────────────────────────────────────┐
│  [← Back]  Beijing · 3 Days  [💾][🔗]│
├──────────────────────────────────────┤
│  ✨ Generated by AI · Tap to edit     │
├──────────────────────────────────────┤
│  [Day 1]  [Day 2]  [Day 3]           │
│  ──────                               │
│                                       │
│  Day 1 — Imperial Beijing             │
│                                       │
│  ┌─────────────────────────────────┐ │
│  │ 09:00  Palace Museum (故宫)     │ │
│  │        2–3 hrs · ¥60            │ │
│  │        [Navigate]  [Details]    │ │
│  └─────────────────────────────────┘ │
│                                       │
│  → Walk 10 min (0.8 km)               │
│                                       │
│  ┌─────────────────────────────────┐ │
│  │ 12:00  Tiananmen Square          │ │
│  │        1 hr · Free               │ │
│  │        [Navigate]  [Details]    │ │
│  └─────────────────────────────────┘ │
│                                       │
│  → Subway Line 1 (3 stops, 8 min)     │
│                                       │
│  ┌─────────────────────────────────┐ │
│  │ 14:00  Wangfujing Snack Street  │ │
│  │        1–2 hrs · Budget         │ │
│  │        [Navigate]  [Details]    │ │
│  └─────────────────────────────────┘ │
│                                       │
│  [+ Add Stop]                         │
│                                       │
│  ┌─────────────────────────────────┐ │
│  │  💬 Ask AI to adjust this plan  │ │
│  │  [e.g. "add more food stops"]   │ │
│  └─────────────────────────────────┘ │
│                                       │
│        [View on Map]                  │
│                                       │
└──────────────────────────────────────┘
```

**Specifications:**
```yaml
Day Tab Bar:
  Height: 40px
  Active underline: Jade 500, 2px
  Swipeable

Activity Card:
  Height: auto (min 80px)
  Padding: 12px 16px
  Background: White
  Border-left: 3px Jade 500
  Border Radius: 8px
  Shadow: 0px 1px 4px rgba(0,0,0,0.08)

Activity Card Content:
  Time: Caption, Jade 600, bold
  Name EN: Body, Gray 900, semibold
  Name ZH: Caption, Gray 500 (brackets)
  Duration + Cost: Caption, Gray 600
  Buttons: Text buttons, Jade 500, small

Transit Connector:
  Icon: arrow or transit icon
  Text: Caption, Gray 500
  Line: 1px dashed, Gray 200, vertical left

AI Chat Input:
  Height: 52px
  Background: Jade 50
  Border: 1px Jade 200
  Placeholder: "Ask AI to adjust..."
  Send icon: Jade 500

Save / Share:
  Position: Top-right header icons
  Save: bookmark icon
  Share: export icon
```

---

## 🎙️ Voice Translation

### Screen 11: Voice Translation (Full Screen Modal)

**Purpose:** 沉浸式双向语音翻译（从地图语音按钮进入，或底部导航Voice tab）

**Layout:**
```
┌──────────────────────────────────────┐
│  [✕]      Voice Translation           │
├──────────────────────────────────────┤
│                                       │
│  ┌───────────────────────────────┐   │
│  │  Direction                    │   │
│  │  [EN → 中]  ⇄  [中 → EN]    │   │
│  └───────────────────────────────┘   │
│                                       │
│  Language: [English ▾]               │
│            (or Français / Español)    │
│                                       │
│  ─── Conversation History ──────────  │
│                                       │
│  ┌─────────────────────────────────┐ │
│  │ You said:                       │ │
│  │ "Where is the nearest subway?"  │ │
│  │                     0.8s · EN   │ │
│  └─────────────────────────────────┘ │
│                                       │
│  ┌─────────────────────────────────┐ │
│  │ Translation:                    │ │
│  │ 最近的地铁站在哪里？             │ │
│  │              🔊 Tap to replay   │ │
│  └─────────────────────────────────┘ │
│                                       │
│                                       │
│  Quick Phrases:                       │
│  [How much?] [Where is...] [Help!]    │
│                                       │
│                                       │
│           ┌───────────┐               │
│           │     🎙️    │               │
│           │Hold to    │               │
│           │  speak    │               │
│           └───────────┘               │
│                                       │
└──────────────────────────────────────┘
```

**Specifications:**
```yaml
Direction Toggle:
  Two pills side by side
  Active: Jade 500 bg, White text
  Inactive: Gray 100 bg, Gray 600 text
  Width: 140px each

Language Dropdown:
  Height: 36px
  Options: English / Français / Español
  Change updates ASR dev_pid for next recording

Conversation History:
  Scrollable list
  "You said" card: Gray 50 bg, right-aligned bubble
  "Translation" card: Jade 50 bg, left-aligned bubble
  Each card shows: text + language tag + processing time
  Max visible: 4 exchanges (scroll for more)

Quick Phrases:
  Horizontal scroll pills
  Common travel phrases in target language
  Tap = skip recording, directly translate & play TTS

Mic Button:
  Size: 80×80px circle (larger than map overlay version)
  Idle: Jade 500 → #FF6B35 gradient
  Recording: Red + ripple animation
  Processing: Spinner
  Playing: Green + sound wave animation
  Label: "Hold to speak" / "Listening..." / "Translating..." / "Playing..."

State Flow:
  Idle → (hold) → Recording → (release) → Processing → Playing → Idle
  Processing timeout: 15s (ASR) + 10s (DeepSeek) + 10s (TTS)
  Error: toast + auto-reset 2s
```

---

## 👤 Profile & Settings

### Screen 12: My Profile

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
│  📍 12 Places  |  🗺️ 3 Trips         │
│                                       │
│        [Edit Profile]                 │
│                                       │
├──────────────────────────────────────┤
│  [Trips]  [Saved Places]  [History]  │
│  ──────                               │
│                                       │
│  ┌─────────────────────────────────┐ │
│  │ 📅 Beijing · 3 Days · Culture   │ │
│  │    Jan 12, 2026                  │ │
│  │    [View]  [Edit]  [Share]       │ │
│  └─────────────────────────────────┘ │
│                                       │
│  ┌─────────────────────────────────┐ │
│  │ 📅 Shanghai · 5 Days · Food     │ │
│  │    Dec 28, 2025                  │ │
│  │    [View]  [Edit]  [Share]       │ │
│  └─────────────────────────────────┘ │
│                                       │
├──────────────────────────────────────┤
│   [Home]  [Map]  [Plan]  [🎙️] [Me]   │
└──────────────────────────────────────┘
```

> **v2.0 变更：**
> - 删除 Posts / Badges / Points / Followers 统计（社区功能移除）
> - Profile tabs 改为：Trips · Saved Places · History
> - Trip card 新增 Share 按钮

---

### Screen 13: Settings

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
│  Map & Translation                    │
│  › Map Language: English ▾            │
│    (English / Français / Español)     │
│  › Label Style: Badge ▾               │
│    (Badge / Minimal / Floating)       │
│  › Show Translation Overlay  [●]      │
│                                       │
│  Preferences                          │
│  › App Language: English ▾            │
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
│  › Downloaded Map Data (1.2 GB)       │
│  › Translation Cache (45 MB)          │
│  › Clear Cache                        │
│                                       │
│  About                                │
│  › Help & Support                     │
│  › Terms of Service                   │
│  › Privacy Policy                     │
│  › Version 2.0.0                      │
│                                       │
│         [Log Out]                     │
│                                       │
└──────────────────────────────────────┘
```

> **v2.0 变更：**
> - 新增 "Map & Translation" 设置区块
>   - Map Language（地图翻译语言：EN/FR/ES）
>   - Label Style（标签样式：Badge / Minimal / Floating）
>   - Translation Overlay 开关
> - Data & Storage 新增 Translation Cache 条目
> - 删除 Downloaded Maps → 改为 Downloaded Map Data

---

## 🎯 Additional Screens

### Screen 14: SOS Emergency

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
│  (东城区, 北京)                         │
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
│  (国际友谊医院)  1.2 km  [Directions]  │
│                                       │
│  ┌─────────────────────────────────┐ │
│  │ 🎙️ Call for help in Chinese     │ │
│  │   Tap to auto-translate & call  │ │
│  └─────────────────────────────────┘ │
│                                       │
│         [Cancel Emergency]            │
│                                       │
└──────────────────────────────────────┘
```

> **v2.0 变更：**
> - 位置显示新增中文地名
> - 新增 "Call for help in Chinese" 语音快捷键（集成语音翻译）
> - 最近医院同时显示英文 + 中文名

**Color Scheme:**
- Background: Error 100 (light red tint)
- Title: Error 700
- Buttons: Error 500 (call buttons)

---

## 🔮 Post-MVP Screens (v2)

以下功能在MVP阶段暂缓开发，记录于此供v2规划参考。

### Community Feed（v2）
- 社区帖子流：旅行日记、美食打卡、问答
- 帖子互动：点赞、评论、分享
- 触发条件：月活 ≥ 1000 且核心功能留存率 ≥ 30%

### Create Post（v2）
- 图文编辑、位置标记、话题标签
- 与地图POI联动

### Challenge / Gamification（v2）
- 城市探索挑战
- 积分与徽章体系
- 挑战进度详情页

### Discover / Filter（v2）
- 独立探索频道
- 高级筛选（距离、评分、价格、无障碍）
- 地图视图切换

---

## 📐 Component States Matrix

### Button States

| State | Background | Text | Border | Shadow | Scale |
|-------|-----------|------|--------|--------|-------|
| Default | Jade 500 | White | None | Yes | 1.0 |
| Hover | Jade 700 | White | None | Yes | 1.0 |
| Pressed | Jade 900 | White | None | None | 0.98 |
| Disabled | Gray 200 | Gray 400 | None | None | 1.0 |
| Loading | Jade 500 | Hidden + Spinner | None | Yes | 1.0 |

### Translation Label States

| State | Style | Background | Text Color |
|-------|-------|-----------|-----------|
| High Priority (Attraction) | Badge | #E6FF6B35 orange | White |
| Normal | Badge | #E6FFFFFF white | Gray 900 |
| Minimal (high zoom) | Text only | Transparent | Gray 900 + white shadow |
| Floating | Gradient | Jade gradient | White |
| Loading | Skeleton | Gray 100 animated | — |

### Voice Button States

| State | Color | Icon | Animation |
|-------|-------|------|-----------|
| Idle | #FF6B35 | mic | None |
| Recording | Red #F44336 | mic | Pulse scale 1.0↔1.15 |
| Processing | Orange | spinner | Rotate |
| Playing | Green #4CAF50 | volume_up | None |
| Error | Gray | mic_off | Auto-reset 2s |

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
- #FF6B35 (voice button orange)
- Semantic colors (success, error, warning)
- Translation label badge orange (#FF6B35)

**Map Overlay in Dark Mode:**
- Badge background: rgba(30,30,30, 0.90)
- High priority badge: #FF6B35 unchanged
- Label text: White

---

## ✅ Design Handoff Checklist

**For Each Screen:**
- [ ] All states designed (default, loading, error, empty)
- [ ] Dark mode variant created
- [ ] Translation overlay shown on all map screens
- [ ] Voice button positioned correctly (above nav bar + safe area)
- [ ] Bottom nav uses v2 tabs: Home · Map · Planner · Voice · Me
- [ ] Animation specs documented
- [ ] Copy in English (primary language for foreign tourist users)
- [ ] Assets exported (@1x, @2x, @3x)
- [ ] Accessibility annotations added
- [ ] Developer notes included

**MVP Priority Order:**
1. Onboarding + Auth (Screen 1–5)
2. Home Dashboard (Screen 6)
3. Map + Translation Overlay (Screen 7)
4. Voice Translation (Screen 11)
5. AI Planner (Screen 9–10)
6. Profile + Settings (Screen 12–13)
7. Navigation + SOS (Screen 8, 14)

---

**Last Updated:** 2026-02-13
**Version:** 2.0
**Previous Version:** 1.0 (2025-10-22)
**Next Review:** After Beta Launch
