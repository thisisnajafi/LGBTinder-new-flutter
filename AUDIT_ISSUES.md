# LGBTinder Flutter — Audit Issues & Task List

Audit date: 2026-08-20. Scope: `lgbtindernew` (Flutter app). Backend cross-checked against `lgbtinder-backend` (Laravel 12).

> **Status of this document.** Issues marked **Fixed** were verified with direct evidence (analyzer, compiler, test runs, dependency source inspection). The multi-domain audit has now completed across all ten areas; its findings are folded in below. Findings sourced from the audit sweep but not yet independently re-verified are marked *(unverified)* — confirm before acting on them.

## Baseline metrics

| Metric | At audit start | Current |
| --- | --- | --- |
| `flutter analyze` total problems | 3,269 | 1,910 |
| — errors | 1,830 | 528 |
| — errors in `lib/` | 373 | 303 |
| — errors in `test/` | 225 | 225 |
| — errors in stray root `pages/` | 1,232 | 0 (removed) |
| `flutter build bundle` (Dart compile) | pass | pass |
| `flutter test` | 175 pass / 92 fail / 30 suites fail to load | unchanged |

**Key insight:** `flutter build bundle` succeeds, which compiles everything reachable from `main.dart`. Therefore every remaining `lib/` analyzer error is in code that is **unreachable at runtime** — broken scaffolding, not live breakage.

---

## Fixed

### [CRITICAL] F-1 — Outgoing/active call route was unreachable
- **File:** `lib/routes/route_redirector.dart:75-77`
- **Problem:** A catch-all rule redirected any path starting with `/call/` to the chat list. The app's own real call route is `/call/outgoing` (`app_router.dart:62`), which matched that prefix. GoRouter's global `redirect` runs this on every navigation before route matching (`app_router.dart:277`).
- **Impact:** Both `startOutgoingCall()` and `openActiveCallPage()` (`lib/features/calls/utils/call_navigation.dart:49, 88`) push to this route, so the caller *and* the callee were dumped on the chat list instead of the Agora call UI. Calling was broken at the navigation layer.
- **Fix applied:** Added `_reservedCallSegments = {'outgoing'}` and returned `null` for reserved segments, mirroring the existing `_reservedProfileSegments` mechanism in the same file. Legacy `/call/{id}` links still fall back to chat.
- **Validation:** New regression test in `test/routes/route_redirector_test.dart`; 7/7 pass.

### [HIGH] F-2 — Stale duplicate `pages/` directory at repo root
- **File:** `pages/` (10 files, outside `lib/`)
- **Problem:** An abandoned pre-refactor snapshot. Its relative imports resolved to non-existent paths, producing **1,232 analyzer errors** — 67% of all errors — making `flutter analyze` useless as a regression gate.
- **Fix applied:** Removed via `git rm` (recoverable from history). Every file had a newer counterpart in `lib/pages/`; no import anywhere resolved to the root copy.
- **Validation:** `lib`/`test` error counts unchanged, proving no collateral damage.

### [MEDIUM] F-3 — Broken import depths + invalid `ConsumerState.build` overrides (payments widgets)
- **Files:** `lib/features/payments/presentation/widgets/{payment_method_tile,payment_method_selector,plan_card,upgrade_prompt}.dart`
- **Problem:** (a) Import paths one level too shallow (`../../../core/theme/…` from a 4-deep directory). (b) `Widget build(BuildContext, WidgetRef)` declared inside `ConsumerState`, where `build` takes only the context and `ref` is an inherited field.
- **Fix applied:** Corrected paths; fixed signatures; remapped a non-existent `PaymentMethodType` enum onto the model's real String values; mapped missing icon constants to existing ones; replaced undefined `AppColors.textSecondary` with theme-aware `onSurfaceVariant`.
- **Validation:** `lib/features/payments/` errors 83 → 19.

### [CRITICAL] F-5 — Every Android purchase sent the literal string `"google_play"` as its purchase token
- **File:** `lib/features/payments/data/services/google_play_billing_service.dart:420-451` (`_extractPurchaseToken`)
- **Problem:** On Android the method read `purchaseDetails.verificationData.source` and tried to `jsonDecode` it. `source` is not JSON and not a token — it is the compile-time constant store identifier. Verified in the plugin source: `in_app_purchase_android-0.4.0+10/lib/src/in_app_purchase_android_platform.dart:26` defines `const String kIAPSource = 'google_play'`, and `types/google_play_purchase_details.dart:36-39` assigns `source: kIAPSource` while putting the real token in `serverVerificationData`.
- **Impact:** `jsonDecode('google_play')` always throws, so the `catch` assigned the raw string. Every Android purchase therefore posted `purchase_token: "google_play"` to the backend, guaranteeing Google-side verification failure. This affected all four backend calls that use this helper: purchase verification (`:276`), acknowledgement (`:324`), and two restore paths (`:370`, `:464`). Users would be charged and receive nothing.
- **Fix applied:** Return `verificationData.serverVerificationData` on both platforms — it carries the Play purchase token on Android and the StoreKit receipt on iOS. Removed the now-unused `dart:convert` import. Also dropped the `purchaseID` last-resort fallback: `purchaseID` is the order ID, never a valid token, so falling back to it only converted a hard failure into a silent wrong value. All callers already guard on `purchaseToken.isEmpty` and surface a proper error.
- **Validation:** `flutter analyze` on the file reports 0 errors and no unused-import warning; `flutter build bundle` passes.

