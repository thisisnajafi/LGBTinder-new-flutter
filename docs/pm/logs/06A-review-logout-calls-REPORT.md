# 06A — Review & harden: optimistic logout + call-end black screen

Branch `fix/optimistic-logout-call-blackscreen` (not committed, not pushed, branch not switched).
Reviewed: `git diff main...HEAD` plus the working tree, against prompts 01 / 02 and their reports.

Nothing here was run on a device. Every "fixed" row is backed by an automated test; timing on a real phone is in the QA checklist.

## Outcome

- **Logout:** the earlier fix was sound on the main path. I found and fixed 7 gaps, all races around "log out, then log in again quickly" or around the 401 path, plus log-redaction holes.
- **Calls:** the duplicate-route fix was correct, but one black screen was still reachable on every Decline / caller-cancel / ring timeout, and a debug-only exception fired every time the incoming page closed. Fixed those and 7 smaller gaps.
- **Not fixed, needs a decision:** mid-session "account banned" never reaches the banned screen (B1 below). Pre-existing on `main`; I left it because the safe fix depends on backend behaviour I cannot verify.

## Findings — logout

| # | Check | Status | Where | Notes |
|---|---|---|---|---|
| L1 | No network / slow await between tap and logged-out screen | **fixed** | `auth_provider.dart:209-302` | State flip and header clear are now synchronous, before any `await`. What remains before navigation is local only: one secure-storage read, the token deletes, a synchronous provider reset. Each storage step is capped at 2 s (`:274`). The storage clear has to stay before `go(welcome)` because the route guard reads it. |
| L2 | Double tap | **fixed** | `auth_provider.dart:214-227` | Previously an `await getAuthToken()` sat before the in-flight flag, so two taps in the same frame both ran. Test: "two taps in the same frame run a single logout". |
| L3 | Session epoch: late background completion cannot wipe a new login | OK + **fixed** | `auth_provider.dart:304-398` | Epoch + token checks were already correct for tokens. Three things escaped them, fixed below (L4-L6). |
| L4 | FCM token deleted for the *new* session | **fixed** | `auth_service.dart:599-660`, `auth_provider.dart:333-346`, `push_notification_service.dart:938` | `clearOnLogout()` ran in a `finally` inside the network step with no epoch check. Re-login during a slow logout lost its push registration for the whole session (no message or call pushes). It is now an epoch-guarded step; if a re-login lands while the delete is in flight, a fresh token is fetched and registered. |
| L5 | Background cache purge overlapping the new session | **fixed** | `auth_provider.dart:162-176`, `:374-387` | A step timeout stops waiting, it does not stop the purge. `login()` now waits (max 4 s) for a purge the previous logout already started. Test asserts the order `purge 1 start/end → purge 2 start/end`. |
| L6 | `checkAuthStatus` racing logout / login | **fixed** | `auth_provider.dart:107-152` | A check that started before logout could write `isAuthenticated: true` back. Now epoch-guarded. |
| L7 | Provider invalidation: user B never sees user A data | OK | `cache_invalidator.dart` (`resetInMemorySessionState`, `purgeAll`) | In-memory reset is on the critical path; disk purge runs in background and again at login. With L5 the two can no longer interleave. |
| L8 | Background logout must not trigger the global 401 handler | OK | `dio_client.dart:254`, `:352`; `auth_service.dart` logout options | Uses the captured token with `kSkipUnauthorizedHandlerExtra`; the retry interceptor treats 401 as final. |
| L9 | Late 401 / 403 from user A's request ends user B's session | **fixed** | `dio_client.dart:277-294`, `:411-468` | A request sent before logout can return 401 after someone else logged in. It was refreshed/retried with B's token and could log B out. The failing request's bearer is now compared with the stored token (`shouldEndSessionFor`). Same rule for the banned 403. |
| L10 | Real session expiry (401) lands on welcome | **fixed** | `session_side_effects_host.dart:19-52`, `:92-100` | Pre-existing on `main`: the handler navigated to welcome *before* clearing the session. The guard treats that as "signed-in user on the login screen" and redirects back to Home, leaving the user there with a dead session. Order is now logout → navigate. Test proves both the bounce and the fix. |
| L11 | Logger redaction | **fixed** | `dio_client.dart:20-83`, `app_dio_logger.dart` | `password`, `password_confirmation`, `token`, `refresh_token`, `Authorization` were covered for top-level and nested maps only. Now also: lists of maps, key variants (`current_password`, `profile_completion_token`, `device_token`, `client_secret`…), `?token=` in logged URLs, and response/error bodies. `AppDioLogger` printed raw bodies; it is unused today but now redacts too. Headers are never logged. |

## Findings — calls

