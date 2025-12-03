# Lottie Animation Color Theme Guide

This guide provides color specifications for all Lottie animations to ensure they match the LGBTinder app's design system.

---

## 🎨 Primary Color Palette for Lottie Animations

### Accent Colors (Primary Use)
These are the main colors that should dominate most animations:

```dart
// Primary Accent - Purple
Primary Purple: #8A2BE2 (RGB: 138, 43, 226)
- Use for: Primary actions, main animation elements, active states
- Hex: #8A2BE2

// Gradient Colors
Gradient Start: #7B2BE2 (RGB: 123, 43, 226)
Gradient End: #D33CFF (RGB: 211, 60, 255)
- Use for: Gradient effects, multi-color animations, premium features

// Secondary Accent - Pink
Accent Pink: #FF3CA6 (RGB: 255, 60, 166)
- Use for: Secondary actions, complementary elements, highlights
```

### Status Colors
Use these for specific states and feedback:

```dart
// Success/Positive
Online Green: #2ECC71 (RGB: 46, 204, 113)
- Use for: Success animations, positive feedback, online indicators

// Error/Negative
Notification Red: #FF3B30 (RGB: 255, 59, 48)
- Use for: Error states, warnings, negative feedback

// Warning/Attention
Warning Yellow: #FFC107 (RGB: 255, 193, 7)
- Use for: Warnings, attention-grabbing elements, super-like effects
```

### Background Colors (For Dark Mode)
Use these for backgrounds and surfaces:

```dart
Background Dark: #0B0B0D (RGB: 11, 11, 13)
Surface Dark: #121214 (RGB: 18, 18, 20)
Surface Elevated: #1A1A1C (RGB: 26, 26, 28)
```

### Text Colors (For Text in Animations)
```dart
Text Primary: #FFFFFF (RGB: 255, 255, 255)
Text Secondary: #A6A6A6 (RGB: 166, 166, 166)
Text Tertiary: #6B6B6B (RGB: 107, 107, 107)
```

---

## 📋 Animation-Specific Color Guidelines

### 1. Loading Animations
**Files**: `loading.json`, `loading_hearts.json`, `loading_rainbow.json`

**Color Scheme**:
- **Primary**: Use `#8A2BE2` (Purple) as the main color
- **Secondary**: Use `#FF3CA6` (Pink) for accents
- **Gradient**: Use gradient from `#7B2BE2` to `#D33CFF` for smooth transitions
- **Background**: Transparent or subtle `#121214` (Surface Dark)