### [MEDIUM] F-4 — Missing `equatable` dependency
- **Files:** `lib/features/payments/data/models/google_play_{purchase,product}.dart`
- **Problem:** Both `extend Equatable` but `equatable` was absent from `pubspec.yaml`.
- **Fix applied:** Added `equatable: ^2.1.0`. `flutter pub add` failed (pub.dev 403 from this machine); resolved with `flutter pub get --offline` from local cache.

### [CRITICAL] C-24 — Realtime broadcasting silently used the log driver
- **Files:** `lgbtinder-backend/config/broadcasting.php`, live `.env`, `env-template.txt`, `ConditionalBroadcastServiceProvider`
- **Problem:** Laravel 12 reads `BROADCAST_CONNECTION`, but `config/broadcasting.php` only looked at `BROADCAST_DRIVER`. Live `.env` set `BROADCAST_DRIVER=pusher` then later `BROADCAST_DRIVER=log` (phpdotenv last-wins), so Pusher never ran. Chat, calls, and match events were silent.
- **Fix applied:** Default is now `env('BROADCAST_CONNECTION', env('BROADCAST_DRIVER', 'pusher'))`. Removed the duplicate `BROADCAST_DRIVER=log`. Warn when the resolved driver is not `pusher` outside testing/CI.
- **Validation:** `php artisan test:broadcasting` reports `Default broadcasting driver: pusher` with Pusher credentials set.

### [CRITICAL] C-2 — Forgot-password treated success as failure
- **File:** `lib/features/auth/data/services/auth_service.dart`
- **Problem:** Backend OTP/reset responses are `{status: true, message}` with no `data` key. The client gated on `response.data != null` and threw using the success message, so every successful reset looked like a failure.
- **Fix applied:** `sendOtp` / `verifyOtp` / `resetPassword` now succeed on `response.isSuccess` and parse `OtpResponse.fromJson(response.data ?? {status, message})`.

### [CRITICAL] C-4 — Change password always 422
- **Files:** `lib/screens/settings/account_management_screen.dart`, `lib/features/settings/data/services/settings_service.dart`
- **Problem:** Live UI posted `current_password` / `password` / `password_confirmation`. `AuthController::changePassword` requires `old_password` / `new_password` / `new_password_confirmation` plus a complexity regex.
- **Fix applied:** Matching field names and client-side complexity check `^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).+$`. Unused `AccountApiService` still posts `current_password` to `/account/change-password`, which *does* expect those names — left alone.

### [CRITICAL] C-5 — Change email always 422 plus a fake verification dialog
- **File:** `lib/screens/settings/account_management_screen.dart`
- **Problem:** Posted `{email}` then showed “code sent” before the request succeeded. Backend `ProfileController::changeEmail` requires `new_email` + `password`.
- **Fix applied:** Payload is `{new_email, password}`; the verification dialog only opens after `response.isSuccess`.

### [CRITICAL] C-6 — 2FA setup UI never shown
- **File:** `lib/screens/two_factor_auth_screen.dart`
- **Problem:** Enable set `_isEnabled = false` and `_showVerificationStep = true`, but `build` only showed the QR/verify step when `_isEnabled` was true.
- **Fix applied:** Instructions show when `!_isEnabled && !_showVerificationStep`. Disable button only when already enabled.

### [CRITICAL] C-12 + C-13 — Mutual match never celebrated; Pusher `new.match` dropped
- **Files:** `LikeController.php`, `lib/features/matching/data/models/match.dart`, `lib/features/discover/providers/discover_cache_provider.dart`, `lib/shared/services/pusher_websocket_service.dart`
- **Problem:** Like/superlike returned `is_match` with no `match` object; Flutter did `if (match == null) return`. Pusher event `new.match` failed a case-sensitive `contains('Match')` check, and `_handleNewMatch` read `user_id` instead of `matched_user.id`.
- **Fix applied:** Backend includes a `match` payload (`id`, `user_id`, `first_name`, avatar). Flutter falls back to the cached discover profile when `match` is still missing. Router handles `new.match` / `NewMatch` / `match.created` / `new_match` and reads `matched_user.id`.
- **Remaining risk:** `MatchChatBootstrapTest` HTTP cases still 500 on `CheckPermanentToken` + Sanctum `TransientToken` (pre-existing, unrelated). Match-list double-unwrap (C-17) is still open.

