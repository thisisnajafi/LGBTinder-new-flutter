---
# LGBTFinder Feature Enhancement Plan
> Generated: 2026-09-12
> Design system: LOCKED — existing tokens only, no new values
> Status: [ ] pending · [x] done · [!] blocked
> Source of truth: `docs/APPLICATION_FEATURES.md` + live `lgbtindernew/` + `lgbtinder-backend/`
---

## Audit Summary

**Home / Discover** is a working production swipe surface, not a stub. The live path is `HomePage` tab 0 → `DiscoveryPage` (`lib/pages/discovery_page.dart`) → `CardStackManager` + `SwipeableCard` + `ProfileDetailSheet`, backed by `discoverCacheProvider` and `LikesService`. Greeting, active-filters bar, passport banner, swipe-limit banner, like/dislike overlays, action row, match celebration (6-phase `MatchCelebrationOverlay`), superlike message sheet, and superlike packs sheet all exist. Remaining gaps are spec deltas, not missing screens: swipe-up opens the sheet (feature doc §2 says up = superlike; this plan follows HOME-CARD-005 — expand), there is no SUPER stamp, photo tap is right-half only, filters live in page-local `_activeFilters` and die on leave, daily-cap / superlike-empty are dialogs not empty-state variants, and the superlike message is required (`canSend` rejects empty) instead of optional. A second unused stack (`SwipeableCardStack`, `discoveryProvider`, confetti `MatchCelebration`) still sits beside the live path.

**Settings** hub (`SettingsPage`) has all four documented sections plus logout and pull-to-refresh. Nested screens exist: privacy, alerts, matching preferences, sounds, appearance, account details, sessions, 2FA, blocked users, safety center. The documented critical gap is confirmed: `NotificationSettingsScreen` keeps every toggle in local `setState` (`_pushEnabled`, `_likes`, …) with no GET/PUT. There is no `NotificationPreferencesProvider`. Privacy is mixed: age/distance/online/data-collection/analytics/block-unknown persist through `settingsProvider` → GET/PUT `/privacy/settings`, but that API route is **absent** from `routes/api.php` (`PrivacyControlsService` exists with no controller). Last seen, who-can-see-me, top picks, swipe-back, ads, and read receipts are local-only. Appearance already persists Light/Dark/System via `themeModeProvider` + SharedPreferences.

**Notifications** inbox is largely complete: category chips All/Matches/Likes/Views/System, swipe-delete with 5s undo, mark-all / clear-all overflow, leave-tab mark-read, empty state, FCM register-device, chat FCM suppress, in-app chat banner. Routing in `NotificationNavigation.resolveDestination` only covers a subset of §4.2/§4.3 (like, match, message/chat, superlike/superlike_sent, calls, four plan types, profile/profile_view). About **37 types** fall through to the notifications tab. Plan-restricted likes do not blur identity. Tile icons exist for some types but not the full table. `NotificationBadge` still watches the unused/broken `notificationProvider`. Flutter GET `/notification-preferences` is not an API route.

**Premium** screens exist and Google Play is wired on choose-plan, management, and superlike packs (`in_app_purchase` + `POST /google-play/validate-purchase` + `POST /subscriptions/activate`). `SubscriptionMetaInterceptor` is registered on Dio and updates `subscriptionProvider` from `meta.subscription`. `StartupCacheService.primeCache()` fetches subscription status after auth (in parallel with profile, not strictly sequential). There is **no** Pusher `plan.updated` event — admin grants and Play webhooks do not push a live tier change. Billing history calls `GET /payments/history`, which is **not** in `api.php` (real paths: `GET /user/payments/history`, `GET /subscriptions/history`). Feature-locked and tier-comparison screens exist as static/paywall UI.

**Real-time** already subscribes to `private-user.{userId}` (and legacy `private-chat.{userId}`) in `PusherWebSocketService.connectUser`. Events handled: chat messages, typing, calls, `user.status`, `new.match`. `new.match` only invalidates the match-list cache (`matchRealtimeSyncProvider`) — it does **not** launch `MatchCelebrationOverlay` on other tabs. Backend `NewLike` broadcasts `new.like`; Flutter has no case. No plan/subscription events exist in `app/Events/`. Feature gates that `ref.watch(subscriptionProvider)` will rebuild when the interceptor or refresh updates state; Pusher cannot currently trigger that path.

---

## Categories

### Category 1: Home — Discovery Card & Bottom Sheet
### Category 2: Home — Filters, Banners & Empty States
### Category 3: Home — Match Celebration & Superlike Flow
### Category 4: Settings — Hub & Nested Screens
### Category 5: Settings — Alerts API Wiring (Critical Gap)
### Category 6: Settings — Privacy, Account & Security
### Category 7: Notifications — Inbox & Routing
### Category 8: Notifications — Push & In-App Banners
### Category 9: Notifications — All Type Handling
### Category 10: Premium — Subscription Screens & Purchase
### Category 11: Premium — Superlike Packs & Flow
### Category 12: Premium — Real-Time Tier Enforcement
### Category 13: Real-Time — Pusher Global Events
### Category 14: Backend — Missing Endpoints & Events

---

## Full Enhancement List

---

### HOME-CARD-001: Profile card bottom sheet — full spec
**Category:** Home — Discovery Card & Bottom Sheet
**Priority:** High
**Effort:** Medium
**Scope:** Flutter
**Affects:** `lib/widgets/cards/swipeable_card.dart`, `lib/widgets/cards/profile_detail_sheet.dart`, `lib/pages/discovery_page.dart` (`_openProfileSheet`, `_sheetProfileFromStack`)
**Depends on:** none
**Feature doc ref:** Section 2 — Card stack; Section 3.1 Profile detail
**Current state:** Collapsed `SwipeableCard` has full-bleed photo, gradient overlay, name/age, online green (`kDiscoveryOnlineGreen` / permitted `0xFF22C55E`), location, match % badge, up to 3 match-reason chips, right-edge photo strip, bio “more”. Expanded `ProfileDetailSheet` uses `DraggableScrollableSheet` with `initialChildSize: 0.62`, `minChildSize: 0.38`, `snapSizes: [0.62, 0.96]`. Sections: identity, online + match %, About, Why you matched, info pills, interests (shared highlighted), photo grid, floating dislike/superlike/like (`DiscoverySheetActionBar`). Card header shrinks to ~45% when sheet opens.
**Gap:** Snap sizes differ from spec (0.60 / 0.50 / 0.92). Sheet missing lifestyle (smoke/drink/gym), languages, music, relationship goal. No report/block from sheet. Photo grid has no zoom. Superlike remaining not on FAB. Card and sheet are siblings in a modal, not a continuous morph.
**Enhancement:** Align snap to spec using existing sheet API (`initialChildSize: 0.60`, `minChildSize: 0.50`, `maxChildSize: 0.92`, `snapSizes: [0.60, 0.92]`) — these are layout fractions, not design tokens. Add remaining profile fields already on `DiscoveryProfile` / stack map when present. Keep floating actions closing the sheet then calling `_handleSheetAction`. Do not invent colors.
**Design tokens to use:** `AppColors.accentPurple`, `AppColors.onlineGreen` / permitted `Color(0xFF22C55E)` for the online dot only, `AppColors.textTertiaryLight/Dark`, `theme.colorScheme.surface`, `theme.textTheme.titleLarge`, `titleMedium`, `bodyMedium`, `bodySmall`, `AppSpacing.spacingSM/MD/LG`, `AppRadius.radiusMD/LG`, `AppAnimations.transitionModal`
**Acceptance criteria:**
- [ ] Collapsed card still shows photo, name+age+online, location, match %, reasons, photo strip (hidden if single photo), bio more
- [ ] Sheet snaps at 0.60 and 0.92; photo region ~45% height
- [ ] Identity, stats, full bio, match reasons, details pills, interests, photo grid render from stack data
- [ ] Floating actions close sheet then like / superlike / dislike
- [ ] No new color/spacing/radius tokens

---

### HOME-CARD-002: Card swipe overlays
**Category:** Home — Discovery Card & Bottom Sheet
**Priority:** High
**Effort:** Small
**Scope:** Flutter
**Affects:** `lib/widgets/cards/card_stack_manager.dart` (`_buildSwipeOverlay`)
**Depends on:** none
**Feature doc ref:** Section 2 — card stack
**Current state:** LIKE (left) and NOPE (right) stamps exist. Rotation currently ±0.18 rad. Opacity from drag. **No SUPER stamp.** Swipe-up opens the sheet, so SUPER would only appear if a future vertical-superlike path is added; for now SUPER must show when the superlike **button** is pressed during the card-exit animation.
**Gap:** Missing SUPER overlay. Stamp rotation/opacity not exactly spec (delta/80 clamped 0→1).
**Enhancement:** Keep LIKE/NOPE. Drive opacity with `dragDelta.abs() / 80.0` clamped 0–1. LIKE color `AppColors.feedbackSuccess`. NOPE `theme.colorScheme.error`. SUPER `theme.colorScheme.primary`, top-center, no rotation, shown on programmatic superlike exit. Font: `theme.textTheme.headlineMedium` + `FontWeight.w800`. Border width must use an existing visual (do **not** introduce 2.5px — use 2.0 if a stroke is needed). Radius: `AppRadius.radiusXS` (6) is the nearest token; do not add a 4px radius constant.
**Design tokens to use:** `AppColors.feedbackSuccess`, `colorScheme.error`, `colorScheme.primary`, `textTheme.headlineMedium`, `AppRadius.radiusXS`, `AppSpacing.spacingSM`
**Acceptance criteria:**
- [ ] LIKE appears top-left while dragging right; NOPE top-right while dragging left
- [ ] SUPER appears on superlike button-driven exit
- [ ] Opacity tracks drag / 80.0
- [ ] Reduce Motion still shows stamps at full opacity on commit

---

### HOME-CARD-003: Action row micro-animations
**Category:** Home — Discovery Card & Bottom Sheet
**Priority:** Medium
**Effort:** Small
**Scope:** Flutter
**Affects:** `lib/widgets/discovery/discovery_swipe_action_button.dart`, `lib/pages/discovery_page.dart` action row
**Depends on:** none
**Feature doc ref:** Section 2 — Action row
**Current state:** `DiscoverySwipeActionButton` already scales to **0.92** and superlike rotates via `AnimationController` (250ms / 180ms reverse). `AppAnimations.buttonPressScale` is 0.97 — do not change that global token. Hardcoded glow hexes exist on the button (`0xFFFFB4BC`, `0xFFFEF9C3`, `0xFFBBF7D0`, `0xFF78350F`) — replace with existing `AppColors.discover*Gradient` / `AppColors.feedback*` only if touching this file.
**Gap:** Press timing not using `AppAnimations.tapDuration` (130ms). Parent sizes 54/58 are magic numbers. Unused `ActionButtonsRow` still has rewind/boost + `Colors.yellow`/`Colors.purple`.
**Enhancement:** Map press duration to `AppAnimations.tapDuration` / `feedbackShort` without changing the existing 0.92 scale already in this widget. Respect `MediaQuery.disableAnimations`. Do not add rewind here (see HOME-REWIND-001). Do not introduce new shadow blur values — if a glow is kept, use documented `shadowFloatingLight/Dark` from UI-DESIGN-SYSTEM.md.
**Design tokens to use:** `AppColors.discoverDislikeGradient`, `discoverSuperlikeGradient`, `discoverLikeGradient`, `AppAnimations.tapDuration`, `AppAnimations.feedbackShort`, `AppSpacing.spacingLG`
**Acceptance criteria:**
- [ ] Press scale 0.92 → 1.0; superlike rotates on press
- [ ] `disableAnimations` skips motion
- [ ] Controller disposed
- [ ] No new shadow/color constants

---

### HOME-CARD-004: Photo navigation in card
**Category:** Home — Discovery Card & Bottom Sheet
**Priority:** Medium
**Effort:** Small
**Scope:** Flutter
**Affects:** `lib/widgets/cards/swipeable_card.dart` (`_PhotoLayer`)
**Depends on:** none
**Feature doc ref:** Section 2 — Card stack
**Current state:** Right-side tap cycles next photo; 5s auto-carousel; strip indicator with `AnimatedContainer`. No left-half previous.
**Gap:** Tap left 50% does not go to previous photo. `HitTestBehavior.translucent` may be missing on the left zone.
**Enhancement:** Split photo into two translucent hit targets. Left → previous (clamp 0). Right → next. Single photo: hide strip. Animate strip with `AppAnimations.imageFadeIn` (200ms). Do not steal horizontal swipe from `CardStackManager`.
**Design tokens to use:** `AppAnimations.imageFadeIn`, `AppSpacing.spacingXS`, `Colors.white` only on photo overlay
**Acceptance criteria:**
- [ ] Left 50% previous, right 50% next
- [ ] Strip hidden for one photo
- [ ] Horizontal swipe still likes/dislikes

