# LGBTinder (lgbtindernew) — Design System Reference & Compliance Audit

**Generated:** June 26, 2026  
**Purpose:** Onboarding reference for UI work — documents the *implemented* design system, how the app is structured, and which screens/components still diverge from it.

**Related specs (may be outdated vs code):**
- `UI-DESIGN-SYSTEM.md` — original visual spec (purple-first palette)
- `Enhanced-Flutter-UI-Document.md` — screen-by-screen UI spec

**Source of truth for tokens:** `lib/core/theme/` and `lib/core/constants/animation_constants.dart`

---

## 1. Project Architecture (high level)

```
lib/
├── core/                    # Theme, widgets, network, cache, location
│   ├── theme/               # AppColors, AppTypography, AppSpacing, AppRadius, AppTheme
│   ├── widgets/             # AppBottomNavBar, AppPageScaffold, shared UI shell
│   └── constants/           # AppAnimations (durations/curves)
├── features/                # Feature modules (preferred for new work)
│   ├── auth/, discover/, chat/, profile/, settings/, payments/, …
├── pages/                   # Main tab shells (HomePage, DiscoveryPage, ChatListPage, …)
├── screens/                 # Legacy + secondary full screens (many still routed)
├── widgets/                 # Legacy shared widgets (cards, chat, buttons, …)
├── routes/                  # go_router (app_router.dart)
└── shared/                  # Cross-cutting services/models
```