### [CRITICAL] C-18 — Play purchases refunded after 3 days if backend never acknowledged
- **File:** `lib/features/payments/data/services/google_play_billing_service.dart`
- **Problem:** `completePurchase()` ran only after backend success. Combined with F-5 (wrong token) and C-19 (package mismatch), every purchase failed verification and Google auto-refunded.
- **Fix applied:** Subscriptions now call `completePurchase` after handling even if backend fails (still restorable; webhook/restore can grant). Consumables stay unfinished until backend success so they are not consumed without entitlement. Purchase-stream handlers are awaited before UI listeners see the update. One-time validate treats `isSuccess` as enough (no longer requires a `data` body).
- **Remaining risk:** Consumable refunds can still happen if Play verification stays broken for 3 days.

### [CRITICAL] C-19 — Package name `com.lgbtfinder` vs `com.lgbtfinder.app`
- **Files:** Flutter billing `_packageName`, `GooglePlayVerificationService.php`, `config/services.php`, webhook middleware
- **Problem:** The APK `applicationId` is `com.lgbtfinder`. Backend default and mismatch check were `com.lgbtfinder.app`, so activate/verify hard-rejected every client request. Google API calls also queried the wrong package.
- **Fix applied:** Default package is `com.lgbtfinder`. Both `com.lgbtfinder` and `com.lgbtfinder.app` are allowed aliases. Verification uses the client-sent package when it is allowed, so a stale admin/env value cannot reject a real purchase.
- **Validation:** `GooglePlayBillingServiceTest` — 3 passed (10 assertions).

### [CRITICAL] C-20 — Superlike packs granted with no payment / client always 422
- **Files:** `superlike_packs_screen.dart`, `superlike_packs_sheet.dart`, `SuperlikePackController.php`, `UserSuperlikePack` model
- **Problem:** Live UI called `POST /superlike-packs/purchase` without `payment_method` (always 422). That endpoint granted packs with no payment verification.
- **Fix applied:** Live UI launches Google Play consumable billing (`superlike_small` / `medium` / `large` / `mega`) and waits for the purchase stream (which already hits `validate-one-time-purchase`). Backend `purchasePack` now requires `payment_method=google_play` plus a verified `purchase_token`/`product_id`; Stripe/PayPal are directed to their checkout endpoints. `google_product_id` is included in the available-packs payload. `google_purchase_token` is fillable so grants can be idempotent.
- **Remaining risk:** Packs with no `google_product_id` and a count outside the catalog fallbacks cannot be bought. Play product IDs in the seeder still do not match pack quantities 1:1.

### [CRITICAL] C-31 — FCM token never reached the backend
- **Files:** `push_notification_service.dart`, `session_services_provider.dart`, `NotificationController.php`, `routes/api.php`, users migration
- **Problem:** `_getFCMToken()` never posted the token. `setApiService` was never called. `POST /notifications/register-device` did not exist, and `users.device_token` was not a migrated column. Backend push fell back to an empty FCM token.
- **Fix applied:** After login, `fcmDeviceRegistrationProvider` wires `ApiService` and uploads the current token. Token refresh also posts. Added `POST /notifications/register-device` and `DELETE /notifications/unregister-device` (before `/{id}` so unregister is not swallowed). Added `device_token` / `device_platform` columns and fillable fields.
- **Remaining risk:** Local MySQL was down so the migration was not applied here. Run it on the live DB. FCM HTTP v1 still needs Firebase credentials on the server.

### [CRITICAL] C-32 — Background FCM handler was a log-only no-op
- **Files:** `lib/shared/services/fcm_background_handler.dart`, `main.dart`, `CallKitService`, `PushNotificationService.php`
- **Problem:** `firebaseMessagingBackgroundHandler` only logged. Background/terminated devices never showed CallKit or a local notification. CallKit `showIncoming` also bailed if listeners were not wired yet.
- **Fix applied:** Background isolate initializes Firebase, presents CallKit for incoming-call payloads, and shows a local notification for data-only messages (OS already displays `notification` payloads). Incoming-call FCM is now data-only + high priority so the handler can ring. CallKit UI no longer requires prior `initialize()`.

### [CRITICAL] C-30 — Agora token was not a real AccessToken
- **Files:** `app/Services/AgoraService.php`, vendored `app/Support/Agora/{RtcTokenBuilder2,AccessToken2,Util}.php`
- **Problem:** The hand-rolled builder emitted a fake `006` string. Even with credentials, `joinChannel` would fail.
- **Fix applied:** Generate AccessToken2 (`007`) via Agora's official PHP builder. `AgoraServiceTest` asserts the prefix.
- **Validation:** `AgoraServiceTest` 2 passed.