---

### HOME-CARD-005: Card info expansion — swipe up gesture
**Category:** Home — Discovery Card & Bottom Sheet
**Priority:** Medium
**Effort:** Small
**Scope:** Flutter
**Affects:** `lib/widgets/cards/card_stack_manager.dart` (`_onPanEnd`, `_sheetOpenDistance = 72`), `lib/widgets/cards/swipeable_card.dart`
**Depends on:** HOME-CARD-001
**Feature doc ref:** Section 2 body lists swipe up as superlike — **this item follows the HOME-CARD-005 spec (expand)**. Superlike remains the middle action button (HOME-SUPER-001).
**Current state:** Vertical-up ≥72px or `vy < -700` already opens the profile sheet. Horizontal lane lock `_laneLockDistance = 16` exists.
**Gap:** No 32×4 drag handle on the photo. Velocity threshold is 700px/s not 300px/s. Handle color not `Colors.white.withOpacity(0.55)`.
**Enhancement:** Keep swipe-up → `_openProfileSheet`. Add a 32×4 rounded handle at the photo bottom edge using `Colors.white.withOpacity(0.55)` (photo-overlay exception). Use fling `> 300` px/s to open. Do not trigger on horizontal lane.
**Design tokens to use:** `Colors.white` (photo overlay only), `AppRadius.radiusRound`, `AppSpacing.spacingXS`
**Acceptance criteria:**
- [ ] Up-drag / up-fling opens HOME-CARD-001 sheet
- [ ] Handle visible on multi-photo and single-photo cards
- [ ] Horizontal swipe never opens the sheet

---

### HOME-FILTER-001: Active filters bar
**Category:** Home — Filters, Banners & Empty States
**Priority:** Medium
**Effort:** Small
**Scope:** Flutter
**Affects:** `lib/features/discover/widgets/discover_active_filters_bar.dart`, `lib/pages/discovery_page.dart` (`build` chips ~1163)
**Depends on:** HOME-FILTER-003
**Feature doc ref:** Section 2 — Active filters bar
**Current state:** **Done (HOME-FILTER-001).** `DiscoverActiveFiltersBar` animates 0→full height in 250ms `easeOutCubic` (`AppAnimations.transitionModal`; `Duration.zero` if Reduce Motion). Chips: distance, age, Online, Verified, Premium, gender/interests/goals/lifestyle plus other fields when present, else Custom filters. Edit fill is `colorScheme.primary` / `onPrimary`. Clear only while the bar is shown.  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Bar height animates 250ms when filters appear/clear
- [x] Chips: distance, age, Online, Verified, Custom (and extra labels when data exists)
- [x] Edit opens filter screen; Clear resets and hides bar

---

### HOME-FILTER-002: Discovery filters sheet — complete spec
**Category:** Home — Filters, Banners & Empty States
**Priority:** Medium
**Effort:** Medium
**Scope:** Flutter
**Affects:** `lib/screens/discovery/filter_screen.dart`, `lib/features/discover/data/models/discovery_filter_mapper.dart`
**Depends on:** PREM-PLAN-002
**Feature doc ref:** Section 2 — Discovery filters
**Current state:** Full-screen `FilterScreen` (not a sheet) already has age, distance, gender (all plans) and Silver+ gated verified/online/premium, interests, goals, job, education, languages, music, smoke/drink/gym. Empty `catch (_) {}` at line 97 swallows matching-preferences load.
**Gap:** Not a bottom sheet. Height/city on mapper unused. Lock icon → paywall path may be incomplete. Apply does not persist after pop (HOME-FILTER-003).
**Enhancement:** Keep the screen if navigation is established; do not restyle as a new design language. Wire every advanced control to `advanced_filters` via `subscriptionProvider`. Locked rows: `AppIcons.lock` + tap → `AppRoutes.featureLocked`. Apply pops an API map and updates the bar. Replace empty catch with `AppLogger`.
**Design tokens to use:** `AppColors.accentPurple`, `AppIcons.lock`, `textTheme.titleMedium`, `AppSpacing.spacingLG`, `colorScheme.outline`
**Acceptance criteria:**
- [ ] All-plan: age, distance, gender
- [ ] Silver+: verified/online/premium, interests, goals, profession, education, languages, music, lifestyle
- [ ] Locked rows open feature-locked paywall
- [ ] Apply updates Discover without hardcoded colors

---

### HOME-BANNER-001: Passport banner
**Category:** Home — Filters, Banners & Empty States
**Priority:** Medium
**Effort:** Small
**Scope:** Flutter
**Affects:** `lib/features/discover/widgets/discover_passport_banner.dart`, `lib/features/discover/presentation/screens/passport_screen.dart`
**Depends on:** none
**Feature doc ref:** Section 2 — Passport banner
**Current state:** Shown when `passport.active`; Return home calls passport deactivate API. `Colors.white` on map icon.
**Gap:** No 250ms slide-down. No remaining-time countdown. Icon color not a token.
**Enhancement:** Animate in with `AppAnimations.transitionModal` + `curveDefault`. Keep city name + Return home. Tint with `colorScheme.surface` / `AppColors.surfaceElevatedLight/Dark`. Icon `AppColors.accentViolet`.
**Design tokens to use:** `colorScheme.surface`, `AppColors.accentViolet`, `AppSpacing.spacingMD`, `AppAnimations.transitionModal`, `AppAnimations.curveDefault`
**Acceptance criteria:**
- [ ] Visible only while passport active
- [ ] Return home restores real location via existing passport API
- [ ] 250ms easeOutCubic slide

---

### HOME-BANNER-002: Swipe limit banner
**Category:** Home — Filters, Banners & Empty States
**Priority:** Medium
**Effort:** Small
**Scope:** Flutter
**Affects:** `lib/features/discover/widgets/discover_swipe_limit_banner.dart`, `planLimitsProvider`
**Depends on:** PREM-PLAN-002
**Feature doc ref:** Section 2 — Swipe limit banner
**Current state:** Shows when remaining ≤ 50% of daily limit; text `N swipes left (used/limit)`; Upgrade chip → subscription plans. Hidden when unlimited. **No progress bar.** Hidden entirely when remaining > 50%.
**Gap:** No `LinearProgressIndicator`. Not always visible with remaining count. Superlike remaining not shown.
**Enhancement:** Always show when the plan is limited (or keep 50% threshold and add a thin progress `used/limit` using `AppColors.accentRose` / `onlineGreen`). Tap → plans or feature-locked. Rebuild from `planLimitsProvider` after each swipe (`DiscoverCacheNotifier` already refreshes limits).
**Design tokens to use:** `AppColors.onlineGreen`, `AppColors.warningYellow`, `AppColors.accentRose`, `textTheme.bodySmall`, `AppSpacing.spacingSM`
**Acceptance criteria:**
- [ ] Remaining count from plan-limits
- [ ] Progress bar N/max
- [ ] Tap opens upgrade
- [ ] Updates after swipes without hardcoded hex besides existing tokens

---

### HOME-EMPTY-001: All empty states
**Category:** Home — Filters, Banners & Empty States
**Priority:** High
**Effort:** Medium
**Scope:** Flutter
**Affects:** `lib/features/discover/widgets/discover_empty_state.dart`, `lib/pages/discovery_page.dart` (`_emptyStateConfig`)
**Depends on:** HOME-SUPER-002, PREM-PLAN-002
**Feature doc ref:** Section 2 — Empty and limit states
**Current state:** Three wired configs — location off, stale location (>7 days), deck exhausted. Daily cap is an upgrade dialog. Superlikes exhausted opens packs sheet. `Colors.white` on search icon.
**Gap:** Missing dedicated empty variants 4 (daily cap) and 5 (superlikes used up) as specified. Copy not exact (`Turn on location for nearby matches`, etc.).
**Enhancement:** Add two configs in `_emptyStateConfig` without changing illustration tokens. CTAs: Enable Location → device settings; Expand/Adjust Filters → `FilterScreen`; Try Passport → `PassportScreen`; daily cap → upgrade; superlikes → `showSuperlikePacksSheet`. SVG from `AppIcons` only.
**Design tokens to use:** `textTheme.titleMedium`, `textTheme.bodyMedium`, `colorScheme.onSurface` muted 0.6 via existing `.withValues`, `AppSpacing.spacingXL`, `AppIcons.locationSlash`, `search`, `heart`, `star`, `crown`
**Acceptance criteria:**
- [ ] Five situations produce the documented copy + CTA
- [ ] SVG icons only
- [ ] Pulse animation respects `disableAnimations`

---

### HOME-MATCH-001: Match celebration overlay — complete
**Category:** Home — Match Celebration & Superlike Flow
**Priority:** High
**Effort:** Small
**Scope:** Flutter
**Affects:** `lib/features/matching/widgets/match_celebration_overlay.dart`, `match_celebration_launcher.dart`, `pages/match_found_page.dart`
**Depends on:** RT-GLOBAL-002
**Feature doc ref:** Section 2 — mutual like launches match celebration
**Current state:** Six phases already implemented (fade, avatars, heart elastic, particle burst, title, CTAs). Auto-dismiss 8s → Keep Swiping (spec said auto-dismiss → chat; live goes Keep Swiping). Reduce Motion jumps to end. Unused confetti `MatchCelebration` still in tree.
**Gap:** Auto-dismiss destination is Keep Swiping not chat. Title copy “New Match!” vs “It's a Match!”. Likes-you Accept uses a snackbar, not this overlay.
**Enhancement:** Align copy to “It's a Match!”. Auto-dismiss 8s → Start Message (chat) per spec. Wire likes-you Accept to `MatchCelebrationLauncher`. Do not add new particle colors — use `AppColors.lgbtGradient` / `accentRose` / `accentViolet`.
**Design tokens to use:** `AppColors.accentRose`, `accentViolet`, `lgbtGradient`, `textTheme.displayMedium`, `AppAnimations` intervals already in overlay
**Acceptance criteria:**
- [ ] Six phases remain; Reduce Motion skips to final
- [ ] CTAs: Send a Message → chat; Keep Swiping → dismiss
- [ ] 8s auto-dismiss → chat
- [ ] Particle colors from AppColors only

---

### HOME-SUPER-001: Superlike optional message flow
**Category:** Home — Match Celebration & Superlike Flow
**Priority:** High
**Effort:** Small
**Scope:** Flutter
**Affects:** `lib/widgets/discovery/superlike_message_sheet.dart`, `lib/pages/discovery_page.dart` (`_showSuperlikeBottomSheet`, abort if empty ~403)
**Depends on:** HOME-SUPER-002
**Feature doc ref:** Section 2 — Superlike can include optional message
**Current state:** Sheet exists (avatar, 200-char field, remaining, Send). `canSend` requires non-empty text. Empty remaining opens packs sheet.
**Gap:** Message is required. No Skip text button.
**Enhancement:** Allow send with empty message. Add Skip (`TextButton`) that sends without body. If remaining is 0, skip this sheet and open packs. After send: close, advance card, match check via existing `_handleSwipe`.
**Design tokens to use:** `colorScheme.primary`, `textTheme.titleMedium`, `bodyMedium`, `AppSpacing.spacingLG`, `AppRadius.radiusMD`
**Acceptance criteria:**
- [ ] Send works with empty message
- [ ] Skip sends without message
- [ ] Remaining 0 → packs sheet, no message sheet
- [ ] No `Colors.white`/`black87` on Send — use `onPrimary`

---

