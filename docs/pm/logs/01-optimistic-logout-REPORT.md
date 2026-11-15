# Run 1/5 — Optimistic, instant logout

**Date:** 2026-11-15  
**Branch:** `fix/optimistic-logout-call-blackscreen`  
**Scope:** Logout must feel instant; network/cleanup never blocks UI navigation.

## Root cause (exact awaits before this change)

Owner baseline: Settings → Log out → confirm → Settings stayed ~**3.4 s** before welcome; `POST /api/auth/logout` itself was only **414 ms**. The rest was local/blocking work on the critical path.

### Sequence on tap (old)

| Step | Where | Await? | Typical cost |
| --- | --- | --- | --- |
| Confirm dialog closes | `settings_page._confirmLogout` | yes (dialog) | UI |
| `authProvider.logout()` | `auth_provider.dart` | **yes, full chain** | — |
| `isLoading: true` | AuthProvider | sync | — |
| Unregister FCM device | `AuthService.logout` → DELETE notifications | **await**, timeout 6s | 0–6s |
| `POST /auth/logout` | AuthService | **await**, timeout 6s | ~0.4s (measured) / up to 6s |
| `PushNotificationService.clearOnLogout` (topics + `deleteToken`) | AuthService `finally` | **await**, timeout 6s | often **1–3s+** on emulator |
| `TokenStorage.clearAllTokens` + Dio clear | AuthService `finally` | await | fast |
| `clearAllTokens` again | AuthProvider | await | redundant |
| `CacheInvalidator.purgeAll` (SQLite chat, outbox, Hive/session, image cache, call history, provider resets) | AuthProvider | **await** | often **1–2s+** |
| Set `isAuthenticated: false` | AuthProvider | sync | **only then** router/UI can leave |
| `context.go(welcome)` | settings_page | after logout returns | — |

Dio defaults: connect/receive/send **60s** (logout itself used a **6s** per-call timeout). Pusher disconnect was *not* on this path (it ran later via `sessionServicesProvider` when auth flipped). Google `signOut` was **not** called on logout before.

**Entry points** (all went through `authProvider.logout`):

- `settings_page.dart` (confirm → await logout → `go` welcome)
- `banned_account_screen.dart` (await silent logout → `go`)
- `delete_account_screen.dart` (`_clearLocalData` → silent logout)
- `session_side_effects_host.dart` (401: `go` welcome first, then silent logout)
- `ProfileSettings.onLogout` callback only (no in-repo wire-up beyond the widget API)

## Design (implemented)

1. **Single path:** `AuthProviderNotifier.logout` for every UI/401 entry; `AuthService.logout` is remote-only (captured bearer + FCM device token).
2. **Critical path (local only):**
   - Capture bearer + FCM device token
   - Set `AuthProviderState` logged-out immediately (`isLoading: false` — no spinner)
   - Clear Dio header + secure storage tokens
   - Sync `CacheInvalidator.resetInMemorySessionState()` (no disk I/O)
   - Return → Settings/`go` welcome within one frame after local clear
3. **Background (`unawaited`, ~7s per step, errors logged never rethrown):**
   - Remote unregister + `POST /auth/logout` with **explicit** `Authorization: Bearer <captured>` and `extra.skipUnauthorizedHandler`
   - FCM `clearOnLogout`
   - Google `signOut` (if service present)
   - CallKit `endAllCalls` + Agora `dispose` (**Android/iOS only** — desktop tests hang on missing channels)
   - Full `purgeAll` disk/cache
4. **Re-entrancy:** session epoch bumped on logout start and on login; background aborts local teardown if epoch/token shows a newer session. Double logout while in-flight is a no-op.
5. **401 safety:** background logout 401 cannot refresh/redirect; `_notifyUnauthorized` already no-ops when storage token is empty.
6. **API log redaction:** `redactSensitiveBody` strips `password`, `password_confirmation`, `token`, `refresh_token`, `access_token`, `id_token` before `[API ▶]` logs.

## Files changed