### [CRITICAL] C-29 — Flutter now used a hardcoded App ID; token response now includes backend App ID
- **Files:** `agora_service.dart`, `AgoraTokenService.php`, `call_signaling_service.dart`, `outgoing_call_page.dart`
- **Problem:** Engine initialized with a compile-time App ID that can differ from the server. `/calls/{id}/agora-token` also 503s when `AGORA_*` / admin settings are empty.
- **Fix applied:** Token payload includes `app_id`; the call page passes it into `AgoraService.initialize`. Hardcoded `AgoraConfig` remains a fallback only (O-8).
- **Still blocked:** Live `config('agora.app_id')` and certificate lengths are **0**. Set `AGORA_APP_ID` / `AGORA_APP_CERTIFICATE` in Admin → Settings or `.env`, then `php artisan config:clear`. Until then every agora-token request stays 503.

### [CRITICAL] C-1 — Dio treated every 4xx as success
- **Files:** `lib/core/network/dio_client.dart`, `test/unit/services/dio_client_status_test.dart`
- **Problem:** `validateStatus` accepted 200–499 (and 600+). Dio therefore never fired `onError` for client errors. `BannedHandler` (403 `user_state: banned` → `/account-banned`) and `RetryInterceptor` (429 with `Retry-After`) lived only on that branch, so they never ran. 401 logout still worked via `onResponse`; banned routing did not.
- **Fix applied:** Default `validateStatus` is 2xx only. Shared `_isBannedAccount` matches `EnsureUserNotBanned` / check-token payloads (`data.user_state == banned` or `data.banned == true`) from `onError` (live path) and `onResponse` (per-request override). 401 refresh/logout still runs in `onError`. Plan 403s (`PREMIUM_REQUIRED` etc.) are unchanged.
- **Validation:** `dio_client_status_test.dart` 4/4 pass; `flutter analyze` on the two files is clean; `flutter build bundle` passes.
- **Remaining risk:** C-7 — Sanctum has no refresh endpoint. A stored refresh token now actually POSTs `/auth/refresh` on 401 (that path was dead before) and then logs out. No refresh token → logout with no extra HTTP.

### [HIGH] O-12 stubs — Deleted 107 unreachable placeholder files
- **Files:** listed in `tool/stubs_to_delete.json` (44 feature-module screens, 55 widget stubs, 5 `core/utils` shells, 3 `shared/services` UnimplementedError shells)
- **Problem:** Scaffolding from `create_all_*.ps1` sat at plausible feature-module paths and produced most remaining `lib/` analyzer errors. None were imported from `lib/` or `test/`.
- **Fix applied:** Deleted all 107 files after resolving every `import`/`export` to them (0 live, 0 test, 0 stub-to-stub). Pruned 23 empty directories.
- **Validation:** `flutter build bundle` still passes. Live screens remain in `lib/screens/` and `lib/pages/`.
- **Remaining:** O-10 leftover unrouted screens. Duplicate *working* copies of routed screens are deleted (O-12).

### [MEDIUM] O-10 — Safety Center and Likes you were built but never reachable
- **Files:** `safety_center_screen.dart`, `report_history_screen.dart`, `emergency_contacts_screen.dart`, `nearby_safe_places_screen.dart`, `likes_received_screen.dart`, `settings_page.dart`, `app_router.dart`
- **Problem:** Seven complete screens had no route. Safety Center / report history / emergency contacts were a closed island. Likes you (`GET /likes/pending`) is a paid feature with no entry point. Contact support showed a fake “coming soon” snackbar even though Help & support already exists.
- **Fix applied:** Named routes `safety-center` and `likes-received` under `/home`. Settings → Safety center and Quick access → Likes you. Contact support now opens Help & support. Report history reads `GET /safety/report-history` (Laravel paginator + `reported_user`). Emergency contacts parse a list payload. Nearby safe places imports corrected (`lib/screens` → `lib/core`). Likes parse `avatar` / `pending_likes` without an extra envelope unwrap.
- **Validation:** `flutter analyze` on the touched files has no new errors; `flutter build bundle` passes.
- **Left unrouted (on purpose):** `accessibility_settings_screen.dart` (save is a fake 300ms delay), `call_history_screen.dart` (`ref.read(callProvider)` is `CallState`, not the notifier — would not compile if reached), `message_search_screen.dart` (chat list already searches conversations; body search can be wired later).

### [HIGH] O-11 — Orphaned profile editors shadowed the live pages
- **Files deleted:** `lib/screens/profile_edit_screen.dart`, `lib/screens/auth/profile_wizard_screen.dart`
- **Live copies:** `lib/pages/profile_edit_page.dart` (router `/profile/edit`), `lib/pages/profile_wizard_page.dart` (router `/profile-wizard`)
- **Diff:** The orphans never loaded real lifestyle fields (hardcoded height/weight/gender/age prefs) and still had `// TODO: Load profile from API`. The live editor loads `getMyProfile`, uploads/reorders photos, saves bio/height/weight/smoke/drink/gym, and uses country/city IDs. Name/gender/age are read-only there (set in the wizard). The live wizard is 7 steps vs the orphan’s 5 and is what `app_router` and email verification already open. Zero Dart imports of the orphan classes.
- **Validation:** `flutter build bundle` passes.

