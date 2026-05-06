# User Flow Smoke Test Checklist

## Scope
Validate end-to-end user journeys after router/auth/role/upsell changes.

## Preconditions
- App builds and launches successfully.
- Test account exists for each tier: `basid`, `silder`, `golden`.
- Backend APIs and push/deep-link handlers are available.

## Core Journey Checklist

- [ ] Launch app -> `Splash` routes to expected destination (welcome/home).
- [ ] Unauthenticated user cannot open protected paths (`/home/*`, `/chat`, `/subscription-plans`, `/feature-locked`).
- [ ] Protected deep-link destination is resumed after login (pending-intent flow).
- [ ] Legacy links are normalized (`/help`, `/discover`, `/profile/:id`, `/chat/:id`, `/matches/:id`).
- [ ] `/help` opens `HelpSupportScreen` correctly.

## Auth + Onboarding

- [ ] Welcome -> Login works for valid account.
- [ ] Email verification required flow routes to `email-verification`.
- [ ] Profile completion required flow routes to `profile-wizard`.
- [ ] Successful login routes to home and records analytics events.

## Tier + Paywall

- [ ] Basid hitting premium feature opens `FeatureLockedScreen`.
- [ ] `FeatureLockedScreen` CTA opens `SubscriptionPlansScreen`.
- [ ] `Compare tiers` opens `TierComparisonScreen`.
- [ ] Silder can access silder-level gated features.
- [ ] Golden can access all gated features.

## Empty States + Escalation

- [ ] Empty Matches shows CTA to discovery + `Contact support`.
- [ ] Empty Notifications shows CTA to discovery + `Contact support`.
- [ ] Subscription status error state shows retry + `Contact support`.

## Subscription

- [ ] Subscription status screen shows current plan and state.
- [ ] Upgrade flow from plans works (or fails gracefully with clear message).
- [ ] Purchase success routes/refresh behavior is correct.

## Analytics (Funnel Events)

- [ ] `auth_view`, `auth_submit`, `auth_success` emitted.
- [ ] `paywall_view`, `paywall_cta`, `paywall_dismiss` emitted.
- [ ] `tier_compare_view`, `tier_compare_cta` emitted.
- [ ] `plans_view`, `plans_cta_subscribe`, purchase outcome events emitted.

## Result

- [ ] PASS
- [ ] FAIL (attach issues and reproduction steps)

