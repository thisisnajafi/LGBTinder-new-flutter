# Splash Screen & ANR Audit Report

**Objective:** Identify issues that can block the UI thread, hang async execution, break widget lifecycle rules, or cause navigation deadlocks so the app never reaches the welcome screen.

**Scope:** Splash lifecycle, Firebase/auth init, auth check logic, navigation timing, widget disposal, UI thread blocking, Android ANR.

---

## Executive Summary

The **active** splash flow (`lib/pages/splash_page.dart` → `AuthCheckScreen`) is largely correct: splash is a StatefulWidget, no async in `build()`, auth runs in a dedicated screen with post-frame callback and timeouts. A few improvements and one critical navigation-safety fix are recommended. A **duplicate heavy splash** at `pages/splash_page.dart` (root) would cause freezes/ANR if ever used; it must not be used on the startup path.

---

## 1. Splash Screen Lifecycle Validation

### 1.1 Implemented as StatefulWidget

**Status:** ✅ **PASS**  
`lib/pages/splash_page.dart` uses `ConsumerStatefulWidget` (StatefulWidget); `lib/screens/auth/auth_check_screen.dart` uses `ConsumerStatefulWidget`.

### 1.2 No async logic inside `build()`

**Status:** ✅ **PASS**  
- Splash: `build()` only builds UI (gradient, logo, loading). No `ref.read`, no `await`, no I/O.
- AuthCheckScreen: `build()` only builds UI. `ref` is used only in `_checkAndRedirect()`, which runs from `addPostFrameCallback`, not in `build()`.

### 1.3 Auth/bootstrap only in `initState()`

**Status:** ✅ **PASS**  
- Splash: `initState()` calls `_navigateAfterDelay()` (delay + `context.go(authCheck)`). No auth I/O in splash.
- AuthCheckScreen: `initState()` schedules `_checkAndRedirect()` via `WidgetsBinding.instance.addPostFrameCallback`. Auth (token + API) runs there.

### 1.4 UI renders immediately (loading allowed)

**Status:** ✅ **PASS**  
Splash and AuthCheckScreen both return a `Scaffold` with content immediately; no `FutureBuilder` or conditional that waits on a Future before showing UI.

### 1.5 Single bootstrap method from `initState()`

**Status:** ✅ **PASS**  
Splash: only `_navigateAfterDelay()`. AuthCheckScreen: only the post-frame callback that calls `_checkAndRedirect()`.

### 1.6 Navigation timing (critical)

**Status:** ⚠️ **IMPROVEMENT**  
Splash calls `context.go(AppRoutes.authCheck)` directly after `await Future.delayed(600ms)`. That runs in an async continuation, not inside `build()`, so it is safe. For maximum safety (ensure we never navigate in the same microtask as the delay completing and that we’re after layout), navigation should be scheduled with `WidgetsBinding.instance.addPostFrameCallback`.

**Red flags checked:** No auth in `build()`, no `FutureBuilder` for navigation, no navigation before first frame in AuthCheckScreen (it uses post-frame). Splash navigates after 600ms so first frame has already rendered; adding post-frame for the go is a hardening step.

---

## 2. Firebase / Authentication Initialization

### 2.1 `WidgetsFlutterBinding.ensureInitialized()` in `main()`

**Status:** ✅ **PASS**  
`lib/main.dart` line 29: `WidgetsFlutterBinding.ensureInitialized();` is the first call in `main()`.

### 2.2 `Firebase.initializeApp()` completes before `runApp()`

**Status:** ✅ **PASS**  
`await Firebase.initializeApp()` is in a try/catch in `main()` before `runApp()`. Failures are logged and treated as non-fatal so the app still runs.

### 2.3 No Firebase/auth before init finishes

**Status:** ✅ **PASS**  
No Firebase or auth API is used before `runApp()`. Push init is deferred to 12s after first frame via `addPostFrameCallback` + `Future.delayed`.

### 2.4 Silent failures / missing await