### [MEDIUM] O-12 — Unused working copies of routed screens
- **Deleted:** 11 shadow files (onboarding ×3, onboarding-preferences feature copy, subscription plans/management in `lib/screens`, both premium-subscription copies, unused superlike-packs copy, unused search page + search screen). Pruned empty `lib/screens/premium/` and `features/onboarding/presentation/screens/`.
- **Kept as live:** `pages/onboarding_page.dart`, `screens/onboarding/onboarding_preferences_screen.dart`, `features/payments/.../subscription_plans_screen.dart`, `superlike_packs_screen.dart`, `subscription_management_page.dart` (plus its typedef re-export), `settings_page.dart` (plus `screens/settings_screen.dart` export used by tests).
- **Left on purpose:** `settings_screen.dart` is a 2-line export; `subscription_management_screen.dart` in features is a typedef to the page. Voice/video call screens remain unrouted (only a test helper imports video).

### [LOW] O-13 — Dead community-forum endpoint constants
- **File:** `lib/core/constants/api_endpoints.dart`
- **Fix applied:** Removed the six `/community-forums*` constants. Nothing in `lib/` or `test/` referenced `ApiEndpoints.communityForums` / `forumPost*`. Unreachable `forum_service.dart` still hardcodes the same paths; backend forums stay disabled.

### [LOW] O-14 — 2FA backup codes had a dead copy TODO
- **File:** `lib/screens/two_factor_auth_screen.dart`
- **Fix applied:** Replaced unused `_copyToClipboard()` (fake “will be implemented” snackbar) with `_copyAllBackupCodes()` and a 44px **Copy all** button on the backup-codes group. Per-code copy was already live.

---

## Open — prioritised

### [HIGH] O-1 — Test suite is substantially broken
- **Evidence:** 92 failing tests, **30 suites fail to load entirely** (the whole `test/e2e/` tree, plus marketing/notification suites). 225 analyzer errors in `test/`.
- **Root cause:** Constructor/API drift — 64 `undefined_named_parameter`, 52 `missing_required_argument`. Tests were written against older model and service signatures.
- **Worst files:** `test/unit/services/notification_service_test.dart` (28), `test/integration/call_system_test.dart` (23), `test/unit/services/reference_data_service_test.dart` (20), `likes_service_test.dart` (19), `payment_service_test.dart` (19).
- **Why it matters:** No reliable regression safety net; "run the relevant tests" cannot be satisfied for most features.
- **Task:** Triage per file — realign each test with the current API, or delete tests for removed features. Estimate: 20+ files.

### [MEDIUM] O-2 — Stale router guard test contradicts implementation
- **File:** `test/routes/app_router_guard_test.dart:29` vs `lib/routes/app_router.dart:241`
- **Problem:** Test expects unauthenticated users on a protected route to be sent to `AppRoutes.login`; the implementation returns `AppRoutes.welcome`.
- **Blocked on:** Product decision — which is the intended landing screen? Fix whichever side is wrong; do not simply edit the test to match.

### [MEDIUM] O-3 — `in_app_purchase` API drift in Google Play product model
- **File:** `lib/features/payments/data/models/google_play_product.dart:35-36`
- **Problem:** Uses `ProductDetails.kind` and `ProductKind`, which do not exist in `in_app_purchase` 3.x.
- **Task:** Determine subscription-vs-consumable another way (e.g. `GooglePlayProductDetails`/`productId` mapping) and correct the model.

### [MEDIUM] O-4 — `payment_provider.dart` references seven undefined providers
- **File:** `lib/features/payments/providers/payment_provider.dart:14-20`
- **Problem:** References `getSubscriptionPlansUseCaseProvider`, `purchaseSubscriptionUseCaseProvider`, `cancelSubscriptionUseCaseProvider`, `restorePurchasesUseCaseProvider`, `validateReceiptUseCaseProvider`, `getSuperlikePacksUseCaseProvider`, `getSubscriptionStatusUseCaseProvider` — none defined anywhere.
- **Task:** Define the use-case providers, or repoint the notifier at the existing payments service layer.

### [MEDIUM] O-5 — Orphaned broken code across features
- **Scope:** 303 analyzer errors remain in `lib/`, all in unreachable files. Concentrated in `features/marketing` (~83), `features/onboarding` (~51), `features/community` (~35), `screens/community_forum_screen.dart` (22), `screens/profile_edit_screen.dart` (16), `features/chat` (18).
- **Sub-causes:** missing `freezed_annotation` dependency plus ungenerated `.freezed.dart`/`.g.dart` files (`features/community/data/models/forum_post.dart`); genuinely missing files (`../models/message_attachment.dart`, `../models/models.dart`, `core/services/api_service.dart`, `../../data/models/incoming_call_data.dart`).
- **Note:** `features/community` implements **forums, which the backend has explicitly disabled** — repairing it may be wasted effort. Same applies to feeds, stories, group chat, and dislikes.
- **Task:** Decide per feature: wire up, repair-to-compile, or delete.

