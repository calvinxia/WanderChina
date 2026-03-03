# WanderChina - Figma Design System Guide

**Version:** 1.0
**Platform:** Mobile (iOS & Android)
**Design Tool:** Figma
**Last Updated:** 2025-10-22

---

## 📋 Table of Contents

1. [Getting Started](#getting-started)
2. [Design Principles](#design-principles)
3. [Color System](#color-system)
4. [Typography](#typography)
5. [Spacing & Grid](#spacing--grid)
6. [Icons & Illustrations](#icons--illustrations)
5. [Components Library](#components-library)
8. [Screen Templates](#screen-templates)
9. [Design Tokens](#design-tokens)
10. [Figma File Structure](#figma-file-structure)

---

## 🚀 Getting Started

### Figma Project Setup

**Project Name:** WanderChina Design System v1.0

**File Structure:**
```
WanderChina/
├── 🎨 Design System
│   ├── 01 - Foundations (Colors, Typography, Spacing)
│   ├── 02 - Components (Buttons, Cards, Forms)
│   ├── 03 - Patterns (Navigation, Modals, Lists)
│   └── 04 - Templates (Screen layouts)
├── 📱 Mobile Screens
│   ├── 01 - Onboarding & Auth
│   ├── 02 - Home & Discovery
│   ├── 03 - Maps & Navigation
│   ├── 04 - Community & Social
│   ├── 05 - Profile & Settings
│   └── 06 - Challenges & Gamification
├── 🖼️ Assets
│   ├── Icons
│   ├── Illustrations
│   └── Photos
└── 📐 Prototypes
    ├── User Flow 1 - Onboarding
    ├── User Flow 2 - Discovery
    └── User Flow 3 - Check-in
```

### Canvas Size & Frames

**Mobile Artboards:**
- **iOS (iPhone 14 Pro):** 393 × 852 px
- **Android (Pixel 7):** 412 × 915 px
- **Design at:** @2x (retina)

**Safe Areas:**
- **iOS Status Bar:** 44 px (top)
- **iOS Bottom Bar:** 34 px (bottom)
- **Android Status Bar:** 24 px (top)
- **Android Navigation:** 48 px (bottom)

---

## 🎨 Design Principles

### Core Principles

**1. Offline-First**
- Clear offline indicators
- Sync status visibility
- Downloaded content badges

**2. Safety-Oriented**
- Emergency features always accessible
- High contrast for critical actions
- Clear error states

**3. Traveler-Friendly**
- Minimal text, maximum visuals
- Universal icons
- Multi-language ready

**4. Delightful**
- Smooth animations
- Celebratory moments
- Gamification elements

**5. Accessible**
- WCAG AA compliance
- Touch target minimum 44×44 px
- Color contrast ratio ≥ 4.5:1

---

## 🌈 Color System

### Brand Colors

#### Primary Palette

**Jade Green (Primary)**
```
Jade 900: #1B5E3D (Darkest)
Jade 700: #2E8B57 (Dark)
Jade 500: #3BAA7A (Primary) ← Main brand color
Jade 300: #6BC99D (Light)
Jade 100: #B8E6D5 (Lightest)
```

**Usage:**
- Primary CTA buttons
- Active navigation items
- Progress indicators
- Success states

---

**Sandstone (Secondary)**
```
Sand 900: #C4A87D (Darkest)
Sand 700: #D9C299 (Dark)
Sand 500: #F5E4C3 (Secondary) ← Accent color
Sand 300: #F8EDDA (Light)
Sand 100: #FBF6ED (Lightest)
```

**Usage:**
- Secondary buttons
- Background highlights
- Subtle dividers
- Card backgrounds

---

#### Neutral Colors

**Gray Scale**
```
Gray 900: #1A1A1A (Almost Black)
Gray 800: #333333 (Charcoal) ← Primary text
Gray 700: #4D4D4D
Gray 600: #666666
Gray 500: #808080
Gray 400: #999999 ← Secondary text
Gray 300: #B3B3B3
Gray 200: #CCCCCC ← Borders
Gray 100: #E6E6E6 ← Light backgrounds
Gray 50:  #F5F5F5 (Off-white)
```

---

#### Semantic Colors

**Success (Green)**
```
Success 700: #0F7B3E
Success 500: #10B759 ← Primary
Success 300: #6FDB9F
Success 100: #D4F4E2
```

**Warning (Yellow)**
```
Warning 700: #B76E00
Warning 500: #FFA500 ← Primary
Warning 300: #FFC34D
Warning 100: #FFE9B8
```

**Error (Red)**
```
Error 700: #C62828
Error 500: #F44336 ← Primary
Error 300: #EF5350
Error 100: #FFCDD2
```

**Info (Blue)**
```
Info 700: #1565C0
Info 500: #2196F3 ← Primary
Info 300: #64B5F6
Info 100: #BBDEFB
```

---

### Dark Mode Colors

**Dark Mode Palette**
```
Background:
  - Primary: #121212
  - Secondary: #1E1E1E
  - Tertiary: #2C2C2C

Text:
  - Primary: #FFFFFF (opacity 87%)
  - Secondary: #FFFFFF (opacity 60%)
  - Disabled: #FFFFFF (opacity 38%)

Surfaces:
  - Elevated: #1F1F1F
  - Overlay: #2C2C2C
  - Card: #242424
```

---

### Color Usage Guidelines

**Accessibility:**
- **Text on Jade 500:** Use White (#FFFFFF)
- **Text on Sand 500:** Use Gray 800 (#333333)
- **Text on Gray 100:** Use Gray 800 (#333333)
- **Text on Dark Background:** Use White with 87% opacity

**Contrast Ratios (WCAG AA):**
- **Normal Text:** ≥ 4.5:1
- **Large Text (≥18pt):** ≥ 3:1
- **UI Components:** ≥ 3:1

---

## ✍️ Typography

### Font Families

**Primary Font (English/Latin):**
- **iOS:** SF Pro Rounded
- **Android:** Google Sans / Roboto Rounded
- **Fallback:** System Default

**Secondary Font (Chinese):**
- **Simplified Chinese:** Noto Sans SC
- **Traditional Chinese:** Noto Sans TC

**Monospace (Code/Numbers):**
- SF Mono / Roboto Mono

---

### Type Scale

| Style | Size | Weight | Line Height | Letter Spacing | Usage |
|-------|------|--------|-------------|----------------|-------|
| **H1** | 32px | Bold (700) | 40px | -0.5px | Page titles |
| **H2** | 28px | Bold (700) | 36px | -0.3px | Section headers |
| **H3** | 24px | Semibold (600) | 32px | 0px | Card titles |
| **H4** | 20px | Semibold (600) | 28px | 0px | Subsection headers |
| **Body Large** | 18px | Regular (400) | 28px | 0px | Prominent body text |
| **Body** | 16px | Regular (400) | 24px | 0px | Default body text |
| **Body Small** | 14px | Regular (400) | 20px | 0px | Secondary text |
| **Caption** | 12px | Regular (400) | 16px | 0.3px | Captions, labels |
| **Overline** | 11px | Medium (500) | 16px | 1px | Uppercase labels |
| **Button Large** | 18px | Semibold (600) | 24px | 0.5px | Primary CTAs |
| **Button** | 16px | Semibold (600) | 20px | 0.5px | Standard buttons |
| **Button Small** | 14px | Medium (500) | 18px | 0.3px | Small buttons |

---

### Text Styles in Figma

**Create Text Styles:**
1. Select text layer
2. Click "Text styles" (4-dot icon)
3. Create style: `WanderChina/Typography/H1`
4. Naming convention: `Category/Subcategory/Name`

**Example Hierarchy:**
```
WanderChina/
├── Typography/
│   ├── Heading/
│   │   ├── H1
│   │   ├── H2
│   │   ├── H3
│   │   └── H4
│   ├── Body/
│   │   ├── Large
│   │   ├── Regular
│   │   └── Small
│   ├── Caption/
│   │   └── Default
│   └── Button/
│       ├── Large
│       ├── Regular
│       └── Small
```

---

## 📐 Spacing & Grid

### 8-Point Grid System

**Base Unit:** 8px

**Spacing Scale:**
```
4px   - XXS (Minimal)
8px   - XS  (Compact)
12px  - S   (Tight)
16px  - M   (Default)
24px  - L   (Relaxed)
32px  - XL  (Spacious)
48px  - XXL (Wide)
64px  - XXXL (Extra wide)
```

**Usage Guidelines:**
- **Padding inside components:** 8px, 12px, 16px
- **Margins between elements:** 16px, 24px
- **Sections spacing:** 32px, 48px
- **Screen padding:** 16px (sides), 24px (top/bottom)

---

### Layout Grid

**Mobile Grid (375px baseline):**
```
Columns: 4 columns
Gutter: 16px
Margin: 16px (left/right)
Column width: 79.75px (auto)
```

**Responsive Breakpoints:**
- **Small (iPhone SE):** 320px
- **Medium (iPhone 14):** 390px
- **Large (iPhone 14 Pro Max):** 430px
- **Tablet:** 768px

---

### Auto Layout in Figma

**Auto Layout Settings:**
```
Direction: Vertical (most common)
Gap: 16px (default)
Padding: 16px (horizontal), 16px (vertical)
Alignment: Top-left
Resizing: Hug contents (most components)
```

**Naming Convention:**
- Add `🔲` prefix for auto-layout frames
- Example: `🔲 Card - Restaurant`

---

## 🎯 Icons & Illustrations

### Icon System

**Icon Style:**
- **Type:** Outline (stroke-based)
- **Stroke Weight:** 2px
- **Corner Radius:** 2px (rounded)
- **Grid:** 24×24 px
- **Export:** SVG, @1x @2x @3x PNG

**Icon Sizes:**
```
Small:  16×16 px (inline icons)
Medium: 24×24 px (default)
Large:  32×32 px (prominent actions)
XLarge: 48×48 px (hero icons)
```

**Icon Colors:**
```
Active:   Jade 500 (#3BAA7A)
Inactive: Gray 400 (#999999)
Disabled: Gray 300 (#B3B3B3)
Error:    Error 500 (#F44336)
```

---

### Icon Categories

**1. Navigation Icons (Bottom Tab Bar)**
- Home (outlined house)
- Planner (outlined calendar)
- Discover (outlined compass)
- Chat (outlined message bubble)
- Profile (outlined user)

**2. Action Icons**
- Search (magnifying glass)
- Add (plus in circle)
- Filter (funnel)
- Share (share arrow)
- Bookmark (outlined bookmark)
- Like (outlined heart)

**3. Status Icons**
- Checkmark (success)
- Warning (exclamation triangle)
- Error (X in circle)
- Info (i in circle)
- Offline (cloud with slash)

**4. Category Icons**
- Food (fork & knife)
- Accommodation (bed)
- Transport (car/bus)
- Attraction (camera)
- Nature (tree)
- Culture (museum building)

---

### Illustration Style

**Characteristics:**
- **Style:** Flat vector with subtle gradients
- **Palette:** Jade, Sand, Gray tones
- **Elements:** Chinese cultural motifs (simplified)
- **Usage:** Onboarding, empty states, celebrations

**Gradient Style:**
```
Direction: 135° (diagonal)
Color 1: Jade 500 (#3BAA7A)
Color 2: Jade 300 (#6BC99D)
```

**Examples:**
- Onboarding: Great Wall silhouette with gradient
- Empty state: Panda holding sign
- Success: Fireworks with Chinese lanterns

---

## 🧩 Components Library

### 1. Buttons

#### Primary Button

**Specs:**
```
Width: Auto (min 120px) or Full-width
Height: 48px (Large), 40px (Medium), 32px (Small)
Background: Jade 500
Text: White, Semibold 16px
Border Radius: 24px (pill-shaped)
Padding: 16px (horizontal), 12px (vertical)
Shadow: 0px 2px 8px rgba(59, 170, 122, 0.2)
```

**States:**
- Default: Jade 500 background
- Hover: Jade 700 background
- Pressed: Jade 900 background + scale(0.98)
- Disabled: Gray 200 background, Gray 400 text

**Variants:**
```
Size: Large / Medium / Small
State: Default / Hover / Pressed / Disabled
Full Width: True / False
```

---

#### Secondary Button

**Specs:**
```
Width: Auto (min 120px) or Full-width
Height: 48px / 40px / 32px
Background: Transparent
Text: Jade 500, Semibold 16px
Border: 2px solid Jade 500
Border Radius: 24px
Padding: 16px, 12px
```

**States:**
- Default: Outlined with Jade 500
- Hover: Background Jade 100
- Pressed: Background Jade 200
- Disabled: Border Gray 300, Text Gray 400

---

#### Icon Button

**Specs:**
```
Size: 44×44 px (touch target)
Icon Size: 24×24 px
Background: Transparent or Gray 100
Border Radius: 22px (circular)
```

**Usage:**
- Navigation back button
- More options (3-dot menu)
- Close modal (X icon)

---

### 2. Cards

#### Place Card (Horizontal)

**Specs:**
```
Width: Full width - 32px margin
Height: 120px
Background: White
Border Radius: 16px
Shadow: 0px 2px 12px rgba(0, 0, 0, 0.08)
Padding: 12px

Layout:
├── Image (100×100 px, rounded 12px) - Left
└── Content (Auto width) - Right
    ├── Title (Body, Gray 800, max 2 lines)
    ├── Category + Distance (Caption, Gray 600)
    ├── Rating (⭐ icon + text)
    └── Price (Body Small, Jade 500)
```

**Figma Component:**
```
Component Name: Card/Place/Horizontal
Variants:
  - Has Bookmark: True / False
  - Is Saved: True / False
```

---

#### Challenge Card

**Specs:**
```
Width: 280px (carousel item)
Height: 360px
Background: White
Border Radius: 20px
Shadow: 0px 4px 16px rgba(0, 0, 0, 0.1)

Layout:
├── Hero Image (280×180 px, top)
├── Badge (Difficulty tag, overlay top-right)
└── Content (padding 16px)
    ├── Title (H4, Gray 900, max 2 lines)
    ├── Description (Body Small, Gray 600, max 3 lines)
    ├── Stats (Points, Time, Distance)
    └── Progress Bar (if in progress)
```

---

#### Post Card (Community Feed)

**Specs:**
```
Width: Full width - 32px margin
Height: Auto (dynamic)
Background: White
Border Radius: 16px
Padding: 16px

Layout:
├── Header
│   ├── Avatar (40×40 px, circular)
│   ├── Username + Location
│   └── More options (icon button)
├── Content
│   ├── Text (Body, max 5 lines with "Read more")
│   └── Image Gallery (optional, 1-5 images)
├── Actions
│   ├── Like button + count
│   ├── Comment button + count
│   └── Share button
└── Timestamp (Caption, Gray 500)
```

---

### 3. Form Elements

#### Text Input

**Specs:**
```
Width: Full width
Height: 48px
Background: Gray 50
Border: 1px solid Gray 200
Border Radius: 12px
Padding: 12px 16px
Text: Body, Gray 800
Placeholder: Body, Gray 400
```

**States:**
- Default: Border Gray 200
- Focus: Border Jade 500, Shadow 0px 0px 0px 4px rgba(59, 170, 122, 0.1)
- Error: Border Error 500, Error message below
- Disabled: Background Gray 100, Text Gray 400

**Label:**
```
Position: Above input, 8px gap
Text: Body Small, Gray 700, Semibold
Required indicator: Red asterisk (*)
```

---

#### Search Bar

**Specs:**
```
Width: Full width
Height: 44px
Background: Gray 100
Border Radius: 22px (pill-shaped)
Padding: 12px 16px

Layout:
├── Search icon (16×16 px, Gray 500) - Left
├── Input text (Body, Gray 800) - Center
└── Clear button (X icon) - Right (when has text)
```

---

#### Dropdown / Select

**Specs:**
```
Width: Full width
Height: 48px
Background: White
Border: 1px solid Gray 200
Border Radius: 12px
Padding: 12px 16px

Layout:
├── Selected value (Body, Gray 800) - Left
└── Chevron down icon - Right

Dropdown Menu:
  Background: White
  Border Radius: 12px
  Shadow: 0px 4px 20px rgba(0, 0, 0, 0.15)
  Max Height: 240px (scrollable)
  Item Height: 48px
  Item Hover: Background Gray 100
  Item Selected: Background Jade 100, Text Jade 700
```

---

#### Checkbox

**Specs:**
```
Size: 24×24 px (touch target 44×44 px)
Border: 2px solid Gray 300
Border Radius: 6px
Background (unchecked): Transparent
Background (checked): Jade 500
Checkmark: White, 16×16 px icon
```

---

#### Radio Button

**Specs:**
```
Size: 24×24 px (touch target 44×44 px)
Border: 2px solid Gray 300
Border Radius: 12px (circular)
Background (unchecked): Transparent
Background (checked): White
Inner Dot (checked): Jade 500, 12×12 px
```

---

#### Toggle Switch

**Specs:**
```
Width: 48px
Height: 28px
Background (off): Gray 300
Background (on): Jade 500
Border Radius: 14px
Handle: 24×24 px, White circle
Handle Position (off): 2px from left
Handle Position (on): 2px from right
Transition: 0.2s ease
```

---

### 4. Navigation

#### Bottom Tab Bar

**Specs:**
```
Width: Full width
Height: 80px (iOS with safe area), 56px (Android)
Background: White
Shadow: 0px -2px 8px rgba(0, 0, 0, 0.05)

Tab Item:
  Width: 20% (5 tabs)
  Icon: 24×24 px
  Label: Caption, Semibold
  Active: Jade 500 (icon + text)
  Inactive: Gray 500

Safe Area (iOS):
  Bottom: 34px padding
```

**Tab Items:**
1. Home (house icon)
2. Planner (calendar icon)
3. Discover (compass icon)
4. Chat (message icon)
5. Profile (user icon)

---

#### Top Navigation Bar

**Specs:**
```
Width: Full width
Height: 44px (iOS), 56px (Android)
Background: White or Transparent (overlay)
Padding: 0px 16px

Layout:
├── Back button (icon button, left) - Optional
├── Title (H4, Gray 900, center or left)
└── Action buttons (icon buttons, right) - Optional
```

**Variants:**
- **Standard:** White background, title left
- **Centered:** Title centered, back button left
- **Transparent:** Overlay on image/map
- **Search:** Search bar instead of title

---

#### Hamburger Menu (Side Drawer)

**Specs:**
```
Width: 280px (75% screen width)
Height: Full screen
Background: White
Shadow: 4px 0px 16px rgba(0, 0, 0, 0.1)
Padding: 24px 16px

Layout:
├── Header (User profile section)
│   ├── Avatar (64×64 px)
│   ├── Name (H4, Gray 900)
│   └── Points badge (Jade chip)
├── Menu Items (48px height each)
│   ├── Icon (24×24 px, left)
│   ├── Label (Body, Gray 800)
│   └── Chevron right (optional)
└── Footer (Settings, Logout)
```

---

### 5. Modals & Overlays

#### Bottom Sheet

**Specs:**
```
Width: Full width
Max Height: 90% screen height
Background: White
Border Radius: 24px (top corners only)
Shadow: 0px -4px 20px rgba(0, 0, 0, 0.15)

Handle (drag indicator):
  Width: 32px
  Height: 4px
  Background: Gray 300
  Border Radius: 2px
  Position: Center top, 12px from top

Content Padding: 24px 16px
```

**Usage:**
- Filter options
- Share options
- Place details (preview)
- Action confirmations

---

#### Dialog (Alert)

**Specs:**
```
Width: 320px (centered)
Max Width: 90% screen width
Background: White
Border Radius: 20px
Shadow: 0px 8px 24px rgba(0, 0, 0, 0.2)
Padding: 24px

Layout:
├── Icon (48×48 px, optional)
├── Title (H3, Gray 900, centered)
├── Message (Body, Gray 700, centered)
└── Actions (buttons, horizontal or stacked)
    ├── Cancel (Secondary button)
    └── Confirm (Primary button)
```

**Types:**
- Success (green checkmark icon)
- Warning (yellow warning icon)
- Error (red X icon)
- Info (blue info icon)

---

### 6. Lists & Data Display

#### List Item (Standard)

**Specs:**
```
Width: Full width
Height: 64px (single line), 88px (two lines)
Background: White
Padding: 12px 16px
Border Bottom: 1px solid Gray 100

Layout:
├── Leading (40×40 px, left) - Icon or Avatar
├── Content (auto width, center)
│   ├── Primary text (Body, Gray 900)
│   └── Secondary text (Caption, Gray 600) - Optional
└── Trailing (right) - Icon, Switch, or Chevron
```

---

#### Badge / Chip

**Specs:**
```
Height: 24px
Padding: 4px 12px
Background: Jade 100 (default), Sand 100, Error 100, etc.
Text: Caption, Semibold, Jade 700 (or matching color)
Border Radius: 12px
```

**Variants:**
- **Default:** Jade 100 background
- **Warning:** Warning 100 background
- **Error:** Error 100 background
- **Info:** Info 100 background
- **Outlined:** Transparent background, 1px border

**Usage:**
- Status tags (Open, Closed)
- Category labels (Food, Culture)
- Difficulty levels (Beginner, Expert)

---

#### Progress Bar

**Specs:**
```
Width: Full width or fixed width
Height: 8px
Background: Gray 200
Fill: Jade 500
Border Radius: 4px

With Label:
  Position: Above or inline
  Text: Caption, Gray 700
  Format: "3 / 5 completed" or "60%"
```

---

#### Avatar

**Specs:**
```
Sizes:
  - Small: 32×32 px
  - Medium: 40×40 px
  - Large: 64×64 px
  - XLarge: 96×96 px

Border Radius: 50% (circular)
Border: 2px solid White (optional, for overlapping)
Placeholder: Initials on Jade 500 background

Online Indicator:
  Size: 12×12 px
  Position: Bottom-right corner
  Border: 2px solid White
  Background: Success 500 (online), Gray 400 (offline)
```

---

### 7. Feedback & Alerts

#### Toast / Snackbar

**Specs:**
```
Width: Full width - 32px margin
Height: Auto (min 48px)
Background: Gray 900 (90% opacity)
Border Radius: 12px
Padding: 12px 16px
Position: Bottom (16px from bottom)
Animation: Slide up + fade in

Layout:
├── Icon (16×16 px, left) - Optional
├── Message (Body Small, White)
└── Action button (Caption, Jade 300) - Optional

Auto-dismiss: 3-5 seconds
```

---

#### Loading Spinner

**Specs:**
```
Size: 24×24 px (small), 48×48 px (large)
Color: Jade 500
Style: Circular, rotating
Animation: Continuous rotation (1s duration)

Full Screen Overlay:
  Background: White (70% opacity) or Gray 900 (50% opacity)
  Spinner: Large (48×48 px), centered
  Text: "Loading..." (Body, Gray 700) - Optional
```

---

#### Skeleton Loader

**Specs:**
```
Background: Gray 200
Border Radius: Match component (8px, 12px, etc.)
Animation: Shimmer effect (left to right, 1.5s duration)

Gradient:
  Color 1: Gray 200
  Color 2: Gray 100 (highlight)
  Color 3: Gray 200
```

**Usage:**
- Card placeholders
- List item placeholders
- Image placeholders

---

## 📱 Screen Templates

### Template 1: List View

**Structure:**
```
┌─────────────────────────────────────┐
│ Top Nav Bar (44px)                  │
├─────────────────────────────────────┤
│ Search Bar (44px + 16px padding)    │
├─────────────────────────────────────┤
│                                      │
│ Scrollable Content                  │
│ ├── Filter Chips (horizontal scroll)│
│ ├── List Item 1                     │
│ ├── List Item 2                     │
│ ├── List Item 3                     │
│ └── ...                              │
│                                      │
├─────────────────────────────────────┤
│ Bottom Tab Bar (80px)               │
└─────────────────────────────────────┘
```

**Example Screens:**
- Discover > Places
- Budget > Expenses List
- Community > Feed

---

### Template 2: Detail View

**Structure:**
```
┌─────────────────────────────────────┐
│ Hero Image (240px)                  │
│ ├── Back Button (overlay, top-left)│
│ └── Bookmark (overlay, top-right)  │
├─────────────────────────────────────┤
│ Scrollable Content                  │
│ ├── Title + Rating                  │
│ ├── Quick Info (Category, Distance) │
│ ├── Action Buttons (Directions, Call)│
│ ├── Description                     │
│ ├── Photos Gallery                  │
│ ├── Reviews                         │
│ └── Nearby Places                   │
│                                      │
├─────────────────────────────────────┤
│ Fixed Bottom CTA (56px)             │
│ └── "Get Directions" Button         │
└─────────────────────────────────────┘
```

**Example Screens:**
- Place Detail
- Challenge Detail
- Profile (Other User)

---

### Template 3: Form View

**Structure:**
```
┌─────────────────────────────────────┐
│ Top Nav Bar                          │
│ ├── Close Button (left)             │
│ └── "Save" Button (right)           │
├─────────────────────────────────────┤
│ Scrollable Form                      │
│ ├── Section Title                   │
│ ├── Input Field 1                   │
│ ├── Input Field 2                   │
│ ├── Dropdown Field                  │
│ ├── Toggle Switch                   │
│ └── ...                              │
│                                      │
├─────────────────────────────────────┤
│ Bottom Padding (for keyboard)       │
└─────────────────────────────────────┘
```

**Example Screens:**
- Add Expense
- Create Post
- Edit Profile

---

### Template 4: Map View

**Structure:**
```
┌─────────────────────────────────────┐
│ Full Screen Map                      │
│ ├── Search Bar (overlay, top)       │
│ ├── Location Button (bottom-right)  │
│ └── Zoom Controls (right side)      │
│                                      │
│ Place Markers (pins on map)         │
│                                      │
├─────────────────────────────────────┤
│ Bottom Sheet (draggable)            │
│ └── Place Card (preview)            │
└─────────────────────────────────────┘
```

**Example Screens:**
- Home > Map View
- Discover > Map Mode
- Navigation

---

### Template 5: Empty State

**Structure:**
```
┌─────────────────────────────────────┐
│ Top Nav Bar                          │
├─────────────────────────────────────┤
│                                      │
│ Centered Content                    │
│ ├── Illustration (160×160 px)       │
│ ├── Title (H3, centered)            │
│ ├── Description (Body, centered)    │
│ └── CTA Button                      │
│                                      │
├─────────────────────────────────────┤
│ Bottom Tab Bar                       │
└─────────────────────────────────────┘
```

**Usage:**
- No saved places
- No trips
- No notifications

---

## 🎨 Design Tokens

### Color Tokens (CSS Variables)

```css
/* Primary Colors */
--color-jade-900: #1B5E3D;
--color-jade-700: #2E8B57;
--color-jade-500: #3BAA7A;
--color-jade-300: #6BC99D;
--color-jade-100: #B8E6D5;

/* Secondary Colors */
--color-sand-900: #C4A87D;
--color-sand-700: #D9C299;
--color-sand-500: #F5E4C3;
--color-sand-300: #F8EDDA;
--color-sand-100: #FBF6ED;

/* Neutral Colors */
--color-gray-900: #1A1A1A;
--color-gray-800: #333333;
--color-gray-700: #4D4D4D;
--color-gray-600: #666666;
--color-gray-500: #808080;
--color-gray-400: #999999;
--color-gray-300: #B3B3B3;
--color-gray-200: #CCCCCC;
--color-gray-100: #E6E6E6;
--color-gray-50: #F5F5F5;

/* Semantic Colors */
--color-success: #10B759;
--color-warning: #FFA500;
--color-error: #F44336;
--color-info: #2196F3;
```

---

### Spacing Tokens

```css
--spacing-xxs: 4px;
--spacing-xs: 8px;
--spacing-s: 12px;
--spacing-m: 16px;
--spacing-l: 24px;
--spacing-xl: 32px;
--spacing-xxl: 48px;
--spacing-xxxl: 64px;
```

---

### Border Radius Tokens

```css
--radius-s: 8px;
--radius-m: 12px;
--radius-l: 16px;
--radius-xl: 20px;
--radius-xxl: 24px;
--radius-pill: 999px;
--radius-circle: 50%;
```

---

### Shadow Tokens

```css
--shadow-sm: 0px 2px 4px rgba(0, 0, 0, 0.05);
--shadow-md: 0px 2px 8px rgba(0, 0, 0, 0.08);
--shadow-lg: 0px 4px 12px rgba(0, 0, 0, 0.1);
--shadow-xl: 0px 8px 24px rgba(0, 0, 0, 0.12);
--shadow-2xl: 0px 16px 48px rgba(0, 0, 0, 0.15);
```

---

## 📂 Figma File Structure

### Pages Organization

**Page 1: 📖 Design System**
- Cover page with project info
- Table of contents

**Page 2: 🎨 Foundations**
- Color palette (all swatches)
- Typography samples
- Spacing guide
- Icon grid

**Page 3: 🧩 Components**
- All component variations
- States (default, hover, active, disabled)
- Size variants

**Page 4: 📱 Screens - Onboarding**
- Splash screen
- Onboarding 1, 2, 3
- Login / Signup
- Permissions

**Page 5: 📱 Screens - Main**
- Home
- Discover
- Planner
- Community
- Profile

**Page 6: 📱 Screens - Features**
- Maps & Navigation
- Translation
- Budget
- Challenges
- Safety (SOS)

**Page 7: 🔗 Prototypes**
- Interactive flows
- Linked screens

---

### Component Naming Convention

**Pattern:** `Category/Type/Variant/State`

**Examples:**
```
Button/Primary/Large/Default
Button/Primary/Large/Hover
Button/Primary/Large/Disabled
Button/Secondary/Medium/Default
Card/Place/Horizontal/Default
Card/Place/Horizontal/Saved
Input/Text/Default/Default
Input/Text/Default/Focus
Input/Text/Default/Error
```

---

### Auto Layout Best Practices

1. **Use Auto Layout for everything**
2. **Name frames descriptively**
3. **Set constraints properly** (Left & Right for full-width)
4. **Use "Hug contents" for components**
5. **Use "Fill container" for backgrounds**

---

## 🚀 Exporting Assets

### Export Settings

**Icons:**
- Format: SVG
- Scale: @1x, @2x, @3x
- Naming: `ic_[name]_[size].svg`

**Images:**
- Format: PNG (photos), SVG (illustrations)
- Scale: @1x, @2x, @3x
- Naming: `img_[name]_[variant].png`

**Components (for Dev):**
- Use Figma Dev Mode
- Export as CSS/React/Flutter code
- Copy design tokens

---

## ✅ Checklist for Designers

**Before Handoff:**
- [ ] All text uses defined text styles
- [ ] All colors use defined color styles
- [ ] All components are in the library
- [ ] All spacing follows 8pt grid
- [ ] All interactive elements ≥ 44×44 px
- [ ] Contrast ratios checked (WCAG AA)
- [ ] Dark mode variants created
- [ ] Prototypes linked and working
- [ ] Annotations added for complex interactions
- [ ] Exported assets organized in shared folder

---

## 📚 Resources

**Figma Plugins:**
- **Stark:** Accessibility checker
- **Unsplash:** Free stock photos
- **Iconify:** Icon library
- **Content Reel:** Placeholder content
- **Autoflow:** Create user flow diagrams

**Inspiration:**
- Dribbble (travel app designs)
- Mobbin (mobile app patterns)
- Figma Community (design systems)

---

**Last Updated:** 2025-10-22
**Version:** 1.0
**Maintained By:** Design Team
**Next Review:** 2025-11-22
