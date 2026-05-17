# E2E Test Run Report

**Date:** 2026-05-17  
**Command:** `flutter test test/e2e/`  
**Environment:** Windows — Flutter mirror `mirror-flutter.runflare.com` returned **402 Payment Required** during `pub get`.

## Summary

| Total | Passed | Failed | Skipped |
|-------|--------|--------|---------|
| —     | —      | —      | —       |

*Tests were authored but could not be executed in this environment.*

## Blocker

```
402 Payment Required trying to find package flutter_riverpod at https://mirror-flutter.runflare.com.
Failed to update packages.
```

**To run locally:**

1. Fix Flutter pub mirror (use official `https://pub.dev` or a working mirror).
2. `cd lgbtindernew && flutter pub get`
3. `flutter test test/e2e/`

## Suite layout (implemented)

| Path | Coverage |
|------|----------|
| `test/e2e/helpers/` | `app_bootstrap.dart`, `auth_helpers.dart`, `mock_services.dart` |
| `test/e2e/config/test_credentials.dart` | Email auth only (no Firebase phone) |
| `test/e2e/auth/auth_flow_test.dart` | TEST-005 – TEST-016, TEST-140 guard |
| `test/e2e/onboarding/profile_wizard_test.dart` | TEST-024, TEST-031, TEST-033, TEST-032 |
| `test/e2e/discover/discovery_swipe_test.dart` | TEST-035, TEST-045 |
| `test/e2e/matching/matching_flow_test.dart` | TEST-048, TEST-049 |
| `test/e2e/chat/chat_flow_test.dart` | TEST-053, TEST-055, TEST-063 |
| `test/e2e/tier_gating/tier_gating_test.dart` | TEST-064 – TEST-073 |
| `test/e2e/safety/safety_flow_test.dart` | TEST-084 – TEST-091, TEST-092 skip guard |
| `test/e2e/settings/settings_flow_test.dart` | TEST-094 |
| `test/e2e/payments/billing_flow_test.dart` | TEST-107, TEST-111, TEST-113, TEST-121 |
| `test/e2e/navigation/router_guards_test.dart` | TEST-122 – TEST-136 |

Additional TEST IDs from the plan are covered by existing unit tests under `test/routes/` and `test/shared/page_tier_rules_test.dart`, or are reserved for live API runs when `premiumEmail` / `freeEmail` are filled in.

## Skipped tests (credentials)

| Test | Reason |
|------|--------|
| TEST-092 | Requires live API + `targetUserId` |
| TEST-121 | Skipped when `apiBaseUrl` is placeholder |
| TEST-140 | Live deep-link journey — needs integration driver + full accounts |

Fill `test/e2e/config/test_credentials.dart` (`premiumEmail`, `freeEmail`, `targetUserId`) to enable tier-specific live tests.

## Flow issues found (static review)

1. **Off-router settings flows** — Many settings sub-screens still use `Navigator.push` instead of `GoRouter`; E2E must tap UI, not only canonical routes.
2. **Community forum / feeds** — Screens exist but are not in `app_router.dart` (expected per product notes).
3. **Duplicate plan screens** — `lib/screens/subscription_plans_screen.dart` vs `features/payments/.../subscription_plans_screen.dart` (router uses features path).

## Recommendations

1. Unblock Flutter pub mirror and run `flutter test test/e2e/` in CI.
2. Fill `premiumEmail` / `freeEmail` for basid/silder/golden live matrix (TEST-068, TEST-069).
3. Add `integration_test` driver for TEST-140 deep-link resume after email login.
4. Migrate remaining `Navigator.push` settings routes to canonical `AppRoutes` for testability.
