# SVG Icons Usage Guide

This guide explains how to use SVG icons throughout the LGBTinder Flutter application.

---

## 📚 Overview

The app uses **SVG icons** from `assets/images/icons/` instead of Material Icons for a more consistent and customizable design. All SVG icons are managed through the `AppIcons` utility class and displayed using the `AppSvgIcon` widget.

---

## 🎯 Quick Start

### 1. Import the App Icons Utility

```dart
import 'package:lgbtindernew/core/utils/app_icons.dart';
```

### 2. Use SVG Icons

```dart
// Simple SVG icon
AppSvgIcon(
  assetPath: AppIcons.heart,
  size: 24,
  color: Colors.pink,
)

// SVG icon button
AppSvgIconButton(
  assetPath: AppIcons.settings,
  onPressed: () {},
  size: 48,
)
```

---

## 📦 Available Components

### 1. `AppSvgIcon` - Basic SVG Icon Widget

A reusable widget for displaying SVG icons with theme support.

**Properties:**
- `assetPath` (required): Path to the SVG file
- `width`: Icon width (optional)
- `height`: Icon height (optional)
- `size`: Icon size (applies to both width and height)
- `color`: Icon color (optional, defaults to theme-based color)
- `fit`: BoxFit for the icon (default: `BoxFit.contain`)
- `alignment`: Alignment for the icon (default: `Alignment.center`)

**Example:**
```dart
AppSvgIcon(
  assetPath: AppIcons.home,
  size: 24,
  color: AppColors.accentPurple,
)
```

### 2. `AppSvgIconButton` - SVG Icon Button

A circular button with an SVG icon.

**Properties:**
- `assetPath` (required): Path to the SVG file
- `onPressed`: Callback when button is tapped
- `size`: Button size (default: 48.0)
- `backgroundColor`: Background color (optional)
- `iconColor`: Icon color (optional)
- `isActive`: Whether button is in active state
- `padding`: Padding around icon (optional)
- `semanticLabel`: Accessibility label (optional)

**Example:**
```dart
AppSvgIconButton(
  assetPath: AppIcons.settings,
  onPressed: () => print('Settings tapped'),
  size: 48,
  isActive: true,
)
```

### 3. `IconButtonCircle` - Enhanced Icon Button

Supports both Material icons and SVG icons.

**Properties:**
- `icon`: Material icon (IconData) - optional
- `svgIcon`: SVG icon path (String) - optional
- `onTap`: Callback when button is tapped
- `size`: Button size (default: 48.0)
- `backgroundColor`: Background color (optional)
- `iconColor`: Icon color (optional)
- `isActive`: Whether button is in active state
- `semanticLabel`: Accessibility label (optional)

**Example:**
```dart
// Using SVG icon
IconButtonCircle(
  svgIcon: AppIcons.heart,
  onTap: () {},
  size: 48,
)

// Using Material icon (fallback)
IconButtonCircle(
  icon: Icons.favorite,
  onTap: () {},
  size: 48,
)
```

---

## 🎨 Available Icons

All icons are accessible through the `AppIcons` class. Here are the main categories:

### Navigation Icons
```dart
AppIcons.home
AppIcons.discover
AppIcons.heart
AppIcons.message
AppIcons.user
AppIcons.settings
AppIcons.search
```

### Action Icons
```dart
AppIcons.add
AppIcons.edit
AppIcons.delete
AppIcons.save
AppIcons.share
AppIcons.download
AppIcons.upload
AppIcons.filter
AppIcons.sort
```

### Arrow Icons
```dart
AppIcons.arrowLeft
AppIcons.arrowRight
AppIcons.arrowUp
AppIcons.arrowDown
AppIcons.back
AppIcons.forward
```

### Media Icons
```dart
AppIcons.camera
AppIcons.gallery
AppIcons.image
AppIcons.video
AppIcons.microphone
AppIcons.play
AppIcons.pause
AppIcons.stop
```

### Communication Icons
```dart
AppIcons.call
AppIcons.videoCall
AppIcons.send
AppIcons.attach
AppIcons.emoji
```

### Social & Interaction Icons
```dart
AppIcons.like
AppIcons.dislike
AppIcons.heart
AppIcons.heartAdd
AppIcons.heartRemove
AppIcons.star
AppIcons.bookmark
```

### Notification & Status Icons
```dart
AppIcons.notification
AppIcons.bell
AppIcons.online
AppIcons.offline
```

### Security & Privacy Icons
```dart
AppIcons.lock
AppIcons.unlock
AppIcons.eye
AppIcons.eyeSlash
AppIcons.shield
AppIcons.key
AppIcons.fingerPrint
```

### Profile & Account Icons
```dart
AppIcons.user
AppIcons.userAdd
AppIcons.userEdit
AppIcons.profile
AppIcons.login
AppIcons.logout
```

### Verification & Badge Icons
```dart
AppIcons.verify
AppIcons.tickCircle
AppIcons.award
AppIcons.medal
AppIcons.crown
AppIcons.badge
```

### Settings & Preferences Icons
```dart
AppIcons.settings
AppIcons.menu
AppIcons.more
```

### Payment & Subscription Icons
```dart
AppIcons.card
AppIcons.wallet
AppIcons.coin
AppIcons.dollarCircle
AppIcons.receipt
```

### Location Icons
```dart
AppIcons.location
AppIcons.gps
AppIcons.map
```

### Time & Calendar Icons
```dart
AppIcons.clock
AppIcons.calendar
AppIcons.timer
```

