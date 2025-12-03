# LGBTinder UI Design System

This document provides comprehensive guidelines for UI, colors, animations, and all visual design elements for the LGBTinder Flutter application.

> **Note**: For detailed screen-by-screen specifications, refer to `Enhanced-Flutter-UI-Document.md`

---

## Table of Contents

1. [Color System](#color-system)
2. [Typography](#typography)
3. [Spacing & Layout](#spacing--layout)
4. [Animations & Transitions](#animations--transitions)
5. [Components](#components)
6. [Icons & Iconography](#icons--iconography)
7. [Shadows & Elevation](#shadows--elevation)
8. [Border Radius](#border-radius)
9. [Gradients](#gradients)
10. [Accessibility](#accessibility)

---

## Color System

### Dark Mode Palette

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

### Light Mode Palette

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

### Color Usage Guidelines

#### Primary Actions
- **Gradient Buttons**: Use `accentGradientStart` → `accentGradientEnd` for primary CTAs
- **Solid Buttons**: Use `accentPurple` for secondary actions
- **Active States**: Use `accentPurple` for selected items, active navigation

#### Status Colors
- **Success/Online**: `onlineGreen` - Use for online indicators, success messages
- **Error/Notifications**: `notificationRed` - Use for errors, notification badges
- **Warning/Super Like**: `warningYellow` - Use for warnings, super-like actions

#### Text Hierarchy
- **Primary Text**: Use `textPrimaryDark/Light` for headings, important content
- **Secondary Text**: Use `textSecondaryDark/Light` for descriptions, captions
- **Tertiary Text**: Use `textTertiaryDark/Light` for metadata, timestamps

#### Contrast Requirements
- **Normal Text**: Minimum 4.5:1 contrast ratio (WCAG AA)
- **Large Text (18pt+)**: Minimum 3:1 contrast ratio
- **Interactive Elements**: Minimum 3:1 contrast ratio

---

## Typography

### Font Family

```dart
// Primary font stack
static const String fontFamily = 'Inter';  // Primary
static const String fontFamilyIOS = 'SF Pro Display';  // iOS fallback
static const String fontFamilyAndroid = 'Roboto';     // Android fallback
```

### Type Scale

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

### Typography Usage

- **H1/H1Large**: Profile names, main headings
- **H2**: Screen titles, card titles
- **H3**: Section headers, list item titles
- **Body/BodyLarge**: Main content, descriptions
- **BodySmall**: Secondary content, metadata
- **Caption**: Timestamps, labels, small text
- **Button**: Button labels, CTAs
- **DisplayScript**: Special headings (match screen)

---

## Spacing & Layout

### Spacing Tokens

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

### Layout Grid

- **Base Unit**: 4px
- **Horizontal Padding**: 16px (contentPadding)
- **Vertical Rhythm**: 12px increments
- **Column Grid**: Single column on mobile, 2 columns for profile galleries

### Responsive Breakpoints

```dart
static const double mobileBreakpoint = 360.0;   // Small mobile
static const double tabletBreakpoint = 600.0;  // Tablet
static const double desktopBreakpoint = 900.0; // Desktop
```

---

## Animations & Transitions

### Animation Durations

```dart
// Micro interactions: 120–220 ms
static const Duration microDuration = Duration(milliseconds: 150);

// Medium transitions: 260–360 ms
static const Duration smallDuration = Duration(milliseconds: 260);
static const Duration mediumDuration = Duration(milliseconds: 400);

// Large modals & match: 500–900 ms
static const Duration largeDuration = Duration(milliseconds: 700);
static const Duration matchDuration = Duration(milliseconds: 900);
```

### Animation Curves

```dart
// Micro interactions
static const Curve microCurve = Curves.easeOut;

// Medium transitions
static const Curve smallCurve = Curves.easeInOut;
static const Curve mediumCurve = Curves.easeInOut;

// Large animations with personality
static const Curve largeCurve = Curves.easeOutBack;
static const Curve matchCurve = Curves.elasticOut;
```

### Key Animations

#### Button Press
- **Duration**: 150ms
- **Effect**: Scale 1.0 → 0.98 → 1.0
- **Curve**: `Curves.easeOut`

#### Card Swipe
- **Duration**: 300ms (spring physics)
- **Effect**: Rotation + translation tracking finger
- **Spring**: Mass: 0.5, Stiffness: 200, Damping: 20

#### Like Button
- **Duration**: 300ms
- **Effect**: Heart pop (scale 1.0 → 1.3 → 1.0) + particle burst
- **Haptic**: Light impact

#### Match Animation
- **Duration**: 900ms
- **Effect**: Hearts converge, confetti, elastic bounce
- **Haptic**: Heavy impact

#### Typing Indicator
- **Duration**: 200ms per dot (staggered)
- **Effect**: Opacity 0.3 → 1.0 → 0.3 (sequential)

#### Page Transitions
- **Fade**: 180ms linear
- **Slide**: 300ms easeInOut
- **Hero**: 400ms easeInOut
- **Modal**: 300ms easeOutBack

### Animation Best Practices

1. **Respect Reduce Motion**: Check `MediaQuery.of(context).disableAnimations`
2. **Use Spring Physics**: For natural, bouncy interactions
3. **Stagger Animations**: For lists and grids (50-100ms delay)
4. **Haptic Feedback**: Light impact for likes, heavy for matches
5. **Performance**: Use `AnimatedContainer` for simple animations, `AnimationController` for complex

---

## Components

### AvatarRing

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
}
```

### DiscoveryCard

**Purpose**: Swipeable profile card

```dart
class DiscoveryCard extends StatelessWidget {
  final Profile profile;
  
  // Features
  - Full-bleed image with bottom gradient overlay
  - Badges on top-left
  - Name, age, distance on bottom-left
  - Swipe gestures with spring physics
  - Hero animation for transitions
}
```

### GradientPillButton

**Purpose**: Primary CTA button

```dart
class GradientPillButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  
  // Styling
  - Gradient: accentGradientStart → accentGradientEnd
  - Rounded corners: radiusRound (999px)
  - Height: 56px
  - Text: button style, white
  - Tap animation: scale 0.98
}
```

### BottomGlassNav

**Purpose**: Floating bottom navigation

```dart
class BottomGlassNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  
  // Features
  - 5 navigation items
  - Active item: purple background circle
  - Glass effect: semi-transparent background
  - Rounded top corners (20px)
  - Icon animations on tap
}
```

### ChatListTile

**Purpose**: Chat list item

```dart
class ChatListTile extends StatelessWidget {
  final Chat chat;
  
  // Features
  - Avatar with online indicator
  - Name, last message, timestamp
  - Unread badge (red circle with count)
  - Typing indicator animation
  - Swipe actions
}
```

### InterestTag

**Purpose**: Interest/personality tag

```dart
class InterestTag extends StatelessWidget {
  final String label;
  final IconData icon;
  
  // Styling
  - Rounded pill: radiusRound
  - Background: dark gray (dark mode) / light gray (light mode)
  - Icon + text: white (dark) / black (light)
  - Padding: spacingXS
}
```

---

## Icons & Iconography

### Icon Set

- **REQUIRED**: **ALL icons MUST be SVG format from `assets/icons` directory**
- **Icon Location**: `assets/icons/` with subdirectories: `bold/`, `broken/`, `bulk/`, `linear/`, `outline/`, `twotone/`
- **Usage**: Use `SvgPicture.asset()` or the `AppSvgIcon` wrapper widget
- **Utility Class**: Use `AppIcons` constants for icon paths (defined in `lib/core/utils/app_icons.dart`)
- **Style**: Rounded, minimal line icons
- **Stroke Width**: 1.5-2px

### Icon Implementation

**CRITICAL**: Do NOT use Material Icons (`Icons.xxx`). All icons must be SVG from `assets/icons`.

```dart
// ✅ CORRECT - Use AppSvgIcon wrapper
import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/widgets/common/app_svg_icon.dart'; // Adjust path as needed

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
  colorFilter: ColorFilter.mode(
    AppColors.accentPurple,
    BlendMode.srcIn,
  ),
)

// ❌ WRONG - Do NOT use Material Icons
Icon(Icons.favorite) // DO NOT USE
```

### Icon Sizes

```dart
static const double iconSizeXS = 12.0;   // Small icons
static const double iconSizeSM = 16.0;   // Small icons
static const double iconSizeMD = 20.0;   // Medium icons
static const double iconSizeLG = 24.0;   // Large icons (standard)
static const double iconSizeXL = 32.0;   // Extra large icons
```

### Icon Usage

- **Action Icons**: 24px with 44x44px tappable area minimum
- **Navigation Icons**: 24px in bottom nav
- **Status Icons**: 12-16px for indicators
- **Decorative Icons**: 32-48px for hero sections

### Icon Colors

- **Default**: Use `Theme.of(context).iconTheme.color` or theme-aware colors
- **Accent**: Use `accentPurple` for active states
- **Muted**: Use `textSecondaryDark/Light` for inactive states
- **Theme Support**: Icons should adapt to dark/light mode automatically via `AppSvgIcon` widget

### Icon Directory Structure

Icons are organized in `assets/icons/` with the following subdirectories:
- `bold/` - Bold style icons
- `broken/` - Broken/outline style icons
- `bulk/` - Bulk/filled style icons
- `linear/` - Linear style icons
- `outline/` - Outline style icons (recommended for most use cases)
- `twotone/` - Two-tone style icons

**Path Format**: `assets/icons/{style}/{icon-name}.svg`

**Example**: `assets/icons/outline/heart.svg`

---

## Shadows & Elevation

### Dark Mode Shadows

```dart
// Surface shadow
static const List<BoxShadow> shadowSurfaceDark = [
  BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.6),
    blurRadius: 18,
    offset: Offset(0, 6),
  ),
];

// Floating card shadow
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
```

### Light Mode Shadows

```dart
// Surface shadow
static const List<BoxShadow> shadowSurfaceLight = [
  BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.1),
    blurRadius: 12,
    offset: Offset(0, 4),
  ),
];

// Floating card shadow
static const List<BoxShadow> shadowFloatingLight = [
  BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.15),
    blurRadius: 24,
    offset: Offset(0, 8),
  ),
];
```

### Elevation Levels

- **Level 0**: No shadow (background)
- **Level 1**: `shadowSurface` (cards, containers)
- **Level 2**: `shadowFloating` (floating elements, modals)

---

## Border Radius

### Radius Tokens

```dart
static const double radiusXS = 6.0;    // Small badges, chips
static const double radiusSM = 12.0;   // Cards, containers
static const double radiusMD = 16.0;   // Dialogs, bottom sheets
static const double radiusLG = 24.0;   // Large cards, profile cards
static const double radiusRound = 999.0; // Avatars, pill buttons
```

### Usage Guidelines

- **XS (6px)**: Small badges, chips, tags
- **SM (12px)**: Standard cards, containers, buttons
- **MD (16px)**: Dialogs, bottom sheets, modals
- **LG (24px)**: Large profile cards, hero sections
- **Round (999px)**: Circular elements (avatars, pill buttons)

---

## Gradients

### Primary Gradient

```dart
// Accent gradient (primary CTA)
static LinearGradient accentGradient = LinearGradient(
  colors: [accentGradientStart, accentGradientEnd],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
```

### Usage

- **Primary Buttons**: Use accent gradient
- **Story Rings**: Use accent gradient with stroke
- **Hero Sections**: Use accent gradient for backgrounds
- **Cards**: Use subtle gradients for depth

### Gradient Examples

```dart
// Button gradient
Container(
  decoration: BoxDecoration(
    gradient: accentGradient,
    borderRadius: BorderRadius.circular(radiusRound),
  ),
)

// Story ring gradient
Container(
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    gradient: accentGradient,
  ),
)
```

---

## Accessibility

### Color Contrast

- **Normal Text**: Minimum 4.5:1 ratio (WCAG AA)
- **Large Text (18pt+)**: Minimum 3:1 ratio
- **Interactive Elements**: Minimum 3:1 ratio

### Interactive Elements

- **Minimum Tappable Area**: 44x44px
- **Focus Indicators**: Clear focus rings for keyboard navigation
- **Gesture Alternatives**: Button alternatives for all swipe gestures

### Text Scaling

- **Support System Font Scaling**: All text respects `MediaQuery.textScaleFactor`
- **Minimum Sizes**: No text smaller than 12px
- **Line Height**: Minimum 1.4 for body text

### Screen Reader Support

- **Semantic Labels**: All interactive elements have descriptive labels
- **Image Alt Text**: Profile images include descriptive alt text
- **State Announcements**: Match, new message, typing indicators announced

### Motion

- **Respect Reduce Motion**: Check `MediaQuery.of(context).disableAnimations`
- **Provide Toggle**: Settings option to reduce animations
- **Essential Animations**: Only reduce non-essential animations

---

## Implementation Example

### Complete Theme Setup

```dart
// lib/core/theme/app_theme.dart