### [LOW] O-6 — Dead deep links
- **File:** `lib/routes/route_redirector.dart:43-45`
- **Problem:** `/badges`, `/promotions`, and `/daily-rewards` all silently redirect to `/home`, so those deep links/notification taps land nowhere useful.
- **Task:** Point them at the real marketing screens, or remove the links from whatever generates them.

### [LOW] O-7 — Repo hygiene
- Build artifacts committed: `flutter_01.log`, `flutter_01.png`. Empty stray `lgbtindernew/lgbtindernew/` directory. 58 status markdown files and 8 `create_all_*.ps1` scaffolding scripts at project root.

---

## Environment blockers

These are **machine/network issues, not code defects**, but they block verification:

1. **pub.dev returns 403 Forbidden.** New dependencies cannot be added unless already in the local pub cache. Workaround: `flutter pub get --offline`.
2. **Gradle artifact mirror `gradle.jamko.ir` has an invalid TLS certificate** (its cert covers `*.chrepo.ir` only), and the Google fallback returns 403. `flutter build apk` therefore fails at `checkDebugAarMetadata`, before Dart compilation. The project's own `android/build.gradle.kts` and `settings.gradle.kts` are clean — this comes from the environment. **No on-device verification is currently possible.**

---

## Reachability map (measured)

The dead-code sweep resolved every `import`/`export`/`part` across all 880 Dart files in `lib/` and did a breadth-first traversal from `lib/main.dart`.

**479 files reachable, 401 unreachable (45.6%).**

This is the single most useful fact in the audit, because it partitions every other finding into "affects users" and "affects only the repo". Critically, **the reachable set contains zero placeholder screens, zero stub widgets, and exactly one TODO.** All 44 placeholder `X Screen` scaffolds, all 55 `// TODO: Implement widget` stubs, and every "coming soon" snackbar live in the orphaned 401. The live app is far cleaner than the raw file count suggests.

It also explains the analyzer baseline: `flutter build bundle` passes while `lib/` still reports 303 errors, because all of those errors are in unreachable files.

### Disabled backend features are correctly absent from the routed UI

Each backend feature that is commented out in `routes/api.php` was checked against the reachable set:

| Backend feature | Backend status | Reachable Flutter UI |
| --- | --- | --- |
| Community forums | disabled (`api.php:820-829`) | none — only orphaned constants and an orphaned screen |
| Feeds | disabled (`api.php:547`, `652`) | none |
| Stories | disabled (`api.php:668-669`) | none |
| Group chat | disabled (`api.php:530-538`) | none — the feature screen is an orphaned stub |
| Dislikes | `dislikes` prefix disabled (`api.php:599-605`) | **not affected** — see below |

**No routed screen will fail at runtime because of a disabled backend feature.** The dislike case deserves a specific note: although the `dislikes` resource is disabled, the backend deliberately keeps `/likes/dislike` (`api.php:611`) and `/matches/dislike` (`api.php:626`) alive as Flutter aliases, and those are exactly what `api_endpoints.dart:142,152` call. Swipe-left is fine.

---

## Open — from the completed audit sweep

### [MEDIUM] O-8 — Hardcoded Agora App ID shipped as the dart-define default
- **File:** `lib/core/config/agora_config.dart:8-11` — **reachable**, feeds the live call path via `features/calls/pages/outgoing_call_page.dart`.
- **Problem:** `defaultValue: '66ec2577665249188fd54334b11f3cd4'`. A production App ID in source is extractable from any shipped APK and lets a third party originate channels billed to your account. It also means a build that forgets `--dart-define` silently ships the dev credential instead of failing loudly.
- **Why this was not auto-fixed:** setting the default to `''` makes `isConfigured` false and breaks calling in every build that does not pass the define — and the backend `.env` is also missing `AGORA_APP_ID`/`AGORA_APP_CERTIFICATE`. This needs a coordinated change (rotate the credential, set it in CI dart-defines and in the backend `.env`, then empty the default and gate the call UI on `AgoraConfig.isConfigured`).

### [MEDIUM] O-9 — `trustDeviceSession` silently no-ops against an endpoint that does not exist
- **File:** `lib/features/settings/data/services/settings_service.dart:161-165`, reached from the wired `lib/screens/active_sessions_screen.dart` (Settings → Active sessions).
- **Re-inspected:** The live `active_sessions_screen.dart` only offers per-session and "log out all other devices". It never calls `trustDeviceSession`. The fake-success path exists only on `settingsProvider`, which privacy/safety settings use for other methods — not trust.
- **Status:** No user-facing trust control to hide. Leftover no-op stays until the backend ships `POST /sessions/{id}/trust`.

### [MEDIUM] O-10 — Seven complete, working screens are built but routed from nothing
- **Shipped:** Safety Center island + Likes you (see Fixed).
- **Still unrouted:** `message_search_screen.dart`, `call_history_screen.dart` (broken compile if reached), `accessibility_settings_screen.dart` (fake persist). Do not route the last two without fixing them.