**Status:** ✅ **PASS**  
Firebase and SharedPreferences init are awaited and wrapped in try/catch with debug logs.

---

## 3. Authentication Check Logic

### 3.1 AuthCheckScreen (active path)

**Status:** ✅ **PASS** (with minor note)  
- Uses `tokenStorage.isAuthenticated().timeout(2s, onTimeout: () => false)` — no indefinite wait.
- API check uses `dioClient.dio.get(...).timeout(4s)`.
- Guard timer (5s) and escape hatch (5s) force redirect to welcome if something hangs.
- Full try/catch; all branches redirect. No `authStateChanges().first` or stream-based indefinite wait.
- Preferred pattern (immediate token check + API validate) is followed.

### 3.2 AuthProviderNotifier constructor

**Status:** ⚠️ **MINOR**  
`AuthProviderNotifier` calls `checkAuthStatus()` in the constructor (fire-and-forget). That does not block the provider creation, but it triggers async work and `state = ...` updates during provider init. Best practice: defer with `Future.microtask(() => checkAuthStatus())` so no async work or state updates run synchronously during provider creation.

### 3.3 Unacceptable patterns

**Status:** ✅ **NONE FOUND**  
No awaiting of auth streams in splash or auth-check screen; no dependency on listeners to resolve navigation.

---

## 4. Navigation Safety and Timing

### 4.1 No navigation inside `build()`

**Status:** ✅ **PASS**  
Splash and AuthCheckScreen do not call `context.go`/push in `build()`.

### 4.2 No navigation before first frame (AuthCheckScreen)

**Status:** ✅ **PASS**  
AuthCheckScreen uses `WidgetsBinding.instance.addPostFrameCallback` before calling `_checkAndRedirect()`, so redirects happen after the first frame.

### 4.3 Splash navigation

**Status:** ⚠️ **IMPROVEMENT**  
Splash navigates after 600ms delay; first frame has long been rendered. Scheduling `context.go(AppRoutes.authCheck)` inside `addPostFrameCallback` is recommended so navigation always runs after layout and never in the same microtask as the delay completion.

### 4.4 No self-navigation or loops

**Status:** ✅ **PASS**  
Splash → auth-check → welcome or home. No redirect back to splash; no loop detected.

---

## 5. Widget Disposal and Async Safety

### 5.1 `setState()` after async

**Status:** ✅ **PASS**  
AuthCheckScreen does not call `setState` after async; it only calls `context.go` and checks `mounted`/`_redirected` before redirecting.

### 5.2 Mounted checks in async callbacks

**Status:** ✅ **PASS**  
- Splash: `if (!mounted) return` after the delay; `if (mounted)` in catch before `context.go`.
- AuthCheckScreen: `if (!mounted || _redirected) return` at every await and before every redirect; guard and escape hatch also check `mounted`.

### 5.3 Navigation after disposal

**Status:** ✅ **PASS**  
All redirects are gated by `mounted` and `_redirected`, so no navigation after disposal.

---

## 6. UI Thread Blocking

### 6.1 Splash (lib/pages/splash_page.dart)

**Status:** ✅ **PASS**  
Only `Future.delayed(600ms)` then `context.go`. No sync I/O, no heavy computation, no SharedPreferences sync, no JSON parsing.

### 6.2 AuthCheckScreen

**Status:** ✅ **PASS**  
Token and API checks are async with timeouts. Guard/escape hatch run in parallel and do not block. No sync blocking in `build()` or init.

### 6.3 Provider creation on auth-check path

**Status:** ✅ **PASS**  
`tokenStorageServiceProvider` and `dioClientProvider` only instantiate objects (no await in provider body). `ConnectivityService.initialize()` is async and not awaited in the provider; it is fire-and-forget, so it does not block the provider.

### 6.4 Duplicate heavy splash (root `pages/splash_page.dart`)

**Status:** 🔴 **CRITICAL RISK IF USED**  
File `pages/splash_page.dart` (project root, **not** `lib/pages/splash_page.dart`) contains a **heavy** splash that in `initState()` → `_initializeApp()`:

