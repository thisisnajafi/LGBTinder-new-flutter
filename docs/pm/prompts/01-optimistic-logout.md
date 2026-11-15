# Claude run 1/5 — Optimistic, instant logout (LGBTFinder Flutter)

You are a senior Flutter engineer working in `E:\1 - laravel\1 - LGBTinder\lgbtindernew` (Flutter 3.x, Riverpod 2, go_router 13, Dio, Pusher via `third_party/pusher_channels_flutter`, Agora `agora_rtc_engine 6.5.x`, `flutter_callkit_incoming`, Firebase Messaging). Branch `fix/optimistic-logout-call-blackscreen` is already checked out. Work deeply and carefully; this is one of a very small number of expensive runs, so finish the whole job in this run.

## Problem (owner report)
When the user taps **Logout**, the app waits for the backend `logout` HTTP request to finish before leaving the screen. On a slow or flaky network this feels frozen. Logout must feel instant.

## Goal
Logout is **optimistic**: on tap, within one frame the UI navigates to the logged-out entry (login/welcome) and the local session is gone. All network/cleanup work happens in the background and can never block, delay, or bounce the UI back.

## Files to read first (root cause before code)
- `lib/features/auth/providers/auth_provider.dart`
- `lib/features/auth/domain/use_cases/logout_use_case.dart`
- `lib/features/auth/data/repositories/auth_repository.dart`, `lib/features/auth/data/services/auth_service.dart`, `lib/features/auth/data/services/google_auth_service.dart`
- `lib/core/auth/unauthorized_handler.dart`, `lib/core/network/dio_client.dart` (401 handling / token interceptor — make sure the background logout call cannot trigger a second "session expired" navigation)
- `lib/core/cache/cache_invalidator.dart`, `lib/core/widgets/session_side_effects_host.dart`
- `lib/shared/services/push_notification_service.dart` (FCM token unregister), Pusher/socket services, `lib/shared/services/agora_service.dart`, call providers under `lib/features/calls/providers/`
- Every logout entry point: `lib/features/settings/pages/settings_page.dart`, `lib/widgets/profile/profile_settings.dart`, `lib/screens/active_sessions_screen.dart`, `lib/screens/banned_account_screen.dart`, `lib/features/settings/presentation/screens/delete_account_screen.dart`, plus anything else `rg -n "logout|signOut" lib` finds.
- The router (find the go_router config and its `redirect`/`refreshListenable` that reacts to auth state).

Write down (in the report) the exact current sequence: which awaits sit between the tap and the navigation, and how long each can take (Dio timeouts etc.).

## Required design
1. A single `logout()` orchestration path used by every entry point (no duplicated logout logic in widgets).
2. Synchronous-feeling phase (must complete before/at navigation, only local work, no network awaits):
   - capture the current bearer token / device id needed for the server call into local variables;
   - clear the in-memory auth state so the router redirect fires immediately;
   - clear secure storage tokens and per-user caches (await only fast local storage; if any local clear is slow, do it after navigation but guarantee no stale user data is shown — e.g. invalidate providers first);
   - navigate with `go`/redirect to the logged-out route, replacing the stack (no back navigation into authed pages).
3. Background phase (`unawaited`, guarded, each step with its own short timeout ~5–8 s, all errors caught and logged, never rethrown, never touching `BuildContext`):
   - POST backend logout using the **captured** token explicitly (the interceptor must not attach a newer token or trigger the global 401/unauthorized handler/navigation for this request);
   - unregister FCM token / delete FCM token server-side if that is what the app does today;
   - disconnect Pusher / sockets and unsubscribe channels;
   - end any active call and release Agora engine safely; end CallKit calls;
   - Google sign-out / disconnect if used.
4. Idempotent & re-entrant: double tap, logout while a background logout is still running, and immediately logging back in (possibly as a different user) must be safe. A late background completion must NOT clear the new session's tokens or state (use a session generation/epoch id or compare captured token).
5. Provider teardown: make sure user-scoped Riverpod providers are invalidated/disposed so user B never sees user A's data after re-login, without throwing "ref used after dispose" errors.
6. Keep the existing UX copy/confirm dialog (if there is a confirm dialog, close it first, then navigate; no spinner waiting for network). Remove any loading spinner that only existed to wait for the server.

## Optional, low-risk only
If you see obviously safe optimistic-UI wins in the same area (e.g. like/unlike, block, send message already partially optimistic), list them in the report under "Candidates"; implement only if the change is tiny, isolated, and has rollback-on-error. Do not refactor unrelated features.

## Constraints
- No backend (Laravel) changes. No changes to `pubspec.yaml` dependencies unless unavoidable (explain).
- Do not commit, push, merge, or switch branches. Do not delete files unrelated to this change. Do not touch `android/app/src/production/*`, signing, or Codemagic config.
- Keep code style consistent with the repo; no new global singletons if a provider fits.
- Never log tokens or passwords.

## Tests & verification (run them yourself)
- Add/extend unit tests (e.g. `test/features/auth/...`) proving: (a) local state is cleared and navigation/redirect happens without awaiting the network (use a fake repository whose logout never completes or takes 30 s); (b) background errors are swallowed; (c) a late background completion after re-login does not wipe the new session; (d) double logout is a no-op.
- Run `flutter analyze` on changed files (whole project analyze is fine if it finishes) and `flutter test` for the tests you added plus existing auth tests. Fix what you broke. Report pre-existing failures separately.

## Report
Write `docs/pm/logs/01-optimistic-logout-REPORT.md` with: root cause (exact awaits), design, files changed, tests added and their results, analyze result, risks, manual QA steps for the emulator (what to tap and what should happen with timings), and "Candidates" for other optimistic UI. End your final message with the line `RUN1_DONE`.

## Baseline evidence (measured 2026-11-15 on emulator, debug build, prod API)
- Settings > Log out > confirm "Log out": the confirm dialog closes, then the Settings page stays on screen for ~3.4 s before the welcome screen appears (screen recording, 5 fps).
- In the same run `POST /api/auth/logout` took only 414 ms (18:05:54.182 -> 54.596). So ~3 s of the wait is NOT the HTTP call: find every other awaited step in the logout chain (FCM deleteToken / unregister, Pusher disconnect/unsubscribe, Google signOut, secure-storage/cache/sqlite/Hive clears, provider invalidation, call teardown, analytics, etc.) and move all of it off the critical path.
- Note: debug logs print the login request body including the plaintext password (`[API >] POST /auth/login-password req: {..., password: ...}`). Redact `password`, `password_confirmation`, `token`, `refresh_token` in the API logging interceptor.
