# E2E Test Plan — LGBTFinder (lgbtindernew)

**Status:** Phase 1 complete — test list defined; implementation pending credentials and Phase 3.  
**Last updated:** 2026-05-17  
**Target suite location:** `test/e2e/`

---

## Audit summary

| Area | Findings |
|------|----------|
| **Router** | 25+ named routes; home shell at `/home` with tabs: `discovery`, `chat-list`, `notifications`, `profile`, `settings`; nested: `matches`, `blocked-users`, `google-play-billing-test` |
| **Auth stages** | `unauthenticated` → welcome; `profileCompletion` → only `profile-wizard` / `onboarding-preferences`; `authenticated` → full app |
| **Tier model** | `basid` / `silder` / `golden`; `TierGatedFeature`: `likesYou`, `advancedFilters`, `videoCalls` (silder+), `boost` (golden) |
| **Gating runtime** | `PlanGuard` (limits) + `FeatureLockedScreen` (upsell); CTA → `subscription-plans`, compare → `tier-comparison` |
| **Off-router screens** | Many settings/safety flows use `Navigator.push` (e.g. `SafetySettingsScreen`, `EmergencyContactsScreen`, `FilterScreen`) — E2E must drive UI, not only `GoRouter` paths |
| **Existing tests** | Unit/widget coverage in `test/routes/`, `test/shared/page_tier_rules_test.dart`, `test/integration/*` |
| **Payments** | Google Play Billing only; Stripe removed from Flutter |
| **Firebase** | FCM/push only — no phone-auth login in active flow |

**Source-of-truth files:** `lib/routes/app_router.dart`, `lib/shared/models/page_tier_rules.dart`, `docs/USER_PAGE_FLOW_CANVAS.md`, `docs/USER_FLOW_SMOKE_TEST_CHECKLIST.md`

---

## Planned file structure (Phase 3)

```
test/e2e/
├── config/
│   └── test_credentials.dart
├── helpers/
│   ├── app_bootstrap.dart
│   ├── auth_helpers.dart
│   └── mock_services.dart
├── auth/
│   └── auth_flow_test.dart
├── onboarding/
│   └── profile_wizard_test.dart
├── discover/
│   └── discovery_swipe_test.dart
├── matching/
│   └── matching_flow_test.dart
├── chat/
│   └── chat_flow_test.dart
├── tier_gating/
│   └── tier_gating_test.dart
├── safety/
│   └── safety_flow_test.dart
├── navigation/
│   └── router_guards_test.dart
└── payments/
    └── billing_flow_test.dart
```

---

## E2E Test Plan

**Total planned tests:** 140

### Group 1: Auth & Session

- [ ] TEST-001: Splash cold start (no token) — shows splash then routes to welcome after intro-onboarding seen
- [ ] TEST-002: Splash first launch — routes to intro `OnboardingPage` when intro not seen
- [ ] TEST-003: Splash valid session — token check succeeds and routes to `/home`
- [ ] TEST-004: Splash invalid/expired token — clears tokens and routes to welcome
- [ ] TEST-005: Welcome screen render — CTAs for login and register visible
- [ ] TEST-006: Welcome → Login navigation — tapping login opens `/login`
- [ ] TEST-007: Welcome → Register navigation — tapping register opens `/register`
- [ ] TEST-008: Login form validation — invalid email/password blocks submit with field errors
- [ ] TEST-009: Login happy path (ready user) — valid credentials store token and land on `/home`
- [ ] TEST-010: Login email verification required — redirects to `/email-verification?email=…&isNewUser=false`
- [ ] TEST-011: Login profile completion required — redirects to `/profile-wizard` with profile-completion token persisted
- [ ] TEST-012: Login API failure — error snackbar/dialog shown, remains on login
- [ ] TEST-013: Register happy path — valid registration navigates to email verification (`isNewUser=true`)
- [ ] TEST-014: Register validation — weak/invalid email blocks submission
- [ ] TEST-015: Email verification empty email guard — missing `email` query redirects to welcome with error
- [ ] TEST-016: Email verification valid code — stores session token and routes per user state (home or wizard)
- [ ] TEST-017: Email verification invalid code — error shown, stays on verify screen
- [ ] TEST-018: Email verification resend — resend disabled during countdown, enabled after expiry
- [ ] TEST-019: Email verification back navigation — new user → register; returning user → login
- [ ] TEST-020: Logout from settings — clears tokens and returns to welcome
- [ ] TEST-021: Session restore after app restart — valid token skips auth and opens home
- [ ] TEST-022: Unauthorized API (401) — global handler logs out and redirects to welcome