### HOME-SUPER-002: Superlike packs purchase sheet
**Category:** Home — Match Celebration & Superlike Flow
**Priority:** High
**Effort:** Small
**Scope:** Flutter
**Affects:** `lib/widgets/discovery/superlike_packs_sheet.dart`, `lib/features/payments/presentation/screens/superlike_packs_screen.dart`
**Depends on:** PREM-SUPER-001
**Feature doc ref:** Section 2 — Superlikes used up → pack sheet
**Current state:** Bottom sheet lists packs from API, Google Play purchase, updates `superlikesRemainingProvider`. Full screen also exists.
**Gap:** Best-value badge may be missing on sheet. Stripe/PayPal only on full screen. After purchase, own-profile hero updates only if it watches the same provider (it does via `superlikesRemainingProvider`).
**Enhancement:** Ensure Best value on cheapest per-unit pack using existing premium badge pattern. After purchase: `superlikesRemainingProvider.setCount`, invalidate `planLimitsProvider`, snackbar. Tokens only.
**Design tokens to use:** `AppColors.warningYellow`, `accentPurple`, `textTheme.titleMedium`, `AppSpacing.spacingMD`, `AppRadius.radiusMD`
**Acceptance criteria:**
- [ ] Packs from GET superlike-packs
- [ ] Google Play → activate → remaining updates
- [ ] Best value badge on best option

---

### SET-HUB-001: Settings hub — verify all sections complete
**Category:** Settings — Hub & Nested Screens
**Priority:** High
**Effort:** Small
**Scope:** Flutter
**Affects:** `lib/features/settings/pages/settings_page.dart`
**Depends on:** none
**Feature doc ref:** Section 5
**Current state:** Quick access (7), Account (4), App experience (2), Support & legal (4), Log out with confirm. Pull-to-refresh `appCacheManagerProvider.revalidateAll()`. Security tile opens **sessions** (subtitle says Sessions & 2FA; 2FA is a separate Account tile — acceptable). About `onTap: () {}` (doc: not tappable). Unlinked stubs: `HapticFeedbackSettingsScreen`, `GroupNotificationSettingsScreen`, `SafetySettingsScreen`, `ComprehensiveSettingsScreen`.
**Gap:** Does not watch `settingsSummaryProvider`. Security does not deep-link 2FA. Haptics screen is a TODO stub and is not in the hub (Sounds & haptics is enough if vibration lives there).
**Enhancement:** Keep hub structure. Optionally subtitle Security with “Active sessions” only. Do not link TODO stub screens. Confirm About remains non-navigating.
**Design tokens to use:** existing `PremiumHubGridSection` / `PremiumSettingsGroup` tokens already on the page
**Acceptance criteria:**
- [ ] All §5.1–5.5 tiles present and navigate
- [ ] Pull-to-refresh revalidates cache
- [ ] Log out confirm copy matches doc
- [ ] About shows version, not tappable

---

### SET-HUB-002: Appearance setting — theme toggle
**Category:** Settings — Hub & Nested Screens
**Priority:** Medium
**Effort:** Small
**Scope:** Flutter
**Affects:** `lib/features/settings/presentation/screens/appearance_settings_screen.dart`, `lib/core/providers/theme_mode_provider.dart`
**Depends on:** none
**Feature doc ref:** Section 5.3 — Light / Dark / System
**Current state:** Three-option selector already persists `app_theme_mode` in SharedPreferences and updates `ThemeMode` on root. No API (correct).
**Gap:** Verify segmented control uses design tokens only; no extra work unless visual mismatch.
**Enhancement:** Verify only. If the control is not a three-option segmented selector, restyle with existing `Premium` chips — no new colors.
**Design tokens to use:** `colorScheme.primary`, `surface`, `AppSpacing.spacingMD`, `AppRadius.radiusSM`
**Acceptance criteria:**
- [ ] System / Light / Dark persist locally
- [ ] MaterialApp themeMode updates immediately
- [ ] No API call

---

### SET-ALERTS-001: Wire Alerts screen to notification preferences API
**Category:** Settings — Alerts API Wiring (Critical Gap)
**Priority:** Critical
**Effort:** Large
**Scope:** Both
**Affects:** `lib/screens/notification_settings_screen.dart`, new `NotificationPreferencesProvider`, `lib/features/notifications/data/models/notification_preferences.dart`, `NotificationService.getPreferences` / `updatePreferences`, backend `NotificationPreferenceController` (new API) + `AuthController::updateNotificationPreferences`
**Depends on:** BE-NOTIF-001
**Feature doc ref:** Section 4.5 — explicitly noted as not wired
**Current state:** CONFIRMED GAP. All toggles (`_pushEnabled`, `_newMatches`, `_newMessages`, `_messageLikes`, `_superlikes`, `_topPicks`, `_boosts`, `_profileViews`, `_likes`, email group, `_soundEnabled`, `_vibrationEnabled`) are `setState` only. No `initState` load. `NotificationService` GET/PUT `/notification-preferences` is unused and **not an API route**. Live API is POST `/user/notification-preferences` with different keys (`match_notifications`, `like_notifications`, …). Flutter model A matches §4.5; AuthController does not.
**Gap:** Nothing persists. Quiet hours absent. Two Flutter models + three backend writers disagree.
**Enhancement:** Backend GET+PUT `/api/notifications/preferences` returning/accepting §4.5 fields (BE-NOTIF-001). Flutter: `NotificationPreferencesProvider` — GET on mount, optimistic toggle, debounce PUT 500ms, revert + error snackbar on failure, shimmer matching toggle layout. Map Alerts UI rows onto model fields (`likes`, `matches`, `messages`, `superlikes`, `profile_views`, `premium_features`, `email_enabled`, `marketing_emails`, `weekly_digest`). Top picks / boosts → `customPreferences` or `premium_features` until backend adds keys — do not invent backend columns in a migration; store in JSON preferences. Wire sound/vibration to existing `soundPreferencesProvider` (already API) instead of duplicate local bools.
**Design tokens to use:** existing `PremiumToggleRow`, `PremiumSettingsGroup`, `AppSpacing.spacingLG`, `AppColors.accentPurple`, shimmer via `AppAnimations.shimmerDuration`
**Acceptance criteria:**
- [ ] Cold start loads GET preferences into every toggle
- [ ] Toggle survives app restart
- [ ] Failed PUT reverts UI
- [ ] Loading shimmer, no `setState` feature flags
- [ ] Quiet hours fields round-trip even if picker is SET-ALERTS-003

---

### SET-ALERTS-002: Push toggle master switch behavior
**Category:** Settings — Alerts API Wiring (Critical Gap)
**Priority:** Medium
**Effort:** Small
**Scope:** Flutter
**Affects:** `lib/screens/notification_settings_screen.dart`
**Depends on:** SET-ALERTS-001
**Feature doc ref:** Section 5.6 Alerts
**Current state:** Nested push rows are `if (_pushEnabled)` — hidden, not faded.
**Gap:** Spec wants opacity 0.4 + non-interactive + `AnimatedOpacity` 200ms for push and email masters.
**Enhancement:** Keep children mounted. `AnimatedOpacity` 0.4, `IgnorePointer` when master off. Duration `AppAnimations.imageFadeIn` (200ms). Same for `email_enabled`.
**Design tokens to use:** `AppAnimations.imageFadeIn`, `AppAnimations.transitionTab`
**Acceptance criteria:**
- [ ] Master off → child rows visible at 0.4 and not tappable
- [ ] 200ms opacity animation; Reduce Motion → instant

---

### SET-ALERTS-003: Quiet hours picker
**Category:** Settings — Alerts API Wiring (Critical Gap)
**Priority:** Medium
**Effort:** Medium
**Scope:** Flutter
**Affects:** `lib/screens/notification_settings_screen.dart`, FCM foreground (`push_notification_service.dart`)
**Depends on:** SET-ALERTS-001
**Feature doc ref:** Section 4.5 — quiet_hours_enabled + start/end
**Current state:** Fields exist on Flutter `NotificationPreferences`. No Alerts UI. OneSignal/web controllers accept quiet hours; Auth API does not.
**Gap:** No From/To pickers. FCM does not suppress during quiet hours.
**Enhancement:** When enabled, `AnimatedContainer` height 0 → `AppSpacing.spacingXXXL` (48) *not* 72 (72 is not a spacing token; use `spacingXXXL` 48 or `spacingXXXL + spacingLG` 64 — nearest tokens). Time pickers save via PUT. Foreground handler skips banners during window.
**Design tokens to use:** `AppSpacing.spacingLG`, `spacingXXXL`, `textTheme.bodyMedium`, `AppAnimations.transitionModal`
**Acceptance criteria:**
- [ ] Enabling quiet hours reveals From/To
- [ ] Values persist via preferences API
- [ ] Local/in-app banners suppressed during the window

---

### SET-PRIV-001: Privacy & safety — all controls wired
**Category:** Settings — Privacy, Account & Security
**Priority:** High
**Effort:** Large
**Scope:** Both
**Affects:** `lib/screens/privacy_settings_screen.dart`, `lib/features/settings/data/models/privacy_settings.dart`, `SettingsService.getPrivacySettings`, backend privacy API (BE-PRIV-001)
**Depends on:** BE-PRIV-001
**Feature doc ref:** Section 5.6 — Privacy & safety
**Current state:** UI complete. Wired: profile visible, show age/distance/online, matching+analytics sharing, block unknown messages, discovery visibility via PUT `/preferences/matching`. Local-only: last seen, who can see my profile, show in discovery, top picks, swipe back, ads, read receipts. Flutter calls `/privacy/settings` — **route missing**. `PrivacyControlsService` has `show_last_seen`, `profile_visibility`, `read_receipts` but is unused.
**Gap:** Half the screen lies. Endpoint 404s unless something else proxies it.
**Enhancement:** After BE-PRIV-001, map every §5.6 control to a real field. `discovery_mode` / visibility radios persist. No leftover `setState`-only privacy flags.
**Design tokens to use:** existing `PremiumToggleRow` / settings tokens
**Acceptance criteria:**
- [ ] Every §5.6 control round-trips API
- [ ] Reloading the screen restores values
- [ ] No local-only privacy toggles

---

### SET-PRIV-002: Data sharing controls
**Category:** Settings — Privacy, Account & Security
**Priority:** Medium
**Effort:** Small
**Scope:** Both
**Affects:** `lib/screens/privacy_settings_screen.dart`
**Depends on:** SET-PRIV-001
**Feature doc ref:** Section 5.6 — Data sharing
**Current state:** Matching (`dataCollection`) and analytics (`analyticsSharing`) persist. Ads is local default false. No explanation copy under ads.
**Gap:** Ads not persisted. Missing helper text.
**Enhancement:** Add `ads_sharing` to privacy payload (BE-PRIV-001). Short `textTheme.bodySmall` explanation under each toggle.
**Design tokens to use:** `textTheme.bodySmall`, `AppColors.textTertiaryLight/Dark`, `AppSpacing.spacingXS`
**Acceptance criteria:**
- [ ] Three data-sharing toggles persist
- [ ] Each has one-line explanation

---

### SET-SEC-001: Active sessions screen
**Category:** Settings — Privacy, Account & Security
**Priority:** Medium
**Effort:** Small
**Scope:** Flutter
**Affects:** `lib/screens/active_sessions_screen.dart`, `SessionApiService`
**Depends on:** none
**Feature doc ref:** Section 5.2 — Active sessions
**Current state:** GET `/sessions`, revoke POST `/sessions/revoke/:id`, revoke-all POST `/sessions/revoke-all`. Current device labeled. Confirm dialogs exist. Unused parallel `settingsProvider.loadDeviceSessions`.
**Gap:** Verify IP masked to first 3 octets. `trustDeviceSession` is a no-op.
**Enhancement:** Mask IP in the tile if the API returns a full address. Keep revoke confirm. Do not add trust (no backend).
**Design tokens to use:** existing session tiles, `AppColors.feedbackError` for revoke
**Acceptance criteria:**
- [ ] Device name, OS, last active shown
- [ ] IP masked when present
- [ ] This device labeled; others can revoke
- [ ] Revoke-all works

---

### SET-SEC-002: Two-factor authentication — complete flow
**Category:** Settings — Privacy, Account & Security
**Priority:** Medium
**Effort:** Medium
**Scope:** Flutter
**Affects:** `lib/screens/two_factor_auth_screen.dart`
**Depends on:** none
**Feature doc ref:** Section 5.2 — 2FA
**Current state:** GET `/2fa/status`, POST enable, GET qr-code, POST backup-codes, POST verify (auto at 6 digits), POST disable `{}`. QR via `CachedNetworkImage`. Copy backup codes.
**Gap:** Disable has no TOTP/password. Backup codes fetched **before** verify. No regenerate after enabled. No otpauth fallback.
**Enhancement:** Disable requires current 6-digit code. Fetch backup codes only after verify succeeds. Add regenerate using existing backup-codes endpoint. Download/copy remain.
**Design tokens to use:** existing 2FA screen tokens, `AppIcons.lock`, `shieldTick`
**Acceptance criteria:**
- [ ] Enable: QR → 6-digit confirm → backup codes
- [ ] Disable requires current code
- [ ] Backup codes copyable after successful enable