| # | Check | Status | Where | Notes |
|---|---|---|---|---|
| C1 | Lone `/call/incoming` (black screen) | **fixed** | `incoming_call_page.dart:61-104`, `call_navigation.dart:309-331` | The page removed itself only when `currentConfiguration.uri.path == /call/incoming`. That is never true: the route is pushed imperatively, so the URI still names the page underneath. After Decline, caller cancel, ring timeout or a denied permission the page stayed as an empty dark scaffold. It now checks the top of the match stack. |
| C2 | Provider notified from `dispose` | **fixed** | `incoming_call_page.dart:53-59`, `incoming_call_provider.dart:107-118` | `dispose` called `markIncomingPageOpen(false)` → `ref.notifyListeners()`. Riverpod asserts on that in debug builds, so `super.dispose()` never ran — an exception on every incoming call in QA builds. The flag still flips immediately; listeners are notified after the frame. |
| C3 | Incoming de-dup, same `call_id` from Pusher + FCM + CallKit | OK + **fixed** | `incoming_call_banner.dart:349-384`, `incoming_call_provider.dart:66-93`, `:121`, `:152` | The in-flight guard and presented-id guard were correct. Missing: memory of calls already closed. A late FCM copy, or the persisted payload read on resume, could ring a call again after Decline / cancel / timeout. Added a bounded closed-call set checked by `present` and `adoptRinging`. |
| C4 | Accept replaces incoming | OK + **fixed** | `call_navigation.dart:262-273`, `incoming_call_provider.dart:309-318` | Replacement was correct. In-app Accept did not mark the call answered or clear the persisted payload, so the next resume re-adopted the live call as "ringing" (ghost banner over the call). |
| C5 | Stale ringing payload after the app was killed | **fixed** | `incoming_call_handler.dart:101-131`, `:192-212` | The persisted invite had no age. One left from a call that ended while the app was dead rang on the next launch. It now carries a first-seen time and is dropped once older than the ring timeout + 15 s. Answered calls are unaffected. |
| C6 | Idempotent end | OK | `call_end_orchestrator.dart`, `outgoing_call_page.dart` (`_endCall`), `active_call_session_provider.dart:103` | `beginEnd` gates every path; a 404 on end counts as success. |
| C7 | `leaveCallRoutes` never pops below the call | OK | `call_navigation.dart:177-202` | Pops only while the top match is call UI; falls back to home on an empty stack or dead splash. New tests cover the in-call page and base route being left alone. |
| C8 | Duplicate in-call page | **fixed** | `call_navigation.dart:280-304`, `incoming_call_provider.dart:653`, `incoming_call_banner.dart:481` | Three "is the call page already open?" checks used the same stale URI, so a notification tap or banner tap could push a second in-call page. All use `isActiveCallRouteOnStack` now. |
| C9 | No `ref` in `dispose` | OK | all 14 `dispose` bodies under `lib/features/calls`; `lib/screens/voice_call_screen.dart:538`, `video_call_screen.dart:626` | None read `ref` (the two legacy screens are not routed). C2 was the one indirect case. |
| C10 | `ref` used after unmount | **fixed** | `outgoing_call_page.dart:215-225`, `:1137-1151` and reconnect paths | Reconnect give-up, media restore and messenger sync could run from timers / Agora callbacks after the page was gone. They now use notifiers captured in `initState`, or return when unmounted. |
| C11 | Video: `AgoraVideoView` unmounted before engine release | **fixed** | `outgoing_call_page.dart:1308-1321`, `:1530-1534` | The video layer stayed mounted while the engine was released. It is now dropped as soon as the call is leaving, and teardown waits one frame (max 300 ms, skipped in background) before releasing. |
| C12 | Hang Up from the Android ongoing-call notification while minimized | **fixed** | `outgoing_call_page.dart:1242-1252` | The handler belonged to the unmounted page: nothing told the server and the return banner stayed. It now hands off to the session provider, which outlives the page. |
| C13 | Call ended by the system while the call page is visible | **fixed** | `outgoing_call_page.dart:1256-1260`, `:1535-1543` | The page kept showing a "connected" call with a released engine until the user tapped End. It now runs the normal end UI. |
| C14 | Incoming from background / killed state | OK | `call_kit_service.dart:250-267`, `incoming_call_provider.dart` (`acceptFromCallKit`) | Reviewed with C3-C5 applied; CallKit accept still restores from extras or the persisted payload. Needs device QA. |
| C15 | In-app banner / overlay | OK | `incoming_call_banner.dart:407-447`; `lib/widgets/common/incoming_call_overlay.dart` | Banner hides while the full page is open and returns if the page closes with the call still ringing. The overlay file is deprecated dead UI that forwards to the same notifier, so it shares the de-dup. |

## Open risks