**Example**:
- Spinner: Purple (#8A2BE2)
- Accent elements: Pink (#FF3CA6)
- Gradient effects: #7B2BE2 → #D33CFF

---

### 2. Success & Celebration Animations
**Files**: `success.json`, `celebration.json`, `match_celebration.json`, `heart_burst.json`

**Color Scheme**:
- **Primary**: Use `#2ECC71` (Green) for success checkmarks
- **Celebration**: Use gradient `#7B2BE2` → `#D33CFF` → `#FF3CA6` for confetti/particles
- **Hearts**: Use `#FF3CA6` (Pink) for heart elements
- **Stars/Sparkles**: Use `#FFC107` (Yellow) for sparkle effects
- **Match Celebration**: Combine all accent colors in a rainbow effect

**Example**:
- Success checkmark: Green (#2ECC71)
- Confetti particles: Purple (#8A2BE2), Pink (#FF3CA6), Magenta (#D33CFF)
- Hearts: Pink (#FF3CA6) with Purple (#8A2BE2) outline
- Stars: Yellow (#FFC107) with Purple (#8A2BE2) glow

---

### 3. Profile & Verification Animations
**Files**: `profile_complete.json`, `verification_badge.json`, `profile_edit.json`

**Color Scheme**:
- **Primary**: Use `#8A2BE2` (Purple) for main elements
- **Badge/Icon**: Use gradient `#7B2BE2` → `#D33CFF` for verification badges
- **Accent**: Use `#FF3CA6` (Pink) for highlights
- **Success**: Use `#2ECC71` (Green) for completion indicators

**Example**:
- Profile icon: Purple (#8A2BE2)
- Verification badge: Gradient (#7B2BE2 → #D33CFF)
- Completion checkmark: Green (#2ECC71)

---

### 4. Empty State Animations
**Files**: `empty_matches.json`, `empty_chats.json`, `empty_discover.json`, `empty_notifications.json`

**Color Scheme**:
- **Primary**: Use muted `#6B6B6B` (Text Tertiary) for subtle elements
- **Accent**: Use `#8A2BE2` (Purple) at 50% opacity for gentle highlights
- **Background**: Transparent or very subtle

**Example**:
- Main illustration: Muted gray (#6B6B6B)
- Accent highlights: Purple (#8A2BE2) at 50% opacity
- Keep it subtle and non-intrusive

---

### 5. Error State Animations
**Files**: `error.json`, `error_network.json`, `error_generic.json`

**Color Scheme**:
- **Primary**: Use `#FF3B30` (Red) for error indicators
- **Accent**: Use `#FFC107` (Yellow) for warning elements
- **Background**: Subtle dark background

**Example**:
- Error icon: Red (#FF3B30)
- Warning elements: Yellow (#FFC107)
- Keep background minimal

---

### 6. Interactive Animations
**Files**: `like_animation.json`, `super_like.json`, `pass_animation.json`, `rewind.json`

**Color Scheme**:
- **Like**: Use `#FF3CA6` (Pink) for heart/like animations
- **Super Like**: Use `#FFC107` (Yellow) with `#8A2BE2` (Purple) glow
- **Pass**: Use muted colors or `#6B6B6B` (Gray)
- **Rewind**: Use `#8A2BE2` (Purple) for rewind icon

**Example**:
- Like heart: Pink (#FF3CA6) with burst effect
- Super like star: Yellow (#FFC107) with Purple (#8A2BE2) glow
- Pass X: Muted gray (#6B6B6B)
- Rewind icon: Purple (#8A2BE2)

---

### 7. Premium Animations
**Files**: `premium_badge.json`, `premium_unlock.json`, `premium_sparkle.json`

**Color Scheme**:
- **Primary**: Use gradient `#7B2BE2` → `#D33CFF` → `#FF3CA6` for premium effects
- **Gold Accent**: Use `#FFC107` (Yellow) for premium badges
- **Sparkles**: Use all accent colors in a rainbow effect

**Example**:
- Premium badge: Gold (#FFC107) with Purple gradient (#7B2BE2 → #D33CFF)
- Unlock effect: Full gradient rainbow (Purple → Magenta → Pink)
- Sparkles: Multi-color (Purple, Pink, Yellow, Magenta)

---

## 🛠️ Implementation: Dynamic Color Theming

### Option 1: Color Replacement in Lottie Files
When creating/editing Lottie files, use these specific color values:
- Replace default colors with the app's color palette
- Use named layers in After Effects/LottieFiles for easy color replacement
- Export with color values matching the specifications above

### Option 2: Runtime Color Replacement (Flutter)
Use the `lottie` package's color replacement feature:

```dart
import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ThemedLottieAnimation extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final bool loop;
  final bool animate;

  const ThemedLottieAnimation({
    Key? key,
    required this.assetPath,
    this.width,
    this.height,
    this.loop = true,
    this.animate = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Color replacement map
    final colorReplacements = <String, Color>{
      // Replace common color names/values in Lottie with app colors
      'primary': AppColors.accentPurple,
      'secondary': AppColors.accentPink,
      'success': AppColors.onlineGreen,
      'error': AppColors.notificationRed,
      'warning': AppColors.warningYellow,
      // Add more mappings as needed
    };

    return Lottie.asset(
      assetPath,
      width: width,
      height: height,
      repeat: loop,
      animate: animate,
      // Note: Direct color replacement requires Lottie file to use
      // specific layer names or color values that can be mapped
    );
  }
}
```

### Option 3: Theme-Aware Lottie Wrapper
Create a wrapper that adapts to light/dark mode:

```dart
import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ThemeAwareLottie extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final bool loop;
  final Map<String, Color>? colorOverrides;

  const ThemeAwareLottie({
    Key? key,
    required this.assetPath,
    this.width,
    this.height,
    this.loop = true,
    this.colorOverrides,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Default color overrides based on theme
    final defaultColors = <String, Color>{
      'primary': AppColors.accentPurple,
      'secondary': AppColors.accentPink,
      'background': isDark 
          ? AppColors.backgroundDark 
          : AppColors.backgroundLight,
      'text': isDark 
          ? AppColors.textPrimaryDark 
          : AppColors.textPrimaryLight,
    };

    final colors = {...defaultColors, ...?colorOverrides};

    return Lottie.asset(
      assetPath,
      width: width,
      height: height,
      repeat: loop,
      // Apply color filters if needed
      // Note: This requires the Lottie file structure to support it
    );
  }
}
```

---

## 📐 Color Usage Best Practices

### 1. **Consistency**
- Always use the exact hex values specified above
- Maintain color consistency across all animations
- Use the same color for the same semantic meaning (e.g., Purple for primary actions)

### 2. **Contrast**
- Ensure sufficient contrast for visibility
- Use `#FFFFFF` or `#A6A6A6` for text overlays on colored backgrounds
- Test animations on both dark and light backgrounds

### 3. **Gradients**
- Use gradients sparingly for premium/special effects
- Primary gradient: `#7B2BE2` → `#D33CFF`
- Extended gradient: `#7B2BE2` → `#D33CFF` → `#FF3CA6`

### 4. **Opacity**
- Use opacity variations (50%, 75%) for subtle effects
- Maintain full opacity for primary elements
- Use lower opacity for background/ambient effects

### 5. **Animation Types**
- **Loading**: Purple (#8A2BE2) with Pink (#FF3CA6) accents
- **Success**: Green (#2ECC71) with Purple (#8A2BE2) highlights
- **Celebration**: Full gradient rainbow (Purple → Magenta → Pink → Yellow)
- **Error**: Red (#FF3B30) with Yellow (#FFC107) warnings
- **Interactive**: Context-specific (Like = Pink, Super Like = Yellow, etc.)

---

## 🎯 Quick Reference: Color Values

| Purpose | Color | Hex | RGB |
|---------|-------|-----|-----|
| Primary Accent | Purple | `#8A2BE2` | 138, 43, 226 |
| Gradient Start | Purple | `#7B2BE2` | 123, 43, 226 |
| Gradient End | Magenta | `#D33CFF` | 211, 60, 255 |
| Secondary Accent | Pink | `#FF3CA6` | 255, 60, 166 |
| Success | Green | `#2ECC71` | 46, 204, 113 |
| Error | Red | `#FF3B30` | 255, 59, 48 |
| Warning | Yellow | `#FFC107` | 255, 193, 7 |
| Text Primary | White | `#FFFFFF` | 255, 255, 255 |
| Text Secondary | Gray | `#A6A6A6` | 166, 166, 166 |
| Background Dark | Dark | `#0B0B0D` | 11, 11, 13 |

---

## 📝 Notes for Designers/Developers

1. **Lottie File Creation**:
   - Use the exact hex values when creating animations in After Effects
   - Name color layers semantically (e.g., "primary", "secondary", "accent")
   - Export with color values embedded

2. **Color Replacement**:
   - If using LottieFiles, ensure colors match the specifications
   - Use the "Color" property in LottieFiles editor to set exact values
   - Test animations in both light and dark modes

3. **File Size**:
   - Keep animations under 100KB when possible
   - Use simple color schemes to reduce file size
   - Optimize gradients and complex color effects

4. **Accessibility**:
   - Ensure sufficient contrast for all colors
   - Test with color blindness simulators
   - Provide alternative animations for reduced motion preferences

---

## ✅ Checklist Before Using Lottie Animations

- [ ] Colors match the app's color palette (exact hex values)
- [ ] Animation works in both light and dark modes
- [ ] Contrast is sufficient for visibility
- [ ] File size is optimized (< 100KB recommended)
- [ ] Animation duration is appropriate (1-3 seconds for most)
- [ ] Colors are semantically correct (Purple for primary, Pink for secondary, etc.)
- [ ] Gradient effects use the specified gradient colors
- [ ] Animation is tested on both iOS and Android

---

**Last Updated**: 2024  
**Version**: 1.0