- Calls `tokenStorage.isAuthenticated()` (secure storage I/O)
- Calls `OnboardingService().isOnboardingCompleted()` and `isFirstLaunch()` (SharedPreferences)
- Calls `ref.read(userServiceProvider)` and **`userService.getUserInfo()`** (network)

All of this runs on the main isolate during startup. If this file were ever used as the splash (e.g. wrong import or route), it would:

- Block the UI thread with secure storage and SharedPreferences
- Risk ANR if network or storage is slow
- Violate “no I/O in splash” and “auth in dedicated screen”

**Current app:** Router imports `../pages/splash_page.dart` from `lib/routes/`, so it uses **`lib/pages/splash_page.dart`** (lightweight). The root `pages/splash_page.dart` is either dead code or used only by tests. Ensure no code path uses the root `pages/splash_page.dart` for the app’s initial route.

---

## 7. Android ANR and Log Analysis

### 7.1 Recommendations

- Run: `flutter run --verbose` and watch for:
  - Log output stopping after “[STARTUP] SplashPage…” or “[STARTUP] AuthCheck…”
  - “Skipped N frames” or “jank”
  - ANR / “Input dispatching timeout” in logcat
- Filter logs: `adb logcat | findstr STARTUP` (Windows) or `grep STARTUP` to follow the startup sequence.
- If the app freezes after “navigating to auth-check” or “_checkAndRedirect() started”, the hang is in token storage, Dio/API, or (if ever used) the heavy splash logic.

### 7.2 Controlled isolation test

Temporarily replace splash navigation logic with:

```dart
// In lib/pages/splash_page.dart _navigateAfterDelay():
await Future.delayed(const Duration(seconds: 1));
if (!mounted) return;
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (!mounted) return;
  context.go(AppRoutes.welcome);
});
```

- If the app then **reaches welcome** after 1s: splash and navigation are fine; the problem is in **auth-check or auth/API/token**.
- If the app **still freezes**: the problem is earlier (first frame, router, or something blocking before/during splash build).

---

## 8. Issues Summary and Fixes

### Issue 1: Splash navigation not scheduled in post-frame callback

- **Description:** After the 600ms delay, splash calls `context.go(AppRoutes.authCheck)` directly in the async continuation. It is not inside `build()` and first frame has already rendered, but navigation is not explicitly deferred to after layout.
- **Why it can matter:** In theory, navigating in the same microtask as the delay completion could interact badly with frame scheduling. Post-frame guarantees navigation runs after layout.
- **Severity:** **Minor** (hardening).
- **Fix:** Schedule the go inside `WidgetsBinding.instance.addPostFrameCallback` after the delay.

### Issue 2: AuthProviderNotifier runs async work from constructor

- **Description:** `AuthProviderNotifier` calls `checkAuthStatus()` in the constructor. That starts async work and later updates state during provider creation.
- **Why it can matter:** Can cause subtle ordering/race issues and is not best practice; it does not directly block the splash path because nothing awaits it on startup.
- **Severity:** **Minor**.
- **Fix:** Defer with `Future.microtask(() => checkAuthStatus());` in the constructor.

### Issue 3: Duplicate heavy splash at `pages/splash_page.dart`

- **Description:** A second splash at project root performs token check, SharedPreferences, and **getUserInfo()** in initState. If this widget were used as the app’s splash, it would block the UI and risk ANR.
- **Why it causes freeze/ANR:** Sync/async I/O and network on the main isolate during first screen.
- **Severity:** **Critical** if this file is ever used for the initial route; **Major** as a maintainability/risk issue.
- **Fix:** Do not use `pages/splash_page.dart` for startup. Prefer deleting it or moving its logic to a dedicated “post-login onboarding/home” screen and keeping only the lightweight `lib/pages/splash_page.dart` for splash. Ensure router and all imports use `lib/pages/splash_page.dart`.

---

## 9. Corrected Code Snippets