---

### NOTIF-INBOX-001: Category chips — complete implementation
**Category:** Notifications — Inbox & Routing
**Priority:** High
**Effort:** Small
**Scope:** Flutter
**Affects:** `lib/features/notifications/presentation/screens/notifications_screen.dart` (`_categories`, `_filterByCategory`)
**Depends on:** none
**Feature doc ref:** Section 4.1 — category chips
**Current state:** Five chips + substring filter already match the doc. `PremiumCategoryChips` sticky under header.
**Gap:** Selected-state 15% primary fill must use existing chip style (do not add a new overlay token). Likes chip also matches `superlike*` (doc says that is intended).
**Enhancement:** Verify selected = primary @ 15% + primary border + primary text; unselected = surface variant. No logic change unless a chip misses `verify`/`plan`/`system`.
**Design tokens to use:** `colorScheme.primary.withValues(alpha: 0.15)`, `colorScheme.surface`, `textTheme.labelMedium`, `AppSpacing.spacingSM`
**Acceptance criteria:**
- [ ] Five chips filter the cached list locally
- [ ] Matches/Likes/Views/System rules match §4.1
- [ ] Horizontal, sticky, token colors only

---

### NOTIF-INBOX-002: Swipe delete with 5-second undo
**Category:** Notifications — Inbox & Routing
**Priority:** Medium
**Effort:** Small
**Scope:** Flutter
**Affects:** `notification_tile.dart` `Dismissible`, `notifications_screen.dart` `_queueDelete` / `_undoDelete` / `_commitDelete`
**Depends on:** none
**Feature doc ref:** Section 4.1
**Current state:** Implemented. 5s timer, snackbar Undo, DELETE `/notifications/{id}` on commit, restore on API failure.
**Gap:** Confirm delete zone uses `colorScheme.error` / `AppColors.feedbackError` (not a raw red). Snackbar copy “Notification deleted · Undo”.
**Enhancement:** Verify tokens + copy. Use `AppAnimations.chatListDeleteUndo` (already 5s) instead of a local duration if duplicated.
**Design tokens to use:** `AppColors.feedbackError`, `AppAnimations.chatListDeleteUndo`
**Acceptance criteria:**
- [ ] Full swipe removes immediately
- [ ] Undo within 5s restores position
- [ ] No undo → DELETE API

---

### NOTIF-INBOX-003: Mark all read / Clear all — overflow menu
**Category:** Notifications — Inbox & Routing
**Priority:** Medium
**Effort:** Small
**Scope:** Flutter
**Affects:** `notifications_screen.dart` `_buildHeaderAction`
**Depends on:** none
**Feature doc ref:** Section 4.1
**Current state:** Overflow: Mark all read → POST `/notifications/read-all`; Clear all → DELETE `/notifications` with confirm. Optimistic UI.
**Gap:** Verify confirm dialog + empty state after clear. Badge via `unreadNotificationCountProvider`.
**Enhancement:** Verify only; fix if Clear all does not show empty state.
**Design tokens to use:** existing overflow / dialog tokens
**Acceptance criteria:**
- [ ] Mark all read clears unread style + badge
- [ ] Clear all confirms then empties list

---

### NOTIF-INBOX-004: Leave tab → mark remaining as read
**Category:** Notifications — Inbox & Routing
**Priority:** Medium
**Effort:** Small
**Scope:** Flutter
**Affects:** `notifications_screen.dart` `_onLeaveNotificationsPage`
**Depends on:** none
**Feature doc ref:** Section 4.1
**Current state:** Implemented — leave tab POSTs read-all / commits pending deletes.
**Gap:** Confirm home-shell tab switch (not only route pop) hits deactivate.
**Enhancement:** If `AutomaticKeepAlive` prevents deactivate, hook `HomePage` tab index 2 → not-2 to call mark-read.
**Design tokens to use:** n/a
**Acceptance criteria:**
- [ ] Switching away from Notifications tab marks remaining read
- [ ] Badge goes to 0

---

### NOTIF-INBOX-005: Plan-restricted like — hide identity
**Category:** Notifications — Inbox & Routing
**Priority:** Medium
**Effort:** Medium
**Scope:** Flutter
**Affects:** `lib/features/notifications/presentation/widgets/notification_tile.dart`, `NotificationNavigation`
**Depends on:** PREM-PLAN-002
**Feature doc ref:** Section 4.1 — plan-restricted likes hide identity
**Current state:** Navigation sends plan-restricted + no peer → `featureLocked`. Tile does **not** blur avatar or replace name with “Someone liked you”. No `ImageFilter.blur` in this feature.
**Gap:** Identity still visible for basid users if payload includes name/photo.
**Enhancement:** If `type` contains `like` and `isPlanRestricted` / user tier `basid`: blur avatar sigma 6, title “Someone liked you”, tap → feature locked. `silder`/`golden`: real avatar/name, tap → matches.
**Design tokens to use:** `AppColors.accentPurple`, `textTheme.bodyMedium`, `AppIcons.heart`, `AppIcons.lock`
**Acceptance criteria:**
- [ ] basid like tiles hide identity
- [ ] Tap opens paywall, not profile
- [ ] silder/golden show real identity

---

### NOTIF-PUSH-001: FCM device token registration
**Category:** Notifications — Push & In-App Banners
**Priority:** Medium
**Effort:** Small
**Scope:** Flutter
**Affects:** `lib/shared/services/push_notification_service.dart`, `lib/core/providers/session_services_provider.dart` (`fcmDeviceRegistrationProvider`)
**Depends on:** BE-NOTIF-002
**Feature doc ref:** Section 4.4
**Current state:** After auth, `POST /notifications/register-device` with `device_token` + `platform`. `onTokenRefresh` re-sends. Backend `NotificationController::registerDevice` exists.
**Gap:** Verify `AppLogger` on success/failure. Body key is `device_token` not `token` — keep backend contract; do not rename without updating both.
**Enhancement:** Confirm registration logs via `AppLogger`. Do not duplicate a second register call.
**Design tokens to use:** n/a
**Acceptance criteria:**
- [ ] Token posted after login
- [ ] Refresh re-registers
- [ ] Failures logged, not empty catch

---

### NOTIF-PUSH-002: FCM foreground handler — complete
**Category:** Notifications — Push & In-App Banners
**Priority:** Critical
**Effort:** Medium
**Scope:** Flutter
**Affects:** `PushNotificationService._onForegroundMessage` (lines ~280–323), `ChatFcmSuppress`, `InAppChatBannerPolicy`
**Depends on:** SET-ALERTS-001, NOTIF-PUSH-003
**Feature doc ref:** Section 4.4
**Current state:** Call types → CallKit path, no banner. Chat suppress for open thread / muted peer. Chat → in-app banner. Else local notification. Premium types → `SubscriptionSyncService.onSubscriptionChangeNotification`.
**Gap:** Does not check `NotificationPreferences.mutedUsers`. Quiet hours not applied. Non-chat types use system tray, not NOTIF-PUSH-003 toast (except chat). Unread badge increment may rely on inbox refresh only.
**Enhancement:** Order: (1) call type → no banner (2) active chat suppress (3) muted_users from preferences (4) quiet hours (5) else NOTIF-PUSH-003 (6) increment unread provider. Keep CallKit exclusive for calls.
**Design tokens to use:** n/a (behavior)
**Acceptance criteria:**
- [ ] Call push never shows a normal banner
- [ ] Active chat + muted users + quiet hours suppress
- [ ] Other types show in-app banner and bump badge

---

### NOTIF-PUSH-003: In-app notification banner
**Category:** Notifications — Push & In-App Banners
**Priority:** Medium
**Effort:** Medium
**Scope:** Flutter
**Affects:** `lib/widgets/chat/in_app_chat_banner.dart`, `in_app_chat_banner_provider.dart` — extend or add a generic overlay
**Depends on:** NOTIF-ROUTE-001
**Feature doc ref:** Section 4.4 — toast-style new-message banner
**Current state:** Chat-only Telegram-style banner exists (`AppAnimations.incomingBanner` 400ms, hold `inAppChatBannerHold` 4s). Non-chat foreground uses `_showLocalNotification`.
**Gap:** No generic 72px banner for likes/matches/plans. 72px is not a spacing token — use `spacingXXXL + spacingLG` (64) or existing chat banner height; do not add `bannerHeight = 72`.
**Enhancement:** Generalize the existing banner widget for any type: 40px avatar (`AppSpacing.spacingXXL`? 32 is XXL — use 40 only if already in that widget), title `textTheme.bodyMedium` bold, body `bodySmall` 1-line ellipsis, dismiss `AppIcons.close`. Slide `Offset(0,-1)→0` with `AppAnimations.transitionPage` (300ms) + `curveDefault`. Tap → `NotificationNavigation`. Max 2 stacked with `AppSpacing.spacingXS` offset. Shadow: documented `shadowFloatingLight/Dark` only.
**Design tokens to use:** `colorScheme.surface`, `textTheme.bodyMedium`, `bodySmall`, `AppSpacing.spacingXS/SM/MD`, `AppAnimations.transitionPage`, `curveDefault`, `inAppChatBannerHold`
**Acceptance criteria:**
- [ ] Non-call, non-suppressed notifications slide down
- [ ] Auto-dismiss 4s; swipe up / × dismiss
- [ ] Tap routes via NOTIF-ROUTE-001
- [ ] Max 2 visible

---

### NOTIF-ROUTE-001: Complete notification routing — all 40+ types
**Category:** Notifications — All Type Handling
**Priority:** Critical
**Effort:** Medium
**Scope:** Flutter
**Affects:** `lib/shared/services/notification_navigation.dart` (`resolveDestination`), `DeepLinkingService._registerDefaultHandlers`
**Depends on:** none
**Feature doc ref:** Section 4.2 + 4.3
**Current state:** Handled: `message`, `chat`, `match`, `like`, `superlike`, `superlike_sent`, `call`, `incoming_call`, `incoming_call_audio`, `incoming_call_video`, `active_call`, `plan_purchased`, `plan_granted`, `plan_upgraded`, `subscription_renewed`, `profile`, `profile_view`, `notification`, unknown → inbox. `actionUrl` wins. Plan-restricted + no peer → feature locked.
**Gap — types NOT handled (fall through to inbox):**
`view`, `visit`, `profile_visit`, `superlike_received`, `missed_call`, `call_declined`, `call_not_answered`, `plan_downgraded`, `subscription_canceled`, `subscription_expired`, `subscription_reminder`, `renewal_reminder`, `payment_success`, `payment_failed`, `premium_feature`, `superlike_pack_purchased`, `superlike_pack_finished`, `superlike_pack_auto_activated`, `safety_alert`, `system_announcement`, `announcement`, `admin`, `system`, `general`, `verification_reminder`, `verification_approved`, `verification_rejected`, `marketing`, `promotion`, `promo`, `story_like`, `story_reply`, `feed_like`, `feed_comment`, `comment`, `reply`, `comment_like`
**Enhancement:** Expand the switch exactly per the routing table in this item’s original spec. Register the same types in `DeepLinkingService`. Unknown → notifications tab.
**Design tokens to use:** n/a
**Acceptance criteria:**
- [ ] Every type in §4.3 has an explicit destination
- [ ] `action_url` still wins
- [ ] Unknown → notifications tab
- [ ] Deep-link handlers match the switch

---

### NOTIF-ROUTE-002: Notification tile designs — all types
**Category:** Notifications — All Type Handling
**Priority:** Low
**Effort:** Small
**Scope:** Flutter
**Affects:** `lib/features/notifications/presentation/widgets/notification_visuals.dart` (`iconAssetFor`)
**Depends on:** NOTIF-ROUTE-001
**Feature doc ref:** Section 4.3
**Current state:** Heart/star/message/eye/crown/tick/warning/gift/verify/call + missed-call/shield/info. Unread fill = primary @ 5%.
**Gap:** —
**Enhancement:** Map remaining categories to existing `AppIcons` (`shield`, `infoCircle`, `callMissed`, `eye`). Unread container `primary.withValues(alpha: 0.05)`.
**Design tokens to use:** `AppIcons.heart`, `star`, `message`, `call`, `crown`, `verify`, `shield`, `infoCircle`, `eye`, `colorScheme.primary` @ 0.05
**Acceptance criteria:**
- [x] Each category shows the specified SVG tint
- [x] Unread vs read backgrounds use tokens only

