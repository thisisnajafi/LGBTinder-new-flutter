# Auth Check Migration: Splash-Only Token Check

## Goal

Remove the dedicated **AuthCheckScreen** and perform token validation on the **Splash** screen. If the user has a valid token (verified by a backend endpoint), redirect to **Home**; otherwise redirect to **Welcome**.

## Why

- **Auth check as a screen** adds an extra route and a full-screen “Checking…” state. Users see Splash → AuthCheck (same-looking screen) → Welcome/Home, which is redundant.
- **Splash can do the check**: after a short delay, call a lightweight backend **token-check** endpoint; on 200 → Home, on 401/error → Welcome. One less screen and a simpler flow.

## Architecture After Migration

```
Splash (/) 
  → delay (e.g. 600ms) 
  → if no token in storage → Welcome
  → else GET /auth/check-token (Bearer token)
      → 200 → Home
      → 401 / timeout / error → clear token, Welcome
```

No `/auth-check` route. No AuthCheckScreen.

---

## Task 1: Backend – Token check route

**Goal:** Add a lightweight endpoint that validates the Bearer token and returns 200 if valid, 401 if not.

**Backend (Laravel):**

- **Route:** `GET /api/auth/check-token`
- **Middleware:** `auth:sanctum` (Sanctum will return 401 if token missing/invalid)
- **Response:** `200` with minimal body e.g. `{ "valid": true }` (or `204 No Content`)

**Files to touch:**

- `lgbtinder-backend/routes/api.php` – add route (closure or controller method).
- Optionally `AuthController::checkToken()` – if using controller.

**Acceptance:**  
- Valid Bearer → 200.  
- No/invalid Bearer → 401.

---

## Task 2: Flutter – API endpoint and client

**Goal:** Flutter knows the new endpoint and can call it with the stored token.

**Flutter:**

- In `lib/core/constants/api_endpoints.dart` add:
  - `static const String authCheckToken = '/auth/check-token';`
- Use existing Dio client (with auth interceptor that adds Bearer token) to call `GET authCheckToken`. No new service required if Dio already attaches the token from storage.

**Acceptance:**  
- App can call `GET /api/auth/check-token` with Authorization header.

---

## Task 3: Splash – Perform check and redirect

**Goal:** Splash screen (and only Splash) decides: redirect to Home or Welcome based on token + backend check.

**Flutter:**

- In **Splash** (e.g. `lib/pages/splash_page.dart`):
  - After the initial delay (e.g. 600ms), in a post-frame callback:
    1. Read token from storage (or use existing `TokenStorageService.isAuthenticated()` for “has token?”).
    2. If no token → `context.go(AppRoutes.welcome)`.
    3. If token exists → call `GET /auth/check-token` (with timeout, e.g. 3–4s).
       - On 200 → `context.go(AppRoutes.home)`.
       - On 401 / timeout / error → clear tokens (in background), `context.go(AppRoutes.welcome)`.
  - Use `mounted` checks and a single “redirect done” flag to avoid double navigation.
  - Keep a safety timeout (e.g. 5s) after which you force redirect to Welcome if something hangs.

**Acceptance:**  
- Logged-in user (valid token) → Splash → Home.  
- No token or invalid token → Splash → Welcome.  
- No ANR: no heavy work on UI thread; timeouts and background token clear.

---

## Task 4: Remove AuthCheckScreen and `/auth-check` route ✅

**Goal:** Delete the dedicated auth-check screen and route so the app never navigates to `/auth-check`.

**Flutter (done):**

- Removed route **`/auth-check`** and its `AuthCheckScreen` builder from `lib/routes/app_router.dart`.
- Splash no longer goes to auth-check; it goes to Welcome or Home directly.
- Deleted file `lib/screens/auth/auth_check_screen.dart`.
- Updated **redirect loop guard**: if the app used “never go back to `/auth-check`” logic, remove references to `authCheck` in that guard (only splash `/` might need guarding).
- **markStartupFlowLeft()** is called from Splash when redirecting to Welcome or Home.

**Acceptance:**  
- No references to AuthCheckScreen or `/auth-check`.  
- Splash is the only place that does token check and redirect.

---

## Task 5: Docs and logging

**Goal:** Document the new flow and keep logging for debugging.

**Flutter:**

- In `lib/core/utils/app_logger.dart` (or existing logging), ensure:
  - Splash logs when it starts token check, when it gets 200 vs 401/error, and when it redirects to Home vs Welcome.
- In this doc or README: “Startup: Splash checks token via GET /auth/check-token; valid → Home, invalid → Welcome.”

**Acceptance:**  
- Logs make it clear whether Splash went to Home or Welcome and why.

---

## Summary

| Task | Description |
|------|-------------|
| 1 | Backend: add `GET /auth/check-token` (auth:sanctum), return 200 when valid |
| 2 | Flutter: add `authCheckToken` endpoint constant; use Dio to call it |
| 3 | Splash: after delay, if no token → Welcome; else call check-token → 200 Home, else Welcome |
| 4 | Remove AuthCheckScreen and `/auth-check` route; update redirect guard |
| 5 | Document and add/keep logs for Splash token check and redirect |

---

## Rollback

If issues arise:

- Re-add route `/auth-check` and `AuthCheckScreen` that calls existing logic (token + GET /user).
- Revert Splash to only “delay then go to auth-check”.
- Backend route `GET /auth/check-token` can remain; it is harmless.