### Group 2: Onboarding & Profile Wizard

- [ ] TEST-023: Intro onboarding completion — finishing intro marks seen and next launch goes to splash auth check
- [ ] TEST-024: Profile wizard step 0 (photo) — renders avatar step; missing primary photo blocks Next
- [ ] TEST-025: Profile wizard step 1 (basic/contact) — required name/phone/location validation blocks Next
- [ ] TEST-026: Profile wizard step 2 (about) — age/bio/gender/birthdate validation enforced
- [ ] TEST-027: Profile wizard step 3 (preferences/lifestyle) — height/weight/preferences required
- [ ] TEST-028: Profile wizard step 4 (interests/music) — minimum selections enforced
- [ ] TEST-029: Profile wizard step 5 — intermediate step renders and allows back/forward
- [ ] TEST-030: Profile wizard step 6 complete — submits registration, clears profile-completion token, routes to home
- [ ] TEST-031: Profile wizard back button — returns to previous step without losing entered data
- [ ] TEST-032: Profile-completion guard — user with profile-completion token cannot open `/home/discovery` until wizard done
- [ ] TEST-033: Onboarding preferences screen — accessible during profile-completion stage at `/onboarding-preferences`
- [ ] TEST-034: Post-wizard home tabs — completing wizard unlocks all home tab routes

### Group 3: Discovery / Swipe

- [ ] TEST-035: Discovery tab render — card stack visible with profile data when API returns profiles
- [ ] TEST-036: Swipe right (like) — triggers like action and removes/advances card
- [ ] TEST-037: Swipe left (dislike) — triggers pass/dislike and advances deck
- [ ] TEST-038: Empty discovery deck — `EmptyState` shown with adjust-filters / increase-distance CTAs
- [ ] TEST-039: Empty deck recovery — increase-distance action refreshes with expanded radius
- [ ] TEST-040: Filter panel open — navigates to `FilterScreen` from discovery
- [ ] TEST-041: Filter apply (basid) — basic filters apply; advanced options gated for basid
- [ ] TEST-042: Superlike with message — message payload sent via likes service
- [ ] TEST-043: Profile detail from card — tap opens `/profile-detail?userId=`
- [ ] TEST-044: Discovery plan limit — basid at swipe limit shows denied state/upsell (PlanGuard)
- [ ] TEST-045: Home tab route sync — tapping bottom nav updates URL and `IndexedStack` index

### Group 4: Matching & Likes

- [ ] TEST-046: Mutual like match modal — match overlay/dialog appears after mutual like
- [ ] TEST-047: Match modal → chat — CTA opens `/chat?userId=&userName=&avatarUrl=`
- [ ] TEST-048: Matches list render — `/home/matches` shows match rows from API
- [ ] TEST-049: Matches empty state — empty list shows discovery + Contact support CTAs
- [ ] TEST-050: Match list item tap — opens chat thread for selected match
- [ ] TEST-051: Likes received (silder+) — screen loads for premium; basid sees feature-locked redirect
- [ ] TEST-052: Profile detail like action — like from detail updates match state

### Group 5: Chat

- [ ] TEST-053: Chat list render — `/home/chat-list` shows conversations with avatars/names
- [ ] TEST-054: Chat list filters — all/unread/online filter sheet changes visible list
- [ ] TEST-055: Open chat thread — tap opens `/chat?userId=…` with header and messages
- [ ] TEST-056: Send text message — optimistic UI append, API success keeps message
- [ ] TEST-057: Send message failure — failed send rolls back or shows error state
- [ ] TEST-058: Pusher/real-time update (mock) — incoming event appends message without refresh
- [ ] TEST-059: Chat media send — image/video picker sends via `chatService.sendMessage` with media
- [ ] TEST-060: Pinned messages modal — header action lists pinned messages from API
- [ ] TEST-061: Video call gating (basid) — video call blocked with redirect to feature-locked
- [ ] TEST-062: Video call allowed (silder) — video call entry navigates when PlanGuard allows
- [ ] TEST-063: Chat without userId — `/chat` without query shows `ChatListPage` fallback

