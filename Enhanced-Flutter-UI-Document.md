# LGBTinder - Complete Flutter UI Design Specification

## 1. Introduction

LGBTinder is a premium, inclusive dating and social connection application designed specifically for the LGBTQ+ community. The application prioritizes user safety, authentic expression, and meaningful connections through a modern, visually stunning interface that adapts seamlessly between dark and light modes.

### Core Design Principles

- **Inclusivity First**: Flexible gender identity, pronoun selection, and inclusive language throughout the UI
- **Visual Focus**: Profile photos and avatars are the primary visual elements, creating an intimate, human-centered experience
- **Tactile Interactions**: Smooth animations, haptic feedback, and gesture-driven navigation create a premium, responsive feel
- **Accessibility**: High contrast ratios, screen reader support, and adaptive typography ensure the app is usable by everyone
- **Dark-First with Light Fallback**: Primary design optimized for dark mode with carefully crafted light mode variants

---

## 2. Theme & Design System

### 2.1 Color Palette

#### Dark Mode Colors

```dart
// Primary Background & Surfaces
static const Color backgroundDark = Color(0xFF0B0B0D);        // Main page background
static const Color surfaceDark = Color(0xFF121214);           // Elevated cards, containers
static const Color surfaceElevatedDark = Color(0xFF1A1A1C);   // Higher elevation surfaces

// Accent Colors
static const Color accentPurple = Color(0xFF8A2BE2);          // Primary accent (buttons, active states)
static const Color accentGradientStart = Color(0xFF7B2BE2);  // Gradient start
static const Color accentGradientEnd = Color(0xFFD33CFF);    // Gradient end
static const Color accentPink = Color(0xFFFF3CA6);           // Secondary accent

// Text Colors
static const Color textPrimaryDark = Color(0xFFFFFFFF);       // High contrast text
static const Color textSecondaryDark = Color(0xFFA6A6A6);     // Muted text, captions
static const Color textTertiaryDark = Color(0xFF6B6B6B);      // Very muted text

// Status & Indicators
static const Color onlineGreen = Color(0xFF2ECC71);           // Online status indicator
static const Color notificationRed = Color(0xFFFF3B30);        // Notification badges, errors
static const Color warningYellow = Color(0xFFFFC107);         // Warnings, super-like

// Borders & Dividers
static const Color borderSubtleDark = Color.fromRGBO(255, 255, 255, 0.04);
static const Color borderMediumDark = Color.fromRGBO(255, 255, 255, 0.08);
static const Color dividerDark = Color.fromRGBO(255, 255, 255, 0.06);

// Overlays & Glass Effects
static const Color overlayDark = Color.fromRGBO(0, 0, 0, 0.55);        // Image gradient overlay
static const Color glassOverlayDark = Color.fromRGBO(255, 255, 255, 0.02); // Glassy container inner
static const Color storyRingDark = Color.fromRGBO(138, 43, 226, 0.9);  // Story ring stroke
```

#### Light Mode Colors

```dart
// Primary Background & Surfaces
static const Color backgroundLight = Color(0xFFFFFFFF);       // Main page background
static const Color surfaceLight = Color(0xFFF5F5F7);           // Elevated cards, containers
static const Color surfaceElevatedLight = Color(0xFFFFFFFF); // Higher elevation surfaces

// Accent Colors (same as dark mode for brand consistency)
static const Color accentPurple = Color(0xFF8A2BE2);
static const Color accentGradientStart = Color(0xFF7B2BE2);
static const Color accentGradientEnd = Color(0xFFD33CFF);
static const Color accentPink = Color(0xFFFF3CA6);

// Text Colors
static const Color textPrimaryLight = Color(0xFF000000);      // High contrast text
static const Color textSecondaryLight = Color(0xFF6B6B6B);    // Muted text, captions
static const Color textTertiaryLight = Color(0xFF9B9B9B);      // Very muted text

// Status & Indicators (same as dark mode)
static const Color onlineGreen = Color(0xFF2ECC71);
static const Color notificationRed = Color(0xFFFF3B30);
static const Color warningYellow = Color(0xFFFFC107);

// Borders & Dividers
static const Color borderSubtleLight = Color.fromRGBO(0, 0, 0, 0.08);
static const Color borderMediumLight = Color.fromRGBO(0, 0, 0, 0.12);
static const Color dividerLight = Color.fromRGBO(0, 0, 0, 0.1);

// Overlays & Glass Effects
static const Color overlayLight = Color.fromRGBO(0, 0, 0, 0.3);        // Lighter overlay for light mode
static const Color glassOverlayLight = Color.fromRGBO(255, 255, 255, 0.8); // Glassy container inner
static const Color storyRingLight = Color.fromRGBO(138, 43, 226, 0.7);  // Slightly more transparent
```

#### Color Usage Rules

- **Accent Gradient**: Use for primary CTAs, story rings, and hero components
- **Solid Accent Purple**: Use for solid buttons, active states, and secondary actions
- **Contrast Requirements**: 
  - Body text on background: minimum 4.5:1 ratio (WCAG AA)
  - Large text (18pt+): minimum 3:1 ratio
  - Interactive elements: minimum 3:1 ratio for focus indicators

### 2.2 Typography System

#### Font Family

```dart
// Primary font stack
static const String fontFamily = 'Inter';  // Primary
static const String fontFamilyIOS = 'SF Pro Display';  // iOS fallback
static const String fontFamilyAndroid = 'Roboto';     // Android fallback
```

#### Type Scale