### Info & Help Icons
```dart
AppIcons.infoCircle
AppIcons.question
AppIcons.danger
AppIcons.warning
AppIcons.help
AppIcons.support
```

### Error & Status Icons
```dart
AppIcons.error
AppIcons.success
AppIcons.warningTriangle
AppIcons.info
```

For a complete list, see `lib/core/utils/app_icons.dart`.

---

## 🔄 Migration Guide

### Replacing Material Icons with SVG Icons

**Before (Material Icon):**
```dart
Icon(
  Icons.favorite,
  color: Colors.pink,
  size: 24,
)
```

**After (SVG Icon):**
```dart
AppSvgIcon(
  assetPath: AppIcons.heart,
  size: 24,
  color: Colors.pink,
)
```

**Before (IconButton with Material Icon):**
```dart
IconButton(
  icon: Icon(Icons.settings),
  onPressed: () {},
)
```

**After (IconButton with SVG Icon):**
```dart
IconButton(
  icon: AppSvgIcon(
    assetPath: AppIcons.settings,
    size: 24,
  ),
  onPressed: () {},
)
```

**Before (Custom Icon Button):**
```dart
IconButtonCircle(
  icon: Icons.favorite,
  onTap: () {},
)
```

**After (SVG Icon Button):**
```dart
IconButtonCircle(
  svgIcon: AppIcons.heart,
  onTap: () {},
)
```

---

## 🎨 Theming

SVG icons automatically adapt to the app's theme (light/dark mode). You can also override colors:

```dart
// Use theme color (default)
AppSvgIcon(
  assetPath: AppIcons.settings,
  size: 24,
)

// Override with custom color
AppSvgIcon(
  assetPath: AppIcons.settings,
  size: 24,
  color: AppColors.accentPurple,
)
```

---

## ♿ Accessibility

Always provide semantic labels for interactive icons:

```dart
AppSvgIconButton(
  assetPath: AppIcons.settings,
  onPressed: () {},
  semanticLabel: 'Open settings',
)
```

Or use `Semantics` widget:

```dart
Semantics(
  label: 'Like profile',
  button: true,
  child: AppSvgIconButton(
    assetPath: AppIcons.heart,
    onPressed: () {},
  ),
)
```

---

## 📝 Best Practices

1. **Use SVG Icons First**: Prefer SVG icons over Material icons for consistency
2. **Use AppIcons Constants**: Always use `AppIcons.xxx` instead of hardcoding paths
3. **Provide Semantic Labels**: Add accessibility labels for interactive icons
4. **Consistent Sizing**: Use standard sizes (16, 20, 24, 32, 48) for icons
5. **Theme Awareness**: Let icons adapt to theme unless you need a specific color
6. **Performance**: SVG icons are cached automatically by `flutter_svg`

---

## 🔍 Finding Icons

### Method 1: Check AppIcons Class

Open `lib/core/utils/app_icons.dart` and search for the icon you need.

### Method 2: Check Assets Directory

Browse `assets/images/icons/` to see all available SVG files.

### Method 3: Use getIconPath (Fallback)

If an icon isn't in `AppIcons`, you can use:

```dart
final iconPath = AppIcons.getIconPath('icon-name');
if (iconPath != null) {
  AppSvgIcon(assetPath: iconPath, size: 24)
}
```

---

## 🐛 Troubleshooting

### Icon Not Found

**Error**: `Unable to load asset: assets/images/icons/icon-name.svg`

**Solution**: 
1. Check if the file exists in `assets/images/icons/`
2. Verify the file name matches exactly (case-sensitive)
3. Ensure the file is listed in `pubspec.yaml` under `assets:`

### Icon Not Displaying

**Possible Causes**:
1. File path is incorrect
2. SVG file is corrupted
3. Color filter is hiding the icon

**Solution**:
```dart
// Try without color filter
AppSvgIcon(
  assetPath: AppIcons.heart,
  size: 24,
  // Remove color parameter to see if it displays
)
```

### Icon Too Small/Large

**Solution**: Adjust the `size` parameter:

```dart
AppSvgIcon(
  assetPath: AppIcons.heart,
  size: 32, // Increase from default 24
)
```

---

## 📚 Examples

### Example 1: Navigation Bar Icon

```dart
AppSvgIcon(
  assetPath: AppIcons.home,
  size: 24,
  color: isActive ? AppColors.accentPurple : AppColors.textSecondaryDark,
)
```

### Example 2: Action Button

```dart
AppSvgIconButton(
  assetPath: AppIcons.add,
  onPressed: () => _addItem(),
  size: 48,
  isActive: false,
  semanticLabel: 'Add new item',
)
```

### Example 3: Icon in List Item

```dart
ListTile(
  leading: AppSvgIcon(
    assetPath: AppIcons.settings,
    size: 24,
  ),
  title: Text('Settings'),
  onTap: () {},
)
```

### Example 4: Conditional Icon

```dart
AppSvgIcon(
  assetPath: isLiked ? AppIcons.heartTick : AppIcons.heart,
  size: 24,
  color: isLiked ? AppColors.accentPink : AppColors.textSecondaryDark,
)
```

---

## ✅ Checklist

When using SVG icons:

- [ ] Import `app_icons.dart`
- [ ] Use `AppIcons.xxx` constant instead of hardcoded path
- [ ] Use `AppSvgIcon` or `AppSvgIconButton` widget
- [ ] Provide semantic label for interactive icons
- [ ] Test in both light and dark themes
- [ ] Verify icon displays correctly
- [ ] Check accessibility (screen reader support)

---

**Last Updated**: 2024  
**Version**: 1.0

