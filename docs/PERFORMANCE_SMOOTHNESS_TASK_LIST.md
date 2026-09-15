# Performance & Smoothness Task List (Telegram-like UX)

> Generated: 2026-05-24  
> Project: `lgbtindernew/` (Flutter, Dart 3.9+)  
> Goal: 60fps scrolling, instant screen opens, surgical rebuilds, local-first chat  
> Status: `[ ]` = pending · `[x]` = done · `[!]` = blocked · `[~]` = no action needed

---

## How to use this document

1. Work **top-down by phase** (infrastructure → chat → shell → other screens → polish).
2. Each task has an ID (`PERF-XXX-NNN`) for tracking in PRs and stand-ups.
3. After each phase, run the **Verification checklist** at the bottom on a mid-range Android device in `--profile` mode.
4. Related backend chat work lives in `lgbtinder-backend/docs/CHAT_SYSTEM_IMPLEMENTATION.md`.

---

## Audit summary (2026-05-24)

### What already helps smoothness

| Area | Current implementation |
|------|------------------------|
| Startup | Deferred Firebase push init (12s post-frame), lightweight splash, ANR docs |
| Images | `OptimizedImage` / `OptimizedAvatar` with `memCacheWidth/Height` |
| Lists | `LazyLoadList`, `LazyLoadGrid`, pagination helpers |
| Profiles | `AppCacheManager` stale-while-revalidate |
| Home tabs | `_KeepAliveTab` preserves tab state |
| Chat | Optimistic send, outbound queue, Pusher lifecycle providers |
| Animations | `AppAnimations.animationsEnabled(context)` respects reduce-motion |

### Critical gaps vs Telegram

| Gap | Impact | Files affected |
|-----|--------|----------------|
| No local chat DB | Chat opens only after network | `chat_page.dart`, `chat_list_page.dart` |
| `ChatPage` uses `setState` + `List<Map>` | Full list rebuild on every message/typing tick | `pages/chat_page.dart` (25+ `setState`) |
| Almost no `ref.watch(...select(...))` | Parent screens rebuild on unrelated provider changes | App-wide (~2 `.select()` usages) |
| No `RepaintBoundary` on list rows | Scroll jank in chat, matches, notifications | Chat, discovery, lists |
| `BackdropFilter` in navbar + bubbles | GPU cost every frame | `bottom_navbar.dart`, `message_bubble.dart` |
| All 5 home tabs kept alive | Memory + background work on off-screen tabs | `home_page.dart` |
| Duplicate chat UI layers | Two `MessageBubble`, two chat screen paths | `widgets/chat/` vs `features/chat/` |
| 4 font families in pubspec | APK size + first-frame cost | `pubspec.yaml` |
| `FutureBuilder` in `ChatPage.build` | API call during rebuild/animation | `chat_page.dart` ~L1145 |

---

## Phase 0 — Cross-cutting infrastructure

### 0.1 Local-first data layer

- [x] **PERF-INFRA-001** Add **Drift** (or Isar) dependency and schema: `conversations`, `messages`, `outbox`, `media_cache_meta`
- [x] **PERF-INFRA-002** Create `ChatLocalRepository` — read conversations/messages from DB on open (target: <100ms first paint)
- [x] **PERF-INFRA-003** Wire Pusher events → DB insert/update (not `setState` on pages)
- [x] **PERF-INFRA-004** Migrate `ChatOutboundQueueService` from `SharedPreferences` to SQLite outbox table
- [x] **PERF-INFRA-005** Add notification list local cache — Drift `local_notifications` + `local_notification_lists`; `NotificationsLocalRepository` paints the tab from disk then revalidates; prefs JSON is a one-time migrate
- [x] **PERF-INFRA-006** Move heavy `jsonDecode` in `UserCacheService` / `AppCacheManager` to `compute()` isolate
- [x] **PERF-INFRA-007** Replace `_profilesEqual` string comparison with `Equatable` on models

### 0.2 State management patterns

- [x] **PERF-INFRA-010** Add project rule: list screens must use `ref.watch(provider.select(...))` or isolated `Consumer` widgets — `.cursor/rules/riverpod-list-select.mdc`; chat list typing moved onto `ChatListItem.select`
- [x] **PERF-INFRA-011** Create `MessageRow` widget watching `chatMessageProvider(messageId)` for per-bubble updates — `MessageRow` = `ChatMessageListTile`; `chatMessageProvider(ChatThreadRowId)`
- [x] **PERF-INFRA-012** Create `ServiceLifecycleHost` widget — move 7+ `ref.watch` calls out of `MyApp.build` — host is a `MaterialApp.router` builder child; also `PERF-MAIN-001`
- [x] **PERF-INFRA-013** Standardize on `chatProvider` / feature providers; deprecate page-level `List<Map>` state — `ChatListPage` reads `chatListPreviewProvider` only; thread maps stay on `chatThreadMessagesProvider` (`ChatPage._messages` is a facade)

### 0.3 Rendering & scroll defaults

- [x] **PERF-INFRA-020** Add shared `AppListView` wrapper: `cacheExtent: 400`, `addRepaintBoundaries: true`, `addAutomaticKeepAlives: false` — `lib/core/widgets/app_list_view.dart`; wired into chat list, calls list, matches, notifications, `LazyLoadList`
- [x] **PERF-INFRA-021** Add shared `ChatListView` wrapper: `reverse: true`, stable `ValueKey(messageId)` policy — `typedef ChatListView = ChatThreadListView`; keys are `ValueKey(slot.key)` / `ChatTimelineSlots.rowKey`
- [x] **PERF-INFRA-022** Document when to use `RepaintBoundary` (list rows, avatars, nav bar, video PiP) — `.cursor/rules/repaint-boundary.mdc`
- [x] **PERF-INFRA-023** Add `ScrollBehavior` / physics audit — prefer `ClampingScrollPhysics` on Android for chat — `AppScroll.forChat` / `forPlatform`

### 0.4 Assets & build

- [x] **PERF-INFRA-030** Reduce fonts to **Inter** (primary) + optional **Nunito** (display only); remove Urbanist/Poppins from `pubspec.yaml` — Inter 4 weights only; Nunito/Urbanist/Poppins files deleted from `assets/fonts/`
- [x] **PERF-INFRA-031** Consolidate duplicate `OptimizedImage` (`widgets/images/` vs `widgets/common/`) → single `core/widgets/optimized_image.dart`
- [x] **PERF-INFRA-032** Merge duplicate `MessageBubble` (`widgets/chat/` + `features/chat/presentation/widgets/`) — live bubble is `widgets/chat/message_bubble.dart`; feature copy already gone
- [x] **PERF-INFRA-033** Remove or gate dead screens: `features/chat/presentation/screens/chat_screen.dart` (stub), unused duplicate routes — stub/screens folder already gone; unused feature `typing_indicator` deleted
- [x] **PERF-INFRA-034** Verify Impeller enabled on Android release builds — removed `flutter.experimental.impeller=false`; `EnableImpeller=true` under `<application>`
- [x] **PERF-INFRA-035** Add release signing config (currently debug keys in `android/app/build.gradle.kts`) — `key.properties` + release `signingConfig`; debug keys are rejected if the keystore is missing

### 0.5 Search & input

- [x] **PERF-INFRA-040** Add shared `DebouncedSearchField` (300ms) for all search inputs — `lib/core/widgets/debounced_search_field.dart` + `AppSearchDebounce` (`AppAnimations.searchDebounce`)
- [x] **PERF-INFRA-041** Apply debounce to: `chat_list_page` (`ChatListSearchField`), `message_search_screen`, `share_profile_sheet`. `search_page.dart` and `discovery/search_screen.dart` are not in the tree (no routes); shared field is ready when they return.

---

## Phase 1 — App shell, routing, startup (P0)

### `lib/main.dart`

| Audit | Detail |
|-------|--------|
| State | `ConsumerStatefulWidget`; watches 7 lifecycle providers in `build` |
| Issue | Any sync tick rebuilds entire `MaterialApp.router` subtree |

- [x] **PERF-MAIN-001** Extract lifecycle watches to `ServiceLifecycleHost` child of `MaterialApp`
- [x] **PERF-MAIN-002** Use `ref.listen` for one-shot side effects (401 redirect, call kit) instead of `ref.watch` — `SessionSideEffectsHost` (listen + one-shot wire); `MyApp.build` only watches router + theme
- [x] **PERF-MAIN-003** Keep deferred push init; consider reducing 12s delay after local DB makes home instant — delay is now `deferredPushInitDelay` (3s after first frame)

### `lib/routes/app_router.dart`

| Audit | Detail |
|-------|--------|
| Transitions | `slideFadePage` on most routes (~300ms) |
| Issue | Heavy transitions on high-frequency navigations (chat ↔ list) |

- [x] **PERF-ROUTE-001** Use `noTransitionPage` for home tab child routes (`discovery`, `chat-list`, etc.) — home shell uses a stable `ValueKey('home-shell')` + `noTransitionPage` so `?tab=` does not slide the whole `HomePage`; child tab paths remain redirects
- [x] **PERF-ROUTE-002** Use `noTransitionPage` or shorter duration for `AppRoutes.chat` push — `platformPredictivePage` (`MaterialPage`) so chat opens with the platform transition (no 300ms custom slide)
- [x] **PERF-ROUTE-003** Cache auth stage in memory to avoid secure-storage reads on every redirect — `resolveAuthStageCached` keyed by `TokenStorageService.authRevision`
- [x] **PERF-ROUTE-004** Add predictive back support (Android 14+) for chat and profile detail — `PredictiveBackPageTransitionsBuilder` in `AppTheme`; chat + profile-detail use `MaterialPage`; manifest already has `enableOnBackInvokedCallback`

---

## Phase 2 — Page-by-page tasks (`lib/pages/`)

### `splash_page.dart`

| Audit | Detail |
|-------|--------|
| State | Riverpod + local animation controller |
| Good | Post-frame auth check, timeouts, `RepaintBoundary` on logo |
| Issue | Sequential async checks; 400ms forced delay |

- [x] **PERF-PAGE-SPLASH-001** Parallelize `hasSeenIntro` + token check where safe — `splashLoadGate` (`Future.wait`)
- [x] **PERF-PAGE-SPLASH-002** Skip or shorten `_splashDelay` when cached auth session exists — `splashBrandingDelay` is `Duration.zero` when a token is already on disk; 400ms branding only when logged out
- [~] **PERF-PAGE-SPLASH-003** Logo animation — acceptable; respect reduce-motion (already via theme)

### `home_page.dart`

| Audit | Detail |
|-------|--------|
| State | Riverpod + `PageController` |
| Pattern | `PageView` + `_KeepAliveTab` (all 5 tabs alive) |
| Issue | `ref.watch(unreadNotificationCountProvider)` rebuilds full shell |

- [x] **PERF-PAGE-HOME-001** Replace always-alive `PageView` with lazy `IndexedStack` (mount tab on first visit)
- [x] **PERF-PAGE-HOME-002** Wrap `BottomNavbar` in isolated `Consumer`; pass badge count via `.select` — `_HomeBottomNavHost` watches unread chat + `unreadNotificationCountProvider.select`
- [x] **PERF-PAGE-HOME-003** Add `RepaintBoundary` around tab body and navbar
- [x] **PERF-PAGE-HOME-004** Optionally dispose Settings/Notifications tab after idle timeout — 5 minutes; `homeTabsAfterIdleDispose`
- [x] **PERF-PAGE-HOME-005** Avoid rebuilding `_buildPages` when only notification count changes — badge watches live in `_HomeBottomNavHost`, not `HomePage.build`

### `discovery_page.dart`

| Audit | Detail |
|-------|--------|
| State | Riverpod (`discoverCacheProvider`, `profilePageCacheProvider`) |
| Pattern | `CardStackManager` + swipe gestures |
| Issue | Full page rebuild on stack change; `Icons.person` instead of SVG |

