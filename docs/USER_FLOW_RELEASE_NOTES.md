# User Flow Release Notes

## Release Summary
This release delivers a complete user-flow hardening and monetization readiness pass across routing, auth protection, deep links, role gating, empty states, support escalation, and funnel analytics.

## Highlights

- Router security upgraded with global auth guard for protected routes.
- Legacy routes/deep links normalized to valid `GoRouter` destinations.
- Pending-intent resume added so users return to target page after login.
- Role model introduced: `basid`, `silder`, `golden`.
- Premium gating added for restricted features with dedicated full-screen upsell.
- Tier comparison page introduced to improve upgrade conversion.
- Empty states upgraded with actionable journeys and support escalation paths.
- Subscription status summary page added in-app.
- Funnel analytics events instrumented for conversion tracking.

## New Screens

- `FeatureLockedScreen` (`/feature-locked`)
- `TierComparisonScreen` (`/tier-comparison`)
- `SubscriptionStatusScreen` (`/subscription-status`)
- `HelpSupportScreen` routed directly (`/help-support`)

## Routing and Deep Linking

- Added robust legacy route resolver for outdated links.
- Standardized deep-link targets for chat/profile/discovery/matches.
- Updated `/help` behavior to route to actual support screen.

## QA Artifacts

- New smoke checklist: `docs/USER_FLOW_SMOKE_TEST_CHECKLIST.md`
- Added tests:
  - `test/routes/route_redirector_test.dart`
  - `test/shared/deep_linking_service_test.dart`
  - `test/shared/user_tier_test.dart`
  - `test/shared/user_tier_access_test.dart`

## Notes

- Analytics uses existing backend activity tracking endpoint via `AppEventTracker`.
- Runtime smoke execution still required on target environments/devices before release sign-off.

