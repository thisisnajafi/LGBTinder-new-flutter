# Complete Assets Requirements List

This document lists all images, animations, and Lottie files needed for the LGBTinder Flutter application.

---

## 📁 Directory Structure

```
assets/
├── images/
│   ├── logo/
│   ├── icons/
│   ├── onboarding/
│   ├── avatars/
│   └── placeholders/
├── lottie/
├── animations/
└── sounds/
```

---

## 🖼️ IMAGES

### 1. Logo & Branding (Required)

#### Logo Files
- `assets/images/logo/logo.png` - Main app logo (512x512px recommended)
  - **Format**: PNG with transparency
  - **Usage**: Splash screen, welcome screen, app bar
  - **Variants needed**: 
    - Light mode version (for dark backgrounds)
    - Dark mode version (for light backgrounds)
    - Icon version (1024x1024px for app icon)

#### App Icon
- `assets/images/logo/app_icon.png` - App icon (1024x1024px)
- `assets/images/logo/app_icon_android.png` - Android adaptive icon
- `assets/images/logo/app_icon_ios.png` - iOS app icon

---

### 2. Onboarding Images (Required)

#### Basic Onboarding (4 images)
- `assets/images/onboarding/1.png` - Welcome/Introduction slide
  - **Size**: 1080x1920px (portrait) or 1920x1080px (landscape)
  - **Content**: Welcome illustration showing inclusivity
  
- `assets/images/onboarding/2.png` - Discover/Explore slide
  - **Content**: Discovery/swiping illustration
  
- `assets/images/onboarding/3.png` - Connect/Chat slide
  - **Content**: Messaging/connection illustration
  
- `assets/images/onboarding/4.png` - Community/Be Yourself slide
  - **Content**: Community/authenticity illustration

#### Enhanced Onboarding (Additional 2 images)
- `assets/images/onboarding/welcome.png` - Welcome screen image
- `assets/images/onboarding/match.png` - Match discovery illustration
- `assets/images/onboarding/connections.png` - Building connections
- `assets/images/onboarding/community.png` - Community illustration
- `assets/images/onboarding/safety.png` - Safety features (optional)

**Format**: PNG or WebP, optimized for mobile (under 500KB each)

---

### 3. Splash Screen (Required)

- `assets/images/splash/splash.png` - Splash screen background
  - **Size**: Full screen (1080x1920px or device-specific)
  - **Format**: PNG or WebP
  - **Content**: App branding with gradient background

---

### 4. Placeholder Images (Required)

#### Avatar Placeholders
- `assets/images/placeholders/avatar_placeholder.png` - Default user avatar
  - **Size**: 200x200px
  - **Format**: PNG with transparency
  - **Content**: Generic person silhouette or icon

- `assets/images/placeholders/avatar_male.png` - Male avatar placeholder
- `assets/images/placeholders/avatar_female.png` - Female avatar placeholder
- `assets/images/placeholders/avatar_nonbinary.png` - Non-binary avatar placeholder

#### Image Placeholders
- `assets/images/placeholders/image_placeholder.png` - Generic image placeholder
  - **Size**: 400x400px
  - **Content**: Image icon or broken image placeholder

- `assets/images/placeholders/photo_placeholder.png` - Photo upload placeholder
- `assets/images/placeholders/video_placeholder.png` - Video placeholder

#### Empty State Images
- `assets/images/placeholders/empty_matches.png` - No matches illustration
  - **Size**: 300x300px
  - **Content**: Empty state illustration for matches screen

- `assets/images/placeholders/empty_chat.png` - No messages illustration
- `assets/images/placeholders/empty_notifications.png` - No notifications illustration
- `assets/images/placeholders/empty_feed.png` - Empty feed illustration
- `assets/images/placeholders/empty_search.png` - No search results illustration
- `assets/images/placeholders/empty_likes.png` - No likes received illustration

#### Error State Images
- `assets/images/placeholders/error_generic.png` - Generic error illustration
  - **Size**: 300x300px
  - **Content**: Error/alert illustration

- `assets/images/placeholders/error_network.png` - Network error illustration
- `assets/images/placeholders/error_404.png` - 404 error illustration