- **B1 — mid-session ban never shows the banned screen (not fixed).** `BannedHandler` navigates to `/account-banned` while the session is still stored. That route is an auth-entry route, so the guard redirects to Home, the same mechanism as L10. Clearing the session first would fix it, but a false positive in `_isBannedAccount` (any 403 whose body has `banned: true`) would then log a healthy user out, where today it does nothing. I can't rule that out without the backend. Recommendation: confirm which endpoints can return that body, then apply the same reorder.
- **Storage timeout:** if the secure-storage clear takes longer than 2 s, logout still returns and `go(welcome)` can bounce to Home once. Previously that case hung the UI instead.
- **Closed-call memory is per process.** After a restart the protection against a repeated invite is the payload age check (C5) plus CallKit's own state.
- **Redaction is by key name.** A secret sent under an unrelated key (for example an OTP in a field called `code`) is still logged in debug / development builds. `code` was left alone because it is also the error-code field in responses.
- **C11** relies on one frame being enough to detach the platform views. If a device still shows a black video surface after hang-up, raise the wait rather than remove it.

## Files changed

Source
- `lib/features/auth/providers/auth_provider.dart`
- `lib/features/auth/data/services/auth_service.dart`
- `lib/shared/services/push_notification_service.dart`
- `lib/core/network/dio_client.dart`
- `lib/core/network/app_dio_logger.dart`
- `lib/core/widgets/session_side_effects_host.dart`
- `lib/features/calls/pages/incoming_call_page.dart`
- `lib/features/calls/pages/outgoing_call_page.dart`
- `lib/features/calls/providers/incoming_call_provider.dart`
- `lib/features/calls/presentation/widgets/incoming_call_banner.dart`
- `lib/features/calls/utils/call_navigation.dart`
- `lib/shared/services/incoming_call_handler.dart`

Tests
- `test/features/auth/optimistic_logout_test.dart` (extended: 6 → 24 tests)
- `test/features/auth/session_expiry_redirect_test.dart` (new, 5)
- `test/unit/features/calls/incoming_call_dedup_test.dart` (new, 12)
- `test/widget/features/calls/incoming_call_route_hardening_test.dart` (new, 10)

## Tests and results

| Suite | Result |
|---|---|
| `test/features/auth` | 29 passed |
| `test/unit/features/calls` | 207 passed, 1 failed (pre-existing) |
| `test/widget/features/calls` | 20 passed |
| `test/widget/widgets/incoming_call_host_overlay_test.dart` | 1 passed |
| `test/routes` | 25 passed |
| `flutter analyze` on the changed files | no errors, no new warnings |

Pre-existing failures, confirmed identical on an untouched checkout of `HEAD`:
- `test/unit/features/calls/call_primary_photo_test.dart` — "prefers primary_image_url over avatar crop".
- `test/unit/services/dio_client_test.dart` — does not compile (3 × "expression has type 'void'").
- `test/unit/models/api_error_test.dart` — "shouldForceLogout returns true for 401 on protected routes".
- `test/e2e/auth/auth_session_test.dart` — 11 failures (splash / register / verification flows).
- `test/e2e/navigation/router_guards_test.dart` — 4 failures (TEST-122…125).

The four `IncomingCallPage` widget tests failed until C2 was fixed; they are what surfaced it. For C1 the test asserts the cause directly: with the incoming page on top, `currentConfiguration.uri.path` is still `/chat`, so the old self-pop condition could not be true.

## Manual QA checklist

Logout
- [ ] Settings → Log out: welcome appears with no visible wait, online and in airplane mode.
- [ ] Double-tap "Log out": one transition, no error.
- [ ] Log out as A, log in as B within 2-3 s on a slow network: B's chats/matches only; B receives a message push and an incoming-call push.
- [ ] Expire or revoke the token server-side, then use the app: it lands on welcome and stays there (previously it returned to Home).
- [ ] Debug build log during login / change password: no password, token or `Authorization` value.

Calls (repeat voice and video; caller and callee)
- [ ] Incoming call, app foreground → Decline: returns to the previous screen, no dark empty page.
- [ ] Incoming call → caller cancels while ringing: same.
- [ ] Incoming call → let it ring out: same.
- [ ] Incoming call → Accept: one in-call screen; after hang-up one back step reaches the previous screen.
- [ ] Accept, send the app to background, return: no incoming banner over the live call.
- [ ] Decline, background, return: the declined call does not ring again.
- [ ] Kill the app during an unanswered ring, reopen two minutes later: no ghost incoming screen.
- [ ] Incoming call from killed state → Accept from the system UI: lands in the call; hang-up returns Home.
- [ ] Video call hang-up from each side: no black frame / frozen video after the summary.
- [ ] Minimize a connected call, pull down the shade → Hang Up: banner disappears and the other side sees the call end.
- [ ] Minimize, then tap the return banner and the call notification repeatedly: one in-call screen only.
- [ ] Debug build: no red "Tried to modify a provider while the widget tree was building" when an incoming call closes.