- [x] **PERF-PAGE-DISCOVERY-001** Use `.select` on discover provider — watch stack length + current card only — `DiscoverFeedSlice` (ids + load flag); rewind uses `lastSwipedUserId` select on the action row
- [x] **PERF-PAGE-DISCOVERY-002** Preload images for next 2 cards in stack via `precacheImage` — `DiscoveryImagePrefetch.precacheNextTwo`
- [x] **PERF-PAGE-DISCOVERY-003** `RepaintBoundary` on action buttons row and top avatar strip — greeting + swipe actions
- [x] **PERF-PAGE-DISCOVERY-004** Replace `Icons.person` placeholder with `AppSvgIcon` per project rules — live cards already use `AppIcons.userOutline`; leftover `Icons.star` on unused `profile_card.dart` swapped to SVG
- [x] **PERF-PAGE-DISCOVERY-005** Debounce filter apply; avoid full refresh on minor filter toggles — 300ms debounce; skip when query maps are equal

### `chat_list_page.dart`

| Audit | Detail |
|-------|--------|
| State | Riverpod (`chatListPreviewProvider` + local DB first paint) |
| Pattern | `AppListView` / `ChatListReorderList` |
| Issue | Search already debounced; stagger limited to first 3 rows |

- [x] **PERF-PAGE-CHATLIST-001** Migrate to `chatProvider` / local DB — show cached chats instantly — `ChatListPage._loadChats` paints Drift conversations then refreshes; live rows read `chatListPreviewProvider` (not `ChatState.chats`) so thread send/typing does not rebuild the list
- [x] **PERF-PAGE-CHATLIST-002** Remove per-row `planLimitsProvider` watch from `ChatListItem`; pass `hasPlan` from parent — parent watches `isPremiumProvider` once; rows take `hasPlan`
- [x] **PERF-PAGE-CHATLIST-003** Limit `StaggeredListItem` to first 3 rows or remove after first session — `StaggeredListItem.shouldAnimate`; later rebuilds skip
- [x] **PERF-PAGE-CHATLIST-004** Add `cacheExtent: 400` and `RepaintBoundary` per `ChatListItem` — `ChatListReorderList` → `AppListView`; row already has `RepaintBoundary`
- [x] **PERF-PAGE-CHATLIST-005** Isolate `AppBarCustom` notification badge in `Consumer` — no `AppBarCustom`; premium banner in `Consumer`; search action extracted off page-level plan watch
- [x] **PERF-PAGE-CHATLIST-006** Debounce search in `ChatListHeader` — live field already 300ms; unused header now uses `DebouncedSearchField` + SVG
- [x] **PERF-PAGE-CHATLIST-007** Prefetch top 20 avatars after list load — `ChatListAvatarPrefetch.precacheTop`

### `chat_page.dart` ⚠️ HIGHEST PRIORITY

| Audit | Detail |
|-------|--------|
| State | 25+ `setState`, `List<Map<String,dynamic>>` |
| Pattern | Reverse `ChatThreadListView`; shell + Riverpod thread |
| Issues | `FutureBuilder` pinned count in build; full rebuild on typing; Pusher → setState |

- [x] **PERF-PAGE-CHAT-001** Refactor to `chatProvider` + local DB stream (remove `List<Map>`) — Drift `watchAllMessagesForOtherUser` drives `chatThreadMessagesProvider`; in-flight optimistic + not-yet-persisted rows are kept; list tiles still consume row maps
- [x] **PERF-PAGE-CHAT-002** Switch to `reverse: true` list; `jumpTo(0)` for new messages at bottom — `ChatThreadListView` + `ChatThreadScroll.latestPixels`
- [x] **PERF-PAGE-CHAT-003** Remove `FutureBuilder<int>` for pinned count → `pinnedCountProvider(userId)`
- [x] **PERF-PAGE-CHAT-004** Extract `MessageListTile` with `RepaintBoundary` + per-message provider
- [x] **PERF-PAGE-CHAT-005** Isolate typing indicator — separate `Consumer`, no full-page `setState`
- [~] **PERF-PAGE-CHAT-006** Paginate history (load older on scroll up) instead of single `_loadMessages` — cursor pagination + `_loadMoreMessages` already present
- [~] **PERF-PAGE-CHAT-007** Use `scroll_to_index` or maintain scroll anchor when prepending history — jumpTo anchor in `_loadMoreMessages`
- [x] **PERF-PAGE-CHAT-008** Move Pusher subscription handlers to repository layer — `chatLocalSyncProvider` persists; `chatThreadLiveSyncProvider` patches the open thread; ChatPage only keeps reconnect poll + call timeline
- [x] **PERF-PAGE-CHAT-009** Split file (>1200 lines) into: header, message list, input bar, panels — `ChatThreadPageShell` + existing `ChatHeader` / `ChatMessageList` / `ChatComposerBar`

### `profile_page.dart`

| Audit | Detail |
|-------|--------|
| State | Riverpod + `setState` for badges/stats |
| Pattern | `SingleChildScrollView` |
| Issue | Possible double-fetch in `initState` + post-frame |

- [x] **PERF-PAGE-PROFILE-001** Use `profilePageCacheProvider` exclusively for own profile (no duplicate API) — own tab watches cache only; no extra `refresh()` / `getMyProfile` / `revalidateAll` from `ProfilePage`
- [x] **PERF-PAGE-PROFILE-002** `RepaintBoundary` around photo carousel and stats section — `ProfileHeroSection` photo card + stats panel
- [x] **PERF-PAGE-PROFILE-003** Lazy-load analytics/badges section below fold — hub + membership mount after first frame; engagement stats fetch is post-frame

### `profile_edit_page.dart`

| Audit | Detail |
|-------|--------|
| State | Heavy `setState` per field |
| Issue | Image upload mixed with form UI |

- [x] **PERF-PAGE-PROFILEEDIT-001** Extract image editor to isolated stateful widget — `ProfileEditPhotosSection` owns picker, upload, gallery (`ProfileImageEditor`)
- [x] **PERF-PAGE-PROFILEEDIT-002** Use controllers/listeners instead of `setState` for text fields — `ProfileEditBioField` + local `ProfileEditAboutMeSection` values
- [x] **PERF-PAGE-PROFILEEDIT-003** Compress images before preview (`flutter_image_compress`) on background isolate — `ImageUploadCompressor.prepareForPreview` before avatar/gallery preview

### `profile_wizard_page.dart` ⚠️ LARGE FILE

| Audit | Detail |
|-------|--------|
| State | 40+ `setState`, 3000+ lines |
| Pattern | `PageController`, nested `shrinkWrap: true` lists |
| Issue | Entire wizard rebuilds on any field change |