| Layer | Role |
|-------|------|
| **pages/** | Tab content inside `HomePage` shell; primary user flows |
| **features/** | Clean-architecture modules (`data/`, `presentation/`, `providers/`) |
| **screens/** | Older standalone screens; many are still in the router |
| **core/widgets/** | Design-system-aligned reusable shell components |

**State management:** `flutter_riverpod`  
**Routing:** `go_router` with `AppAnimations.transitionPage` slide/fade transitions  
**Main shell:** `HomePage` → 5 tabs via `AppBottomNavBar` (Discover, Chat, Notifications, Profile, Settings)

---

## 2. Implemented Design System

### 2.1 Colors (`lib/core/theme/app_colors.dart`)

The **live palette aligns with the marketing site** (Tailwind zinc neutrals + rose/violet accents), **not** the older purple-only values in `UI-DESIGN-SYSTEM.md`.

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `backgroundLight/Dark` | `#FFFFFF` / `#18181B` | Page background |
| `surfaceLight/Dark` | `#FAFAFA` / `#27272A` | Cards, list tiles |
| `surfaceElevatedLight/Dark` | `#FFFFFF` / `#3F3F46` | Modals, elevated surfaces |
| `textPrimaryLight/Dark` | `#18181B` / `#FFFFFF` | Headings, primary text |
| `textSecondaryLight/Dark` | `#52525B` / `#D4D4D8` | Descriptions |
| `textTertiaryLight/Dark` | `#71717A` / `#FFA1A1AA` | Metadata |
| `accentRose` | `#F43F5E` | Primary CTA |
| `accentViolet` / `accentPurple` | `#8B5CF6` | Secondary accent, active states |
| `accentGradientStart/End` | `#7C3AED` → `#EC4899` | Gradient buttons |
| `brandGradient` | rose → violet | Brand headers/CTAs |
| `onlineGreen` | `#2ECC71` | Online indicator |
| `notificationRed` / `feedbackError` | rose tones | Errors, badges |
| `warningYellow` | `#F59E0B` | Warnings, super-like |
| `lgbtGradient` / `prideGradient` | 6-color pride | Splash, special CTAs |

**Discover swipe gradients:** `discoverDislikeGradient`, `discoverSuperlikeGradient`, `discoverLikeGradient`

**Access pattern:**
```dart
final theme = Theme.of(context);
final isDark = theme.brightness == Brightness.dark;
final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
// Prefer theme.colorScheme when possible
theme.colorScheme.primary; // maps to accentPurple / violet
```

### 2.2 Typography (`lib/core/theme/typography.dart`)

| Style | Size | Weight | Use |
|-------|------|--------|-----|
| `h1Large` | 32 | w700 | Profile names, hero headings |
| `h1` | 28 | w700 | Main headings |
| `h2` / `headlineSmall` | 24 | w600 | Screen titles |
| `h3` | 18 | w600 | Section headers |
| `h4` / `titleMedium` | 16 | w600 | List item titles |
| `titleLarge` | 22 | w600 | Card titles |
| `bodyLarge` | 16 | w400 | Main content |
| `body` / `bodyMedium` | 14 | w400 | Default body |
| `bodySmall` | 12 | w400 | Secondary content |
| `caption` | 12 | w400 | Timestamps, labels |
| `button` | 16 | w600 | CTA labels |
| `displayScript` | 36 italic | w400 | Match celebration |

**Font:** Inter is declared in `pubspec.yaml` (`assets/fonts/Inter/`) but **`AppTheme` does not set `fontFamily: 'Inter'`** — the app currently falls back to platform default unless a widget sets Inter explicitly.

**Access:**
```dart
Theme.of(context).textTheme.headlineMedium;
AppTypography.h2.copyWith(color: AppColors.textPrimaryDark);
```

### 2.3 Spacing (`lib/core/theme/spacing_constants.dart`)

Base unit: **4px**

| Token | Value |
|-------|-------|
| `spacingXS` | 4 |
| `spacingSM` | 8 |
| `spacingMD` | 12 |
| `spacingLG` | 16 |
| `contentPadding` | 16 |
| `spacingXL` | 24 |
| `spacingXXL` | 32 |
| `spacingXXXL` | 48 |
| `contentPaddingVertical` | 12 |

### 2.4 Border Radius (`lib/core/theme/border_radius_constants.dart`)

| Token | Value | Use |
|-------|-------|-----|
| `radiusXS` | 6 | Chips, small badges |
| `radiusSM` | 12 | Standard cards |
| `radiusMD` | 16 | Sheets, dialogs |
| `radiusLG` | 24 | Profile cards |
| `radiusXL` | 32 | Large hero cards |
| `radiusRound` | 999 | Pills, avatars |

### 2.5 Animations (`lib/core/constants/animation_constants.dart`)

| Token | Duration | Use |
|-------|----------|-----|
| `tapDuration` | 130ms | Button press |
| `transitionPage` | 300ms | Route push/pop |
| `transitionTab` | 300ms | Bottom nav |
| `transitionModal` | 250ms | Sheets/dialogs |
| `cardExit` / `cardReveal` | 200 / 380ms | Discovery stack |
| `buttonPressScale` | 0.97 | Press feedback |
| `curveDefault` | easeOutCubic | Most transitions |

Respect reduce motion: `AppAnimations.animationsEnabled(context)`

### 2.6 Theme (`lib/core/theme/app_theme.dart`)

- Material 3 (`useMaterial3: true`)
- Light + dark `ThemeData` with `ColorScheme` mapped to `AppColors`
- Transparent `AppBar`, zero elevation
- `AppTheme.accentGradient` and `AppTheme.splashGradient` (pride colors)

### 2.7 Icons

**Rule:** SVG only from `assets/icons/{bold,broken,bulk,linear,outline,twotone}/`

| Utility | Path |
|---------|------|
| Path constants | `lib/core/utils/app_icons.dart` |
| Wrapper widget | `lib/shared/widgets/common/app_svg_icon.dart` (exports `AppSvgIcon`) |

**Do not use** `Icons.*` (Material Icons).

### 2.8 Canonical UI Components (design-system aligned)

| Component | Path | Notes |
|-----------|------|-------|
| `AppBottomNavBar` | `core/widgets/app_bottom_nav_bar.dart` | **Active** — used by `HomePage` |
| `AppPageScaffold` | `core/widgets/app_page_scaffold.dart` | Standard sub-page shell + `AppPageHeader` |
| `AuthPageScaffold` | `core/widgets/auth_page_scaffold.dart` | Auth flows |
| `AppGroupedListCard` | `core/widgets/app_grouped_list_card.dart` | Settings-style grouped lists |
| `GradientButton` | `widgets/buttons/gradient_button.dart` | **Real** primary CTA (not the stub below) |
| `AppSettingsDetail` | `core/widgets/app_settings_detail.dart` | Settings detail rows |
| `ConnectivityBanner` | `core/widgets/connectivity_banner.dart` | Offline banner |
| Premium shell | `core/widgets/premium/*` | Profile ecosystem premium UI |
| `ScaleTapFeedback` | `widgets/buttons/scale_tap_feedback.dart` | Press scale animation |

**Stubs / legacy duplicates to avoid:**

| Item | Issue |
|------|-------|
| `core/widgets/gradient_pill_button.dart` | Empty `TODO` stub — use `GradientButton` |
| `widgets/navbar/bottom_navbar.dart` | Legacy glass nav with labels — **not** used by `HomePage` |
| `screens/subscription_plans_screen.dart` | Duplicate of `features/payments/.../subscription_plans_screen.dart` |
| `screens/premium/*` | Partially duplicated by `features/payments/...` |

---

## 3. Documented vs Implemented Gaps

| Area | `UI-DESIGN-SYSTEM.md` | Implemented code |
|------|----------------------|------------------|
| Dark background | `#0B0B0D` | `#18181B` (zinc-900) |
| Accent purple | `#8A2BE2` | `#8B5CF6` (violet-500) |
| Primary CTA | Purple gradient | Rose → violet (`brandGradient`) |
| Dark surfaces | `#121214`, `#1A1A1C` | `#27272A`, `#3F3F46` |
| Text secondary (dark) | `#A6A6A6` | `#D4D4D8` (zinc-300) |
| Font family | Inter (specified) | Inter in pubspec, **not wired in `AppTheme`** |
| `GradientPillButton` | Fully specified | Stub only; `GradientButton` is the real widget |
| Breakpoints | 360 / 600 / 900 | Used ad-hoc in some widgets (e.g. `BottomNavbar`) |
| Shadows | `shadowSurfaceDark/Light` tokens | Not centralized in theme — often inline `BoxShadow` |

**Recommendation:** Treat `AppColors` + `AppTypography` as source of truth; update `UI-DESIGN-SYSTEM.md` when doing a palette doc sync.

---

## 4. Compliance Audit Summary

Automated scan of `lib/**/*.dart` (June 2026):

| Check | Count | Severity |
|-------|-------|----------|
| Files using `Icons.*` (Material Icons) | **~250** | High |
| Files with inline `Color(0x...)` outside theme | **~22** | Medium |
| `screens/` files using Material Icons | **64** | High |
| `features/` files using Material Icons | **95** | High |
| `widgets/` files using Material Icons | **62** | High |
| `screens/` without `AppPageScaffold` / `AuthPageScaffold` / Premium shell | **23** | Medium |

Most screens **do** import `AppColors`; color token usage is widespread. The biggest systematic gap is **Material Icons instead of SVG**.

---

## 5. Pages / Screens Not Matching Design System

Legend:
- **Icons** = uses `Icons.*` instead of `AppSvgIcon` / `SvgPicture`
- **Scaffold** = custom layout instead of `AppPageScaffold` / `AuthPageScaffold`
- **Legacy** = duplicate or superseded implementation
- **Colors†** = hardcoded `Color(0x...)` values

### 5.1 Main tab pages (`lib/pages/`)

| File | Issues |
|------|--------|
| `discovery_page.dart` | Icons (6), imports legacy `screens/premium/superlike_packs_screen.dart` |
| `chat_list_page.dart` | Icons (2) |
| `chat_page.dart` | Icons (6), uses legacy `widgets/chat/*` stack |
| `profile_page.dart` | Icons (3) |
| `profile_wizard_page.dart` | Icons (5) |
| `search_page.dart` | Icons (6) |
| `chat_conversation_info_page.dart` | Icons (7) |
| `subscription_management_page.dart` | Icons (9), hardcoded colors† |
| `home_page.dart` | ✅ Uses `AppBottomNavBar` — aligned |
| `splash_page.dart` | Pride gradient — aligned |

### 5.2 Routed screens — Material Icons (`lib/screens/`)

All **64** screens below use Material Icons and should migrate to SVG:

<details>
<summary>Full list (click to expand)</summary>

- `accessibility_settings_screen.dart`
- `active_sessions_screen.dart`
- `add_payment_method_screen.dart`
- `animation_settings_screen.dart`
- `auth/login_screen.dart`
- `auth/email_verification_screen.dart`
- `auth/password_reset_flow_screen.dart`
- `auth/profile_completion_screen.dart`
- `auth/profile_completion_welcome_screen.dart`
- `auth/profile_wizard_screen.dart`
- `auth/register_screen.dart`
- `auth/welcome_screen.dart` *(no standard scaffold — intentional hero layout)*
- `banned_account_screen.dart`
- `billing_history_screen.dart`
- `blocked_users_screen.dart`
- `call_history_screen.dart`
- `community_forum_screen.dart`
- `discovery/filter_screen.dart`
- `discovery/likes_received_screen.dart`
- `discovery/search_screen.dart`
- `emergency_contacts_screen.dart`
- `feature_locked_screen.dart`
- `group_notification_settings_screen.dart`
- `haptic_feedback_settings_screen.dart`
- `help_support_screen.dart`
- `image_compression_settings_screen.dart`
- `media_picker_settings_screen.dart`
- `message_search_screen.dart`
- `nearby_safe_places_screen.dart`
- `notification_settings_screen.dart`
- `onboarding/enhanced_onboarding_screen.dart`
- `onboarding/onboarding_preferences_screen.dart`
- `onboarding/onboarding_screen.dart`
- `payment_methods_screen.dart`
- `payment_screen.dart`
- `payment_settings_screen.dart`
- `premium/premium_subscription_screen.dart` **Legacy** (router uses `features/payments/...`)
- `premium/superlike_packs_screen.dart` **Legacy** (still imported from `discovery_page.dart`)
- `premium_features_screen.dart`
- `privacy_settings_screen.dart`
- `profile/advanced_profile_customization_screen.dart`
- `profile/profile_analytics_screen.dart`
- `profile/profile_backup_screen.dart`
- `profile/profile_completion_incentives_screen.dart`
- `profile/profile_export_screen.dart`
- `profile/profile_sharing_screen.dart`
- `profile/profile_templates_screen.dart`
- `profile/profile_verification_screen.dart`
- `profile_edit_screen.dart`
- `pull_to_refresh_settings_screen.dart`
- `rainbow_theme_settings_screen.dart`
- `report_history_screen.dart`
- `safety_center_screen.dart`
- `safety_settings_screen.dart`
- `settings/account_management_screen.dart`
- `settings/comprehensive_settings_screen.dart`
- `skeleton_loader_settings_screen.dart`
- `subscription_management_screen.dart` **Legacy** duplicate
- `subscription_plans_screen.dart` **Legacy** duplicate
- `subscription_status_screen.dart`
- `support_tickets_screen.dart`
- `tier_comparison_screen.dart`
- `two_factor_auth_screen.dart`
- `video_call_screen.dart`
- `voice_call_screen.dart`

</details>

### 5.3 Screens without standard scaffold (custom layouts)

These use bespoke `Scaffold` instead of `AppPageScaffold` / `AuthPageScaffold`:

| File | Notes |
|------|-------|
| `auth/welcome_screen.dart` | Full-bleed marketing hero — may be intentional |
| `auth/profile_completion_welcome_screen.dart` | Celebration layout |
| `banned_account_screen.dart` | Standalone state screen |
| `video_call_screen.dart` / `voice_call_screen.dart` | Full-screen call UI |
| `discovery/profile_detail_screen.dart` | Full-bleed profile |
| `legal/privacy_policy_screen.dart` / `terms_of_service_screen.dart` | Document reader |
| `onboarding/enhanced_onboarding_screen.dart` / `onboarding_screen.dart` | Wizard flow |
| `settings/account_management_screen.dart` | Custom header |
| `settings/call_settings_screen.dart` | Custom layout |
| `active_sessions_screen.dart` | Custom list scaffold |
| `blocked_users_screen.dart` | Custom scaffold |
| `emergency_contacts_screen.dart` | Custom scaffold |
| `help_support_screen.dart` | Custom scaffold |
| `nearby_safe_places_screen.dart` | Map-style layout |
| `notification_settings_screen.dart` | Custom scaffold |
| `privacy_settings_screen.dart` | Custom scaffold |
| `safety_settings_screen.dart` | Custom scaffold |
| `settings_screen.dart` | Legacy settings entry |
| `support_tickets_screen.dart` | Custom scaffold |
| `two_factor_auth_screen.dart` | Custom scaffold |

### 5.4 Feature module screens — highest Material Icons offenders

| File | `Icons.*` count | Other issues |
|------|-----------------|--------------|
| `features/profile/.../other_user_profile_sections.dart` | 33 | Hardcoded colors† in places |
| `features/chat/.../message_attachment_viewer.dart` | 21 | Heavy custom UI |
| `features/admin/.../admin_dashboard_screen.dart` | 20 | Admin-only |
| `features/settings/pages/settings_page.dart` | 16 | Tab settings hub |
| `features/profile/.../profile_details_sections.dart` | 15 | Profile sections |
| `features/profile/.../profile_hero_section.dart` | 10 | Hardcoded colors† |
| `features/analytics/.../analytics_screen.dart` | 12 | Charts/icons |
| `features/marketing/.../daily_rewards_screen.dart` | 11 | Gamification UI |
| `features/notifications/.../notification_visuals.dart` | 11 | Icon mapping uses Material |
| `features/payments/.../premium_subscription_screen.dart` | 9 | Routed — priority fix |
| `features/payments/.../subscription_plans_screen.dart` | 4 | Routed — mostly aligned colors |
| `features/safety/.../report_category_tile.dart` | 9 | Safety flow |

---

## 6. Components Not Matching Design System

### 6.1 Top Material Icons offenders (components/widgets)

| File | `Icons.*` | Priority |
|------|-----------|----------|
| `widgets/cards/swipeable_card.dart` | 14 | **Critical** — discovery core |
| `widgets/profile/profile_info_sections.dart` | 14 | High |
| `widgets/chat/message_bubble.dart` | 7 | **Critical** — chat core |
| `features/chat/presentation/widgets/message_bubble.dart` | 5 | Duplicate chat bubble |
| `widgets/chat/chat_user_info_panel.dart` | 7 | High |
| `widgets/chat/message_input.dart` | 2 | High |
| `features/chat/presentation/widgets/chat_input.dart` | 9 | Duplicate input |
| `features/calls/presentation/widgets/call_controls.dart` | 9 | Calls UI |
| `features/marketing/presentation/widgets/badge_display.dart` | 9 | Hardcoded colors† |
| `features/payments/presentation/widgets/payment_method_tile.dart` | 10 | Hardcoded colors† |
| `features/payments/presentation/widgets/subscription_status_card.dart` | 10 | Payments |
| `features/marketing/presentation/widgets/daily_rewards_dialog.dart` | 9 | Marketing |
| `features/marketing/presentation/widgets/promo_code_input.dart` | 6 | Marketing |
| `widgets/navbar/bottom_navbar.dart` | 3 | **Legacy** — replace usages with `AppBottomNavBar` |
| `core/widgets/gradient_pill_button.dart` | — | **Stub** — implement or delete |

### 6.2 Hardcoded `Color(0x...)` outside theme (sample)

| File | Notes |
|------|-------|
| `widgets/navbar/bottom_navbar.dart` | Inline glass fill colors |
| `widgets/cards/swipeable_card.dart` | Swipe overlay tints |
| `widgets/discovery/discovery_swipe_action_button.dart` | Action button fills (prefer `AppColors.discover*Gradient`) |
| `features/profile/.../profile_hero_section.dart` | Hero overlay |
| `features/profile/.../profile_details_sections.dart` | Section accents |
| `features/onboarding/widgets/onboarding_celebration_screen.dart` | Celebration palette |
| `features/marketing/.../badge_display.dart` | Badge tier colors |
| `features/marketing/.../enhanced_plans_screen.dart` | Plan cards |
| `features/marketing/.../daily_rewards_screen.dart` | Reward UI |
| `features/payments/.../plan_theme_helper.dart` | Plan-specific themes (may be intentional) |
| `core/theme/typography.dart` | `bodySmall` uses hardcoded `#A6A6A6` / `#6B6B6B` instead of `AppColors.textSecondary*` |

### 6.3 Duplicate / parallel implementations

| Domain | Legacy path | Preferred path |
|--------|-------------|----------------|
| Bottom nav | `widgets/navbar/bottom_navbar.dart` | `core/widgets/app_bottom_nav_bar.dart` |
| Primary CTA | `core/widgets/gradient_pill_button.dart` (stub) | `widgets/buttons/gradient_button.dart` |
| Chat bubbles | `widgets/chat/message_bubble.dart` | `features/chat/presentation/widgets/message_bubble.dart` |
| Chat input | `widgets/chat/message_input.dart` | `features/chat/presentation/widgets/chat_input.dart` |
| Subscription plans | `screens/subscription_plans_screen.dart` | `features/payments/presentation/screens/subscription_plans_screen.dart` |
| Superlike packs | `screens/premium/superlike_packs_screen.dart` | `features/payments/presentation/screens/superlike_packs_screen.dart` |
| Premium subscription | `screens/premium/premium_subscription_screen.dart` | `features/payments/presentation/screens/premium_subscription_screen.dart` |
| Interest chips | `widgets/ui/interest_tag.dart` | `features/profile/widgets/interest_chip_list.dart` |
| Match UI | `widgets/match/match_screen.dart` | `features/matching/presentation/widgets/match_celebration.dart` |

### 6.4 Components that ARE design-system aligned (reference examples)

Use these as templates when refactoring:

- `core/widgets/app_bottom_nav_bar.dart` — spacing, radius, SVG icons, theme colors
- `core/widgets/app_grouped_list_card.dart` — settings lists
- `widgets/buttons/gradient_button.dart` — CTA with `AppAnimations`, `AppColors`, SVG
- `widgets/discovery/filter_widgets.dart` — heavy `AppColors` + `AppSpacing` usage
- `screens/auth/login_screen.dart` — `AuthPageScaffold` + tokens (icons still need SVG migration)
- `features/discover/widgets/discover_empty_state.dart` — empty state pattern
- `core/widgets/connectivity_banner.dart` — banner pattern with `AppSvgIcon`

---

## 7. Recommended Fix Order (for upcoming work)

1. **Wire Inter font in `AppTheme`** — one-line fix, app-wide typography consistency
2. **Discovery stack** — `swipeable_card.dart`, `discovery_page.dart`, swipe action buttons
3. **Chat stack** — consolidate `message_bubble` / `message_input` duplicates + SVG icons
4. **Settings hub** — `settings_page.dart`, `comprehensive_settings_screen.dart`, grouped list pattern
5. **Profile sections** — `profile_hero_section.dart`, `profile_details_sections.dart`, `other_user_profile_sections.dart`
6. **Payments/marketing** — routed screens first; remove legacy `screens/premium/*` imports
7. **Delete or implement** `gradient_pill_button.dart` stub; deprecate `bottom_navbar.dart`
8. **Sync docs** — update `UI-DESIGN-SYSTEM.md` to match `AppColors` zinc/rose palette

---

## 8. Quick Reference Cheatsheet

```dart
// Theme
import 'package:lgbtindernew/core/theme/app_colors.dart';
import 'package:lgbtindernew/core/theme/typography.dart';
import 'package:lgbtindernew/core/theme/spacing_constants.dart';
import 'package:lgbtindernew/core/theme/border_radius_constants.dart';
import 'package:lgbtindernew/core/constants/animation_constants.dart';

// Icons (required)
import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/shared/widgets/common/app_svg_icon.dart';

// Page shell
import 'package:lgbtindernew/core/widgets/app_page_scaffold.dart';

// Primary button
import 'package:lgbtindernew/widgets/buttons/gradient_button.dart';
```

```dart
// ✅ Correct icon
AppSvgIcon(assetPath: AppIcons.heart, size: 24, color: theme.colorScheme.primary)

// ❌ Wrong
Icon(Icons.favorite)

// ✅ Correct spacing
padding: EdgeInsets.all(AppSpacing.spacingLG)

// ✅ Reduce motion
if (AppAnimations.animationsEnabled(context)) { /* animate */ }
```

---

*This audit is a snapshot. Re-run `rg -c "Icons\." lib --glob "*.dart"` after migration batches to track progress.*