#### Loading Placeholders
- `assets/images/placeholders/loading_placeholder.png` - Loading state placeholder

---

### 5. Profile & User Images (Optional - for demo/testing)

#### Default Avatars
- `assets/images/avatars/avatar_1.webp` - Default avatar 1
- `assets/images/avatars/avatar_2.webp` - Default avatar 2
- `assets/images/avatars/avatar_3.webp` - Default avatar 3
- ... (up to 16 default avatars for testing)

**Format**: WebP (optimized), 400x400px each

---

### 6. Icons (Optional - if using custom icons)

If you want custom icons beyond Material Icons:

- `assets/images/icons/` - Custom SVG icons
  - Heart icon (filled/outline)
  - Star icon (super like)
  - X icon (dislike)
  - Chat bubble icon
  - Profile icon
  - Settings icon
  - etc.

**Format**: SVG (scalable vector graphics)

---

## 🎬 LOTTIE ANIMATIONS (Required)

All Lottie files should be in JSON format and placed in `assets/lottie/`

### Loading Animations (3 files)

1. **`loading.json`** - General loading spinner
   - **Duration**: 1-2 seconds (looping)
   - **Size**: Keep under 50KB
   - **Usage**: General loading states
   - **Source**: [LottieFiles - Loading](https://lottiefiles.com/search?q=loading&category=animations)

2. **`loading_hearts.json`** - Loading with animated hearts
   - **Duration**: 2-3 seconds (looping)
   - **Theme**: Hearts animation matching app theme
   - **Usage**: Loading states in discovery/matching screens
   - **Source**: [LottieFiles - Hearts Loading](https://lottiefiles.com/search?q=hearts+loading)

3. **`loading_rainbow.json`** - Rainbow-themed loading animation
   - **Duration**: 2-3 seconds (looping)
   - **Theme**: Rainbow colors matching LGBT+ theme
   - **Usage**: Special loading states
   - **Source**: [LottieFiles - Rainbow](https://lottiefiles.com/search?q=rainbow)

---

### Success & Celebration Animations (4 files)

4. **`success.json`** - Success checkmark animation
   - **Duration**: 1 second (one-time)
   - **Usage**: Success confirmations, form submissions
   - **Source**: [LottieFiles - Success](https://lottiefiles.com/search?q=success+checkmark)

5. **`celebration.json`** - Confetti/celebration animation
   - **Duration**: 2-3 seconds (one-time)
   - **Usage**: Profile completion, achievements
   - **Source**: [LottieFiles - Celebration](https://lottiefiles.com/search?q=celebration+confetti)

6. **`match_celebration.json`** - Special match celebration animation
   - **Duration**: 3-4 seconds (one-time)
   - **Theme**: Hearts, stars, celebration
   - **Usage**: When users match (CRITICAL)
   - **Source**: [LottieFiles - Match](https://lottiefiles.com/search?q=match+celebration)

7. **`heart_burst.json`** - Hearts bursting animation
   - **Duration**: 1-2 seconds (one-time)
   - **Usage**: Like actions, heart reactions
   - **Source**: [LottieFiles - Heart Burst](https://lottiefiles.com/search?q=heart+burst)

---

### Profile & Verification Animations (3 files)

8. **`profile_complete.json`** - Profile completion celebration
   - **Duration**: 2-3 seconds (one-time)
   - **Usage**: Profile wizard completion screen
   - **Source**: [LottieFiles - Profile Complete](https://lottiefiles.com/search?q=profile+complete)

9. **`verification_success.json`** - Verification approved animation
   - **Duration**: 2 seconds (one-time)
   - **Usage**: Profile verification success
   - **Source**: [LottieFiles - Verification](https://lottiefiles.com/search?q=verification+success)

10. **`photo_upload.json`** - Photo upload progress animation
    - **Duration**: 2-3 seconds (looping)
    - **Usage**: Photo upload progress indicator
    - **Source**: [LottieFiles - Upload](https://lottiefiles.com/search?q=photo+upload)

---

### Empty State Animations (5 files)

11. **`empty_matches.json`** - No matches found animation
    - **Duration**: 3-4 seconds (looping)
    - **Usage**: Empty matches screen
    - **Source**: [LottieFiles - Empty](https://lottiefiles.com/search?q=empty+matches)

12. **`empty_chat.json`** - No messages yet animation
    - **Duration**: 3-4 seconds (looping)
    - **Usage**: Empty chat list
    - **Source**: [LottieFiles - Empty Chat](https://lottiefiles.com/search?q=empty+chat)

13. **`empty_notifications.json`** - No notifications animation
    - **Duration**: 3-4 seconds (looping)
    - **Usage**: Empty notifications screen
    - **Source**: [LottieFiles - Empty Notifications](https://lottiefiles.com/search?q=empty+notifications)

14. **`empty_feed.json`** - Empty feed animation
    - **Duration**: 3-4 seconds (looping)
    - **Usage**: Empty social feed
    - **Source**: [LottieFiles - Empty Feed](https://lottiefiles.com/search?q=empty+feed)

15. **`empty_search.json`** - No search results animation
    - **Duration**: 3-4 seconds (looping)
    - **Usage**: Empty search results
    - **Source**: [LottieFiles - Empty Search](https://lottiefiles.com/search?q=empty+search)

---

### Error State Animations (3 files)

16. **`error.json`** - General error animation
    - **Duration**: 2 seconds (one-time)
    - **Usage**: General error states
    - **Source**: [LottieFiles - Error](https://lottiefiles.com/search?q=error)

17. **`network_error.json`** - Network connection error
    - **Duration**: 3 seconds (looping)
    - **Usage**: Network connectivity issues
    - **Source**: [LottieFiles - Network Error](https://lottiefiles.com/search?q=network+error)

18. **`something_wrong.json`** - Something went wrong animation
    - **Duration**: 2-3 seconds (one-time)
    - **Usage**: Generic error messages
    - **Source**: [LottieFiles - Something Wrong](https://lottiefiles.com/search?q=something+wrong)

---

### Interactive Element Animations (4 files)

19. **`swipe_left.json`** - Swipe left hint animation
    - **Duration**: 2 seconds (looping)
    - **Usage**: Discovery screen swipe hints
    - **Source**: [LottieFiles - Swipe](https://lottiefiles.com/search?q=swipe+left)

20. **`swipe_right.json`** - Swipe right hint animation
    - **Duration**: 2 seconds (looping)
    - **Usage**: Discovery screen swipe hints
    - **Source**: [LottieFiles - Swipe Right](https://lottiefiles.com/search?q=swipe+right)

21. **`like_animation.json`** - Heart like animation
    - **Duration**: 1 second (one-time)
    - **Usage**: Like button tap animation
    - **Source**: [LottieFiles - Like](https://lottiefiles.com/search?q=heart+like)

22. **`super_like_animation.json`** - Super like star animation
    - **Duration**: 1-2 seconds (one-time)
    - **Usage**: Super like button tap animation
    - **Source**: [LottieFiles - Super Like](https://lottiefiles.com/search?q=star+super+like)

---

### Premium Feature Animations (3 files)

23. **`premium_badge.json`** - Premium membership badge animation
    - **Duration**: 2 seconds (one-time or looping)
    - **Usage**: Premium badge display
    - **Source**: [LottieFiles - Premium](https://lottiefiles.com/search?q=premium+badge)

24. **`unlock_feature.json`** - Feature unlock animation
    - **Duration**: 2-3 seconds (one-time)
    - **Usage**: Unlocking premium features
    - **Source**: [LottieFiles - Unlock](https://lottiefiles.com/search?q=unlock+feature)

25. **`boost_profile.json`** - Profile boost animation
    - **Duration**: 2-3 seconds (one-time)
    - **Usage**: Profile boost activation
    - **Source**: [LottieFiles - Boost](https://lottiefiles.com/search?q=boost+profile)

---

## 🎵 SOUNDS (Optional but Recommended)

Place in `assets/sounds/`

### Notification Sounds
- `assets/sounds/notification.mp3` - Default notification sound
- `assets/sounds/message_received.mp3` - Message received sound
- `assets/sounds/match_sound.mp3` - Match notification sound (IMPORTANT)
- `assets/sounds/super_like_sound.mp3` - Super like sound

### Interaction Sounds
- `assets/sounds/like_sound.mp3` - Like button tap sound
- `assets/sounds/dislike_sound.mp3` - Dislike button tap sound
- `assets/sounds/button_tap.mp3` - General button tap sound

### Error Sounds
- `assets/sounds/error_sound.mp3` - Error notification sound

**Format**: MP3 or WAV, optimized (under 100KB each)

---

## 📋 SUMMARY CHECKLIST

### Required Assets (Must Have)

#### Images
- [ ] App logo (logo.png)
- [ ] App icon (app_icon.png)
- [ ] Splash screen image (splash.png)
- [ ] 4 Onboarding images (1.png, 2.png, 3.png, 4.png)
- [ ] Avatar placeholder (avatar_placeholder.png)
- [ ] Image placeholder (image_placeholder.png)
- [ ] Empty state images (5-6 images)
- [ ] Error state images (2-3 images)

#### Lottie Animations (25 files)
- [ ] Loading animations (3 files)
- [ ] Success & Celebration (4 files)
- [ ] Profile & Verification (3 files)
- [ ] Empty States (5 files)
- [ ] Error States (3 files)
- [ ] Interactive Elements (4 files)
- [ ] Premium Features (3 files)

### Optional Assets (Nice to Have)

- [ ] Enhanced onboarding images (4 additional)
- [ ] Default avatars (16 files)
- [ ] Custom icons (SVG)
- [ ] Sound effects (8-10 files)

---

## 🔗 Download Sources

### Lottie Animations
1. **LottieFiles.com** - https://lottiefiles.com/
   - Largest collection of free Lottie animations
   - Search by keywords: "loading", "success", "celebration", "match", etc.
   - Filter by: Free, Commercial use

2. **Icons8 Lottie** - https://icons8.com/lottie-animations
   - Curated collection of animations

3. **Lottielab** - https://www.lottielab.com/
   - Online Lottie editor

### Images
1. **Unsplash** - https://unsplash.com/ (for placeholder images)
2. **Pexels** - https://www.pexels.com/ (for onboarding images)
3. **Freepik** - https://www.freepik.com/ (for illustrations)
4. **Flaticon** - https://www.flaticon.com/ (for icons)

### Sounds
1. **Freesound** - https://freesound.org/
2. **Zapsplat** - https://www.zapsplat.com/
3. **Mixkit** - https://mixkit.co/free-sound-effects/

---

## 📐 Image Specifications

### Logo
- **Format**: PNG with transparency
- **Size**: 512x512px (main), 1024x1024px (app icon)
- **Background**: Transparent

### Onboarding Images
- **Format**: PNG or WebP
- **Size**: 1080x1920px (portrait) or 1920x1080px (landscape)
- **Max File Size**: 500KB per image
- **Optimization**: Compress for web/mobile

### Placeholder Images
- **Format**: PNG or WebP
- **Size**: 200x200px to 400x400px
- **Background**: Transparent or solid color matching theme

### Lottie Files
- **Format**: JSON
- **Max File Size**: 200KB per file (aim for 50-100KB)
- **Duration**: 1-4 seconds depending on use case
- **Loop**: Configure based on animation type

---

## 🚀 Quick Setup

1. **Create directories**:
   ```bash
   mkdir -p assets/images/{logo,onboarding,placeholders,avatars,icons}
   mkdir -p assets/lottie
   mkdir -p assets/sounds
   ```

2. **Download assets** from sources listed above

3. **Update pubspec.yaml** (already configured):
   ```yaml
   assets:
     - assets/images/
     - assets/lottie/
     - assets/sounds/
   ```

4. **Verify assets** are properly referenced in code

---

## 📝 Notes

- All images should be optimized for mobile (WebP preferred)
- Lottie animations should match the app's color scheme (purple/pink gradient)
- Ensure all assets are properly licensed for commercial use
- Test animations on both iOS and Android
- Consider providing @2x and @3x versions for high-DPI displays

---

**Last Updated**: December 2024  
**Total Required Assets**: 
- Images: ~15-20 files
- Lottie Animations: 25 files
- Sounds: 8-10 files (optional)
- **Total**: ~48-55 asset files