---

### PREM-PLAN-001: Choose plan screen — complete
**Category:** Premium — Subscription Screens & Purchase
**Priority:** High
**Effort:** Medium
**Scope:** Flutter
**Affects:** `lib/features/payments/presentation/screens/subscription_plans_screen.dart`, `_subscribeWithGooglePlay`
**Depends on:** PREM-RT-001
**Feature doc ref:** Section 3.5
**Current state:** Plans from API; Google Play purchase; post-purchase `subscriptionRefreshProvider.refresh()` + notification handler. Feature lists from plan payload.
**Gap:** Verify Basic/Silver/Golden copy, yearly Best value, current plan checkmark without CTA, activate POST then provider update.
**Enhancement:** Audit UI against §3.5 flags (unlimited likes, likes-you, advanced filters, passport, rewind, read receipts, ad-free, priority likes; Golden + video, AI, boost, incognito). Fix missing rows only. No new gold hex — use `AppColors.warningYellow` / `accentYellow` for Golden accents already in `plan_theme_helper.dart`.
**Design tokens to use:** `AppColors.accentPurple`, `warningYellow`, `textTheme.titleLarge`, `AppSpacing.spacingLG`, `AppRadius.radiusMD`
**Acceptance criteria:**
- [ ] Three tiers visible with features + CTA
- [ ] Current plan has check, no buy CTA
- [ ] Play purchase → activate → provider refresh

---

### PREM-PLAN-002: Feature locked paywall
**Category:** Premium — Subscription Screens & Purchase
**Priority:** High
**Effort:** Small
**Scope:** Flutter
**Affects:** `lib/screens/feature_locked_screen.dart`, `AppRoutes.featureLocked`
**Depends on:** PREM-PLAN-001
**Feature doc ref:** Section 3.5 — Upgrade required
**Current state:** Full-screen paywall exists; CTA → `/subscription-plans`. Mini comparison may be static.
**Gap:** Must accept feature name + minimum tier. Maybe later dismiss. Work for every gate (filters, likes-you, video, passport, rewind, blurred chat).
**Enhancement:** Ensure route extra/query passes `feature` + `minTier` (`basid`/`silder`/`golden`). Mini table uses tokens. Maybe later pops.
**Design tokens to use:** `AppIcons.lock`, `crown`, `colorScheme.primary`, `textTheme.headlineMedium`
**Acceptance criteria:**
- [ ] Shows feature name + unlock copy
- [ ] Mini Basic/Silver/Golden table
- [ ] Upgrade Now → choose plan; Maybe later dismisses

---

### PREM-PLAN-003: Subscription management — complete
**Category:** Premium — Subscription Screens & Purchase
**Priority:** High
**Effort:** Medium
**Scope:** Flutter
**Affects:** `lib/features/payments/pages/subscription_management_page.dart` (alias `subscription_management_screen.dart`)
**Depends on:** none
**Feature doc ref:** Section 3.5 — Subscription management
**Current state:** Current plan, restore, Play URL, cancel, history via `getSubscriptionHistory()`. Google Play wired.
**Gap:** Verify `cancel_at_period_end` warning, cancel sheet (end of period vs immediate + type CANCEL), collapsible history.
**Enhancement:** Complete cancel sheet copy + confirmation. Show “Cancels on {date}” from status payload if present.
**Design tokens to use:** `AppColors.feedbackWarning`, `feedbackError`, `textTheme.titleMedium`, `AppSpacing.spacingLG`
**Acceptance criteria:**
- [ ] Plan name, status, expiry, auto-renew
- [ ] Cancel options + immediate CANCEL confirm
- [ ] Restore + Manage in Google Play

---

### PREM-PLAN-004: Billing history screen
**Category:** Premium — Subscription Screens & Purchase
**Priority:** Medium
**Effort:** Medium
**Scope:** Both
**Affects:** `lib/screens/billing_history_screen.dart`, `PaymentService.getPaymentHistory` (`ApiEndpoints.paymentHistory` = `/payments/history`)
**Depends on:** BE-PREM-002
**Feature doc ref:** Section 3.5 — Billing history
**Current state:** Screen exists, pull-to-refresh, errors become empty list. Endpoint **not in api.php**.
**Gap:** Wrong path. Status badge colors may be hardcoded.
**Enhancement:** Point Flutter at BE-PREM-002 (or existing `GET /user/payments/history`). Paginate. Success badge `AppColors.feedbackSuccess` / primary; failed `feedbackError`.
**Design tokens to use:** `AppColors.feedbackSuccess`, `feedbackError`, `textTheme.bodyMedium`, `labelSmall`
**Acceptance criteria:**
- [ ] List loads from a real API
- [ ] Rows: date, description, amount, status
- [ ] Pagination works

---

### PREM-PLAN-005: Tier comparison screen
**Category:** Premium — Subscription Screens & Purchase
**Priority:** Medium
**Effort:** Small
**Scope:** Flutter
**Affects:** `lib/screens/tier_comparison_screen.dart`, `upgrade_prompt.dart` `PlanComparison`
**Depends on:** PREM-PLAN-001
**Feature doc ref:** Section 3.5 — Compare tiers
**Current state:** Screen + widget exist; static copy; CTA to plans; no live prices from API.
**Gap:** Sticky header, current-tier primary border, SVG check/X per cell, live monthly price.
**Enhancement:** Drive rows from plan feature flags. Sticky header. Current column `Border.all(color: colorScheme.primary)`. Check `AppIcons.checkCircle`, X `AppIcons.close`.
**Design tokens to use:** `colorScheme.primary`, `AppIcons.checkCircle`, `close`, `AppSpacing.spacingSM`, `AppRadius.radiusSM`
**Acceptance criteria:**
- [ ] Three columns Basic / Silver / Golden
- [ ] Sticky header with prices
- [ ] Current tier highlighted
- [ ] CTA on non-current columns

---

### PREM-SUPER-001: Superlike packs screen — complete
**Category:** Premium — Superlike Packs & Flow
**Priority:** High
**Effort:** Small
**Scope:** Flutter
**Affects:** `lib/features/payments/presentation/screens/superlike_packs_screen.dart`
**Depends on:** none
**Feature doc ref:** Section 3.5 — Superlikes
**Current state:** GET packs, remaining at top, Google Play consumable, invalidates packs + plan limits. Remaining provider updated from Discover swipe path.
**Gap:** Auto-activated queued pack snackbar (`superlike_pack_auto_activated`). Best value badge consistency.
**Enhancement:** On `superlike_pack_auto_activated` notification/FCM, snackbar “Your next Superlike pack is now active”. Keep Play → activate → cache.
**Design tokens to use:** `AppColors.warningYellow`, `textTheme.titleMedium`, `AppSpacing.spacingLG`
**Acceptance criteria:**
- [ ] Remaining count at top
- [ ] Purchase updates remaining + profile hero
- [ ] Auto-activate shows snackbar

---

### PREM-SUPER-002: Superlike remaining display in profile hero
**Category:** Premium — Superlike Packs & Flow
**Priority:** Medium
**Effort:** Small
**Scope:** Flutter
**Affects:** `lib/features/profile/presentation/widgets/own_profile/profile_hero_section.dart` (tap → `superlike-packs`), `own_profile_view.dart` (`superlikesRemainingProvider`)
**Depends on:** none
**Feature doc ref:** Section 3.3 — Superlikes remaining in hero
**Current state:** Implemented. Watches `superlikesRemainingProvider`. Tap opens packs.
**Gap:** Confirm it also watches `subscriptionProvider.superlikesRemaining` if those ever diverge. Prefer one source.
**Enhancement:** Unify on `subscriptionProvider.superlikesRemaining` **or** keep `superlikesRemainingProvider` but update both in interceptor/purchase/swipe (already partially done).
**Design tokens to use:** `AppColors.warningYellow`, `AppIcons.star`
**Acceptance criteria:**
- [ ] Hero count matches remaining after swipe and pack purchase
- [ ] Tap opens packs screen

---

### PREM-RT-001: SubscriptionMetaInterceptor — verify active
**Category:** Premium — Real-Time Tier Enforcement
**Priority:** Critical
**Effort:** Small
**Scope:** Flutter
**Affects:** `lib/core/network/subscription_meta_interceptor.dart`, `dio_client.dart` (~230), `subscription_meta_sync.dart`, `subscription_provider.dart`
**Depends on:** none
**Feature doc ref:** prior session + §3.5
**Current state:** **Present and registered.** Reads `meta.subscription` from every JSON response → `SubscriptionMetaSync.instance.handle` → provider + disk cache.
**Gap:** Confirm no Dio instance is created without it (tests / secondary clients). Parse failures already log via `AppLogger`.
**Enhancement:** Verify single Dio path. Add a debug log when tier changes. Do not rewrite if already correct.
**Design tokens to use:** n/a
**Acceptance criteria:**
- [ ] Interceptor on the live Dio singleton
- [ ] `meta.subscription` updates `subscriptionProvider`
- [ ] Parse errors logged, request still succeeds

---

### PREM-RT-002: Subscription Pusher event — plan changes
**Category:** Premium — Real-Time Tier Enforcement
**Priority:** Critical
**Effort:** Medium
**Scope:** Both
**Affects:** `pusher_websocket_service.dart` `_onPusherEvent`, `subscription_provider.dart`, backend BE-PREM-001
**Depends on:** BE-PREM-001, RT-GLOBAL-001
**Feature doc ref:** §3.5 membership live updates
**Current state:** No plan Pusher event in Flutter or `app/Events/`. Tier updates via FCM premium types + interceptor + `POST /subscriptions/refresh`.
**Gap:** Admin grant / Play webhook does not update an open app until the next HTTP call.
**Enhancement:** Listen `plan.updated` on `private-user.{userId}`. Parse tier, `is_active`, `plan_name`, `expires_at`, `features`. Update provider, snackbar “🎉 Your {plan} plan is now active!”, refresh profile + plan-limits.
**Design tokens to use:** snackbar uses existing snackbar theme
**Acceptance criteria:**
- [ ] Event updates tier without restart
- [ ] Snackbar shown
- [ ] Feature gates rebuild (PREM-RT-003)

---

### PREM-RT-003: Feature gate real-time refresh
**Category:** Premium — Real-Time Tier Enforcement
**Priority:** Medium
**Effort:** Medium
**Scope:** Flutter
**Affects:** video call button, `FilterScreen` advanced locks, likes-you, passport, read receipts, chat blur
**Depends on:** PREM-RT-001, PREM-RT-002
**Feature doc ref:** §3.5 typical gates
**Current state:** Helpers on `SubscriptionNotifier` (`canMakeVideoCalls`, `hasUnlimitedLikes`, …) and derived providers. Widgets that `ref.watch(subscriptionProvider)` rebuild; widgets that read a one-shot cache may not.
**Gap:** Audit each gate for `ref.watch` vs copied bool in local state.
**Enhancement:** Replace local cached `isPremium` flags with `ref.watch`. Tiers spelled `basid` | `silder` | `golden`.
**Design tokens to use:** n/a
**Acceptance criteria:**
- [ ] Video, advanced filters, likes-you, passport, read receipts, chat blur update when provider changes without navigation

---

### PREM-RT-004: Startup subscription prime
**Category:** Premium — Real-Time Tier Enforcement
**Priority:** Critical
**Effort:** Small
**Scope:** Flutter
**Affects:** `lib/core/services/startup_cache_service.dart` `primeCache()`
**Depends on:** none
**Feature doc ref:** startup session
**Current state:** After auth: `presence.onForeground()` then **parallel** `Future.wait` of packs, `_fetchAndCacheSubscription`, own profile, `subscriptionRefreshProvider.refresh()`. Re-prime on foreground after 5 minutes. Empty `catch (_) {}` around plan-limits (line 122).
**Gap:** Not sequential markOnline → fetchSubscription → fetchProfile. Failure should keep cache, never flash wrong tier.
**Enhancement:** Sequence subscription fetch before first home paint if not already gated by `StartupCacheListener`. Log plan-limits failures; remove empty catch. On failure use cached `subscriptionProvider` state.
**Design tokens to use:** n/a
**Acceptance criteria:**
- [ ] Authenticated cold start has subscription in provider before Discover gates evaluate
- [ ] Failed network uses cache
- [ ] Errors logged via AppLogger

---