```dart
// Headlines
static const TextStyle h1Large = TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.w700,
  letterSpacing: -0.2,
  height: 1.2,
);

static const TextStyle h1 = TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.w700,
  letterSpacing: -0.2,
  height: 1.2,
);

static const TextStyle h2 = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.w600,
  letterSpacing: 0,
  height: 1.2,
);

static const TextStyle h3 = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w600,
  letterSpacing: 0,
  height: 1.2,
);

// Body Text
static const TextStyle bodyLarge = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w400,
  letterSpacing: 0,
  height: 1.4,
);

static const TextStyle body = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  letterSpacing: 0,
  height: 1.4,
);

static const TextStyle bodySmall = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w400,
  letterSpacing: 0,
  height: 1.4,
);

// Special Styles
static const TextStyle caption = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w400,
  letterSpacing: 0.1,
  height: 1.3,
);

static const TextStyle button = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  letterSpacing: 0.2,
  height: 1.2,
);

// Script/Display Font (for "It's a Match" heading)
static const TextStyle displayScript = TextStyle(
  fontSize: 36,
  fontWeight: FontWeight.w400,
  fontStyle: FontStyle.italic,
  letterSpacing: 0.5,
  height: 1.1,
);
```

### 2.3 Spacing & Layout

#### Spacing Tokens

```dart
// Base spacing unit: 4px
static const double spacingXS = 4.0;   // 4px
static const double spacingSM = 8.0;   // 8px
static const double spacingMD = 12.0;  // 12px
static const double spacingLG = 16.0;  // 16px
static const double spacingXL = 24.0;  // 24px
static const double spacingXXL = 32.0; // 32px
static const double spacingXXXL = 48.0; // 48px

// Content padding
static const double contentPadding = 16.0;  // Horizontal padding for screens
static const double contentPaddingVertical = 12.0;  // Vertical rhythm
```

#### Border Radius

```dart
static const double radiusXS = 6.0;    // Small badges, chips
static const double radiusSM = 12.0;   // Cards, containers
static const double radiusMD = 16.0;   // Dialogs, bottom sheets
static const double radiusLG = 24.0;   // Large cards, profile cards
static const double radiusRound = 999.0; // Avatars, pill buttons
```

#### Elevation & Shadows

```dart
// Dark Mode Shadows
static const List<BoxShadow> shadowSurfaceDark = [
  BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.6),
    blurRadius: 18,
    offset: Offset(0, 6),
  ),
];

static const List<BoxShadow> shadowFloatingDark = [
  BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.7),
    blurRadius: 30,
    offset: Offset(0, 10),
  ),
  BoxShadow(
    color: Color.fromRGBO(255, 255, 255, 0.02),
    blurRadius: 1,
    offset: Offset(0, -1),
  ),
];

// Light Mode Shadows
static const List<BoxShadow> shadowSurfaceLight = [
  BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.1),
    blurRadius: 12,
    offset: Offset(0, 4),
  ),
];

static const List<BoxShadow> shadowFloatingLight = [
  BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.15),
    blurRadius: 24,
    offset: Offset(0, 8),
  ),
];
```

### 2.4 Iconography

**CRITICAL**: **ALL icons MUST be SVG format from `assets/icons` directory. Do NOT use Material Icons.**

- **Icon Source**: **REQUIRED** - All icons must be SVG files from `assets/icons/` directory
- **Icon Subdirectories**: `bold/`, `broken/`, `bulk/`, `linear/`, `outline/`, `twotone/`
- **Implementation**: Use `SvgPicture.asset()` or the `AppSvgIcon` wrapper widget
- **Utility Class**: Use `AppIcons` constants for icon paths (see `lib/core/utils/app_icons.dart`)
- **Core Sizes**: 18px, 20px, 24px
- **Action Icons**: Minimum 24px with 44x44px tappable area
- **Style**: Rounded, minimal line icons with 1.5-2px stroke width
- **Active States**: Filled or accent-colored versions
- **Theme Support**: Icons automatically adapt to dark/light mode via `AppSvgIcon`

**Icon Usage Example**:
```dart
// ✅ CORRECT - Use AppSvgIcon
import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/widgets/common/app_svg_icon.dart';

AppSvgIcon(
  assetPath: AppIcons.heart,
  size: 24,
  color: AppColors.accentPurple,
)

// ✅ CORRECT - Use SvgPicture directly
import 'package:flutter_svg/flutter_svg.dart';

SvgPicture.asset(
  'assets/icons/outline/heart.svg',
  width: 24,
  height: 24,
)

// ❌ WRONG - Do NOT use Material Icons
Icon(Icons.favorite) // DO NOT USE
```

---

## 3. Layout & Navigation Structure

### 3.1 Navigation Architecture

The app uses a **bottom navigation bar** as the primary navigation method, with five main sections:

1. **Home/Discover** (House icon) - Main swiping interface
2. **Explore/Browse** (Compass icon) - Grid view of profiles
3. **Likes/Favorites** (Heart icon) - Mutual likes and matches
4. **Chats/Messages** (Message bubble icon) - Conversations list
5. **Profile** (Person icon) - User's own profile and settings

### 3.2 App Bar Structure

Most screens feature a consistent app bar with:
- **Left**: Back button (circular, semi-transparent background)
- **Center**: Screen title (bold white text in dark mode, black in light mode)
- **Right**: Action buttons (1-2 circular buttons for screen-specific actions)

### 3.3 Page Transitions

```dart
// Transition types
enum PageTransition {
  fade,        // 180ms linear - for subtle transitions
  slide,       // 300ms easeInOut - horizontal navigation
  slideVertical, // 300ms easeInOut - vertical navigation (bottom sheets)
  hero,        // 400ms easeInOut - for profile images
  scale,       // 300ms easeOutBack - for modals
  match,       // 700ms elasticOut - for match animation
}
```