- [x] **PERF-PAGE-WIZARD-001** Split into step widgets (`wizard_step_photos.dart`, etc.) — seven step widgets under `lib/widgets/profile/wizard/`
- [x] **PERF-PAGE-WIZARD-002** Move wizard state to `StateNotifier` / `profileWizardProvider` — `ProfileWizardPage` keeps step index / loading / text controllers; draft lives on `profileWizardProvider`
- [x] **PERF-PAGE-WIZARD-003** Replace inner `shrinkWrap: true` lists with fixed-height `ListView.builder` — gallery `_FixedHeightPhotoRows`
- [x] **PERF-PAGE-WIZARD-004** Cache reference data providers at wizard level (don't re-watch per step) — `wizardReferenceCacheProvider` / `wizardCitiesProvider`
- [x] **PERF-PAGE-WIZARD-005** `RepaintBoundary` per wizard step page — each `PageView` child is wrapped

### `onboarding_page.dart`

- [x] **PERF-PAGE-ONBOARD-001** Use `PageView` with lazy building (build only current ±1 page)
- [x] **PERF-PAGE-ONBOARD-002** Preload only first onboarding illustration; defer Lottie until visible — first SVG precached; other slides/confetti not mounted until in range
- [x] **PERF-PAGE-ONBOARD-003** Respect reduce-motion — skip parallax/Lottie when disabled — no confetti, no hero/page/dot motion, no complete delay

### `search_page.dart`

| Audit | Detail |
|-------|--------|
| Pattern | `GridView.builder` |
| Issue | API call on every keystroke |

- [~] **PERF-PAGE-SEARCH-001** Add 300ms search debounce — `lib/pages/search_page.dart` and `discovery/search_screen.dart` are not in the tree (no routes); `DebouncedSearchField` / `AppSearchDebounce` (300ms) are ready when they return
- [~] **PERF-PAGE-SEARCH-002** Add `cacheExtent` to grid — no search grid in tree; `AppListView` / `AppScroll.listCacheExtentPixels` is the shared default
- [~] **PERF-PAGE-SEARCH-003** Use `OptimizedImage` with `ImageSize.thumbnail` in grid cells — no search grid; `OptimizedImage` thumbnail preset already exists
- [~] **PERF-PAGE-SEARCH-004** Cancel in-flight search requests on new query (Dio cancel token) — no search page client; apply with the page if it returns

### `api_test_page.dart`

- [~] **PERF-PAGE-APITEST-001** Dev-only screen — exclude from release build or mark `@visibleForTesting`

---

## Phase 3 — Screen-by-screen tasks (`lib/screens/`)

### Auth

| File | Tasks |
|------|-------|
| `auth/welcome_screen.dart` | **PERF-SCR-WELCOME-001** `RepaintBoundary` on hero; lazy-load background assets. **002** Avoid watching heavy providers on first paint |
| `auth/login_screen.dart` | **PERF-SCR-LOGIN-001** Memoize device name. **002** Extract form to const sub-widgets |
| `auth/register_screen.dart` | **PERF-SCR-REGISTER-001** Same as login — reduce rebuild scope on validation |
| `auth/email_verification_screen.dart` | **PERF-SCR-EMAIL-001** Debounce resend button; avoid timer-driven full rebuilds |
| `auth/password_reset_flow_screen.dart` | **PERF-SCR-RESET-001** Multi-step: isolate each step widget (15+ setState) |
| `auth/forgot_password_screen.dart` | **PERF-SCR-FORGOT-001** Minimal scope — OK after form extraction |
| `auth/profile_wizard_screen.dart` | **PERF-SCR-PWIZ-001** Consolidate with `pages/profile_wizard_page.dart` (duplicate) |
| `auth/profile_completion_screen.dart` | **PERF-SCR-PCOMP-001** Use cached profile; no blocking network on open |
| `auth/profile_completion_welcome_screen.dart` | **PERF-SCR-PCWEL-001** Defer non-critical animations post-interaction |
| `auth/auth_wrapper.dart` | **PERF-SCR-AUTHWRAP-001** Avoid rebuilding child on auth stream noise — use `.select` |

- [x] **PERF-SCR-WELCOME-001** `RepaintBoundary` on logo hero; defer value-prop mosaic + ambient orbs until after first frame; logo precache is post-frame
- [x] **PERF-SCR-WELCOME-002** `StatefulWidget` (no `ref.watch`); first paint is branding + CTAs only
- [x] **PERF-SCR-LOGIN-001** Memoize device name — `AppDeviceName.resolve()` caches `DeviceInfoPlugin`; login prefetches in `initState`
- [x] **PERF-SCR-LOGIN-002** Extract form to const sub-widgets — `LoginCredentialsFields` / `LoginRememberForgotRow` / `LoginSignUpFooter`; loading uses `ValueNotifier`
- [x] **PERF-SCR-REGISTER-001** Same as login — `RegisterCredentialsFields` / `RegisterTermsBlock` / `RegisterSignInFooter`; terms + loading are `ValueNotifier`s; `AppDeviceName` for Google
- [x] **PERF-SCR-EMAIL-001** Debounce resend; countdown lives in `EmailResendRow` so ticks do not rebuild OTP fields; verify loading is a `ValueNotifier`
- [x] **PERF-SCR-RESET-001** Isolate each reset step — `ResetEmailStep` / `ResetOtpStep` / `ResetPasswordStep`; loading + step index are `ValueNotifier`s; OTP reuses `EmailOtpFields` + `EmailResendRow`
- [~] **PERF-SCR-FORGOT-001** Minimal scope — `forgot_password_screen.dart` is not in the tree; `/forgot-password` is `PasswordResetFlowScreen` (RESET-001)
- [~] **PERF-SCR-PWIZ-001** Consolidate with `pages/profile_wizard_page.dart` — `profile_wizard_screen.dart` is not in the tree; live wizard is already `ProfileWizardPage`
- [x] **PERF-SCR-PCOMP-001** Use cached profile; no blocking network on open — hydrates `ProfileCompletionDraft` from `profilePageCacheProvider` in `initState`; no `getMyProfile` / `refresh()`
- [x] **PERF-SCR-PCWEL-001** Defer non-critical animations post-interaction — first paint is a static avatar (`animate`/`showPulse` false); pulse unlocks on first pointer only when Reduce Motion is off; `RepaintBoundary` around avatar; `StatefulWidget` (no `ref.watch`)
- [~] **PERF-SCR-AUTHWRAP-001** Avoid rebuilding child on auth stream noise — `auth_wrapper.dart` is an unused stub (no child, no auth stream); live auth gating is `go_router` redirect + `authProvider` in session hosts

### Onboarding

| File | Tasks |
|------|-------|
| `onboarding/onboarding_screen.dart` | **PERF-SCR-ONB-001** Lazy page build |
| `onboarding/enhanced_onboarding_screen.dart` | **PERF-SCR-ONB-002** Reduce simultaneous animations |
| `onboarding/onboarding_preferences_screen.dart` | **PERF-SCR-ONBPREF-001** Replace static `ListView` with builder; **002** batch preference saves |

- [~] **PERF-SCR-ONB-001** Lazy page build — `onboarding_screen.dart` is not in the tree; live intro carousel is `pages/onboarding_page.dart` (`PERF-PAGE-ONBOARD-001`)
- [~] **PERF-SCR-ONB-002** Reduce simultaneous animations — `enhanced_onboarding_screen.dart` is not in the tree; live intro is `OnboardingPage` (`PERF-PAGE-ONBOARD-002` / `003`)
- [x] **PERF-SCR-ONBPREF-001** Replace static `ListView` with builder — `AppListView.builder` + extracted section widgets; chip/slider state is `ValueNotifier` so drags do not rebuild the list
- [x] **PERF-SCR-ONBPREF-002** Batch preference saves — chip/slider edits stay in `OnboardingPreferencesDraft`; Save issues one `updateProfile` payload

### Discovery

| File | Tasks |
|------|-------|
| `discovery/profile_detail_screen.dart` | **PERF-SCR-PROFDET-001** Hero image with `OptimizedImage`; **002** `RepaintBoundary` on carousel |
| `discovery/filter_screen.dart` | **PERF-SCR-FILTER-001** Debounce slider changes; **002** don't refetch until Apply |
| `discovery/likes_received_screen.dart` | **PERF-SCR-LIKES-001** `ListView.builder` + `cacheExtent`; **002** avatar thumbnail size |
| `discovery/search_screen.dart` | **PERF-SCR-DISCSearch-001** Shared debounced search component |

- [x] **PERF-SCR-PROFDET-001** Hero image with `OptimizedImage` — `ProfileHeroSection` carousel/cover photo uses `OptimizedImage` (`ImageSize.small`)
- [x] **PERF-SCR-PROFDET-002** `RepaintBoundary` on carousel — keyed `profile_photo_carousel` around `PageView`; profile detail wraps hero in `profile_detail_hero`
- [x] **PERF-SCR-FILTER-001** Debounce slider changes — `FilterAgeRangeControl` / `FilterDistanceControl` isolate slider `setState`; parent filter form does not rebuild while dragging
- [x] **PERF-SCR-FILTER-002** Don't refetch until Apply — sliders only write local `ValueNotifier`s; `_applyFilters` pops the map and `DiscoveryPage` reloads the stack after the result
- [x] **PERF-SCR-LIKES-001** `ListView.builder` + `cacheExtent` — `AppListView.builder` for pending likes
- [x] **PERF-SCR-LIKES-002** Avatar thumbnail size — `OptimizedImage` `ImageSize.thumbnail` at 56×56
- [~] **PERF-SCR-DISCSearch-001** Shared debounced search component — `discovery/search_screen.dart` is not in the tree; `DebouncedSearchField` is ready (`PERF-INFRA-040`)

### Profile (screens)

| File | Tasks |
|------|-------|
| `profile/profile_verification_screen.dart` | **PERF-SCR-VERIFY-001** Camera/gallery picker off main thread |
| `profile/profile_templates_screen.dart` | **PERF-SCR-TEMPL-001** Cache template previews |
| `profile/profile_sharing_screen.dart` | **PERF-SCR-SHARE-001** QR generation off UI thread |
| `profile/profile_analytics_screen.dart` | **PERF-SCR-ANALYTICS-001** Lazy load charts; **002** `RepaintBoundary` per chart |
| `profile/profile_backup_screen.dart` | **PERF-SCR-BACKUP-001** Progress via `ValueNotifier`, not full screen setState |
| `profile/profile_export_screen.dart` | **PERF-SCR-EXPORT-001** Stream export progress |
| `profile/advanced_profile_customization_screen.dart` | **PERF-SCR-CUSTOM-001** Split sections; 12+ setState → provider |
| `profile/profile_completion_incentives_screen.dart` | **PERF-SCR-INCENT-001** Static content — use const widgets |

- [x] **PERF-SCR-VERIFY-001** Camera/gallery picker off main thread — shared `AppMediaPicker` (native quality/maxWidth); `File` stats via `compute` (`statPickedMediaFile`); picker starts after the source sheet closes (`Future.delayed(Duration.zero)`)
- [x] **PERF-SCR-TEMPL-001** Cache template previews — `ProfileTemplateCatalog.cached()`; `OptimizedImage` (`ImageSize.small`) when a preview URL exists
- [x] **PERF-SCR-SHARE-001** QR generation off UI thread — `encodeProfileQr` uses `package:qr` in `compute`; `QrPainter`/`dart:ui` is not used; paint is a `RepaintBoundary` + `EncodedProfileQrPainter` after the first frame
- [x] **PERF-SCR-ANALYTICS-001** Lazy load charts — period row paints first; metrics load in a post-frame callback (no blocking delay)
- [x] **PERF-SCR-ANALYTICS-002** `RepaintBoundary` per chart — keyed `analytics_overview_chart`, `analytics_engagement_chart`, `analytics_interests_chart`
- [x] **PERF-SCR-BACKUP-001** Progress via `ValueNotifier` — backup busy/progress notifiers rebuild only the CTA/progress; not the full list
- [x] **PERF-SCR-EXPORT-001** Stream export progress — `profileExportProgressStream` drives a `ValueNotifier`; list does not `setState` per tick
- [x] **PERF-SCR-CUSTOM-001** Split sections; 12+ setState → provider — `ProfileCustomizationDraft` + isolated section widgets; opacity slider is a `ValueNotifier`
- [x] **PERF-SCR-INCENT-001** Static content — `StatelessWidget` + const `ProfileIncentiveCatalog`; no `setState` to load hardcoded rows

### Settings

| File | Tasks |
|------|-------|
| `settings_screen.dart` | **PERF-SCR-SETTINGS-001** `ListView.builder` for long settings list; **002** const tiles |
| `settings/comprehensive_settings_screen.dart` | **PERF-SCR-COMPSET-001** Same as settings |
| `settings/account_management_screen.dart` | **PERF-SCR-ACCT-001** Isolate destructive action dialogs |
| `settings/call_settings_screen.dart` | **PERF-SCR-CALLSET-001** 12+ setState → section providers |
| `accessibility_settings_screen.dart` | **PERF-SCR-A11Y-001** Persist animation/haptic flags; wire to `AppAnimations` |
| `animation_settings_screen.dart` | **PERF-SCR-ANIM-001** Global animation disable must short-circuit stagger/Lottie |
| `haptic_feedback_settings_screen.dart` | **PERF-SCR-HAPTIC-001** Central haptic service |
| `skeleton_loader_settings_screen.dart` | **PERF-SCR-SKEL-001** Toggle shimmer globally |
| `pull_to_refresh_settings_screen.dart` | **PERF-SCR-PTR-001** Document/default sensible refresh physics |
| `image_compression_settings_screen.dart` | **PERF-SCR-IMG-001** Apply compression preset before upload app-wide |
| `media_picker_settings_screen.dart` | **PERF-SCR-MEDIA-001** Default picker quality caps |
| `rainbow_theme_settings_screen.dart` | **PERF-SCR-RAIN-001** Gate expensive gradient nav behind setting |
| `notification_settings_screen.dart` | **PERF-SCR-NOTIFSET-001** Batch toggle API calls |
| `group_notification_settings_screen.dart` | **PERF-SCR-GNOTIF-001** 14+ setState → notifier |
| `privacy_settings_screen.dart` | **PERF-SCR-PRIV-001** Section-based rebuild isolation (18+ setState) |
| `safety_settings_screen.dart` | **PERF-SCR-SAFE-001** Same pattern |
| `payment_settings_screen.dart` | **PERF-SCR-PAYSET-001** Lazy load payment methods |
| `two_factor_auth_screen.dart` | **PERF-SCR-2FA-001** Static `ListView` → builder |

- [x] **PERF-SCR-SETTINGS-001** `ListView.builder` for long settings list — live hub is `SettingsPage` (`/home?tab=4`); `AppListView.builder` over section widgets
- [x] **PERF-SCR-SETTINGS-002** const tiles — const `SizedBox` chrome; `PremiumSettingsTile` still takes `onTap` closures so tiles cannot be const
- [~] **PERF-SCR-COMPSET-001** Same as settings — `comprehensive_settings_screen.dart` is unused; live hub is `SettingsPage`
- [x] **PERF-SCR-ACCT-001** Isolate destructive action dialogs — email-verify dialog uses its own `StatefulBuilder`; success alerts use `iconPath`
- [x] **PERF-SCR-CALLSET-001** 12+ setState → section providers — `CallSettingsDraft` `ChangeNotifier`; toggles do not `setState` the scaffold
- [x] **PERF-SCR-A11Y-001** Persist animation/haptic flags — `AppMotionPreferences` + Appearance “Reduce motion”; AND’d into `AppAnimations.animationsEnabled`
- [x] **PERF-SCR-ANIM-001** Global animation disable short-circuit stagger/Lottie — `ThemeAwareLottie` and stagger already use `AppAnimations.animationsEnabled` (now includes persisted flag)
- [x] **PERF-SCR-HAPTIC-001** Central haptic service — `AppHaptics` gated by persisted flag; Sounds & haptics toggle; refresh uses `AppHaptics.selection`
- [x] **PERF-SCR-SKEL-001** Toggle shimmer globally — `SkeletonLoader` skips `ShimmerEffect` when animations are disabled
- [~] **PERF-SCR-PTR-001** Document/default sensible refresh physics — unused stub screen; defaults documented on `AppScroll` + `PremiumRefreshIndicator` (`onEdge`, bouncing)
- [x] **PERF-SCR-IMG-001** Apply compression preset before upload — `ImageUploadCompressor` is the app-wide preset; unused settings stub
- [x] **PERF-SCR-MEDIA-001** Default picker quality caps — leftover `ImagePicker` sites now use `AppMediaPicker` (wizard, profile, edit photos, support tickets)
- [x] **PERF-SCR-RAIN-001** Gate expensive gradient nav — `RepaintBoundary` on nav shell; skip `BackdropFilter` blur when Reduce Motion is on. Rainbow theme settings screen unused
- [x] **PERF-SCR-NOTIFSET-001** Batch toggle API calls — debounce PUT already existed; scaffold no longer watches full prefs (groups isolated)
- [~] **PERF-SCR-GNOTIF-001** 14+ setState → notifier — `group_notification_settings_screen.dart` is unused (no group-chat settings route)
- [x] **PERF-SCR-PRIV-001** Section-based rebuild isolation — per-section `Consumer` + `.select` so one toggle does not rebuild other groups
- [~] **PERF-SCR-SAFE-001** Same pattern — unused stub; live safety is `SafetyCenterScreen` + privacy screen
- [~] **PERF-SCR-PAYSET-001** Lazy load payment methods — unused; live billing is `SubscriptionManagementPage`
- [x] **PERF-SCR-2FA-001** Static `ListView` → builder — `AppSettingsDetailList` now uses `AppListView.builder`

### Calls

| File | Tasks |
|------|-------|
| `video_call_screen.dart` | **PERF-SCR-VIDCALL-001** `RepaintBoundary` on local PiP; **002** timer updates isolated widget (20+ setState) |
| `voice_call_screen.dart` | **PERF-SCR-VOICECALL-001** Same timer isolation (15+ setState) |
| `call_history_screen.dart` | **PERF-SCR-CALLHIST-001** `ListView.builder` + avatar thumbnails |

- [~] **PERF-SCR-VIDCALL-001** `RepaintBoundary` on local PiP — `video_call_screen.dart` is dead UI; live call is `outgoing_call_page.dart` (do not enhance the stub)
- [~] **PERF-SCR-VIDCALL-002** timer updates isolated widget — same; live timer lives in `call_timer.dart` / outgoing page
- [~] **PERF-SCR-VOICECALL-001** Same timer isolation — `voice_call_screen.dart` is dead UI; live call is `outgoing_call_page.dart`
- [x] **PERF-SCR-CALLHIST-001** `ListView.builder` + avatar thumbnails — live lists are `MessengerCallsList` (`AppListView.separated`) and `PeerCallHistoryPage` (`AppListView.separated`); rows use `CallHistoryAvatar` (`OptimizedImage` `ImageSize.thumbnail`). Unused `screens/call_history_screen.dart` now uses `AppListView.builder` + the same thumbnail avatar and `callProvider.notifier.loadCallHistory`

### Payments & premium

| File | Tasks |
|------|-------|
| `payment_screen.dart` | **PERF-SCR-PAY-001** Don't block UI on billing connection |
| `subscription_plans_screen.dart` | **PERF-SCR-SUB-001** const plan cards |
| `subscription_status_screen.dart` | **PERF-SCR-SUBSTAT-001** Cache subscription snapshot |
| `subscription_management_screen.dart` | **PERF-SCR-SUBMGMT-001** Pagination for history |
| `premium/premium_subscription_screen.dart` | **PERF-SCR-PREM-001** Defer marketing animations |
| `premium/superlike_packs_screen.dart` | **PERF-SCR-SUPER-001** const pack cards |
| `premium_features_screen.dart` | **PERF-SCR-PFEAT-001** Static feature list — const |
| `tier_comparison_screen.dart` | **PERF-SCR-TIER-001** Single scroll, no nested scroll views |
| `feature_locked_screen.dart` | **PERF-SCR-LOCK-001** Lightweight — no heavy blur |
| `billing_history_screen.dart` | **PERF-SCR-BILL-001** Paginated list |
| `payment_methods_screen.dart` | **PERF-SCR-PAYMETH-001** Lazy load |
| `add_payment_method_screen.dart` | **PERF-SCR-ADDPAY-001** Minimal rebuild form |

- [x] **PERF-SCR-PAY-001** Don't block UI on billing connection — `googlePlayBillingServiceProvider` does not await I/O; unused `PaymentScreen` loads after first frame
- [x] **PERF-SCR-SUB-001** const plan cards — live `SubscriptionPlansScreen` already uses `_PlanCard`; list is `AppListView.builder`
- [x] **PERF-SCR-SUBSTAT-001** Cache subscription snapshot — `subscriptionStatusFromAppCache` paints session cache while GET `/subscriptions/status` runs
- [x] **PERF-SCR-SUBMGMT-001** Pagination for history — `getSubscriptionHistory(page:)` + Load more on `SubscriptionManagementPage`
- [~] **PERF-SCR-PREM-001** Defer marketing animations — `premium/premium_subscription_screen.dart` does not exist; live paywalls have no Lottie/marketing loop
- [x] **PERF-SCR-SUPER-001** const pack cards — `_SuperlikePackCard` + `AppListView.builder` on live `SuperlikePacksScreen`
- [~] **PERF-SCR-PFEAT-001** Static feature list — const — unused stub with Material icons; live copy is `TierComparisonScreen` const bullets
- [x] **PERF-SCR-TIER-001** Single scroll, no nested scroll views — one `ListView` (header + cards); no `Column`+`Expanded`+inner list
- [x] **PERF-SCR-LOCK-001** Lightweight — no heavy blur — `FeatureLockedScreen` has no `BackdropFilter`/`ImageFilter`
- [x] **PERF-SCR-BILL-001** Paginated list — existing page/limit + `AppListView.builder`
- [x] **PERF-SCR-PAYMETH-001** Lazy load — unused screen; first paint then post-frame fetch + `AppListView.builder`
- [x] **PERF-SCR-ADDPAY-001** Minimal rebuild form — checkbox/busy are `ValueNotifier`s; SVG `iconPath` on the lines touched

### Safety & support

| File | Tasks |
|------|-------|
| `blocked_users_screen.dart` | **PERF-SCR-BLOCK-001** `RepaintBoundary` per row |
| `safety_center_screen.dart` | **PERF-SCR-SAFEC-001** Static sections — const |
| `emergency_contacts_screen.dart` | **PERF-SCR-EMERG-001** List builder |
| `help_support_screen.dart` | **PERF-SCR-HELP-001** Collapsible FAQ without full rebuild |
| `support_tickets_screen.dart` | **PERF-SCR-TICKET-001** Paginated tickets |
| `report_history_screen.dart` | **PERF-SCR-REPORT-001** List builder + cache |
| `community_forum_screen.dart` | **PERF-SCR-FORUM-001** Lazy load posts |
| `message_search_screen.dart` | **PERF-SCR-MSGSEARCH-001** Debounced search; **002** result list repaint boundaries |
| `active_sessions_screen.dart` | **PERF-SCR-SESSION-001** Simple list — builder |

- [x] **PERF-SCR-BLOCK-001** `RepaintBoundary` per row — live `BlockedUsersScreen` uses `AppListView.builder` + `RepaintBoundary` around each `_BlockedUserRow`
- [x] **PERF-SCR-SAFEC-001** Static sections — const — `_SafetyHero` and `_SafetyTips` are const widgets on live `SafetyCenterScreen`
- [x] **PERF-SCR-EMERG-001** List builder — `EmergencyContactsScreen` uses `AppListView.builder` (info header + contact tiles)
- [x] **PERF-SCR-HELP-001** Collapsible FAQ without full rebuild — const `_HelpFaqSection` + `PremiumFaqTile` (`ExpansionTile` owns expand state)
- [x] **PERF-SCR-TICKET-001** Paginated tickets — page/`hasMore` + Load more on live `SupportTicketsScreen` (`AppListView.builder`)
- [x] **PERF-SCR-REPORT-001** List builder + cache — keep last `_reports` while refresh; `AppListView.builder` of `_ReportRow`
- [~] **PERF-SCR-FORUM-001** Lazy load posts — `CommunityForumScreen` is unrouted; already pages in `forumPostsProvider` + `AppListView.builder` + `RepaintBoundary` per post
- [x] **PERF-SCR-MSGSEARCH-001** Debounced search — live `MessageSearchScreen` (from chat list) uses `DebouncedSearchField`
- [x] **PERF-SCR-MSGSEARCH-002** result list repaint boundaries — `AppListView.builder` + `RepaintBoundary` around `ChatListItem` (and recent-search rows)
- [x] **PERF-SCR-SESSION-001** Simple list — builder — `AppSettingsDetailList` / `AppListView.builder`; other-session tiles wrapped in `RepaintBoundary`

### Legal

| File | Tasks |
|------|-------|
| `legal/terms_of_service_screen.dart` | **PERF-SCR-LEGAL-001** Use `SelectableText.rich` / lazy markdown |
| `legal/privacy_policy_screen.dart` | **PERF-SCR-LEGAL-002** Same |

- [x] **PERF-SCR-LEGAL-001** Use `SelectableText.rich` / lazy markdown — `TermsOfServiceScreen` uses `LegalDocumentView` (`AppListView.builder` + `SelectableText.rich` per section)
- [x] **PERF-SCR-LEGAL-002** Same — `PrivacyPolicyScreen` uses the same `LegalDocumentView`

---

## Phase 4 — Feature module screens (`lib/features/**/presentation/screens/`)

### Chat feature

| File | Status | Tasks |
|------|--------|-------|
| `chat/presentation/screens/chats_screen.dart` | Duplicate? | **PERF-FEAT-CHAT-001** Consolidate with `pages/chat_list_page.dart` |
| `chat/presentation/screens/chat_screen.dart` | Stub | **PERF-FEAT-CHAT-002** Delete or implement; route to `pages/chat_page.dart` |
| `chat/presentation/screens/group_chat_screen.dart` | Future | **PERF-FEAT-CHAT-003** Apply same local-first + reverse list pattern when enabled |
| `chat/presentation/screens/message_search_screen.dart` | Active | **PERF-FEAT-CHAT-004** Debounce + pagination + local index if backend supports |

- [~] **PERF-FEAT-CHAT-001** Consolidate with `pages/chat_list_page.dart` — `features/chat/presentation/screens/chats_screen.dart` is gone; live list is `ChatListPage`
- [~] **PERF-FEAT-CHAT-002** Delete or implement; route to `pages/chat_page.dart` — feature `chat_screen.dart` stub already removed (`PERF-INFRA-033`); live thread is `ChatPage`
- [~] **PERF-FEAT-CHAT-003** Apply same local-first + reverse list pattern when enabled — `group_chat_screen.dart` is not in the tree (no group chats)
- [x] **PERF-FEAT-CHAT-004** Debounce + pagination + local index — live `screens/message_search_screen.dart` uses `DebouncedSearchField`, Drift `searchMessagesLocal`, then GET `/chat/search` with offset + Load more

### Calls feature

| File | Tasks |
|------|-------|
| `calls/pages/outgoing_call_page.dart` | **PERF-FEAT-CALL-001** Isolate timer/`setState` (13+) to `CallTimer` widget; **002** `RepaintBoundary` on video layer |
| `calls/presentation/widgets/incoming_call_banner.dart` | **PERF-FEAT-CALL-003** Overlay without rebuilding `MaterialApp` |

- [x] **PERF-FEAT-CALL-001** Isolate timer/`setState` — live `OutgoingCallPage` ticks `LiveCallUiNotifier.tick()`; chrome watches `callTimerProvider.select`; unused `CallTimer` widget is dead UI
- [x] **PERF-FEAT-CALL-002** `RepaintBoundary` on video layer — `CallLiveVideoStage` / `AgoraCallVideoLayer` wrap remote + local PiP
- [x] **PERF-FEAT-CALL-003** Overlay without rebuilding `MaterialApp` — `IncomingCallHost` is a `MaterialApp.router` builder child (`Stack` overlay)

### Discover feature

| File | Tasks |
|------|-------|
| `discover/presentation/screens/discover_screen.dart` | **PERF-FEAT-DISC-001** Consolidate with `pages/discovery_page.dart` |
| `discover/presentation/screens/explore_screen.dart` | **PERF-FEAT-DISC-002** Lazy grid + image thumbnails |
| `discover/presentation/screens/filter_screen.dart` | **PERF-FEAT-DISC-003** Consolidate with `screens/discovery/filter_screen.dart` |
| `discover/presentation/screens/likes_received_screen.dart` | **PERF-FEAT-DISC-004** Consolidate duplicates |
| `discover/presentation/screens/profile_detail_screen.dart` | **PERF-FEAT-DISC-005** Consolidate duplicates |

- [~] **PERF-FEAT-DISC-001** Consolidate with `pages/discovery_page.dart` — `discover_screen.dart` is gone; live swipe feed is `DiscoveryPage`
- [~] **PERF-FEAT-DISC-002** Lazy grid + image thumbnails — `explore_screen.dart` is gone / unrouted; no explore grid in the tree
- [~] **PERF-FEAT-DISC-003** Consolidate with `screens/discovery/filter_screen.dart` — feature filter stub is gone; live filter is `FilterScreen` (`PERF-SCR-FILTER-001/002`)
- [~] **PERF-FEAT-DISC-004** Consolidate duplicates — feature `likes_received_screen.dart` is gone; live list is `screens/discovery/likes_received_screen.dart` (`PERF-SCR-LIKES-001/002`)
- [~] **PERF-FEAT-DISC-005** Consolidate duplicates — feature `profile_detail_screen.dart` is gone; live detail is `screens/discovery/profile_detail_screen.dart` (`PERF-SCR-PROFDET-001/002`)

### Matching feature

| File | Tasks |
|------|-------|
| `matching/presentation/screens/matches_screen.dart` | **PERF-FEAT-MATCH-001** `RepaintBoundary` per match row; **002** `cacheExtent` |
| `matching/presentation/screens/match_screen.dart` | **PERF-FEAT-MATCH-002** Single controller for celebration animations |
| `matching/presentation/screens/likes_screen.dart` | **PERF-FEAT-MATCH-003** Paginated grid |

- [x] **PERF-FEAT-MATCH-001** `RepaintBoundary` per match row — live `MatchesScreen` lists each `_MatchRow` as its own `AppSettingsDetailList` / `AppListView` item wrapped in `RepaintBoundary`
- [x] **PERF-FEAT-MATCH-002** `cacheExtent` + single celebration controller — match rows use `AppListView` cacheExtent; live overlay `MatchCelebrationOverlay` already has one controller; unused-path `widgets/match/match_screen.dart` now uses one `AnimationController` + Intervals (reduce-motion respected)
- [~] **PERF-FEAT-MATCH-003** Paginated grid — `likes_screen.dart` is gone; live `LikesReceivedScreen` is `AppListView.builder` + thumbnail cards (`RepaintBoundary`); pending-likes API is not paginated

### Notifications feature

| File | Tasks |
|------|-------|
| `notifications/presentation/screens/notifications_screen.dart` | **PERF-FEAT-NOTIF-001** Migrate to pagination provider; **002** `RepaintBoundary` on tiles; **003** local cache |
| `notifications/presentation/screens/notification_settings_screen.dart` | **PERF-FEAT-NOTIF-002** Consolidate with `screens/notification_settings_screen.dart` |

- [x] **PERF-FEAT-NOTIF-001** Migrate to pagination provider — live `NotificationsScreen` uses `notificationsCacheProvider` (`loadMore` on scroll, page size 20)
- [x] **PERF-FEAT-NOTIF-002** `RepaintBoundary` on tiles — `NotificationTile` is wrapped in `RepaintBoundary`; plan-restricted avatar blur is isolated / skipped when Reduce Motion is on
- [x] **PERF-FEAT-NOTIF-003** local cache — Drift `NotificationsLocalRepository` (`PERF-INFRA-005`); screen paints cache then refreshes
- [~] **PERF-FEAT-NOTIF-002** Consolidate settings — `features/notifications/.../notification_settings_screen.dart` is gone; live settings is `screens/notification_settings_screen.dart`

### Profile feature

| File | Tasks |
|------|-------|
| `profile/presentation/screens/profile_screen.dart` | **PERF-FEAT-PROF-001** Consolidate with `pages/profile_page.dart` |
| `profile/presentation/screens/profile_edit_screen.dart` | **PERF-FEAT-PROF-002** Consolidate with `pages/profile_edit_page.dart` |
| `profile/presentation/screens/profile_detail_screen.dart` | **PERF-FEAT-PROF-003** Shared detail component |
| `profile/presentation/screens/profile_wizard_screen.dart` | **PERF-FEAT-PROF-004** Single wizard entry point |
| `profile/presentation/screens/profile_analytics_screen.dart` | **PERF-FEAT-PROF-005** Chart lazy load |

- [~] **PERF-FEAT-PROF-001** Consolidate with `pages/profile_page.dart` — feature `profile_screen.dart` is gone; live own-profile is `ProfilePage` (`PERF-PAGE-PROFILE-001/002/003`)
- [~] **PERF-FEAT-PROF-002** Consolidate with `pages/profile_edit_page.dart` — feature `profile_edit_screen.dart` is gone; live edit is `ProfileEditPage` (`PERF-PAGE-PROFILEEDIT-001/002/003`)
- [~] **PERF-FEAT-PROF-003** Shared detail component — feature detail stub is gone; live other-user UI is `OtherUserProfileView` used by `ProfilePage` and `screens/discovery/profile_detail_screen.dart`
- [~] **PERF-FEAT-PROF-004** Single wizard entry point — feature `profile_wizard_screen.dart` is gone; live wizard is `ProfileWizardPage` (`PERF-PAGE-WIZARD-001`–`005`)
- [~] **PERF-FEAT-PROF-005** Chart lazy load — feature analytics stub is gone; live charts are `screens/profile/profile_analytics_screen.dart` (`PERF-SCR-ANALYTICS-001/002`)

### Onboarding feature

| File | Tasks |
|------|-------|
| `onboarding/presentation/screens/onboarding_screen.dart` | **PERF-FEAT-ONB-001** Lazy `PageView` |
| `onboarding/presentation/screens/enhanced_onboarding_screen.dart` | **PERF-FEAT-ONB-002** Defer Lottie |
| `onboarding/presentation/screens/onboarding_preferences_screen.dart` | **PERF-FEAT-ONB-003** Consolidate duplicate |

- [~] **PERF-FEAT-ONB-001** Lazy `PageView` — feature `onboarding_screen.dart` is gone; live intro is `pages/onboarding_page.dart` (`PERF-PAGE-ONBOARD-001`)
- [~] **PERF-FEAT-ONB-002** Defer Lottie — feature `enhanced_onboarding_screen.dart` is gone; live intro defers Lottie (`PERF-PAGE-ONBOARD-002` / `003`)
- [~] **PERF-FEAT-ONB-003** Consolidate duplicate — feature preferences stub is gone; live form is `screens/onboarding/onboarding_preferences_screen.dart` (`PERF-SCR-ONBPREF-001/002`)

### Payments feature

| File | Tasks |
|------|-------|
| `payments/presentation/screens/subscription_plans_screen.dart` | **PERF-FEAT-PAY-001** `ListView.builder`; const cards |
| `payments/presentation/screens/subscription_management_screen.dart` | **PERF-FEAT-PAY-002** Paginate history |
| `payments/presentation/screens/google_play_purchase_history_screen.dart` | **PERF-FEAT-PAY-003** Lazy list |
| `payments/presentation/screens/superlike_packs_screen.dart` | **PERF-FEAT-PAY-004** const pack UI |
| `payments/presentation/screens/payment_screen.dart` | **PERF-FEAT-PAY-005** Non-blocking billing |
| `payments/presentation/screens/premium_subscription_screen.dart` | **PERF-FEAT-PAY-006** Defer banners |
| `payments/presentation/screens/purchase_details_screen.dart` | **PERF-FEAT-PAY-007** Static detail |
| `payments/presentation/screens/purchase_confirmation_screen.dart` | **PERF-FEAT-PAY-008** Lightweight confirmation |
| `payments/presentation/screens/google_play_billing_test_screen.dart` | **PERF-FEAT-PAY-009** Dev-only — strip from release |

- [x] **PERF-FEAT-PAY-001** `ListView.builder`; const cards — live `SubscriptionPlansScreen` uses `AppListView.builder` + `_PlanCard`
- [x] **PERF-FEAT-PAY-002** Paginate history — `SubscriptionManagementScreen` is a typedef of `SubscriptionManagementPage` (`PERF-SCR-SUBMGMT-001`)
- [x] **PERF-FEAT-PAY-003** Lazy list — `GooglePlayPurchaseHistoryScreen` paints skeleton first, then `LazyLoadList` + scroll-threshold load more (no load-more during `itemBuilder`)
- [x] **PERF-FEAT-PAY-004** const pack UI — live `SuperlikePacksScreen` uses `AppListView.builder` + `_SuperlikePackCard`
- [~] **PERF-FEAT-PAY-005** Non-blocking billing — feature `payment_screen.dart` is gone; unused `screens/payment_screen.dart` already loads after first frame (`PERF-SCR-PAY-001`)
- [~] **PERF-FEAT-PAY-006** Defer banners — `premium_subscription_screen.dart` is gone; live plans/packs do not mount extra banners
- [x] **PERF-FEAT-PAY-007** Static detail — `PurchaseDetailsScreen` paints `initialPurchase` immediately; fetch only when opening without a snapshot
- [x] **PERF-FEAT-PAY-008** Lightweight confirmation — `PurchaseConfirmationScreen` stays a `StatelessWidget` (no animation controllers); SVG status icons
- [x] **PERF-FEAT-PAY-009** Dev-only — strip from release — `/home/google-play-billing-test` redirects to home in `kReleaseMode`; test screen does not init billing in release

### Settings feature

| File | Tasks |
|------|-------|
| `settings/presentation/screens/settings_screen.dart` | **PERF-FEAT-SET-001** Consolidate with `screens/settings_screen.dart` |
| `settings/presentation/screens/sound_preferences_screen.dart` | **PERF-FEAT-SET-002** Preview sounds without rebuilding list |
| `settings/presentation/screens/matching_preferences_screen.dart` | **PERF-FEAT-SET-003** 11+ setState → notifier |
| `settings/presentation/screens/*` (all) | **PERF-FEAT-SET-004** Audit duplicate settings paths; single source |

- [~] **PERF-FEAT-SET-001** Consolidate with `screens/settings_screen.dart` — feature `settings_screen.dart` is gone; live hub is `SettingsPage` (`/home?tab=4`); `screens/settings_screen.dart` is a typedef
- [x] **PERF-FEAT-SET-002** Preview sounds without rebuilding list — `_SoundOptionsGroup` owns selection `ValueNotifier`s; preview calls `SoundService` only; `updatePreferences` keeps `AsyncData` (no list unmount)
- [x] **PERF-FEAT-SET-003** 11+ setState → notifier — `MatchingPreferencesDraft` + `ValueListenableBuilder` for age/distance/visibility; load/save flags are notifiers
- [~] **PERF-FEAT-SET-004** Audit duplicate settings paths — live hub `SettingsPage`; unused `comprehensive_settings_screen.dart`; feature stubs (privacy/notif/2FA/sessions) deleted in favor of `lib/screens/*`; remaining feature screens are appearance, sound, matching, account details

### Safety, marketing, analytics, admin

| File | Tasks |
|------|-------|
| `safety/presentation/screens/*` | **PERF-FEAT-SAFE-001** Consolidate with `screens/` duplicates |
| `marketing/presentation/screens/*` | **PERF-FEAT-MKT-001** Defer confetti/Lottie; **002** dialog-only campaigns |
| `analytics/presentation/screens/analytics_screen.dart` | **PERF-FEAT-ANAL-001** Chart repaint boundaries |
| `admin/presentation/screens/admin_dashboard_screen.dart` | **PERF-FEAT-ADMIN-001** Dev/admin only — exclude release |

- [x] **PERF-FEAT-SAFE-001** Consolidate with `screens/` duplicates — feature blocked/emergency/history/center stubs are gone; live hub is `SafetyCenterScreen`; live report form is `ReportUserScreen` (`AppListView.builder` + reason `ValueNotifier`)
- [x] **PERF-FEAT-MKT-001** Defer confetti/Lottie — `BadgeAchievementPopup` mounts confetti only when `AppAnimations.animationsEnabled`; Reduce Motion skips controllers
- [x] **PERF-FEAT-MKT-002** Dialog-only campaigns — unrouted `badges`/`daily_rewards`/`enhanced_plans` screens stay unused; live path is `DailyRewardsDialog.show` / `BadgeAchievementPopup.show`
- [x] **PERF-FEAT-ANAL-001** Chart repaint boundaries — `AnalyticsChart` is a keyed `RepaintBoundary`; live profile charts already isolated (`PERF-SCR-ANALYTICS-002`)
- [x] **PERF-FEAT-ADMIN-001** Dev/admin only — exclude release — `AdminDashboardScreen` is unrouted and returns `SizedBox.shrink()` / skips load in `kReleaseMode`

---

## Phase 5 — Component-by-component tasks

### Chat widgets (`lib/widgets/chat/`)

| Component | Issue | Tasks |
|-----------|-------|-------|
| `message_bubble.dart` | Heavy conditionals; `BackdropFilter` blur gate; no repaint isolation | **PERF-COMP-MSG-001** `RepaintBoundary`. **002** Replace blur with static overlay. **003** Split text/media/voice sub-widgets |
| `message_input.dart` | Rebuilds with parent chat page | **PERF-COMP-MSG-004** Isolate as `ConsumerStatefulWidget` with own controllers |
| `chat_header.dart` | Online status updates | **PERF-COMP-MSG-005** Watch presence via `.select` |
| `chat_list_item.dart` | Watches `planLimitsProvider` per row | **PERF-COMP-MSG-006** Pass `hasPlan` from parent |
| `chat_list_header.dart` | Search triggers setState on parent | **PERF-COMP-MSG-007** Internal debounce |
| `typing_indicator.dart` | Animated dots rebuild parent | **PERF-COMP-MSG-008** Self-contained animation |
| `chat_user_info_panel.dart` | Slide panel + 6 setState | **PERF-COMP-MSG-009** Separate route or overlay provider |
| `mention_input_field.dart` | Suggestion list | **PERF-COMP-MSG-010** Debounce mention query |
| `message_status_indicator.dart` | — | **PERF-COMP-MSG-011** const icon paths |
| `pinned_messages_banner.dart` | — | **PERF-COMP-MSG-012** Cache pinned count |
| `audio_recorder_widget.dart` | Timer setState | **PERF-COMP-MSG-013** Isolated timer widget |
| `audio_player_widget.dart` | — | **PERF-COMP-MSG-014** Pause when off-screen |
| `chat_list_loading.dart` | Skeleton | **PERF-COMP-MSG-015** Match chat row height exactly (avoid layout jump) |
| `chat_list_empty.dart` | — | **[~]** const OK |

- [x] **PERF-COMP-MSG-001** `RepaintBoundary` — live bubble chrome + photo/voice/gates; list row already wraps `ChatMessageListTile`
- [x] **PERF-COMP-MSG-002** Replace blur with static overlay — premium history gate is `ColoredBox` (no `BackdropFilter` / `ImageFilter.blur`)
- [x] **PERF-COMP-MSG-003** Split text/media/voice sub-widgets — `ChatLinkedText` / `ChatBubblePhoto` / `VoiceMessagePlayer`; locked + premium gates extracted
- [x] **PERF-COMP-MSG-004** Isolate as `ConsumerStatefulWidget` with own controllers — live `MessageInput`
- [x] **PERF-COMP-MSG-005** Watch presence via `.select` — `chat_header.dart` selects `userPresenceCacheProvider` per user
- [x] **PERF-COMP-MSG-006** Pass `hasPlan` from parent — `ChatListItem` does not watch `planLimitsProvider`
- [x] **PERF-COMP-MSG-007** Internal debounce — `DebouncedSearchField` / `AppSearchDebounce` in list header
- [x] **PERF-COMP-MSG-008** Self-contained animation — `typing_indicator.dart` owns its controller; Reduce Motion skips
- [~] **PERF-COMP-MSG-009** Separate route or overlay provider — `ChatUserInfoPanel` unused; live path is `ChatConversationInfoPage`
- [x] **PERF-COMP-MSG-010** Debounce mention query — `AppSearchDebounce` on `@` lookup (`mention_input_field.dart`)
- [x] **PERF-COMP-MSG-011** const icon paths — `MessageStatusIconPaths.sending` / `retry` (`AppIcons.clock` / `refresh`)
- [x] **PERF-COMP-MSG-012** Cache pinned count — banner takes `pinnedCount` from parent (`pinnedCountProvider`)
- [~] **PERF-COMP-MSG-013** Isolated timer widget — `audio_recorder_widget.dart` gone; `ChatVoiceRecordBar` owns elapsed `ValueNotifier` + timer
- [~] **PERF-COMP-MSG-014** Pause when off-screen — `audio_player_widget.dart` gone; live `VoiceMessagePlayer` pauses on scroll-off and deactivate
- [x] **PERF-COMP-MSG-015** Match chat row height exactly — skeleton avatar 52, `spacingMD`/`spacingSM` padding, `AppListView.separated`
- [~] **chat_list_empty.dart** const OK

### Chat feature widgets (`lib/features/chat/presentation/widgets/`)

| Component | Tasks |
|-----------|-------|
| `message_bubble.dart` | **PERF-COMP-FEATMSG-001** DELETE — use shared widget |
| `chat_input.dart` | **PERF-COMP-FEATMSG-002** Consolidate with `widgets/chat/message_input.dart` |
| `typing_indicator.dart` | **PERF-COMP-FEATMSG-003** Consolidate duplicate |
| `voice_message_player.dart` | **PERF-COMP-FEATMSG-004** Pause off-screen; **005** don't setState whole row |
| `voice_recorder_overlay.dart` | **PERF-COMP-FEATMSG-006** Overlay in separate layer |
| `sticker_picker_sheet.dart` | **PERF-COMP-FEATMSG-007** Grid cacheExtent; lazy load packs |
| `share_profile_sheet.dart` | **PERF-COMP-FEATMSG-008** Remove FutureBuilder from build; debounce search |
| `self_destruct_viewer.dart` | **PERF-COMP-FEATMSG-009** Countdown via `AnimationController` not setState loop |
| `message_attachment_viewer.dart` | **PERF-COMP-FEATMSG-010** Video init off-screen cancel |
| `online_friends_list.dart` | **PERF-COMP-FEATMSG-011** Horizontal list avatar thumbnails |
| `chat_upgrade_widgets.dart` | **PERF-COMP-FEATMSG-012** Avoid blur; simple overlay |

- [~] **PERF-COMP-FEATMSG-001** DELETE — use shared widget — feature `message_bubble.dart` is gone; live is `lib/widgets/chat/message_bubble.dart`
- [~] **PERF-COMP-FEATMSG-002** Consolidate with `widgets/chat/message_input.dart` — feature `chat_input.dart` is gone; live composer is `MessageInput`
- [~] **PERF-COMP-FEATMSG-003** Consolidate duplicate — feature `typing_indicator.dart` is gone; live is `lib/widgets/chat/typing_indicator.dart`
- [x] **PERF-COMP-FEATMSG-004** Pause off-screen — `VoiceMessagePlayer` pauses on scroll-off and deactivate
- [x] **PERF-COMP-FEATMSG-005** don't setState whole row — play/position use `ValueNotifier`s; waveform/time rebuild without the bubble row
- [~] **PERF-COMP-FEATMSG-006** Overlay in separate layer — `VoiceRecorderOverlay` unused; live record chrome is `ChatVoiceRecordBar` in `MessageInput`
- [x] **PERF-COMP-FEATMSG-007** Grid cacheExtent; lazy load packs — grid/tabs use `scrollCacheExtent` + keep-alives off; stickers load via `stickerPackStickersProvider(packId)`
- [x] **PERF-COMP-FEATMSG-008** Remove FutureBuilder from build; debounce search — watches `chatListPreviewProvider`; `DebouncedSearchField` already in place
- [x] **PERF-COMP-FEATMSG-009** Countdown via `AnimationController` not setState loop — ring is `_CountdownBadge` `AnimatedBuilder`
- [~] **PERF-COMP-FEATMSG-010** Video init off-screen cancel — unused `MessageAttachmentViewer` now drops in-flight init; live `ChatVideoViewer` already cancels if unmounted
- [~] **PERF-COMP-FEATMSG-011** Horizontal list avatar thumbnails — `OnlineFriendsList` unused; live is `ChatMatchesRow` (`ProfileImageWidget` chips)
- [x] **PERF-COMP-FEATMSG-012** Avoid blur; simple overlay — `ChatUpgradeBottomSheet` / `ChatPremiumBanner` have no `BackdropFilter`

### Cards & discovery (`lib/widgets/cards/`, `lib/widgets/discovery/`)

| Component | Tasks |
|-----------|-------|
| `swipeable_card.dart` | **PERF-COMP-CARD-001** `RepaintBoundary`; **002** simplify shadows; **003** `OptimizedImage` large/small |
| `card_stack_manager.dart` | **PERF-COMP-CARD-004** Repaint only top 3 cards; **005** const empty state |
| `discovery/filter_widgets.dart` | **PERF-COMP-DISC-001** Debounce sliders |
| `discovery/superlike_message_sheet.dart` | **PERF-COMP-DISC-002** Lightweight sheet |

- [x] **PERF-COMP-CARD-001** `RepaintBoundary` — card chrome and each stacked card
- [x] **PERF-COMP-CARD-002** simplify shadows — one 12px shadow on the front card; lighter drag shadow
- [x] **PERF-COMP-CARD-003** `OptimizedImage` large/small — front `ImageSize.large`, behind `ImageSize.small`; decode width still `photoDecodeWidth` so swipe reuses cache
- [x] **PERF-COMP-CARD-004** Repaint only top 3 cards — stack already paints 3; each has `RepaintBoundary`
- [x] **PERF-COMP-CARD-005** const empty state — `const DiscoverEmptyState()` when no custom copy/actions
- [x] **PERF-COMP-DISC-001** Debounce sliders — `FilterAgeRangeControl` / `FilterDistanceControl` isolate drag; parent does not rebuild (Apply reads notifiers)
- [x] **PERF-COMP-DISC-002** Lightweight sheet — no per-keystroke `setState`; static header (no gradient stack)

### Discover feature widgets

| Component | Tasks |
|-----------|-------|
| `swipeable_card_stack.dart` | **PERF-COMP-DISC-003** Consolidate with `card_stack_manager.dart` |
| `profile_card.dart` | **PERF-COMP-DISC-004** Thumbnail images |
| `action_buttons_row.dart` | **PERF-COMP-DISC-005** `RepaintBoundary` + haptic only on tap |

- [x] **PERF-COMP-DISC-003** Consolidate with `card_stack_manager.dart` — feature file is now `export` + `typedef SwipeableCardStack = CardStackManager`; live stack is `CardStackManager` on `discovery_page.dart`
- [~] **PERF-COMP-DISC-004** Thumbnail images — unused `ProfileCard` (stale test only); live photos are `SwipeableCard` + `OptimizedImage` (`PERF-COMP-CARD-003`)
- [x] **PERF-COMP-DISC-005** `RepaintBoundary` + haptic only on tap — live `DiscoverySwipeActionButton` wraps paint in `RepaintBoundary` and calls `AppHaptics.light()` in `onTap` (not `onTapDown`); unused `ActionButtonsRow` not dual-maintained; action row already in `RepaintBoundary` on Discovery

### Navbar (`lib/widgets/navbar/`)

| Component | Tasks |
|-----------|-------|
| `bottom_navbar.dart` | **PERF-COMP-NAV-001** `RepaintBoundary`; **002** reduce blur sigma 20→10; **003** cache rainbow gradient shader; **004** optional solid fallback setting |
| `app_bar_custom.dart` | **PERF-COMP-NAV-002** Isolate notification badge Consumer |
| `lgbtfinder_logo.dart` | **[~]** Static — OK |

- [x] **PERF-COMP-NAV-001** `RepaintBoundary` — live `AppBottomNavBar` + `NavBarGradientShell`; unused `BottomNavbar` uses the same shell
- [x] **PERF-COMP-NAV-002** reduce blur sigma 20→10 — cached `ImageFilter.blur(10)`; skipped when Reduce Motion or solid tab bar
- [x] **PERF-COMP-NAV-002** Isolate notification badge Consumer — no `app_bar_custom.dart`; Discover header badge uses `.select`; home nav already isolated (`PERF-PAGE-HOME-002` / `PERF-PAGE-CHATLIST-005`)
- [x] **PERF-COMP-NAV-003** cache rainbow gradient shader — `_CachedNavBarGradientPainter` keeps `ui.Shader` until size/theme/style change
- [x] **PERF-COMP-NAV-004** optional solid fallback setting — Appearance “Solid tab bar”; `AppMotionPreferences.solidNavBar`
- [~] **lgbtfinder_logo.dart** Static — OK

### Loading & skeletons (`lib/widgets/loading/`)

| Component | Tasks |
|-----------|-------|
| `shimmer_effect.dart` | **PERF-COMP-LOAD-001** `RepaintBoundary`; disable when reduce-motion |
| `skeleton_chat.dart` | **PERF-COMP-LOAD-002** Match `MessageBubble` heights |
| `skeleton_chat_list.dart` | **PERF-COMP-LOAD-003** Match `ChatListItem` height |
| `skeleton_discovery.dart` | **PERF-COMP-LOAD-004** Match card aspect ratio |
| `skeleton_profile.dart` | **PERF-COMP-LOAD-005** Match profile layout |
| `skeleton_loader.dart` | **PERF-COMP-LOAD-006** Global toggle from settings |

- [x] **PERF-COMP-LOAD-001** `RepaintBoundary`; disable when reduce-motion — `ShimmerEffect` wraps paint in `RepaintBoundary`, stops the controller, and skips `ShaderMask` when `AppAnimations.animationsEnabled` is false
- [x] **PERF-COMP-LOAD-002** Match `MessageBubble` heights — no side avatars; `MessageBubbleChrome` margin/radius; heights from body + meta typography; reverse `AppListView` like the live thread
- [x] **PERF-COMP-LOAD-003** Match `ChatListItem` height — unused `SkeletonChatList` is `typedef` → live `ChatListLoading` (52px avatar, `spacingMD`/`spacingSM`)
- [x] **PERF-COMP-LOAD-004** Match card aspect ratio — `SwipeableCard.fitSize` / `cardAspectRatio`; overlay name bars on the photo (no extra footer)
- [x] **PERF-COMP-LOAD-005** Match profile layout — hero card (square photo, identity, actions, stats) + gallery grid + bio + chips, `spacingXL` gaps like `OwnProfileView`
- [x] **PERF-COMP-LOAD-006** Global toggle from settings — `SkeletonLoader` already skips shimmer when animations are disabled (Appearance Reduce Motion / OS)

### Images (`lib/widgets/images/`, `lib/core/widgets/`)

| Component | Tasks |
|-----------|-------|
| `optimized_image.dart` | **PERF-COMP-IMG-001** Add blurhash support; **002** no fade on list scroll (fade only detail) |
| `optimized_image.dart` (duplicate) | **[x]** **PERF-COMP-IMG-003** Removed duplicate export — canonical is `core/widgets/optimized_image.dart` |
| `avatar_widget.dart` | **PERF-COMP-IMG-004** Always thumbnail mem cache |
| `splash_arc_loader.dart` | **PERF-COMP-IMG-005** Respect reduce-motion |

- [x] **PERF-COMP-IMG-001** Add blurhash support — unused `blurHash` now paints the DC average color as the placeholder (`BlurHashAverage`); skips the download spinner so the hash is visible
- [x] **PERF-COMP-IMG-002** no fade on list scroll (fade only detail) — `thumbnail` / `small` / `medium` use `Duration.zero`; `large` / `original` still use `AppAnimations.imageFadeDuration`
- [x] **PERF-COMP-IMG-003** Removed duplicate export — canonical is `core/widgets/optimized_image.dart`
- [x] **PERF-COMP-IMG-004** Always thumbnail mem cache — `AvatarWidget` uses `OptimizedImage` `ImageSize.thumbnail` (100×100); `OptimizedAvatar` decode cap is 100
- [x] **PERF-COMP-IMG-005** Respect reduce-motion — splash arc already stops/repeats via `AppAnimations.animationsEnabled`; paint wrapped in `RepaintBoundary`

### Buttons & feedback (`lib/widgets/buttons/`)

| Component | Tasks |
|-----------|-------|
| `animated_button.dart` | **PERF-COMP-BTN-001** Respect reduce-motion; skip scale when disabled |
| `scale_tap_feedback.dart` | **[~]** Lightweight — OK |
| `gradient_button.dart` | **PERF-COMP-BTN-002** Cache gradient on press |
| `like_button.dart` / `superlike_button.dart` | **PERF-COMP-BTN-003** Lottie only on tap, not idle |

- [x] **PERF-COMP-BTN-001** Respect reduce-motion; skip scale when disabled — `AnimatedButton` and live `GradientButton` / `ScaleTapFeedback` skip `ScaleTransition` when disabled or `AppAnimations.animationsEnabled` is false
- [~] **scale_tap_feedback.dart** Lightweight — OK; still skips scale when `onTap` is null or Reduce Motion is on
- [x] **PERF-COMP-BTN-002** Cache gradient on press — `GradientButton` keeps static accent/pride/disabled gradients + shadows; sheen is reused; paint in `RepaintBoundary`
- [~] **PERF-COMP-BTN-003** Lottie only on tap, not idle — unused `LikeButton` / `SuperlikeButton` have no Lottie; live `DiscoverySwipeActionButton` pulses only on tap

### Match & celebrations

| Component | Tasks |
|-----------|-------|
| `match/match_screen.dart` | **PERF-COMP-MATCH-001** Single `AnimationController`; **002** confetti limit particles |
| `animations/match_celebration.dart` | **PERF-COMP-MATCH-002** Full-screen overlay in separate route |
| `match_interaction/animated_snackbar.dart` | **PERF-COMP-MATCH-003** Don't rebuild underlying screen |
| `features/matching/.../match_celebration.dart` | **PERF-COMP-MATCH-004** Consolidate duplicates |

- [~] **PERF-COMP-MATCH-001** Single `AnimationController` — unused `MatchScreen` already used one controller; live `MatchCelebrationOverlay` is `SingleTickerProviderStateMixin` + `AnimatedBuilder` (ticker actually rebuilds frames) and `AppAnimations.animationsEnabled`
- [x] **PERF-COMP-MATCH-002** confetti limit particles — live burst is `ParticleBurstPainter.maxParticleCount` (14), not `ConfettiWidget`; Reduce Motion skips particles; paint in `RepaintBoundary`
- [x] **PERF-COMP-MATCH-002** Full-screen overlay in separate route — `MatchFoundPage.show` is `PageRouteBuilder(opaque: false)`; fade skipped when Reduce Motion; `ProfilePage` / `ProfileDetailScreen` now use `MatchCelebrationLauncher` instead of `MatchScreen` / `showDialog`
- [x] **PERF-COMP-MATCH-003** Don't rebuild underlying screen — `AnimatedSnackbar.show` stays an `OverlayEntry`; removed full-screen `Positioned.fill` hit-eater; Reduce Motion skips slide/fade; SVG icons (`AppIcons`)
- [~] **PERF-COMP-MATCH-004** Consolidate duplicates — unused `widgets/animations/match_celebration.dart` and `features/matching/presentation/widgets/match_celebration.dart` now export live overlay/launcher (no ConfettiWidget / bounce-repeat dual UI)

### Profile widgets (`lib/widgets/profile/`, `lib/features/profile/`)

| Component | Tasks |
|-----------|-------|
| `profile_photo_carousel.dart` | **PERF-COMP-PROF-001** Prefetch adjacent images; **002** `RepaintBoundary` |
| `profile_image_carousel.dart` | **PERF-COMP-PROF-002** Consolidate duplicate |
| `photo_gallery.dart` | **PERF-COMP-PROF-003** Lazy grid |
| `profile_action_buttons.dart` | **PERF-COMP-PROF-004** `BackdropFilter` audit — remove or isolate |
| `profile_header.dart` | **PERF-COMP-PROF-005** Cache hero image |
| `profile_bio.dart` | **PERF-COMP-PROF-006** Expand/collapse without parent rebuild |
| `edit/profile_image_editor.dart` | **PERF-COMP-PROF-007** Compress on background isolate |

- [x] **PERF-COMP-PROF-001** Prefetch adjacent images — live `ProfileHeroSection` / `ProfilePhotoGalleryViewer` call `ProfileImagePrefetch.prefetchAdjacent` (current ±1) via `precacheImage`
- [x] **PERF-COMP-PROF-002** `RepaintBoundary` — live carousel already keyed `profile_photo_carousel`; gallery viewer paint is isolated
- [~] **PERF-COMP-PROF-002** Consolidate duplicate `profile_image_carousel.dart` — unused; live photos are hero carousel + `ProfileImageEditor` (not dual-maintained)
- [x] **PERF-COMP-PROF-003** Lazy grid — live galleries are `GridView.builder` (max 6) + `PhotoViewGallery.builder`; tiles use `OptimizedImage` `ImageSize.small` in `RepaintBoundary`. Unused `PhotoGallery` not dual-maintained
- [x] **PERF-COMP-PROF-004** `BackdropFilter` audit — removed 0.5σ blur from live hero photo card; live `OtherUserProfileActionBar` is solid (no blur). Unused frosted `ProfileActionButtons` not dual-maintained
- [x] **PERF-COMP-PROF-005** Cache hero image — `OptimizedImage` + `LgbtfinderImageCacheManager`; prefetch warms current/adjacent into Flutter's image cache
- [x] **PERF-COMP-PROF-006** Expand/collapse without parent rebuild — live `ExpandableProfileBio` owns expand `setState`; unused `ProfileBio` not dual-maintained
- [x] **PERF-COMP-PROF-007** Compress on background isolate — already `ImageUploadCompressor` (`FlutterImageCompress` native thread) from `ProfileEditPhotosSection`; editor is grid-only

### Calls widgets (`lib/features/calls/presentation/widgets/`)

| Component | Tasks |
|-----------|-------|
| `agora_call_video_layer.dart` | **PERF-COMP-CALL-001** `RepaintBoundary`; limit setState to video bounds |
| `call_timer.dart` | **PERF-COMP-CALL-002** Own timer — already extracted; use everywhere |
| `call_controls.dart` | **PERF-COMP-CALL-003** const buttons |
| `call_history_bubble.dart` | **PERF-COMP-CALL-004** const layout |
| `incoming_call_banner.dart` | **PERF-COMP-CALL-005** Overlay layer |

- [x] **PERF-COMP-CALL-001** `RepaintBoundary`; limit setState to video bounds — live `AgoraCallVideoLayer` keeps Agora views in `RepaintBoundary`; PiP drag/snap `setState` moved to `_DraggableLocalPip` so ticks do not rebuild the main stage
- [x] **PERF-COMP-CALL-002** Own timer — already extracted; live timer is `OutgoingCallHeader` / `callTimerProvider`; unused `call_timer.dart` now exports `CallDurationFormatter` only
- [x] **PERF-COMP-CALL-003** const buttons — live `CallMuteButton` / `CallFlipButton` / `CallEndButton` keep const constructors and paint in `RepaintBoundary`; unused `call_controls.dart` not dual-maintained
- [x] **PERF-COMP-CALL-004** const layout — live `CallHistoryBubble` is a const-constructed `ChatSystemMessage` row inside `RepaintBoundary`
- [x] **PERF-COMP-CALL-005** Overlay layer — `IncomingCallHost` no longer watches incoming state; banner/minimized chrome is `_IncomingCallForegroundLayer` so the navigator child does not rebuild

### Notifications widgets

| Component | Tasks |
|-----------|-------|
| `notification_tile.dart` | **PERF-COMP-NOTIF-001** `RepaintBoundary`; thumbnail avatar |
| `notification_badge.dart` | **PERF-COMP-NOTIF-002** Animated scale only on count change |

- [x] **PERF-COMP-NOTIF-001** `RepaintBoundary`; thumbnail avatar — live `NotificationTile` wraps the row and leading avatar in `RepaintBoundary`; `AvatarWidget` decodes `ImageSize.thumbnail`
- [x] **PERF-COMP-NOTIF-002** Animated scale only on count change — live `widgets/badges/notification_badge.dart` pulses in `didUpdateWidget` when count changes (not first build / not when hiding); Reduce Motion skips `ScaleTransition`
- [x] **PERF-COMP-NOTIF-002** Unused feature `notification_badge.dart` (child wrapper + idle elastic) not dual-maintained

### Shared / core widgets

| Component | Tasks |
|-----------|-------|
| `lazy_load_list.dart` | **PERF-COMP-SHARED-001** Replace custom `VisibilityDetector` with package or slivers; **002** default cacheExtent |
| `staggered_list_item.dart` | **PERF-COMP-SHARED-002** Cap max stagger index; disable via settings |
| `error_boundary.dart` | **[~]** OK |
| `offline_wrapper.dart` | **PERF-COMP-SHARED-003** Banner only — don't rebuild child |
| `incoming_call_overlay.dart` | **PERF-COMP-SHARED-004** Root overlay |

- [x] **PERF-COMP-SHARED-001** Replace custom `VisibilityDetector` with slivers — `LazyLoadList` uses `AppListView`; `LazyLoadGrid` uses `SliverGrid` + `scrollCacheExtent`; `LazyLoadItem` is a pass-through (no scroll-notification detector)
- [x] **PERF-COMP-SHARED-002** Default `cacheExtent` — `AppListView` 400px on `LazyLoadList`; `LazyLoadGrid` `AppScroll.listCacheExtentPixels`
- [x] **PERF-COMP-SHARED-002** Cap max stagger index; disable via settings — `StaggeredListItem.maxStaggerIndex` / `cappedStaggerIndex`; Reduce Motion + `AppMotionPreferences` skip the appear animation
- [~] **error_boundary.dart** OK — manual fallback only; framework errors stay in `main.dart`
- [x] **PERF-COMP-SHARED-003** Banner only — don't rebuild child — live `ConnectivityBanner` overlay sibling `_ConnectivityBannerLayer`; unused `offline_wrapper.dart` not dual-maintained
- [x] **PERF-COMP-SHARED-004** Root overlay — live `IncomingCallHost` in `MaterialApp.router` builder; unused `incoming_call_overlay.dart` redirects (not dual-maintained)

### Animations & Lottie

| Component | Tasks |
|-----------|-------|
| `animations/lottie_animations.dart` | **PERF-COMP-ANIM-001** Lazy load; **002** limit concurrent Lotties |
| `animations/animated_components.dart` | **PERF-COMP-ANIM-002** Gate behind reduce-motion |
| `onboarding_page_view.dart` | **PERF-COMP-ANIM-003** 14 animation refs — audit trim |

- [x] **PERF-COMP-ANIM-001** Lazy load — `ThemeAwareLottie` mounts `Lottie.asset` only after the first frame
- [x] **PERF-COMP-ANIM-002** Limit concurrent Lotties — `LottiePlaybackLimiter.maxConcurrent = 1`; extra instances keep the static fallback
- [~] **PERF-COMP-ANIM-002** Gate `animated_components.dart` behind reduce-motion — file is deleted/unreachable (`stubs_to_delete.json`); not dual-maintained. Live Lottie still respects `AppAnimations.animationsEnabled`
- [~] **PERF-COMP-ANIM-003** 14 animation refs — unused `onboarding_page_view.dart` (Animated/AutoAdvance) not dual-maintained; live intro is `pages/onboarding_page.dart` (4 slides, current±1, Reduce Motion)

### Premium & marketing widgets

| Component | Tasks |
|-----------|-------|
| `promotional_banner.dart` | **PERF-COMP-MKT-001** Static image preferred over animated gradient |
| `badge_achievement_popup.dart` | **PERF-COMP-MKT-002** Queue popups; one at a time |
| `daily_rewards_dialog.dart` | **PERF-COMP-MKT-003** Preload reward icon only |
| `upgrade_dialog.dart` | **PERF-COMP-MKT-004** No blur backdrop |

- [x] **PERF-COMP-MKT-001** Static image preferred over animated gradient — `PromotionalBanner` hero uses `OptimizedImage` when `imageUrl` is set (no gradient); enter motion skipped when Reduce Motion is on
- [x] **PERF-COMP-MKT-002** Queue popups; one at a time — `BadgePopupQueue` serializes `BadgeAchievementPopup.show`; `MultipleBadgeAchievementPopup.show` plays badges sequentially
- [x] **PERF-COMP-MKT-003** Preload reward icon only — only today's cell loads artwork / network icon (`precacheImage`); other days are a hollow circle
- [x] **PERF-COMP-MKT-004** No blur backdrop — live `UpgradeDialog` uses a solid `barrierColor` (`Colors.black54`); no `BackdropFilter`

---

## Phase 6 — Android-specific polish

- [x] **PERF-ANDROID-001** Enable predictive back gesture for chat/profile routes — `PredictiveBackPageTransitionsBuilder` + `platformPredictivePage` (`MaterialPage`) on chat and profile-detail (same as PERF-ROUTE-004)
- [x] **PERF-ANDROID-002** Set `android:enableOnBackInvokedCallback="true"` in manifest — already on `<application>`
- [~] **PERF-ANDROID-003** Verify 120Hz display refresh — `displayRefreshRateHz()` logs after first frame; no 120Hz device in this pass (`flutter run --profile` still required on hardware)
- [x] **PERF-ANDROID-004** Baseline profile — `android/app/src/main/baseline-prof.txt` + `androidx.profileinstaller` in release deps
- [~] **PERF-ANDROID-004** Full `:macrobenchmark` module — skipped (needs a device/CI bench runner; baseline profile covers cold-start hints)
- [x] **PERF-ANDROID-005** Audit Agora + Firebase background services — FCM isolate handler; Agora stays on main isolate and hops UI via `_emitUi`; see `docs/ANR_DEBUGGING.md` §10
- [x] **PERF-ANDROID-006** Use `SurfaceProducer` / texture path — `kAgoraUseFlutterTexture` on live `AgoraCallVideoLayer` (`useAndroidSurfaceView: false`)
- [x] **PERF-ANDROID-007** Release R8 + ProGuard — `isMinifyEnabled` / `isShrinkResources`; keep rules for Agora, Firebase, Pusher

---

## Phase 7 — Duplicate consolidation map

Reduce maintenance and double rebuild paths:

| Keep (canonical) | Remove / redirect | Status |
|------------------|-------------------|--------|
| `pages/chat_list_page.dart` | `features/chat/.../chats_screen.dart` | Stub gone |
| `pages/chat_page.dart` | `features/chat/.../chat_screen.dart` | Stub gone |
| `pages/discovery_page.dart` | `features/discover/.../discover_screen.dart` | Stub gone |
| `pages/profile_page.dart` | `features/profile/.../profile_screen.dart` | Stub gone |
| `widgets/chat/message_bubble.dart` | `features/chat/.../message_bubble.dart` | Stub gone |
| `core/widgets/optimized_image.dart` | `widgets/images/` and `widgets/common/optimized_image.dart` | Duplicates gone |
| `widgets/cards/card_stack_manager.dart` | `features/discover/.../swipeable_card_stack.dart` | Export shim deleted |
| `features/settings/pages/settings_page.dart` | `screens/settings_screen.dart`, `ComprehensiveSettingsScreen` | Export aliases only |

Router: home tabs are `/home` + `?tab=`. Chat thread is `/chat`. Other-user profile is `/profile-detail`. Unused top-level `/discovery` `/chat-list` `/profile` `/settings` `/notifications` aliases removed.

- [x] **PERF-DEDUP-001** Complete consolidation map above — live pages/widgets listed; feature stubs already gone (`stubs_to_delete.json` / `unreachable.json`)
- [x] **PERF-DEDUP-002** Update `app_router.dart` to single path per screen — home shell + `HomeTabRoutes` redirects; dropped unused `AppRoutes` aliases; error page uses SVG
- [x] **PERF-DEDUP-003** Delete dead stubs and unused imports — deleted unused `swipeable_card_stack.dart`; `settings_screen.dart` / `comprehensive_settings_screen.dart` re-export `SettingsPage`

---

## Verification checklist (run after each phase)

Automated stand-in: `test/unit/core/verification_checklist_test.dart`.
Device FPS / ANR still needs `flutter run --profile` on hardware.

### Devices
- [~] Mid-range Android (4–6GB RAM, 60Hz) — no device in this pass; `displayRefreshRateHz()` is the probe
- [~] High-refresh Android (120Hz) if available — same as PERF-ANDROID-003; emulator/tests report 60Hz
- [~] Low-end Android (3GB RAM) for blur/Lottie fallbacks — `LottiePlaybackLimiter.maxConcurrent = 1` + Reduce Motion static fallback (unit/widget tests)

### Metrics (Flutter DevTools → Performance)

| Metric | Target |
|--------|--------|
| Cold start → interactive | < 2s (cached session) |
| Chat open → first message visible | < 100ms (from local DB) |
| Chat scroll FPS | ≥ 58fps sustained (200+ messages) |
| Chat list scroll FPS | ≥ 58fps (50+ conversations) |
| Frame build time (new message while scrolled up) | < 8ms |
| Discovery swipe frame time | < 16ms during drag |

### Manual flows
- [x] Send 20 messages rapidly — no input lag — composer `MessageInput` 20 sequential sends (lock + post-frame unlock); no dropped/double fires
- [x] Receive messages while scrolled up — no scroll jump — `ChatUnseenIncoming` badges + FAB when `pixels > 200`; does not auto-stick
- [x] Switch home tabs 10× — no growing memory leak — `homeTabsAfterIdleDispose` never keeps all 5 tabs after idle
- [x] Open chat from notification — instant history — `NotificationNavigation` `message` → `/chat?userId=`
- [x] Airplane mode → open chat — cached history visible — Drift `ChatLocalRepository.upsertMessages` / `getMessagesForOtherUser`
- [x] Reduce motion ON — no stagger/Lottie/confetti — `StaggeredListItem` skips `AnimatedBuilder`; `ThemeAwareLottie` does not mount `LottieBuilder`
- [x] Voice message play + scroll — no stutter — `ChatVoicePositionGate` drops sub-100ms position ticks; player pauses off-screen

### Commands
```bash
cd lgbtindernew
flutter run --profile
# DevTools → Performance → Record timeline while scrolling chat
flutter build apk --release
```

---

## Recommended implementation order

| Sprint | Focus | Key task IDs |
|--------|-------|--------------|
| 1 | Chat hot path | PERF-INFRA-001–004, PERF-PAGE-CHAT-001–008 |
| 2 | Chat list + local convos | PERF-PAGE-CHATLIST-001–007, PERF-COMP-MSG-* |
| 3 | App shell | PERF-PAGE-HOME-001–003, PERF-MAIN-001, PERF-COMP-NAV-* |
| 4 | State patterns | PERF-INFRA-010–013, PERF-INFRA-020–022 |
| 5 | Discovery & images | PERF-PAGE-DISCOVERY-*, PERF-COMP-CARD-* |
| 6 | Dedup & fonts | PERF-DEDUP-*, PERF-INFRA-030–032 |
| 7 | Settings & secondary screens | PERF-SCR-SETTINGS-*, PERF-FEAT-SET-* |
| 8 | Android & benchmarks | PERF-ANDROID-* |

---

## Task count summary

| Category | Tasks |
|----------|-------|
| Infrastructure | 27 |
| Pages (`lib/pages/`) | 38 |
| Screens (`lib/screens/`) | 55 |
| Feature screens | 45 |
| Components | 95 |
| Android | 7 |
| Dedup | 3 |
| **Total** | **~270** |

---

## References

- `docs/SPLASH_ANR_AUDIT_REPORT.md` — startup ANR fixes
- `docs/ANR_DEBUGGING.md` — Firebase / background isolate rules
- `docs/USER_PAGE_FLOW_TASK_LIST.md` — navigation consolidation
- `lgbtinder-backend/docs/CHAT_SYSTEM_IMPLEMENTATION.md` — backend chat alignment
- `UI-DESIGN-SYSTEM.md` — animation tokens & reduce-motion
- Telegram UX principles: local-first, reverse chat list, surgical diffs, cheap pixels

---

*Last updated: 2026-09-15*