### RT-GLOBAL-001: Global user channel subscription
**Category:** Real-Time — Pusher Global Events
**Priority:** High
**Effort:** Small
**Scope:** Flutter
**Affects:** `pusher_websocket_service.dart` `connectUser`, `chat_pusher_providers.dart`
**Depends on:** none
**Feature doc ref:** live overlays §4
**Current state:** `connectUser` subscribes `private-user.{userId}` + `private-chat.{userId}`. Lifecycle via `chatPusherLifecycleProvider` after auth. Unsubscribe on dispose/logout. Reconnect path calls `connectUser` again (~928).
**Gap:** Confirm shell always watches the lifecycle provider (not only chat tab).
**Enhancement:** Ensure home shell / session services watch `chatPusherLifecycleProvider` so Discover-only users still get user-channel events.
**Design tokens to use:** n/a
**Acceptance criteria:**
- [ ] Subscribe after login regardless of tab
- [ ] Unsubscribe on logout
- [ ] Reconnect re-subscribes

---

### RT-GLOBAL-002: New match Pusher event → celebration
**Category:** Real-Time — Pusher Global Events
**Priority:** Medium
**Effort:** Medium
**Scope:** Flutter
**Affects:** `pusher_websocket_service.dart` `_handleNewMatch`, `match_realtime_sync.dart` (cache invalidate only), `MatchCelebrationLauncher`
**Depends on:** HOME-MATCH-001, RT-GLOBAL-001
**Feature doc ref:** Section 2 mutual like
**Current state:** `new.match` → `MatchEvent` stream → match list cache invalidate. Celebration only from Discover swipe `onMatch` in `DiscoveryPage`.
**Gap:** Mutual like while on Chat/Settings does not show overlay.
**Enhancement:** Global listener (shell) on `matchStream` launches `MatchCelebrationLauncher` with payload profile when not already showing. Dedupe vs Discover local `onMatch`.
**Design tokens to use:** HOME-MATCH-001 tokens
**Acceptance criteria:**
- [ ] Celebration appears on any tab
- [ ] Payload supplies peer name/avatar
- [ ] No double overlay when swiping on Discover

---

### RT-GLOBAL-003: Discovery card deck updates in real-time
**Category:** Real-Time — Pusher Global Events
**Priority:** Low
**Effort:** Medium
**Scope:** Flutter
**Affects:** `discover_cache_provider.dart`, block/report flows
**Depends on:** RT-GLOBAL-001
**Feature doc ref:** Discover stack
**Current state:** Successful block/report calls `DiscoverCacheNotifier.removeUser` via `purgeProfile`.
**Gap:** —
**Enhancement:** On successful block/report, remove that `userId` from `discoverCacheProvider` immediately. Optional: ignore adding new users to the end of the deck (out of scope unless cheap).
**Design tokens to use:** n/a
**Acceptance criteria:**
- [x] Block/report removes the user from the stack without pull-to-refresh

---

### BE-NOTIF-001: Notification preferences endpoint
**Category:** Backend — Missing Endpoints & Events
**Priority:** Critical
**Effort:** Medium
**Scope:** Backend
**Affects:** new API controller (do not confuse with web `NotificationPreferencesController`), `routes/api.php`, `AuthController::updateNotificationPreferences`
**Depends on:** none
**Feature doc ref:** Section 4.5
**Current state:** POST `/api/user/notification-preferences` accepts `push_enabled`, `match_notifications`, `like_notifications`, `message_notifications`, `profile_view_notifications`, `story_notifications`, `feed_notifications`. Quiet hours live on POST `/onesignal/update-preferences` and **web** PUT `/notification-preferences`. No GET for the mobile app.
**Gap:** Missing GET+PUT `/api/notifications/preferences` with §4.5 keys.
**Enhancement:** Add authenticated GET and PUT `/api/notifications/preferences` in a **service class** (not fat controller). Response `{ success, message, data, meta }`. Fields: `push_enabled`, `email_enabled`, `sms_enabled`, `likes`, `matches`, `messages`, `superlikes`, `profile_views`, `premium_features`, `weekly_digest`, `marketing_emails`, `security_alerts`, `quiet_hours_enabled`, `quiet_hours_start`, `quiet_hours_end`, `muted_users`. Store JSON on the user (existing `notification_preferences` column) — **no new migration** if the column already holds JSON; map old keys on read for backward compatibility.
**Design tokens to use:** n/a
**Acceptance criteria:**
- [ ] GET returns all §4.5 fields
- [ ] PUT accepts all §4.5 fields
- [ ] Existing Auth POST still works (alias/map)
- [ ] Feature tests pass

---

### BE-NOTIF-002: Register device endpoint
**Category:** Backend — Missing Endpoints & Events
**Priority:** Medium
**Effort:** Small
**Scope:** Backend
**Affects:** `NotificationController::registerDevice` (api.php ~374)
**Depends on:** none
**Feature doc ref:** Section 4.4
**Current state:** **Present.** Validates `device_token` 10–512, `platform` android|ios. Writes `users.device_token` + `device_platform`.
**Gap:** Token rotation: old token not cleared if a new user logs in on the same device (verify).
**Enhancement:** On register, detach this token from any other user. Keep response shape `{success, message, data, meta}`.
**Design tokens to use:** n/a
**Acceptance criteria:**
- [ ] POST register-device stores token
- [ ] Re-register rotates cleanly
- [ ] Token unique per user

---

### BE-PREM-001: Plan change Pusher event
**Category:** Backend — Missing Endpoints & Events
**Priority:** Critical
**Effort:** Medium
**Scope:** Backend
**Affects:** new `app/Events/PlanUpdated.php` (or similar), subscription activate / admin grant / Play webhook services
**Depends on:** none
**Feature doc ref:** PREM-RT-002
**Current state:** No `PlanActivated` / `SubscriptionUpdated` / `PlanChanged` in `app/Events/` (19 events, all chat/call/match/like).
**Gap:** Clients cannot learn about grants until HTTP.
**Enhancement:** Broadcast on `PrivateChannel('user.{id}')` as `plan.updated` with `{ tier, is_active, plan_name, expires_at, features }`. Fire from activate, admin grant, webhook upgrade/downgrade/expire. Do not modify old migrations.
**Design tokens to use:** n/a
**Acceptance criteria:**
- [ ] `broadcastAs()` is `plan.updated`
- [ ] Channel `private-user.{userId}` (Laravel `user.{id}`)
- [ ] Payload includes tier + features
- [ ] Tests for event dispatch

---

### BE-PREM-002: Billing history endpoint
**Category:** Backend — Missing Endpoints & Events
**Priority:** Medium
**Effort:** Medium
**Scope:** Backend
**Affects:** `routes/api.php`, `SubscriptionController@history` (`GET /subscriptions/history`), `GET /user/payments/history`
**Depends on:** none
**Feature doc ref:** Section 3.5
**Current state:** No `/billing-history`. Flutter uses `/payments/history` (missing). Real: `/subscriptions/history`, `/user/payments/history`, `/google-play/purchases/history`.
**Gap:** Mobile billing screen 404s.
**Enhancement:** Either add `GET /api/billing-history` as an alias that paginates transactions (`id`, `date`, `description`, `amount`, `currency`, `status`, `provider`) **or** document and switch Flutter to `/user/payments/history` in PREM-PLAN-004. Prefer one canonical path + alias so old clients can migrate.
**Design tokens to use:** n/a
**Acceptance criteria:**
- [ ] Paginated list with documented fields
- [ ] statuses success | failed | refunded
- [ ] Auth required

---

### HOME-REWIND-001: Discover rewind control
**Category:** Home — Discovery Card & Bottom Sheet
**Priority:** Medium
**Effort:** Small
**Scope:** Flutter
**Affects:** `lib/pages/discovery_page.dart`, `LikesService.rewind`, `discoverCacheProvider`
**Depends on:** PREM-PLAN-002
**Feature doc ref:** Section 3.5 rewind flag; unused `ActionButtonsRow` rewind
**Current state:** `LikesService.rewind` exists. Live Discover action row is dislike / superlike / like only. Unused `ActionButtonsRow` had rewind + boost.
**Gap:** No rewind on the live stack.
**Enhancement:** Add rewind only if `subscriptionProvider` rewind flag is true; else lock → paywall. Restore last swiped card from cache. SVG `AppIcons.refresh` / `undo`. Do not resurrect `Colors.yellow`.
**Design tokens to use:** `AppColors.accentViolet`, `AppIcons.refresh`, `AppSpacing.spacingMD`
**Acceptance criteria:**
- [ ] Rewind restores last card when plan allows
- [ ] Locked tap opens PREM-PLAN-002
- [ ] SVG only

---

### HOME-FILTER-003: Persist discovery filters
**Category:** Home — Filters, Banners & Empty States
**Priority:** Medium
**Effort:** Small
**Scope:** Flutter
**Affects:** `lib/pages/discovery_page.dart` `_activeFilters`, filter apply path
**Depends on:** HOME-FILTER-001
**Feature doc ref:** Section 2 filters
**Current state:** **Done (HOME-FILTER-003).** `discoveryFiltersProvider` is a non-autoDispose Riverpod notifier, so applied filters survive leaving Discover. `DiscoveryPage` reads/writes that provider (no page-local `_activeFilters`). Clear sets the notifier to null.  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Applied filters survive leaving Discover
- [x] Clear wipes persisted filters
- [x] No `setState` as source of truth

---

### HOME-BADGE-001: Superliked-you badge on card
**Category:** Home — Discovery Card & Bottom Sheet
**Priority:** Low
**Effort:** Small
**Scope:** Flutter
**Affects:** `lib/widgets/cards/swipeable_card.dart`, `DiscoveryProfile.isSuperliked`
**Depends on:** none
**Feature doc ref:** Section 2 / matching
**Current state:** `SwipeableCard` shows a warning-yellow star chip when `is_superliked`.
**Gap:** —
**Enhancement:** Small star chip using `AppIcons.star` + `AppColors.warningYellow` when true.
**Design tokens to use:** `AppIcons.star`, `AppColors.warningYellow`, `AppSpacing.spacingXS`, `AppRadius.radiusRound`
**Acceptance criteria:**
- [x] Badge only when `is_superliked`
- [x] SVG + existing yellow token

---

### NOTIF-PUSHER-001: Handle backend `new.like` on user channel
**Category:** Real-Time — Pusher Global Events
**Priority:** Medium
**Effort:** Small
**Scope:** Flutter
**Affects:** `pusher_websocket_service.dart` `_onPusherEvent`
**Depends on:** RT-GLOBAL-001
**Feature doc ref:** Section 4 likes; backend `NewLike::broadcastAs()` = `new.like`
**Current state:** Event is broadcast; Flutter switch has no case (only `new.match`).
**Gap:** Likes-you list/badge stale until refresh.
**Enhancement:** Handle `new.like` → invalidate likes-received cache + unread notification count. Do not steal match celebration.
**Design tokens to use:** n/a
**Acceptance criteria:**
- [ ] `new.like` updates likes-you without restart
- [ ] Logged via AppLogger

---

### NOTIF-BADGE-001: Notification badge provider alignment
**Category:** Notifications — Inbox & Routing
**Priority:** Medium
**Effort:** Small
**Scope:** Flutter
**Affects:** `lib/features/notifications/presentation/widgets/notification_badge.dart`, `notification_provider.dart`
**Depends on:** none
**Feature doc ref:** Section 4.1 badge
**Current state:** Nav badge uses `unreadNotificationCountProvider`. `NotificationBadge` watches unused `notificationProvider`. That notifier’s use cases throw `UnimplementedError`; `_updateUnreadCount` references undefined `_notificationRepository`.
**Gap:** Dead provider is compile-risk if constructed; badge widget can show 0.
**Enhancement:** Point `NotificationBadge` at the live unread provider. Do not construct the broken notifier from UI.
**Design tokens to use:** `AppColors.notificationRed`, `textTheme.labelSmall`
**Acceptance criteria:**
- [ ] Badge count matches inbox unread
- [ ] Broken notifier not used by UI

---