### Group 6: Tier Gating & Upgrade Flows

- [ ] TEST-064: basid → likesYou locked — `canAccessFeature` false; UI routes to `/feature-locked?minTier=silder`
- [ ] TEST-065: basid → advancedFilters locked — filter advanced section shows upsell
- [ ] TEST-066: basid → videoCalls locked — chat video CTA shows feature-locked
- [ ] TEST-067: basid → boost locked — boost action shows golden-tier lock
- [ ] TEST-068: silder tier unlock — likesYou, advancedFilters, videoCalls accessible; boost still locked
- [ ] TEST-069: golden tier unlock — all `TierGatedFeature` values accessible
- [ ] TEST-070: FeatureLockedScreen render — shows feature title, min tier label, upgrade bullets
- [ ] TEST-071: FeatureLocked CTA View plans — navigates to `/subscription-plans`
- [ ] TEST-072: FeatureLocked Compare tiers — navigates to `/tier-comparison`
- [ ] TEST-073: Tier comparison screen — basid/silder/golden comparison content renders
- [ ] TEST-074: Premium features screen matrix — per-feature min tier labels and lock taps route to feature-locked
- [ ] TEST-075: Settings Compare tiers entry — settings tile opens tier comparison

### Group 7: Notifications

- [ ] TEST-076: Notifications tab render — list loads first page
- [ ] TEST-077: Notifications pagination — scroll loads next page without duplicates
- [ ] TEST-078: Mark notification read — unread badge decrements after read
- [ ] TEST-079: Mark all read — all items marked, badge zeroed
- [ ] TEST-080: Delete notification — item removed, badge/provider invalidated
- [ ] TEST-081: Notification tap routing — match/message types open profile or chat canonical routes
- [ ] TEST-082: Notifications empty state — shows discovery + Contact support CTAs
- [ ] TEST-083: Unread badge on home nav — `unreadNotificationCountProvider` reflected on bottom bar

### Group 8: Safety (Block / Report / Emergency Contacts)

- [ ] TEST-084: Safety settings entry — settings → safety opens `SafetySettingsScreen`
- [ ] TEST-085: Report user modal/screen — submit report calls API and dismisses with success feedback
- [ ] TEST-086: Report validation — empty reason blocks submit
- [ ] TEST-087: Block user dialog — confirm block removes user from discovery/deck
- [ ] TEST-088: Blocked users list — `/home/blocked-users` shows blocked entries
- [ ] TEST-089: Unblock user — unblock removes from list and restores discoverability (mock API)
- [ ] TEST-090: Report history — safety settings → report history lists past reports
- [ ] TEST-091: Emergency contacts empty state — empty list shows add CTA
- [ ] TEST-092: Add emergency contact — form submit saves and appears in list
- [ ] TEST-093: Remove emergency contact — delete removes contact from list

### Group 9: Settings & Account

- [ ] TEST-094: Settings tab render — all primary sections/tiles visible
- [ ] TEST-095: Home tab navigation — each bottom-nav tab updates route and visible page
- [ ] TEST-096: Profile tab — own profile loads at `/home/profile`
- [ ] TEST-097: Profile edit — `/profile/edit` opens edit form and saves changes (mock)
- [ ] TEST-098: Account management — Navigator flow from settings opens account screen
- [ ] TEST-099: Matching preferences — opens and saves preference changes
- [ ] TEST-100: Privacy settings — toggles persist (mock settings service)
- [ ] TEST-101: Notification settings — opens notification preferences screen
- [ ] TEST-102: Accessibility settings — opens and renders accessibility options
- [ ] TEST-103: Help & support — `/help-support` FAQ and contact actions render
- [ ] TEST-104: Support tickets — `/support-tickets` list and create-ticket escalation
- [ ] TEST-105: Terms of service — `/terms-of-service` renders legal content
- [ ] TEST-106: Privacy policy — `/privacy-policy` renders legal content
- [ ] TEST-107: Subscription status — `/subscription-status` shows plan name/state for tier
- [ ] TEST-108: Active subscription management CTA — active user routes to `/subscription-management` not plans
- [ ] TEST-109: Billing history — `/billing-history` loads transactions or empty state
- [ ] TEST-110: Logout from profile/settings — session cleared (see TEST-020)

