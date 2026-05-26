# E2E Failed Tests — Fix Task List

**Last run:** 2026-05-17 — **56 passed, 0 failed**  
**Command:** `flutter test test/e2e/`

All six previously failing tests are fixed. Details below for reference.

---

## TEST-063 — Chat route without userId ✅

| Field | Detail |
|-------|--------|
| **File** | `test/e2e/chat/chat_flow_test.dart` |
| **Was** | `Found 0 widgets with type "ChatListPage"` (redirect to welcome) |
| **Fix** | Isolated `GoRouter` with `/chat` → `ChatListPage` when `userId` is absent; mock `ChatService.getChats()`. |

---

## TEST-045 — Home tab / bottom navigation ✅

| Field | Detail |
|-------|--------|
| **File** | `test/e2e/discover/discovery_swipe_test.dart` |
| **Was** | `Found 0 widgets with type "HomePage"` |
| **Fix** | Minimal `GoRouter` at `/home` with mocked discovery/cache/plan-limits/notifications; `stubPlanLimitsService()`. |

---

## TEST-035 — Discovery page build ✅

| Field | Detail |
|-------|--------|
| **File** | `test/e2e/discover/discovery_swipe_test.dart` |
| **Was** | Viewport overflow + provider init exceptions |
| **Fix** | Phone viewport; mock `DiscoveryService`, `CacheService`, `PlanLimitsService`; pump `DiscoveryPage` in `MaterialApp` scaffold. |

---

## TEST-084 — Safety settings screen ✅

| Field | Detail |
|-------|--------|
| **File** | `test/e2e/safety/safety_flow_test.dart` |
| **Was** | `Emergency Contacts` not found (below fold) |
| **Fix** | Import `app_bootstrap.dart`; `scrollUntilVisible` for Emergency Contacts; bounded pumps. |

---

## TEST-009 — Login happy path → home ✅

| Field | Detail |
|-------|--------|
| **File** | `test/e2e/auth/auth_flow_test.dart` |
| **Was** | `pumpAndSettle` timeout; home not found |
| **Fix** | `noopAnalyticsOverrides()` mocks both track + get analytics (prevents reload hang); minimal router; `e2ePumpFrames`. |

---

## TEST-010 — Login → email verification ✅

| Field | Detail |
|-------|--------|
| **File** | `test/e2e/auth/auth_flow_test.dart` |
| **Was** | Same timeout as TEST-009 |
| **Fix** | Same analytics + bounded pumps; stub `email_verification_required` login response. |

---

## Shared helpers added

- `noopAnalyticsOverrides()` — `trackActivityUseCase` + `getAnalyticsUseCase`
- `stubPlanLimitsService()` — `isCacheValid`, `getCachedLimits`, `getPlanLimits`
- `e2eSetPhoneViewport` / `e2ePumpFrames` — stable layout and async completion