### BE-PRIV-001: Privacy settings API
**Category:** Backend — Missing Endpoints & Events
**Priority:** Critical
**Effort:** Medium
**Scope:** Backend
**Affects:** `routes/api.php`, `PrivacyControlsService` (unused), Flutter `ApiEndpoints.privacySettings` = `/privacy/settings`
**Depends on:** none
**Feature doc ref:** Section 5.6
**Current state:** Flutter GET/PUT `/privacy/settings`. **No matching route.** `PrivacyControlsService` already knows `show_online_status`, `show_last_seen`, `show_distance`, `show_age`, `profile_visibility`, `read_receipts`, `location_sharing`. Settings summary is GET `/user/settings` / `/settings` without those writes.
**Gap:** Privacy screen cannot persist server-side even for the “wired” toggles.
**Enhancement:** Expose GET+PUT `/api/privacy/settings` via a service wrapping `PrivacyControlsService`, plus fields needed by SET-PRIV-001 (`show_in_discovery`, `show_in_top_picks`, `allow_swipe_back`, `ads_sharing`, `block_unknown_messages`, `discovery_visibility` if not already on matching prefs). `{success, message, data, meta}`. No new migration if columns exist; JSON blob otherwise.
**Design tokens to use:** n/a
**Acceptance criteria:**
- [ ] GET/PUT `/api/privacy/settings` works authenticated
- [ ] Fields cover §5.6
- [ ] Feature tests pass

---

## Implementation Order