### Group 10: Payments (Google Play Billing)

- [ ] TEST-111: Subscription plans screen — `/subscription-plans` loads plan cards from API/mock
- [ ] TEST-112: Plans empty/error state — graceful empty or retry UI when catalog fails
- [ ] TEST-113: Google Play billing test screen — `/home/google-play-billing-test` shows availability + product sections
- [ ] TEST-114: Billing availability (mock) — unavailable store shows error section, no crash
- [ ] TEST-115: Product list render (mock) — subscription and one-time products listed
- [ ] TEST-116: Purchase flow start (mock) — tapping buy invokes billing client without real charge
- [ ] TEST-117: Purchase success handling (mock) — success updates purchase status section
- [ ] TEST-118: Purchase failure handling (mock) — error surfaced in UI, app remains stable
- [ ] TEST-119: Subscription management screen — shows provider-aware manage/cancel actions
- [ ] TEST-120: basid upgrade from plans — selecting plan starts purchase flow (mock)
- [ ] TEST-121: Skip when credentials missing — integration tests guard with `markTestSkipped` if `apiBaseUrl == FILL_ME_IN`

### Group 11: Navigation Guards & Deep Links

- [ ] TEST-122: Unauthenticated `/home` — redirected to welcome, pending route stored
- [ ] TEST-123: Unauthenticated `/chat` — redirected to welcome with pending intent
- [ ] TEST-124: Unauthenticated `/subscription-plans` — redirected to welcome
- [ ] TEST-125: Unauthenticated `/feature-locked` — redirected to welcome
- [ ] TEST-126: Post-login pending resume — login after deep link opens originally requested protected route
- [ ] TEST-127: Authenticated auth-entry redirect — logged-in user at `/login` → `/home` (no pending)
- [ ] TEST-128: Profile-completion blocked route — `/home/discovery` → `/profile-wizard`
- [ ] TEST-129: Profile-completion allowed routes — wizard and onboarding-preferences accessible
- [ ] TEST-130: Splash re-entry guard — second navigation to `/` after startup → welcome (no loop)
- [ ] TEST-131: Legacy `/help` → `/help-support`
- [ ] TEST-132: Legacy `/discover` → `/home/discovery`
- [ ] TEST-133: Legacy `/profile/:id` → `/profile-detail?userId=`
- [ ] TEST-134: Legacy `/chat/:id` → `/chat?userId=`
- [ ] TEST-135: Legacy `/likes` and `/matches` → `/home/matches`
- [ ] TEST-136: Legacy `/plans` → `/subscription-plans`
- [ ] TEST-137: Unknown route error page — invalid path shows 404 scaffold with Go Home button
- [ ] TEST-138: Back on auth screens — system back from login returns to welcome without orphan stack
- [ ] TEST-139: Profile detail missing userId — `/profile-detail` without query falls back to home
- [ ] TEST-140: Deep link while logged out full journey — external link → welcome → login → destination (API integration, credentials required)

---

## Implementation phases

| Phase | Description | Status |
|-------|-------------|--------|
| 1 | Audit & test list (this document) | Done |
| 2 | Create `test/e2e/config/test_credentials.dart` (placeholders) | Pending |
| 3 | Implement `test/e2e/` suite per coding rules | Pending |
| 4 | Run `flutter test test/e2e/` and publish report | Pending |

---

## Constraints

- Tier spellings in code: `basid` | `silder` | `golden`
- Icons are SVG only (`AppSvgIcon` / `AppIcons`) — do not reference `Icons.*` in tests
- Do not edit `LGBTinder-flutter/` (frozen legacy tree)
- Active mobile payments: Google Play Billing only
- Router source of truth: `lib/routes/app_router.dart`
- Feeds, stories, community-forums may be commented out on backend — flag in report, do not fail tests solely for that

---

## Related documents

- [USER_PAGE_FLOW_CANVAS.md](./USER_PAGE_FLOW_CANVAS.md)
- [USER_PAGE_FLOW_TASK_LIST.md](./USER_PAGE_FLOW_TASK_LIST.md)
- [USER_FLOW_SMOKE_TEST_CHECKLIST.md](./USER_FLOW_SMOKE_TEST_CHECKLIST.md)
- [test/README.md](../test/README.md)