### [HIGH] O-11 — Two large orphaned profile implementations shadow the wired ones
- **Status:** **Done** — both files deleted after a field diff against the wired pages (see Fixed).

### [MEDIUM] O-12 — 38 duplicated screens across `lib/screens`, `lib/pages`, and `lib/features/**/presentation/screens`
- **Status:** **Done** for stubs (107 files) and unused working copies of routed screens (see Fixed). Aliases kept: `screens/settings_screen.dart` export, `features/.../subscription_management_screen.dart` typedef.

### [LOW] O-13 — Dead community-forum endpoint constants
- **Status:** **Done** — constants removed (see Fixed).

### [LOW] O-14 — Dead clipboard handler in the wired 2FA screen
- **Status:** **Done** — Copy all wired to backup codes (see Fixed).

---

## Live-path CRITICALs (domain audits, not yet fixed)

These are reachable from `main.dart` and break core product loops. Independently reported by two or more sweeps where noted. The purchase-token bug is **already fixed** as F-5.

### Auth & account

| ID | Severity | Problem | Where |
| --- | --- | --- | --- |
| C-1 | FIXED | Dio `validateStatus` treats every 4xx as success, so the 401/403 `onError` branch never runs. Banned users are never sent to `/account-banned`. | see Fixed |
| C-2 | FIXED | Forgot-password / OTP always throws on success: backend returns no `data` key; client gates on `response.data != null`. | see Fixed |
| C-3 | CRITICAL | Backend accepts hardcoded verification code `123456` for any unverified email. No environment guard. | `AuthController.php:2459-2482` |
| C-4 | FIXED | Change password posts `current_password`/`password`; backend requires `old_password`/`new_password`. Always 422. | see Fixed |
| C-5 | FIXED | Change email posts `{email}` and shows a verification dialog before the request succeeds; backend requires `new_email` + `password`. | see Fixed |
| C-6 | FIXED | 2FA QR / verify step is behind `if (_isEnabled)` while enable sets `_isEnabled = false`. Setup can never complete. | see Fixed |
| C-7 | HIGH | `POST /auth/refresh` does not exist. Sanctum has no refresh tokens. Every 401 becomes a wasted round-trip then logout. | `dio_client.dart:280-369` |
| C-8 | HIGH | Splash 8-second escape hatch calls `_goToWelcome(clearTokens: true)` and wipes a valid session on a slow network. | `splash_page.dart:141-145` |
| C-9 | HIGH | 60-minute profile-completion token is stored as the primary auth token; expired token traps the user in the wizard with no exit. | `auth_service.dart:97-107`, `app_router.dart:188-212` |
| C-10 | HIGH | Privacy/safety toggles PUT `/privacy/settings` and `/user/settings` — neither write route exists. | `api_endpoints.dart:208`, `settings_service.dart:34-80` |
| C-11 | HIGH | Notification settings: 16 toggles, `setState` only, never load or save. Live from Settings → Alerts. | `notification_settings_screen.dart` |

### Discover & matching

| ID | Severity | Problem | Where |
| --- | --- | --- | --- |
| C-12 | FIXED | Match celebration never fires. Backend returns `is_match` with no `match` object; every Flutter call site does `if (match == null) return`. Independently confirmed by two discover sweeps. | see Fixed |
| C-13 | FIXED | Pusher `new.match` is dropped (`contains('Match')` is case-sensitive; payload is `matched_user` not `user_id`). Passive side of a match gets no UI. | see Fixed |
| C-14 | HIGH | Failed like/superlike is never rolled back or retried; card is gone forever. "Will send when reconnected" has no queue. | `discover_cache_provider.dart:432-498` |
| C-15 | HIGH | Fetch truncates the page to remaining swipe quota then advances `nextPage`, permanently skipping candidates. | `discovery_service.dart:140-175` |
| C-16 | HIGH | Rewind is sold as premium but has no button on the live action row. | `discovery_page.dart:1192-1211` |
| C-17 | HIGH | `/likes/matches` double-unwraps the envelope and `Match.fromJson` expects `user_id`/`avatar` the API does not send — match list empty, `userId == 0`. | `likes_service.dart:126-173`, `match.dart:33-73` |

### Payments (remaining after F-5)

| ID | Severity | Problem | Where |
| --- | --- | --- | --- |
| C-18 | FIXED | `completePurchase()` only runs after backend success. Combined with remaining validation bugs, Google auto-refunds after 3 days. | see Fixed |
| C-19 | FIXED | Client sends `package_name: com.lgbtfinder`; backend default is `com.lgbtfinder.app` and hard-rejects mismatches. | see Fixed |
| C-20 | FIXED | Superlike packs: client omits required `payment_method` (always 422); backend grants packs with no payment verification. | see Fixed |
| C-21 | HIGH | "Subscription successful!" fires when the Play sheet *opens*, not when payment completes. | `initiate_google_purchase_use_case.dart:25-33` |
| C-22 | HIGH | Selected billing period is never passed to Play — user is always charged offer index 0. | `google_play_billing_service.dart:531-572` |
| C-23 | HIGH | `purchaseStream` is not subscribed at app start — out-of-band purchases are lost. | `google_play_billing_provider.dart:35-45` |