| File | Change |
| --- | --- |
| `lib/features/auth/providers/auth_provider.dart` | Optimistic logout orchestration, epoch guard, background teardown |
| `lib/features/auth/data/services/auth_service.dart` | Remote logout with captured token; no local token clear |
| `lib/features/auth/data/repositories/auth_repository.dart` | Pass-through named args |
| `lib/features/auth/domain/use_cases/logout_use_case.dart` | Docs + named args (UI should use AuthProvider) |
| `lib/core/network/dio_client.dart` | `kSkipUnauthorizedHandlerExtra`, body redaction |
| `lib/core/cache/cache_invalidator.dart` | Public `resetInMemorySessionState` |
| `lib/features/settings/pages/settings_page.dart` | Comment (still await logout — now near-instant) |
| `lib/core/providers/startup_flow_provider.dart` | `markStartupFlowLeftForTest` for e2e bootstrap |
| `test/features/auth/optimistic_logout_test.dart` | **New** unit tests |
| `test/e2e/helpers/auth_helpers.dart` | stubLogout for named params + `clearInMemoryAuthHeader` |
| `test/e2e/helpers/app_bootstrap.dart` | Use `markStartupFlowLeftForTest` |
| `test/e2e/auth/auth_session_test.dart` | TEST-020 updated for optimistic API |

## Tests

### Added: `test/features/auth/optimistic_logout_test.dart`

| Case | Result |
| --- | --- |
| Local state cleared without awaiting hung network logout | PASS |
| Background logout errors swallowed | PASS |
| Late background after re-login does not wipe new session | PASS |
| Double logout is a no-op | PASS |
| Captured bearer passed to remote logout | PASS |
| `redactSensitiveBody` redacts secrets | PASS |

**Command:** `flutter test test/features/auth/optimistic_logout_test.dart` → **All tests passed (6).**

### Existing

| Suite | Result |
| --- | --- |
| `TEST-020` logout clears tokens | PASS (updated) |
| `test/unit/services/auth_service_test.dart` | **Pre-existing compile fail** (RegisterRequest/LoginRequest ctor drift) |
| `test/unit/services/dio_client_test.dart` | **Pre-existing compile fail** (`onRequest` void await) |
| `test/unit/services/auth_service_google_test.dart` | PASS (4) when run alone with the broken suites excluded |

## Analyze

`flutter analyze` on changed lib files: **no errors/warnings from this work**.  
One pre-existing **info** in `auth_service.dart:869` (`prefer_iterable_wheretype`), unrelated to logout.

## Risks

- Disk cache purge is deferred: brief window where SQLite/Hive still holds user A data until background purge (in-memory providers already reset; login also purges before activating user B).
- Background remote logout uses a captured token; if the server requires a refresh mid-call, request fails quietly (acceptable).
- CallKit/Agora teardown skipped on non-mobile hosts (tests/desktop); real Android/iOS still run it.
- Full `authProvider` + `CacheInvalidator` graph still heavy if constructed in widget tests — unit tests construct `AuthProviderNotifier` directly.

## Manual QA (emulator)

1. Log in (prod API ok). Open **Settings → Log out → confirm**.
2. **Expect:** confirm closes; welcome/login appears in **≪ 300 ms** (one frame + local storage). No spinner waiting on network.
3. Airplane mode → log out again (if you can get to settings online first): UI still leaves instantly; no error toast from background failure.
4. Log out, immediately log in as another account: no flash of previous user’s chat/discover; session stable.
5. Double-tap Log out: single navigation, no crash.
6. Optional: start a call, log out from another path if reachable — CallKit/Agora should tear down in background without blocking welcome.
7. Confirm debug logs for login no longer print plaintext `password` / tokens (`***`).

## Candidates (other optimistic UI — not implemented)

- Discover like/pass already partially optimistic in places — audit remaining awaits on swipe API.
- Block / report user: optimistic remove-from-stack with rollback snackbar.
- Chat send: already has outbox; ensure UI never waits on POST before showing bubble.
- Mute/pin conversation: local-first with server reconcile.

No other optimistic changes shipped in this run (kept isolated).