### 3.4 Bottom Navigation Bar

**Structure:**
- Floating container with rounded top corners (radius: 20px)
- Dark background with slight elevation (dark mode: `surfaceDark`, light mode: `surfaceLight`)
- 5 circular icon buttons, evenly spaced
- Active item: Purple background circle with white icon
- Inactive items: Gray/white icons (dark mode: white, light mode: gray)

**Implementation:**
```dart
// Bottom nav dimensions
static const double bottomNavHeight = 70.0;
static const double bottomNavIconSize = 24.0;
static const double bottomNavActiveSize = 48.0; // Active icon container
```

---

## 4. Screen-by-Screen UI Specification

### 4.1 Welcome/Onboarding Screen

**Purpose**: First impression, brand introduction, and entry point to authentication

#### Screen Structure

```
Scaffold
└── Stack
    ├── Column (main content)
    │   ├── Expanded
    │   │   └── GridView (profile mosaic)
    │   ├── SizedBox (spacing)
    │   ├── Icon (heart with crown)
    │   ├── Text (tagline)
    │   ├── Text (description)
    │   └── SizedBox (spacing)
    └── Column (bottom actions)
        ├── GradientButton ("Get Started")
        └── TextButton ("Login Now")
```

#### Components and Elements

**Profile Grid (Top Section)**
- **Layout**: Irregular grid with 7-9 profile images
- **Image Style**: Rounded corners (radius: 8px), thin dark border (1px)
- **Spacing**: 4-6px gaps between images
- **Aspect Ratio**: Square (1:1) or slightly portrait (3:4)
- **Background**: Dark mode: `backgroundDark`, Light mode: `backgroundLight`

**Branding Section**
- **Icon**: Heart with crown outline, 64px size, `accentPurple` color
- **Tagline**: "Inclusive. Trusted. Secure" - `h1` style, white (dark) / black (light)
- **Description**: "Diverse, dependable, and protected a safe space for everyone to connect with confidence." - `body` style, `textSecondaryDark/Light`

**Call-to-Action Buttons**
- **Get Started Button**:
  - Full-width, rounded corners (radius: `radiusMD`)
  - Gradient background: `accentGradientStart` → `accentGradientEnd`
  - Text: "Get Started" - `button` style, white color
  - Height: 56px
  - Padding: `spacingLG` horizontal
- **Login Link**:
  - Text: "Already have an account? " (regular) + "Login Now" (bold, `accentPurple`)
  - `body` style, centered

#### Responsive Behavior

- **Small screens (< 360px)**: Reduce grid to 6 images, smaller icon (48px)
- **Large screens (> 430px)**: Maintain proportions, center content with max-width container

#### Light Mode Variant

- Background: Pure white (`backgroundLight`)
- Grid images: Slightly darker borders for definition
- Text: Black primary, gray secondary
- Icon: Same purple accent (maintains brand)

#### Dark Mode Variant

- Background: Very dark gray (`backgroundDark`)
- Grid images: Subtle glow effect on hover
- Text: White primary, light gray secondary
- Icon: Purple with slight glow

#### Animation Details

- **Grid Images**: Staggered fade-in (100ms delay between each)
- **Icon**: Scale animation on appear (0.8 → 1.0, 400ms)
- **Buttons**: Subtle scale on press (0.98 → 1.0, 150ms)

---

### 4.2 Home/Discover Screen

**Purpose**: Main swiping interface for discovering profiles

#### Screen Structure

```
Scaffold
└── Column
    ├── AppBar (custom)
    │   ├── Row (left: avatar + greeting, right: notifications + filter)
    └── Expanded
        └── Stack
            ├── DiscoveryCard (swipeable stack)
            └── Row (action buttons: dislike, message, like, super-like)
```

#### Components and Elements

**App Bar Section**
- **Left Side**:
  - Circular avatar (48px) with gradient ring
  - Column:
    - Text: "Good morning" - `caption` style, `textSecondaryDark/Light`
    - Text: "Hello [Name]" - `h3` style, `textPrimaryDark/Light`
- **Right Side**:
  - Notification bell icon (24px) with red badge dot (8px) if unread
  - Filter icon (24px)
  - Both in circular containers (44x44px tappable area)

**Profile Card (DiscoveryCard)**
- **Dimensions**: Full width minus padding, aspect ratio ~0.75 (portrait)
- **Image**: Full-bleed with rounded corners (`radiusLG`)
- **Overlay**: Bottom gradient from transparent to `overlayDark/Light`
- **Top Left Badges**:
  - Rounded pills with semi-transparent background
  - Examples: "Aries", "Designer", "Blogger"
  - `bodySmall` style, white text
  - Padding: `spacingXS` horizontal, `spacingXS` vertical
- **Bottom Left Info**:
  - Status indicator: Green dot (10px) + "Active" text - `caption` style
  - Name: `h1` style, white, bold
  - Distance: Location icon (12px) + "2.8 km" - `bodySmall` style, `textSecondaryDark/Light`
  - Bio: "Your favorite office siren and a portuguese girl boss" - `body` style, `textSecondaryDark/Light`
- **Top Right**: Three-dot menu icon (optional)
- **Shadow**: `shadowFloatingDark/Light`