### Tier 1 — Critical (user-trust breaking if missing)
1. SET-ALERTS-001 — Alerts screen API wiring (documented gap)
2. BE-NOTIF-001 — Notification preferences endpoint *(implement with #1)*
3. BE-PRIV-001 — Privacy settings API
4. PREM-RT-001 — SubscriptionMetaInterceptor verification
5. PREM-RT-004 — Startup subscription prime
6. NOTIF-ROUTE-001 — Complete notification routing
7. NOTIF-PUSH-002 — FCM foreground handler
8. BE-PREM-001 — Plan change Pusher event
9. PREM-RT-002 — Subscription Pusher event

### Tier 2 — High (core feature completeness)
10. SET-PRIV-001 — Privacy controls wired
11. HOME-CARD-001 — Profile card bottom sheet
12. HOME-MATCH-001 — Match celebration overlay
13. HOME-CARD-002 — Swipe overlays
14. HOME-EMPTY-001 — All empty states
15. HOME-SUPER-001 — Superlike message flow
16. HOME-SUPER-002 — Superlike packs sheet
17. PREM-PLAN-001 — Choose plan screen
18. PREM-PLAN-002 — Feature locked paywall
19. PREM-PLAN-003 — Subscription management
20. PREM-SUPER-001 — Superlike packs screen
21. SET-HUB-001 — Settings hub verification
22. NOTIF-INBOX-001 — Category chips
23. RT-GLOBAL-001 — Global user channel
24. PREM-PLAN-004 — Billing history
25. BE-PREM-002 — Billing history endpoint

### Tier 3 — Medium (polish and completeness)
26. HOME-FILTER-001 — Active filters bar
27. HOME-FILTER-002 — Discovery filters complete
28. HOME-FILTER-003 — Persist discovery filters
29. HOME-BANNER-001 — Passport banner
30. HOME-BANNER-002 — Swipe limit banner
31. HOME-CARD-003 — Action row animations
32. HOME-CARD-004 — Photo navigation
33. HOME-CARD-005 — Swipe up to expand
34. HOME-REWIND-001 — Rewind
35. SET-ALERTS-002 — Push master switch behavior
36. SET-ALERTS-003 — Quiet hours picker
37. SET-PRIV-002 — Data sharing controls
38. SET-SEC-001 — Active sessions
39. SET-SEC-002 — 2FA flow
40. SET-HUB-002 — Appearance theme toggle
41. NOTIF-INBOX-002 — Swipe delete with undo
42. NOTIF-INBOX-003 — Mark all / Clear all
43. NOTIF-INBOX-004 — Tab leave marks read
44. NOTIF-INBOX-005 — Plan-restricted like blur
45. NOTIF-PUSH-001 — FCM device registration
46. NOTIF-PUSH-003 — In-app notification banner
47. NOTIF-BADGE-001 — Badge provider
48. NOTIF-PUSHER-001 — `new.like` handler
49. PREM-RT-003 — Feature gate real-time refresh
50. PREM-PLAN-005 — Tier comparison
51. PREM-SUPER-002 — Superlike count in profile
52. RT-GLOBAL-002 — Match Pusher → celebration
53. BE-NOTIF-002 — Register device endpoint

### Tier 4 — Enhancement
54. HOME-BADGE-001 — Superliked-you badge
55. NOTIF-ROUTE-002 — Tile icons per type
56. RT-GLOBAL-003 — Real-time deck updates

---

## Progress Tracker

| ID | Title | Tier | Status | Notes |
|----|-------|------|--------|-------|
| SET-ALERTS-001 | Alerts API wiring | 1 | [x] | Riverpod provider + GET/PUT wired 2026-09-12 |
| BE-NOTIF-001 | Notification preferences endpoint | 1 | [x] | GET/PUT `/api/notifications/preferences` |
| BE-PRIV-001 | Privacy settings API | 1 | [x] | GET/PUT `/api/privacy/settings` + JSON column |
| PREM-RT-001 | SubscriptionMetaInterceptor | 1 | [x] | Live Dio singleton + tier-change log |
| PREM-RT-004 | Startup subscription prime | 1 | [x] | Sequential subscription before parallel packs/profile |
| NOTIF-ROUTE-001 | Complete notification routing | 1 | [x] | §4.3 types explicit; unknown → inbox |
| NOTIF-PUSH-002 | FCM foreground handler | 1 | [x] | muted_users + quiet hours + unread bump |
| BE-PREM-001 | Plan change Pusher event | 1 | [x] | `plan.updated` on `user.{id}` |
| PREM-RT-002 | Subscription Pusher listener | 1 | [x] | Listener + snackbar + cache refresh |
| SET-PRIV-001 | Privacy controls wired | 2 | [x] | GET/PUT `/privacy/settings` + Riverpod |
| HOME-CARD-001 | Profile card bottom sheet | 2 | [x] | Snap 0.60/0.50/0.92 + lifestyle pills |
| HOME-MATCH-001 | Match celebration overlay | 2 | [x] | It's a Match! + 8s → chat |
| HOME-CARD-002 | Swipe overlays | 2 | [x] | LIKE/NOPE /80 + SUPER exit stamp |
| HOME-EMPTY-001 | All empty states | 2 | [x] | 5 configs including daily cap + superlikes |
| HOME-SUPER-001 | Superlike optional message | 2 | [x] | Empty/Skip send; remaining 0 → packs |
| HOME-SUPER-002 | Superlike packs sheet | 2 | [x] | Best value on cheapest per-unit |
| PREM-PLAN-001 | Choose plan screen | 2 | [x] | Current plan check, no buy CTA |
| PREM-PLAN-002 | Feature locked paywall | 2 | [x] | `feature`+`minTier`; Upgrade Now |
| PREM-PLAN-003 | Subscription management | 2 | [x] | Cancel sheet + Cancels on date |
| PREM-SUPER-001 | Superlike packs screen | 2 | [x] | Best value + Play remaining update |
| SET-HUB-001 | Settings hub verification | 2 | [x] | Security = Active sessions |
| NOTIF-INBOX-001 | Category chips | 2 | [x] | Subtle selected = primary @ 15% |
| RT-GLOBAL-001 | Global user channel | 2 | [x] | `sessionServicesProvider` watches lifecycle |
| PREM-PLAN-004 | Billing history | 2 | [x] | Flutter → `/billing-history` + pagination |
| BE-PREM-002 | Billing history endpoint | 2 | [x] | `GET /api/billing-history` alias |
| HOME-FILTER-001 | Active filters bar | 3 | [x] | 250ms height + extra chips |
| HOME-FILTER-002 | Discovery filters complete | 3 | [x] | AppLogger + featureLocked feature query |
| HOME-FILTER-003 | Persist discovery filters | 3 | [x] | Riverpod session notifier |
| HOME-BANNER-001 | Passport banner | 3 | [x] | Slide + accentViolet icon |
| HOME-BANNER-002 | Swipe limit banner | 3 | [x] | Always-on limited + progress bar |
| HOME-CARD-003 | Action row animations | 3 | [x] | AppAnimations durations + token glows |
| HOME-CARD-004 | Photo navigation | 3 | [x] | Left/right halves, clamp 0 |
| HOME-CARD-005 | Swipe up to expand | 3 | [x] | vy < -300 + 32×4 handle |
| HOME-REWIND-001 | Discover rewind | 3 | [x] | Action + POST /likes/rewind |
| SET-ALERTS-002 | Push master switch | 3 | [x] | Fade 0.4 + IgnorePointer |
| SET-ALERTS-003 | Quiet hours picker | 3 | [x] | From/To TimePicker |
| SET-PRIV-002 | Data sharing | 3 | [x] | Helper copy under matching/analytics/ads |
| SET-SEC-001 | Active sessions | 3 | [x] | IPv4 first-3-octet mask |
| SET-SEC-002 | 2FA complete flow | 3 | [x] | Disable password+code; backups after verify |
| SET-HUB-002 | Appearance theme toggle | 3 | [x] | Light/Dark/System already wired |
| NOTIF-INBOX-002 | Swipe delete undo | 3 | [x] | Copy + 5s token duration |
| NOTIF-INBOX-003 | Mark all / Clear all | 3 | [x] | Confirm before clear all |
| NOTIF-INBOX-004 | Leave tab mark read | 3 | [x] | HomePage tab index already wired |
| NOTIF-INBOX-005 | Plan-restricted like blur | 3 | [x] | Sigma 6 + Someone liked you |
| NOTIF-PUSH-001 | FCM device registration | 3 | [x] | info/error logs on register |
| NOTIF-PUSH-003 | In-app notification banner | 3 | [x] | Likes/matches/plans via existing host |
| NOTIF-BADGE-001 | Badge provider | 3 | [x] | unreadNotificationCountProvider |
| NOTIF-PUSHER-001 | `new.like` handler | 3 | [x] | likeStream + likes-you refresh |
| PREM-RT-003 | Feature gate refresh | 3 | [x] | Video calls watch live subscription |
| PREM-PLAN-005 | Tier comparison | 3 | [x] | Live prices + current-plan border |
| PREM-SUPER-002 | Superlike in profile hero | 3 | [x] | Sync remaining from subscription meta |
| RT-GLOBAL-002 | Match Pusher → celebration | 3 | [x] | Home shell + 8s dedupe |
| BE-NOTIF-002 | Register device | 3 | [x] | Detach token from other users |
| HOME-BADGE-001 | Superliked-you badge | 4 | [x] | Star chip on SwipeableCard |
| NOTIF-ROUTE-002 | Tile icons per type | 4 | [x] | Missed-call/shield/info + unread fill |
| RT-GLOBAL-003 | Real-time deck updates | 4 | [x] | Block/report drops stack user |

---

## Pre-Enhancement Audit (reference)

### Design System Tokens Confirmed

**Colors (`AppColors`):**
`backgroundLight`, `surfaceLight`, `surfaceElevatedLight`, `textPrimaryLight`, `textSecondaryLight`, `textTertiaryLight`, `borderSubtleLight`, `borderMediumLight`, `dividerLight`, `backgroundDark`, `surfaceDark`, `surfaceElevatedDark`, `textPrimaryDark`, `textSecondaryDark`, `textTertiaryDark`, `borderSubtleDark`, `borderMediumDark`, `dividerDark`, `accentRose`, `accentRoseDark`, `accentViolet`, `accentPurple`, `accentGradientStart`, `accentGradientEnd`, `accentPink`, `onlineGreen`, `notificationRed`, `warningYellow`, `accentYellow`, `accentRed`, `primaryLight`, `secondaryLight`, `feedbackSuccess`, `feedbackError`, `feedbackWarning`, `feedbackInfo`, `cardBackgroundLight`, `cardBackgroundDark`, `tintRoseLight`, `tintVioletLight`, `tintRoseDark`, `tintVioletDark`, `lgbtGradient` (6 pride stops), `prideGradient`, `brandGradient`, `discoverDislikeGradient`, `discoverSuperlikeGradient`, `discoverLikeGradient`.

`MatchPercentageColors.colorFor` band colors are discovery-only (already in code). Do not add new bands.

Permitted exceptions (product rules, not new tokens): `Colors.white` / `Colors.black` on photo overlays; `Color(0xFF22C55E)` online dot only.

**TextStyles (`AppTypography`):**
`h1Large` 32/w700, `h1` 28/w700, `h2` 24/w600, `h3` 18/w600, `h4` 16/w600, `bodyLarge` 16/w400, `body` 14/w400, `bodySmall` 12/w400, `caption` 12/w400, `button` 16/w600, `labelMedium` 14/w500, `headlineSmall` (=h2), `titleLarge` 22/w600, `titleMedium` (=h4), `bodyMedium` (=body), `labelSmall` 11/w500, `displayScript` 36 italic.

Theme aliases: `displayLarge/Medium/Small`, `headlineMedium`, `bodyLarge/Medium/Small`, `labelLarge/Small`.

**Spacing (`AppSpacing`):**
`spacingXS` 4, `spacingSM` 8, `spacingMD` 12, `spacingLG` 16, `spacingXL` 24, `spacingXXL` 32, `spacingXXXL` 48, `contentPadding` 16, `contentPaddingVertical` 12.

**Border radii (`AppRadius` / `AppBorderRadius`):**
`radiusXS` 6, `radiusSM` 12, `radiusMD` 16, `radiusLG` 24, `radiusXL` 32, `radiusRound` 999.

**Shadows (documented in `UI-DESIGN-SYSTEM.md`; no Dart `AppShadows` class):**
`shadowSurfaceDark` (0,0,0,0.6 blur 18 offset 0,6), `shadowFloatingDark` (0,0,0,0.7 blur 30 offset 0,10 + white 0.02 blur 1 offset 0,-1), `shadowSurfaceLight` (0,0,0,0.1 blur 12 offset 0,4), `shadowFloatingLight` (0,0,0,0.15 blur 24 offset 0,8).

If a widget needs a shadow, copy these exact lists. Do not invent blur/offset. Promoting them into `lib/core/theme/app_shadows.dart` with **identical values** is token extraction, not a new token.

**Animation durations (`AppAnimations`):**
`tapDuration` 130ms, `transitionPage` 300ms, `transitionTab` 200ms, `transitionModal` 250ms, `listItemStagger` 50ms, `feedbackShort` 180ms, `imageFadeIn` 200ms, `imageFadeOut` 100ms, `cardExit` 200ms, `cardReveal` 380ms, `listItemAppear` 200ms, `chatListDeleteUndo` 5s, `shimmerDuration` 1400ms, `snackbarTransition` 200ms, `incomingBanner` 400ms, `inAppChatBannerHold` 4s, plus call/chat-specific durations already in that file. Curves: `curveDefault` easeOutCubic, `curveEmphasized` easeInOutCubic. Scale: `buttonPressScale` 0.97.

UI-DESIGN-SYSTEM.md also documents `microDuration` 150ms / `smallDuration` 260ms / `mediumDuration` 400ms / `largeDuration` 700ms / `matchDuration` 900ms — **not present as Dart constants**. Do not introduce them; use `AppAnimations.*`.

**SVG assets (call-related + groups via `AppIcons`):**
Icons live in `assets/icons/{outline,bold,bulk,linear,broken,twotone}/` (~1000 names × 6 styles). Use `AppIcons` / `getIconPath`.

- **navigation:** `discover`, `home`, `message`, `notification`, `user`, `setting`, `search-normal`, `arrow-*`
- **actions:** `add`, `edit`, `trash`, `close-circle`, `tick-circle`, `share`, `filter`, `undo`, `refresh-2`, `more`
- **social:** `heart`, `heart-tick`, `like`, `dislike`, `star`, `magic-star`, `profile`
- **premium:** `crown`, `crown-1`, `flash`, `gift`, `wallet`, `card`, `receipt`, `discount-circle`
- **notifications:** `notification`, `notification-bing`, `notification-slash`, `sms`
- **settings:** `setting`, `setting-2`, `toggle-on`, `toggle-off`
- **safety:** `shield`, `shield-tick`, `lock`, `unlock`, `eye`, `eye-slash`, `forbidden`, `verify`, `danger`, `warning-2`
- **calls:** `call`, `call-incoming`, `call-outgoing`, `call-slash`, `video`, `video-slash`, `microphone`, `microphone-slash`, `headphone`, `volume-high`
- **misc:** `location`, `gps`, `map`, `info-circle`, `calendar`, `clock`, `document`, `24-support`

### Home Page / Discover — Gap Analysis

| Feature from doc | Implemented | Has Animation | Gap |
|-----------------|-------------|---------------|-----|
| Greeting card | Yes — `DiscoverGreetingWidget` | Skeleton only | No swipe remaining in greeting |
| Active filters bar | Yes | No height anim | Incomplete chips; local filters |
| Passport banner | Yes | No 250ms slide | Icon `Colors.white` |
| Swipe limit banner | Partial | No | Hidden until 50%; no progress bar |
| Card stack (swipe L/R/U) | L/R yes; U = expand | Yes (tilt/exit) | Doc said U = superlike; no rewind |
| LIKE/NOPE/SUPER overlays | LIKE/NOPE | Fade with drag | SUPER missing |
| Action row | Yes | Scale 0.92 + spin | Magic sizes 54/58 |
| Profile card bottom sheet | Yes | Snap | Snap 0.62/0.96 vs 0.60/0.92; missing lifestyle fields |
| Match celebration | Yes — 6 phases | Yes | Auto-dismiss → keep swiping; likes-you Accept snackbar |
| Discovery filters sheet | Full screen `FilterScreen` | n/a | Not a sheet; empty catch L97 |
| All empty states | 3 of 5 | Pulse | Daily cap + superlike empty missing as states |
| Superlike optional message | Sheet yes | Modal | Message **required**; no Skip |

### Settings — Gap Analysis

| Screen | Present | API-wired | Gaps |
|--------|---------|-----------|------|
| Settings hub | Yes | Refresh cache only | Security → sessions; About dead tap (OK) |
| Privacy & safety | Yes | Partial | Last seen, visibility radios, top picks, swipe back, ads, receipts local; `/privacy/settings` missing on backend |
| Alerts | Yes | **NO** | Confirmed local `setState`; no quiet hours |
| Discovery preferences | Yes | Yes age/distance/visibility | No `discovery_mode` field |
| Sounds & haptics | Sounds yes | Yes `/user/sound-preferences` | Haptics stub unlinked |
| Account details | Yes | Profile cache + change email/password | Dual unused `changePassword` use case |
| Active sessions | Yes | Yes GET/revoke | IP mask verify; trust no-op |
| 2FA | Yes | Yes `/2fa/*` | Disable without code; backup codes before verify |
| Blocked users | Yes | Yes | — |
| Safety center | Yes hub | Child screens yes | `SafetySettingsScreen` orphaned |

### Notifications — Gap Analysis

- Category chips: **present**
- All 40+ types handled in routing: **NO**
  Types NOT handled: `view`, `visit`, `profile_visit`, `superlike_received`, `missed_call`, `call_declined`, `call_not_answered`, `plan_downgraded`, `subscription_canceled`, `subscription_expired`, `subscription_reminder`, `renewal_reminder`, `payment_success`, `payment_failed`, `premium_feature`, `superlike_pack_purchased`, `superlike_pack_finished`, `superlike_pack_auto_activated`, `safety_alert`, `system_announcement`, `announcement`, `admin`, `system`, `general`, `verification_reminder`, `verification_approved`, `verification_rejected`, `marketing`, `promotion`, `promo`, `story_like`, `story_reply`, `feed_like`, `feed_comment`, `comment`, `reply`, `comment_like` (**37**)
- In-app chat banner: **present** (chat only)
- FCM foreground handler: call → CallKit; chat suppress; chat banner; else local notification; no muted_users/quiet hours
- Mark all read / Clear all: **present**
- Swipe delete with undo: **present**

### Premium / Subscriptions — Gap Analysis

| Screen | Present | Google Play wired | Real-time update |
|--------|---------|------------------|-----------------|
| Choose plan | Yes | Yes | HTTP refresh + interceptor; no Pusher |
| Superlike packs | Yes | Yes | Provider/cache |
| Subscription management | Yes | Yes | Refresh after restore/cancel |
| Tier comparison | Yes | CTA only | Static |
| Feature locked paywall | Yes | CTA to plans | No live stream |
| Billing history | Yes | No | **Wrong path `/payments/history`** |

- SubscriptionMetaInterceptor: **present** (`dio_client.dart`)
- Subscription Pusher event: **missing**
- Startup cache for subscription: **present** (parallel)
- Post-purchase tier update: **present** via refresh + interceptor

### Notification Preferences API wiring

- Endpoint exists: **NO** for GET/PUT `/api/notifications/preferences`. Closest: POST `/api/user/notification-preferences` (different keys); web PUT `/notification-preferences`; OneSignal quiet hours.
- Alerts screen wired to API: **NO** (confirmed gap from doc §4.5)
- Fields: Flutter model A matches §4.5 (`likes`, `matches`, `quiet_hours_*`, `muted_users`, …). AuthController accepts `push_enabled`, `match_notifications`, `like_notifications`, `message_notifications`, `profile_view_notifications`, `story_notifications`, `feed_notifications`. **Mismatch.**

### TODO comments found (audited surfaces + related)

| File | Note |
|------|------|
| `lib/screens/notification_settings_screen.dart` | No TODO — silent local-only (worse) |
| `lib/screens/haptic_feedback_settings_screen.dart` L41 | Load settings TODO |
| `lib/screens/group_notification_settings_screen.dart` L47 | Load settings TODO |
| `lib/screens/skeleton_loader_settings_screen.dart` L42 | Load settings TODO |
| `lib/screens/add_payment_method_screen.dart` L54 | Stripe Elements TODO |
| Other profile/chat TODOs | Outside this plan’s feature set |

No `TODO` in `lib/features/discover/`, `matching/`, live `discovery_page.dart`.

### Empty catch blocks (audited)

| File | Line |
|------|------|
| `lib/screens/discovery/filter_screen.dart` | 97 |
| `lib/features/discover/data/services/discovery_service.dart` | 40, 160 |
| `lib/features/discover/utils/discovery_image_prefetch.dart` | 60 |
| `lib/screens/discovery/likes_received_screen.dart` | 64, 126 |
| `lib/features/notifications/providers/notifications_cache_provider.dart` | 138 |
| `lib/features/notifications/data/models/notification.dart` | 112, 171 |
| `lib/features/notifications/data/services/notification_service.dart` | 43, 49 |
| `lib/features/notifications/providers/notification_provider.dart` | 240–242 |
| `lib/core/services/startup_cache_service.dart` | 122 |
| `lib/shared/services/pusher_websocket_service.dart` | 249, 295, 864, 905 |
| `lib/features/settings/pages/settings_page.dart` | `_loadVersion` catch sets `'1.0.0'` (not empty) |
| `lib/shared/services/notification_navigation.dart` | 45 JSON decode |

### Hardcoded values found (non-token, high-signal)

- `SwipeableCard`: `kDiscoveryOnlineGreen = Color(0xFF22C55E)` — **permitted** online-dot exception
- `DiscoveryPage` action sizes 54 / 58
- `DiscoverySwipeActionButton` glow hexes `0xFFFFB4BC`, `0xFFFEF9C3`, `0xFFBBF7D0`, `0xFF78350F`
- `CardStackManager` stamp angles ±0.18, thresholds 72 / 16
- `ProfileDetailSheet` snap 0.62 / 0.96 (layout fractions)
- Unused `action_buttons_row.dart`: `Colors.yellow`, `Colors.purple`
- Unused `profile_card.dart`: `Icons.star` (SVG violation on dead widget)
- Superlike send button `Colors.white` / `Colors.black87`
- Greeting avatar shadow `Colors.black`

---

## Design System Lock Reference

The following are the ONLY values permitted in any widget:

- **Colors:** full `AppColors` list in Pre-Enhancement Audit above, plus `Theme.of(context).colorScheme.*` that the theme already maps to those colors. Exceptions: `Colors.white`/`Colors.black` on photo overlays; `Color(0xFF22C55E)` online dot only.
- **TextStyles:** `AppTypography.*` and `theme.textTheme.*` aliases listed above. No new `fontSize`.
- **Spacing:** `AppSpacing.spacingXS` 4, `SM` 8, `MD` 12, `LG` 16, `XL` 24, `XXL` 32, `XXXL` 48, `contentPadding` 16, `contentPaddingVertical` 12.
- **Border radii:** `AppRadius.radiusXS` 6, `SM` 12, `MD` 16, `LG` 24, `XL` 32, `radiusRound` 999.
- **Shadows:** `shadowSurfaceLight/Dark`, `shadowFloatingLight/Dark` from UI-DESIGN-SYSTEM.md only.
- **Animation durations:** `AppAnimations` constants only.

NO new values. NO new constants. Extend, never define.

Tier spellings: **basid | silder | golden**.

---

*End of document.*