### 9.1 Splash: navigate in post-frame callback (lib/pages/splash_page.dart)

```dart
Future<void> _navigateAfterDelay() async {
  if (kDebugMode) debugPrint('[STARTUP] SplashPage: waiting 600ms...');
  try {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    if (kDebugMode) debugPrint('[STARTUP] SplashPage: scheduling navigation to auth-check');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (kDebugMode) debugPrint('[STARTUP] SplashPage: navigating to auth-check');
      context.go(AppRoutes.authCheck);
    });
  } catch (_) {
    if (kDebugMode) debugPrint('[STARTUP] SplashPage: delay failed, navigating to auth-check');
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.authCheck);
      });
    }
  }
}
```

### 9.2 AuthProviderNotifier: defer checkAuthStatus (lib/features/auth/providers/auth_provider.dart)

```dart
AuthProviderNotifier(
  this._authService,
  this._tokenStorage,
  this._onboardingService,
) : super(AuthProviderState()) {
  Future.microtask(() => checkAuthStatus());
}
```

### 9.3 Isolated test: force welcome after 1s (temporary)

In `_navigateAfterDelay()`, temporarily replace the body with:

```dart
await Future.delayed(const Duration(seconds: 1));
if (!mounted) return;
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (!mounted) return;
  context.go(AppRoutes.welcome);
});
```

If welcome appears, the fault is in auth-check or auth services; if not, the fault is in splash/navigation/first frame.

---

## 10. Final Goal Checklist

- [x] Splash is a StatefulWidget; no async in `build()`.
- [x] Auth/bootstrap runs only from `initState()` (and in AuthCheckScreen from post-frame).
- [x] UI renders immediately with loading indicator.
- [x] Firebase and bindings init before `runApp()`; push init deferred.
- [x] Auth check uses timeouts and guard/escape hatch; no indefinite stream wait.
- [x] Mounted checks before all redirects; no navigation in `build()`.
- [x] **Apply:** Navigate from splash via `addPostFrameCallback` (hardening).
- [x] **Apply:** Defer `checkAuthStatus()` in AuthProviderNotifier (best practice).
- [x] **Ensure:** Startup never uses root `pages/splash_page.dart`; use only `lib/pages/splash_page.dart` (duplicate heavy splash at `pages/splash_page.dart` removed).

With these applied and the heavy splash unused on the startup path, the splash flow should remain non-blocking, safe for auth, and not cause ANR on Android.

---

## 11. Redirect Loop Prevention

### Flow (no loop by design)

- **Splash** (`/`) → after 600ms → **auth-check** (`/auth-check`) → **welcome** (`/welcome`) or **home** (`/home`).
- Only `SplashPage` navigates to `/auth-check`. No other screen should call `context.go('/')` or `context.go('/auth-check')` so the app never re-enters splash/auth-check from welcome/home.
- `AuthCheckScreen` redirects at most once (`_redirected` flag) and uses `context.go()` (replaces stack), so back from welcome exits the app instead of returning to auth-check.

### Safeguards applied

- **GoRouter** `redirectLimit: 5` so go_router shows an error screen instead of looping if redirects exceed 5.
- **Billing-history route redirect**: returns `null` when `state.matchedLocation == AppRoutes.welcome` so we never redirect to welcome when already there.
- **Comments** in `app_router.dart` and `splash_page.dart`: only SplashPage may navigate to `/` or `/auth-check`.

### If a loop is suspected

1. Search for any `context.go('/')`, `context.go('/auth-check')`, or `context.go(AppRoutes.splash)` / `context.go(AppRoutes.authCheck)` outside `lib/pages/splash_page.dart` and remove or change to the correct destination.
2. Ensure `appRouterProvider` is not invalidated (no `ref.invalidate(appRouterProvider)`), so the router is not recreated and forced back to `initialLocation`.
3. Run with logs: filter for `[STARTUP]` and watch for repeated "redirecting to WELCOME" / "navigating to auth-check" in sequence.