**Action Buttons Row**
- **Layout**: 4 circular buttons, evenly spaced, centered
- **Buttons** (left to right):
  1. **Dislike** (X): Light blue circle (#4A90E2), white X icon (24px), 56px diameter
  2. **Message** (Chat): Purple circle (`accentPurple`), white chat icon (24px), 56px diameter
  3. **Like** (Heart): Red circle (`notificationRed`), white heart icon (24px), 56px diameter
  4. **Super Like** (Star): Yellow circle (`warningYellow`), white star icon (24px), 56px diameter
- **Spacing**: `spacingXL` between buttons
- **Elevation**: Slight shadow for depth

#### Responsive Behavior

- **Small screens**: Reduce card height, smaller action buttons (48px)
- **Landscape**: Disable or adapt to show grid view instead

#### Light Mode Variant

- Card background: White with subtle border
- Overlay: Lighter gradient for text readability
- Action buttons: Same colors, slightly more saturated

#### Dark Mode Variant

- Card background: `surfaceDark`
- Overlay: Darker gradient for better contrast
- Action buttons: Slightly muted colors

#### Animation Details

- **Swipe Gesture**: Card rotates and translates with finger, spring physics on release
- **Like Button**: Heart pop animation (scale 1.0 → 1.3 → 1.0, 300ms) + particle burst
- **Super Like**: Star sparkle animation (Lottie)
- **Card Stack**: Underlying cards scale down (0.95) and fade slightly

---

### 4.3 Profile Screen (User's Own Profile)

**Purpose**: User's profile management, stats, and settings access

#### Screen Structure

```
Scaffold
└── Column
    ├── AppBar (back, title "Profile", edit icon)
    ├── Column (profile info)
    │   ├── CircleAvatar (large, gradient ring)
    │   ├── Text (name)
    │   └── Text (designation)
    ├── Row (stats cards: Activities, Likes, Life Moments)
    └── Column (menu items: Subscription, Authentication, Terms, Wallet)
```

#### Components and Elements

**App Bar**
- **Left**: Back arrow button (circular, semi-transparent)
- **Center**: "Profile" - `h2` style
- **Right**: Edit icon (pencil, circular button)

**Profile Header**
- **Avatar**: 
  - Size: 100px diameter
  - Gradient ring: 4px stroke, `accentGradientStart` → `accentGradientEnd`
  - Centered
- **Name**: "Ms.Oliva Smith" - `h1` style, centered, `textPrimaryDark/Light`
- **Designation**: "Designer" - `body` style, `textSecondaryDark/Light`, centered, italic

**Statistics Cards**
- **Layout**: 3 equal-width cards in a Row
- **Card Style**:
  - Rounded corners (`radiusSM`)
  - Background: `surfaceDark/Light` (slightly elevated)
  - Padding: `spacingLG` vertical, `spacingMD` horizontal
  - Shadow: `shadowSurfaceDark/Light`
- **Content**:
  - Large number: `h1` style (28px), `textPrimaryDark/Light`
  - Label: `caption` style, `textSecondaryDark/Light`
- **Cards**: "20 Activities", "81 Like", "16 Life Moments"

**Menu Items**
- **Layout**: Vertical list of rounded rectangular items
- **Item Style**:
  - Height: 56px
  - Rounded corners (`radiusSM`)
  - Background: `surfaceDark/Light` (or `accentPurple` for active/primary)
  - Padding: `spacingLG` horizontal
  - Row layout: Icon (left) + Text (center, expanded) + Chevron (right)
- **Items**:
  1. **Subscription**: Purple background (`accentPurple`), diamond icon, white text
  2. **Authentication**: Gray background, padlock with checkmark icon, white text
  3. **Terms of use**: Gray background, info icon (i in circle), white text
  4. **Wallet**: Gray background, wallet icon, white text

#### Responsive Behavior

- **Small screens**: Reduce avatar size (80px), smaller stats cards
- **Large screens**: Center content with max-width, maintain proportions

#### Light Mode Variant

- Stats cards: White background with subtle border
- Menu items: Light gray background, black text
- Subscription item: Same purple, maintains prominence

#### Dark Mode Variant

- Stats cards: `surfaceDark` with subtle glow
- Menu items: `surfaceDark`, white text
- Subscription item: Purple stands out against dark

#### Animation Details

- **Avatar**: Scale animation on appear (0.9 → 1.0, 400ms)
- **Stats Cards**: Staggered fade-in (50ms delay each)
- **Menu Items**: Tap feedback (scale 0.98, 150ms)

---

### 4.4 Chats/Messages Screen

**Purpose**: List of conversations and online friends

#### Screen Structure

```
Scaffold
└── Column
    ├── AppBar (back, "Chats" title, search, more options)
    ├── Horizontal ListView (online friends with avatars)
    ├── Text ("Messages" header)
    └── Expanded
        └── ListView (chat list items)
```

#### Components and Elements

**App Bar**
- **Left**: Back arrow button
- **Center**: "Chats" - `h2` style
- **Right**: Search icon + three-dot menu icon (both circular buttons)

**Online Friends Section**
- **Layout**: Horizontal scrollable ListView
- **Item Structure**:
  - Column:
    - Stack:
      - CircleAvatar (64px)
      - Positioned (bottom-right): Green dot (12px) with white ring (2px)
      - Positioned (outer): Purple gradient ring (2px stroke)
    - Text (name) - `caption` style, centered
- **Spacing**: `spacingLG` between items
- **Padding**: `spacingLG` horizontal

**Messages Header**
- Text: "Messages" - `h3` style, `textPrimaryDark/Light`
- Padding: `spacingLG` horizontal, `spacingMD` vertical

**Chat List Items**
- **Layout**: Row with avatar, text content, timestamp/badge
- **Structure**:
  - CircleAvatar (56px, left)
  - Expanded Column (center):
    - Text (name) - `h3` style, `textPrimaryDark/Light`
    - Text (last message or "Typing...") - `bodySmall` style, `textSecondaryDark/Light`
  - Column (right):
    - Text (timestamp) - `caption` style, `textSecondaryDark/Light`
    - Unread badge (if applicable): Red circle (20px) with white number
- **Padding**: `spacingLG` horizontal, `spacingMD` vertical
- **Divider**: Subtle divider below each item (`dividerDark/Light`)

**Typing Indicator**
- Text: "Typing..." with animated three dots
- Animation: Dots pulse sequentially (200ms each, staggered)

#### Responsive Behavior

- **Small screens**: Smaller avatars (48px), compact list items
- **Large screens**: Wider list items, larger avatars

#### Light Mode Variant

- Background: White
- List items: Light gray background on tap
- Dividers: Light gray lines

#### Dark Mode Variant

- Background: `backgroundDark`
- List items: `surfaceDark` background on tap
- Dividers: Subtle white lines

#### Animation Details

- **Online Friends**: Horizontal scroll with momentum
- **Typing Dots**: Sequential opacity animation (0.3 → 1.0 → 0.3)
- **List Items**: Swipe to reveal actions (mute, archive, delete)

---

### 4.5 Match Screen (AI Match Result)

**Purpose**: Celebrate successful matches with engaging animation

#### Screen Structure

```
Scaffold
└── Stack
    ├── Column (background decor)
    ├── Column (main content)
    │   ├── Stack (heart frames with avatars)
    │   ├── Text ("It's a Match")
    │   ├── Text (tagline)
    │   └── Column (action buttons)
    └── AppBar (back, "Ai Match" title, info icon)
```

#### Components and Elements

**App Bar**
- **Left**: Back arrow button
- **Center**: "Ai Match" - `h3` style
- **Right**: Info icon (i in circle)

**Background Decor**
- Light gray/white line art icons (hearts, envelopes, lips, crowns)
- Opacity: 0.1-0.15
- Scattered across background

**Match Section**
- **Heart Frames**:
  - Two overlapping heart shapes with purple gradient borders (4px stroke)
  - Left heart: User's profile image
  - Right heart: Matched user's profile image
  - Hearts overlap by ~30%
- **Match Badge**:
  - Circular white badge (60px) with purple border (2px)
  - Text: "100%" - `h2` style, `accentPurple` color
  - Positioned at overlap point (top center)

**Match Text**
- **Heading**: "It's a Match" - `displayScript` style, white, centered
- **Tagline**: Two-line paragraph:
  - "Adventurous, creative, and always chasing sunsets."
  - "Let's turn coffee dates into something more."
  - `bodyLarge` style, white, centered
  - Padding: `spacingXL` horizontal

**Action Buttons**
- **"Hai Hello" Button**:
  - Full-width, rounded corners (`radiusMD`)
  - Gradient background: `accentGradientStart` → `accentGradientEnd`
  - Text: "Hai Hello" - `button` style, white
  - Height: 56px
  - Padding: `spacingLG` horizontal
- **"Swiping Now" Button**:
  - Full-width, rounded corners (`radiusMD`)
  - Background: Transparent
  - Border: 1px solid `borderMediumDark/Light`
  - Text: "Swiping Now" - `button` style, white (dark) / black (light)
  - Height: 56px
  - Padding: `spacingLG` horizontal

#### Responsive Behavior

- **Small screens**: Smaller heart frames, reduced text size
- **Large screens**: Maintain proportions, center content

#### Light Mode Variant

- Background: White
- Text: Black for tagline, maintain script style for heading
- Buttons: Same gradient, border button with black border

#### Dark Mode Variant

- Background: `backgroundDark`
- Text: White throughout
- Buttons: Gradient stands out, border button with white border

#### Animation Details

- **Match Animation** (700ms):
  1. Hearts slide in from sides (0ms → 400ms)
  2. Hearts converge to center with slight bounce (400ms → 600ms)
  3. Badge scales in with elastic effect (500ms → 700ms)
  4. Confetti/Lottie animation plays (600ms → 1200ms)
  5. Text fades in (700ms → 900ms)
- **Haptic Feedback**: Heavy impact on match
- **Sound**: Optional celebration sound effect

---

### 4.6 Profile Detail Screen (Other User's Profile)

**Purpose**: Full profile view of another user

#### Screen Structure

```
Scaffold
└── Stack
    ├── PageView (image carousel)
    ├── Positioned (action buttons on right)
    ├── Positioned (image indicators bottom center)
    └── DraggableScrollableSheet (profile info overlay)
```

#### Components and Elements

**Image Carousel**
- **Layout**: Full-screen PageView with horizontal swipe
- **Images**: Full-bleed, aspect ratio ~0.75 (portrait)
- **Indicators**: 5 dots at bottom center
  - Active dot: Purple circle (8px)
  - Inactive dots: White circles (6px) with 50% opacity
  - Spacing: `spacingXS` between dots

**Action Buttons (Right Side)**
- **Layout**: Vertical stack, positioned on right edge
- **Buttons** (top to bottom):
  1. **Message**: Semi-transparent circle, white chat icon (24px)
  2. **Bookmark**: Semi-transparent circle, white bookmark icon (24px)
  3. **Special Action**: Purple circle (`accentPurple`), white heart/star icon (24px)
- **Spacing**: `spacingMD` between buttons
- **Padding**: `spacingLG` from edges

**Profile Info Overlay**
- **Layout**: Draggable bottom sheet, starts at ~40% height
- **Background**: `surfaceDark/Light` with rounded top corners (`radiusMD`)
- **Content**:
  - **Header**: Name + Age - `h1` style, `textPrimaryDark/Light`
  - **Subheader**: Profession - `body` style, `textSecondaryDark/Light`, italic
  - **Location Tag**: Purple pill with location icon + "2.0 km" - `bodySmall` style
  - **About Section 1**:
    - Header: "About" - `h3` style
    - Content: Bio text - `body` style, `textSecondaryDark/Light`
  - **About Section 2** (Interests):
    - Header: "About" - `h3` style
    - Content: Wrap of interest tags
      - Each tag: Rounded pill (`radiusRound`), dark gray background, white icon + text
      - Examples: "Traveling" (car icon), "Photography" (camera icon), "Reading thrillers" (book icon), "Hiking" (hiking icon), "Painting" (palette icon), "Brunch spots" (diamond icon)
      - Spacing: `spacingSM` between tags

#### Responsive Behavior

- **Small screens**: Overlay starts at 50% height, smaller action buttons
- **Large screens**: Overlay starts at 35% height, maintain image quality

#### Light Mode Variant

- Overlay: White background
- Tags: Light gray background, black text
- Action buttons: More opaque for visibility

#### Dark Mode Variant

- Overlay: `surfaceDark` background
- Tags: Dark gray background, white text
- Action buttons: Semi-transparent with glow

#### Animation Details

- **Image Transition**: Smooth page transition (300ms)
- **Overlay Drag**: Spring physics on release
- **Action Buttons**: Scale on tap (0.9 → 1.0, 150ms)
- **Hero Animation**: Profile image to detail screen (shared element)

---

### 4.7 Explore/Browse Screen

**Purpose**: Grid view of profiles for browsing

#### Screen Structure

```
Scaffold
└── Column
    ├── AppBar (title "Explore", filter icon)
    └── Expanded
        └── GridView (2 columns, profile cards)
```

#### Components and Elements

**App Bar**
- **Left**: Back button (if navigated from)
- **Center**: "Explore" - `h2` style
- **Right**: Filter icon

**Profile Grid**
- **Layout**: 2-column GridView with 8px gaps
- **Card Style**:
  - Aspect ratio: 0.75 (portrait)
  - Rounded corners (`radiusSM`)
  - Image: Full-bleed with rounded corners
  - Overlay: Bottom gradient for name visibility
  - Bottom info: Name + age - `h3` style, white
- **Spacing**: `spacingSM` between cards
- **Padding**: `spacingLG` horizontal

#### Responsive Behavior

- **Small screens**: 2 columns maintained, smaller cards
- **Large screens**: 3 columns, larger cards

#### Light Mode Variant

- Cards: White background with border
- Overlay: Lighter gradient

#### Dark Mode Variant

- Cards: `surfaceDark` background
- Overlay: Darker gradient

#### Animation Details

- **Grid Items**: Staggered fade-in on load
- **Tap**: Scale animation (0.95 → 1.0, 200ms)

---

## 5. Reusable Components & Widgets

### 5.1 AvatarRing

**Purpose**: Circular avatar with gradient ring and online indicator

```dart
class AvatarRing extends StatelessWidget {
  final String imageUrl;
  final double size;
  final bool isOnline;
  final bool showRing;
  
  // Styling
  - Gradient ring: accentGradientStart → accentGradientEnd
  - Ring width: 2-4px depending on size
  - Online indicator: 10-12px green dot with 2px white ring
  - Position: bottom-right of avatar
  // NOTE: Any icons used must be SVG from assets/icons using SvgPicture/AppSvgIcon
}
```

**Usage**: Profile headers, chat lists, online friends, story rings

### 5.2 DiscoveryCard

**Purpose**: Swipeable profile card for discovery screen

```dart
class DiscoveryCard extends StatelessWidget {
  final Profile profile;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  
  // Features
  - GestureDetector for swipe gestures
  - Transform for rotation and translation
  - Stack for image, overlay, badges, info
  - Hero widget for image transition
}
```

**Usage**: Home/Discover screen, match preview

### 5.3 ChatListTile

**Purpose**: Individual chat item in messages list

```dart
class ChatListTile extends StatelessWidget {
  final Chat chat;
  final VoidCallback onTap;
  
  // Features
  - Avatar with online indicator
  - Name, last message, timestamp
  - Unread badge (red circle with count)
  - Typing indicator animation
  - Swipe actions (mute, archive, delete)
}
```

**Usage**: Chats/Messages screen

### 5.4 GradientPillButton

**Purpose**: Primary CTA button with gradient background

```dart
class GradientPillButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isFullWidth;
  
  // Styling
  - Gradient: accentGradientStart → accentGradientEnd
  - Rounded corners: radiusRound
  - Text: button style, white
  - Height: 56px
  - Tap animation: scale 0.98
}
```

**Usage**: Get Started, Hai Hello, Subscription buttons

### 5.5 BottomGlassNav

**Purpose**: Floating bottom navigation bar

```dart
class BottomGlassNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  
  // Features
  - 5 navigation items
  - Active item: purple background circle
  - Glass effect: semi-transparent background
  - Rounded top corners
  - Icon animations on tap
}
```

**Usage**: All main screens (except onboarding/auth)

### 5.6 ProfileStatsCard

**Purpose**: Statistics display card

```dart
class ProfileStatsCard extends StatelessWidget {
  final int value;
  final String label;
  
  // Styling
  - Rounded corners: radiusSM
  - Background: surfaceDark/Light
  - Large number: h1 style
  - Label: caption style
  - Shadow: shadowSurfaceDark/Light
}
```

**Usage**: Profile screen, user stats

### 5.7 InterestTag

**Purpose**: Interest/personality tag with icon

```dart
class InterestTag extends StatelessWidget {
  final String label;
  final IconData icon;
  
  // Styling
  - Rounded pill: radiusRound
  - Background: dark gray (dark mode) / light gray (light mode)
  - Icon + text: white (dark) / black (light)
  - Padding: spacingXS horizontal, spacingXS vertical
}
```

**Usage**: Profile detail screen, profile creation

### 5.8 TypingIndicator

**Purpose**: Animated typing indicator

```dart
class TypingIndicator extends StatefulWidget {
  // Features
  - Three dots that pulse sequentially
  - Animation: 200ms per dot, staggered
  - Opacity: 0.3 → 1.0 → 0.3
}
```

**Usage**: Chat list, chat screen

### 5.9 MatchAnimation

**Purpose**: Match celebration animation

```dart
class MatchAnimation extends StatefulWidget {
  final String user1Image;
  final String user2Image;
  final int matchPercentage;
  
  // Features
  - Heart frames converging animation
  - Confetti/Lottie animation
  - Haptic feedback
  - Sound effect (optional)
}
```

**Usage**: Match screen

### 5.10 StoryCarousel

**Purpose**: Horizontal scrollable stories/online friends

```dart
class StoryCarousel extends StatelessWidget {
  final List<User> users;
  
  // Features
  - Horizontal ListView
  - AvatarRing for each user
  - Name below avatar
  - Smooth scrolling
}
```

**Usage**: Chats screen, Home screen (optional)

---

## 6. Accessibility & Inclusivity

### 6.1 Contrast Requirements

- **Minimum Contrast Ratios** (WCAG AA):
  - Normal text: 4.5:1
  - Large text (18pt+): 3:1
  - Interactive elements: 3:1
- **High Contrast Mode**: Toggle in settings to increase contrast by 20%

### 6.2 Screen Reader Support

- **Semantic Labels**: All interactive elements have descriptive labels
  - Example: Avatar → "Ava Williams, 23 years old, online, 2.8 km away"
  - Buttons → "Like profile", "Send message", "Super like"
- **Image Alt Text**: Profile images include descriptive alt text
- **State Announcements**: Match, new message, typing indicators announced

### 6.3 Color Blindness Support

- **Not Color-Only Indicators**: Status uses icons + color (green dot + "Online" text)
- **Pattern Alternatives**: Different patterns for different states (if needed)
- **Accessibility Settings**: Option to use high contrast or color-blind friendly palette

### 6.4 Typography Accessibility

- **System Font Scaling**: All text respects system font size preferences
- **Minimum Sizes**: No text smaller than 12px (captions)
- **Line Height**: Minimum 1.4 for body text, 1.2 for headings

### 6.5 Interaction Accessibility

- **Minimum Tappable Area**: 44x44px for all interactive elements
- **Focus Indicators**: Clear focus rings for keyboard navigation
- **Gesture Alternatives**: All swipe gestures have button alternatives
- **Reduce Motion**: Respects system "Reduce Motion" setting, provides toggle in app settings

### 6.6 Inclusive Language & Options

- **Pronouns**: Flexible selection (he/him, she/her, they/them, custom)
- **Gender Identity**: Multiple options, non-binary inclusive
- **Sexual Orientation**: Optional, multiple selections allowed
- **Language**: Support for multiple languages with proper RTL support

---

## 7. Final Notes for Developer Handoff

### 7.1 Theme Configuration

#### Complete ThemeData Setup

```dart
// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  // Color Tokens (as defined in section 2.1)
  static const Color accentPurple = Color(0xFF8A2BE2);
  static const Color accentGradientStart = Color(0xFF7B2BE2);
  static const Color accentGradientEnd = Color(0xFFD33CFF);
  // ... (all colors from section 2.1)

  // Spacing Tokens (as defined in section 2.3)
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  // ... (all spacing from section 2.3)

  // Border Radius Tokens (as defined in section 2.3)
  static const double radiusXS = 6.0;
  static const double radiusSM = 12.0;
  // ... (all radius from section 2.3)

  // Typography (as defined in section 2.2)
  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.2,
  );
  // ... (all text styles from section 2.2)

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: accentPurple,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: ColorScheme.dark(
        primary: accentPurple,
        secondary: accentPink,
        surface: surfaceDark,
        background: backgroundDark,
        error: notificationRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryDark,
        onBackground: textPrimaryDark,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: h1Large.copyWith(color: textPrimaryDark),
        displayMedium: h1.copyWith(color: textPrimaryDark),
        displaySmall: h2.copyWith(color: textPrimaryDark),
        headlineMedium: h3.copyWith(color: textPrimaryDark),
        bodyLarge: bodyLarge.copyWith(color: textPrimaryDark),
        bodyMedium: body.copyWith(color: textPrimaryDark),
        bodySmall: bodySmall.copyWith(color: textSecondaryDark),
        labelLarge: button.copyWith(color: textPrimaryDark),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimaryDark),
        titleTextStyle: h2.copyWith(color: textPrimaryDark),
      ),
      cardTheme: CardTheme(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSM),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPurple,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: spacingLG,
            vertical: spacingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusRound),
          ),
          textStyle: button,
        ),
      ),
      // Add more theme customizations as needed
    );
  }

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: accentPurple,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: ColorScheme.light(
        primary: accentPurple,
        secondary: accentPink,
        surface: surfaceLight,
        background: backgroundLight,
        error: notificationRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryLight,
        onBackground: textPrimaryLight,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: h1Large.copyWith(color: textPrimaryLight),
        displayMedium: h1.copyWith(color: textPrimaryLight),
        displaySmall: h2.copyWith(color: textPrimaryLight),
        headlineMedium: h3.copyWith(color: textPrimaryLight),
        bodyLarge: bodyLarge.copyWith(color: textPrimaryLight),
        bodyMedium: body.copyWith(color: textPrimaryLight),
        bodySmall: bodySmall.copyWith(color: textSecondaryLight),
        labelLarge: button.copyWith(color: textPrimaryLight),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimaryLight),
        titleTextStyle: h2.copyWith(color: textPrimaryLight),
      ),
      cardTheme: CardTheme(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSM),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPurple,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: spacingLG,
            vertical: spacingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusRound),
          ),
          textStyle: button,
        ),
      ),
      // Add more theme customizations as needed
    );
  }

  // Gradient Helper
  static LinearGradient get accentGradient => LinearGradient(
    colors: [accentGradientStart, accentGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadow Helpers
  static List<BoxShadow> get shadowSurface => [
    BoxShadow(
      color: Colors.black.withOpacity(0.6),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get shadowFloating => [
    BoxShadow(
      color: Colors.black.withOpacity(0.7),
      blurRadius: 30,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: Colors.white.withOpacity(0.02),
      blurRadius: 1,
      offset: Offset(0, -1),
    ),
  ];
}
```

### 7.2 Animation Constants

```dart
// lib/core/constants/animations.dart

class AppAnimations {
  // Durations
  static const Duration microDuration = Duration(milliseconds: 150);
  static const Duration smallDuration = Duration(milliseconds: 260);
  static const Duration mediumDuration = Duration(milliseconds: 400);
  static const Duration largeDuration = Duration(milliseconds: 700);
  static const Duration matchDuration = Duration(milliseconds: 900);

  // Curves
  static const Curve microCurve = Curves.easeOut;
  static const Curve smallCurve = Curves.easeInOut;
  static const Curve mediumCurve = Curves.easeInOut;
  static const Curve largeCurve = Curves.easeOutBack;
  static const Curve matchCurve = Curves.elasticOut;

  // Spring Physics
  static const SpringDescription swipeSpring = SpringDescription(
    mass: 0.5,
    stiffness: 200,
    damping: 20,
  );
}
```

### 7.3 Project Structure

```
lib/
├── core/
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── app_colors.dart
│   ├── constants/
│   │   ├── animations.dart
│   │   ├── spacing.dart
│   │   └── typography.dart
│   ├── utils/
│   │   ├── validators.dart
│   │   └── formatters.dart
│   └── widgets/
│       ├── avatar_ring.dart
│       ├── discovery_card.dart
│       ├── chat_list_tile.dart
│       ├── gradient_pill_button.dart
│       ├── bottom_glass_nav.dart
│       ├── profile_stats_card.dart
│       ├── interest_tag.dart
│       ├── typing_indicator.dart
│       └── match_animation.dart
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   │   ├── welcome_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   └── signup_screen.dart
│   │   └── widgets/
│   ├── discover/
│   │   ├── screens/
│   │   │   ├── home_screen.dart
│   │   │   ├── explore_screen.dart
│   │   │   └── match_screen.dart
│   │   └── widgets/
│   ├── profile/
│   │   ├── screens/
│   │   │   ├── profile_screen.dart
│   │   │   └── profile_detail_screen.dart
│   │   └── widgets/
│   ├── chat/
│   │   ├── screens/
│   │   │   ├── chats_screen.dart
│   │   │   └── chat_screen.dart
│   │   └── widgets/
│   └── settings/
│       ├── screens/
│       └── widgets/
├── routes/
│   └── app_router.dart
└── main.dart
```

### 7.4 Key Implementation Notes

1. **State Management**: Use Riverpod (`flutter_riverpod`) for state management
2. **Routing**: Use `go_router` for declarative navigation
3. **Image Loading**: Use `cached_network_image` for optimized image loading
4. **Icons**: **CRITICAL** - ALL icons must be SVG from `assets/icons/` using `SvgPicture.asset()` or `AppSvgIcon` widget. Do NOT use Material Icons (`Icons.xxx`)
5. **Animations**: Use `lottie` for match animations, `animations` package for Material motion
6. **Gestures**: Implement custom `GestureDetector` for swipe cards with `Transform` widgets
7. **Theme Switching**: Use `ThemeMode` with `ThemeMode.system` as default, allow manual override
8. **Accessibility**: Always provide `Semantics` widgets for screen readers
9. **Performance**: Use `const` constructors, `ListView.builder` for long lists, image caching

### 7.5 Testing Checklist

- [ ] All screens render correctly in both light and dark modes
- [ ] All interactive elements meet 44x44px minimum tappable area
- [ ] Text contrast meets WCAG AA standards (4.5:1 minimum)
- [ ] Screen reader labels are descriptive and accurate
- [ ] Animations respect "Reduce Motion" setting
- [ ] Swipe gestures work smoothly on all supported devices
- [ ] Images load progressively with placeholders
- [ ] Bottom navigation persists across screens
- [ ] Hero animations work correctly for profile transitions
- [ ] Match animation plays correctly with haptic feedback

### 7.6 Asset Requirements

- **Icons**: SVG format for scalability, 24px base size
- **Images**: WebP format for efficiency, multiple sizes (thumbnail, medium, full)
- **Lottie Animations**: Match celebration, confetti, heart burst
- **Fonts**: Inter font family (or system fallbacks)

---

## Conclusion

This document provides a comprehensive Flutter UI design specification for the LGBTinder application. All design tokens, components, and screen specifications are structured for direct implementation using Flutter's widget system. The theme configuration supports both dark and light modes with automatic adaptation, ensuring a consistent and accessible user experience across all platforms.

For questions or clarifications during implementation, refer to the specific screen sections or component definitions above. All measurements, colors, and typography are defined as constants that can be easily imported and used throughout the application.

---

**Document Version**: 1.0  
**Last Updated**: 2024  
**Maintained By**: Flutter Development Team