class AppTheme {
  // Colors (from Color System section)
  static const Color accentPurple = Color(0xFF8A2BE2);
  // ... all colors

  // Typography (from Typography section)
  static const TextStyle h1 = TextStyle(/* ... */);
  // ... all text styles

  // Spacing (from Spacing section)
  static const double spacingLG = 16.0;
  // ... all spacing

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: accentPurple,
      scaffoldBackgroundColor: backgroundDark,
      // ... full theme configuration
    );
  }

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: accentPurple,
      scaffoldBackgroundColor: backgroundLight,
      // ... full theme configuration
    );
  }
}
```

---

## Quick Reference

### Color Access
```dart
// Theme colors
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.surface

// Direct access
AppColors.accentPurple
AppColors.textPrimaryDark
```

### Typography Access
```dart
// Theme text styles
Theme.of(context).textTheme.headlineMedium

// Direct access
AppTypography.h1
AppTypography.body
```

### Spacing Usage
```dart
Padding(
  padding: EdgeInsets.all(AppSpacing.spacingLG),
  child: // ...
)
```

### Animation Usage
```dart
AnimatedContainer(
  duration: AppAnimations.microDuration,
  curve: AppAnimations.microCurve,
  // ...
)
```

---

**Related Documents**:
- `Enhanced-Flutter-UI-Document.md` - Detailed screen-by-screen specifications
- `.cursor/rules/new-flutter-rule.mdc` - Development rules and guidelines

**Last Updated**: 2024  
**Version**: 1.0