### Chat & realtime

| ID | Severity | Problem | Where |
| --- | --- | --- | --- |
| C-24 | FIXED | `config/broadcasting.php` reads `BROADCAST_DRIVER` (Laravel 12 uses `BROADCAST_CONNECTION`). Live `.env` also redefines `BROADCAST_DRIVER=log` later, so last-wins kills Pusher. Chat, calls, and matches all silent. | see Fixed |
| C-25 | HIGH | Chat page polls full 30-message history every 8s even when Pusher is healthy. | `chat_page.dart:370-418` |
| C-26 | HIGH | Typing indicator POSTs once per keystroke into `throttle:60,1`. | `chat_page.dart:500-530` |
| C-27 | HIGH | Own-message echo duplicates media (dedupe by text, not `client_id`/`id`). Pusher subscriptions survive logout. | `chat_page.dart:436-444`, `cache_invalidator.dart:29-75` |
| C-28 | HIGH | Read receipts never sent for messages that arrive while the thread is open. | `chat_page.dart:991-999` |

### Calls & push

| ID | Severity | Problem | Where |
| --- | --- | --- | --- |
| C-29 | CRITICAL | Backend has no Agora credentials (`AGORA_*` / admin settings empty) → `/calls/{id}/agora-token` is 503. Flutter now prefers the App ID from the token payload when credentials exist. | backend `.env`, Admin → Settings |
| C-30 | FIXED | Hand-rolled Agora token builder does not match AccessToken 006. Even with credentials, `joinChannel` fails. | see Fixed |
| C-31 | FIXED | FCM token is never POSTed (`setApiService` never called; `_getFCMToken` never sends). Endpoint `/notifications/register-device` does not exist. Push is dead. | see Fixed |
| C-32 | FIXED | FCM background handler is a log-only no-op. Background/terminated devices never ring. | see Fixed |

### Not yet audited

- *(none — UI vs design system completed)*

---

## Suggested order (revised)

Live-path bugs first; stub deletion still the cheapest analyzer win.

1. ~~C-24 broadcasting~~ **done**
2. ~~C-2, C-4, C-5, C-6 account recovery~~ **done**
3. ~~C-12 + C-13 match celebration + `new.match`~~ **done**
4. ~~C-18, C-19, C-20 remaining payments~~ **done** (token was F-5)
5. ~~C-31, C-32 push; C-30 Agora token format; C-29 App ID from API~~ **code done** — **C-29 still needs live Agora credentials**
6. ~~C-1 Dio 4xx semantics~~ **done**
7. ~~Delete the 107 stub files~~ **done**
8. ~~O-8~~ skipped (needs live Agora credentials). ~~O-9~~ already no trust UI. ~~O-10 Safety Center + Likes you~~ **done** (3 leftover screens still unrouted).
9. ~~O-11 unused profile editors~~ **done**
10. ~~O-12 / O-13 / O-14~~ **done**

---

## UI vs design system (live screens only)

Completed by [UI vs design system](f83dcef0-3c63-48cb-9fc4-7acc0481abdc). Spec: `UI-DESIGN-SYSTEM.md` + `Enhanced-Flutter-UI-Document.md`. SVG icons and loading/empty states on most tabs are already in place. Highest-impact gaps:

| ID | Severity | Problem |
| --- | --- | --- |
| U-1 | CRITICAL | Chat header call/info/back targets are 32–36px (spec ≥44). `chat_header.dart:46-90` |
| U-2 | CRITICAL | Reply-cancel is an 18px Material `Icons.close` with zero constraints. `message_reply_widget.dart:80-87` |
| U-3 | HIGH | Live palette is zinc/rose (`#18181B`, `#F43F5E`); docs specify near-black + electric purple `#8A2BE2`. Product decision: remap colors or rewrite the docs. |
| U-4 | HIGH | Discover action row is 3 buttons (dislike/superlike/like), not the spec 4 (includes Message) and uses wrong fills. |
| U-5 | HIGH | Discover feed failure looks like “nobody nearby” — no error+retry. |
| U-6 | HIGH | Match celebration (overlay + `MatchScreen`) does not match spec 4.5; second copy ignores Reduce Motion. |
| U-7 | HIGH | Welcome, chat list, profile stats, and bubble timestamps diverge from screens 4.1 / 4.3 / 4.4. |
| U-8 | HIGH | Status-bar icons are always `Brightness.light` (`main.dart:109-114`), so light mode is light-on-light. |

Do **not** treat U-3/U-4/U-6 as bugs until product confirms the design docs are still canonical — the live zinc/rose system is internally consistent. Touch-target and Reduce Motion items (U-1, U-2, U-8, typing dots) are unambiguous a11y fixes.
