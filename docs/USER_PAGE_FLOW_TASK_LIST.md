# User Flow Improvement Task List (Step-by-Step)

## Objective
Align page flow, auth protection, and role visibility (`basid`, `silder`, `golden`) into a consistent, market-ready user journey.

---

## Phase 1 - Discovery and source-of-truth

- [x] **Task 1.1** Audit all current pages and screens.
- [x] **Task 1.2** Build the current-state user flow canvas.
- [x] **Task 1.3** Identify route mismatches and missing links.
- [x] **Task 1.4** Define auth/public policy for each route.
- [x] **Task 1.5** Define role visibility policy for basid/silder/golden.

Deliverable:
- `docs/USER_PAGE_FLOW_CANVAS.md`

---

## Phase 2 - Router hardening (start implementation)

- [x] **Task 2.1** Create a single route access policy map (`route -> public/auth/role`).
- [x] **Task 2.2** Implement global auth guard in `lib/routes/app_router.dart`.
- [x] **Task 2.3** Normalize route names used by deep-link and push handlers.
- [x] **Task 2.4** Add fallback for unknown/legacy route strings.
- [x] **Task 2.5** Add post-login intent resume handling.
- [x] **Task 2.6** Remove redundant per-route auth redirects (use global guard).
- [x] **Task 2.7** Add tests for legacy route mapping and pending-intent resume.

Acceptance criteria:
- Unauthenticated users cannot enter protected pages.
- Deep links always resolve to valid routes.
- Intended target opens after successful login.

---

## Phase 3 - Role gating and monetization readiness

- [x] **Task 3.1** Add `UserTier` enum and parser (`basid`, `silder`, `golden`).
- [x] **Task 3.2** Add role guard helpers (`canAccess(feature/page)`).
- [x] **Task 3.3** Gate premium-only pages/features by role.
- [x] **Task 3.4** Add `FeatureLockedPage` upsell for restricted actions.
- [x] **Task 3.5** Add tier comparison page and upgrade CTA placements.

Acceptance criteria:
- Each restricted flow has deterministic guard behavior.
- Basid users see upgrade prompts, not silent failures.

---

## Phase 4 - UX completion pages

- [x] **Task 4.1** Add empty-state journey pages (no matches/chats/notifications).
- [x] **Task 4.2** Add subscription status summary page.
- [x] **Task 4.3** Add support escalation entry points in empty/error states.
- [x] **Task 4.4** Add analytics events across funnel stages (auth, discovery, paywall, subscribe).

Acceptance criteria:
- No dead-end screens in primary user journey.
- Funnel events exist for product/marketing optimization.

---

## Phase 5 - QA and release readiness

- [x] **Task 5.1** Add navigation and guard unit/widget tests.
- [x] **Task 5.2** Add deep-link integration tests.
- [x] **Task 5.3** Add role matrix test coverage.
- [ ] **Task 5.4** Run smoke test checklist for all major journeys. (attempted; blocked by dependency mirror 402)
- [x] **Task 5.5** Create release notes for flow changes.

Acceptance criteria:
- All critical user journeys pass test checklist.
- Auth and role regressions are blocked by automated tests.

---

## Started step-by-step progress

### Step 1 (completed now)
- Current flow and full page inventory documented.
- Auth and role policy defined.
- Missing page and missing route gaps identified.

### Step 2 (in progress)
- Implemented base route access policy and global auth guard in router.
- Normalized deep-link route strings to valid `GoRouter` paths.
- Added fallback handling for legacy links in router redirects.
- Added post-login intent resume handling for protected destinations.
- Next: remove duplicate route-level auth checks and add route-guard tests.

---

## Multi-Task Page Audit Backlog (Issues, Missings, Enhancements)

This section is the next audit pass from start-to-end user flow, grouped into executable task batches.

### Batch A - Startup/Auth funnel (highest conversion impact)

- [x] **A1 Splash/auth-state guard consistency**
  - **Issues:** auth check is token-only; onboarding/profile-complete states can bypass intended flow.
  - **Missing:** explicit user-state routing contract (`email_verification_required`, `profile_completion_required`, ready).
  - **Enhancement:** enforce state-aware redirect policy centrally in router/startup service.
  - **Result (implemented):**
    - Added auth-stage model in router: `unauthenticated`, `profileCompletion`, `authenticated`.
    - Protected-route redirect now allows profile-completion users into `profile-wizard`/`onboarding-preferences` and prevents entering main app pages until completion.
    - Authenticated users visiting auth-entry pages are redirected to home (unless pending protected target exists).
    - File updated: `lib/routes/app_router.dart`.

- [x] **A2 Email verification hardening**
  - **Issues:** verification screen has insecure UX artifact (`123456` default code) and back-flow mismatch.
  - **Missing:** origin-aware back behavior (login vs register), strict email presence validation.
  - **Enhancement:** add verification attempt/success/failure analytics + resend throttling UX.
  - **Result (implemented):**
    - Removed hardcoded default verification code and removed prefill behavior from input fields.
    - Back action is now origin-aware: returns to register for new users and login for existing users.
    - Added email presence guard: if email query param is empty, user is redirected to welcome with error snackbar.
    - File updated: `lib/screens/auth/email_verification_screen.dart`.

- [x] **A3 Profile-wizard/onboarding token alignment**
  - **Issues:** profile completion routes can dead-end when only profile-completion token exists.
  - **Missing:** consistent token contract between auth service and route guards.
  - **Enhancement:** draft autosave + step-dropoff telemetry.
  - **Result (implemented):**
    - Unified profile-completion token handling in auth service across login and email verification paths.
    - Profile-completion flows now persist both `auth_token` and `profile_completion_token` to avoid branch-dependent auth-state drift.
    - File updated: `lib/features/auth/data/services/auth_service.dart`.

- [x] **A4 Auth page validation + nav normalization**
  - **Issues:** weak email/password validation and mixed `Navigator`/`GoRouter` patterns.
  - **Missing:** consistent route-first navigation style across welcome/login/register.
  - **Enhancement:** improve conversion copy and CTA tracking at each auth step.
  - **Result (implemented):**
    - Strengthened email validation in login/register using `EmailValidator` instead of `contains('@')`.
    - Replaced auth-page cross-navigation with `GoRouter` route-based navigation (`AppRoutes.login` / `AppRoutes.register`).
    - Normalized register -> email-verification transition to typed URI query parameters instead of raw route string concatenation.
    - Files updated: `lib/screens/auth/login_screen.dart`, `lib/screens/auth/register_screen.dart`.

### Batch B - Core app tabs (engagement and retention impact)

- [x] **B1 Home shell route synchronization**
  - **Issues:** `IndexedStack` tab state and route tree can drift.
  - **Missing:** route<->tab sync mechanism.
  - **Enhancement:** shell-route architecture for deterministic back/deep-link behavior.
  - **Result (implemented):**
    - Refactored home tab selection to be route-driven (`GoRouterState.matchedLocation`) instead of local mutable tab state.
    - Tab taps now navigate to canonical tab routes (`/home/discovery`, `/home/chat-list`, `/home/notifications`, `/home/profile`, `/home/settings`) using `context.go(...)`.
    - `IndexedStack` index now derives from current route, keeping deep-link/back behavior consistent with visible active tab.
    - File updated: `lib/pages/home_page.dart`.

- [ ] **B2 Discovery superlike and empty-journey quality**
  - **Issues:** superlike message collected but not actually sent.
  - **Missing:** robust empty deck path (adjust filters, increase radius, retry with reason).
  - **Enhancement:** pre-limit upsell nudges (not only hard stop).

- [ ] **B3 Chat reliability + route correctness**
  - **Issues:** sender-state race (`currentUserId` async timing), invalid profile navigation patterns.
  - **Missing:** completed implementations for media/pinned/filter actions.
  - **Enhancement:** route-consistent chat open flow + premium gating for call/media features.

- [ ] **B4 Notifications pagination and count consistency**
  - **Issues:** pagination incomplete (`_currentPage` flow), unread sync risks after read/delete.
  - **Missing:** deterministic pagination + provider invalidation strategy.
  - **Enhancement:** richer empty-state reactivation CTAs and prioritized notification routing.

- [ ] **B5 Profile/profile-detail data fidelity**
  - **Issues:** trust indicators and labels partially placeholder/ID-based.
  - **Missing:** full reference-data mapping for jobs/interests/languages.
  - **Enhancement:** premium-aware profile actions and verification funnel polish.

### Batch C - Settings, premium, support, legal, payments (monetization/compliance)

- [ ] **C1 Canonical route coverage for support/legal/subscription-management**
  - **Issues:** several real screens are not first-class routable paths.
  - **Missing:** explicit routes for support tickets, terms, privacy, subscription management.
  - **Enhancement:** deep-linkable support/legal compliance endpoints.

- [ ] **C2 Subscription status/management action correctness**
  - **Issues:** status page action currently routes to plans instead of management.
  - **Missing:** clear “status vs manage” separation in UX.
  - **Enhancement:** provider-aware management flow by payment source.

- [ ] **C3 Tier-driven premium page behavior**
  - **Issues:** many premium pages still operate as binary premium/non-premium.
  - **Missing:** explicit `basid/silder/golden` page-level visibility rules.
  - **Enhancement:** dynamic tier matrix/features from backend limits instead of static copy.

- [ ] **C4 Help/support trust fixes**
  - **Issues:** live chat still placeholder; email fallback message is misleading in edge cases.
  - **Missing:** clear escalation linkage between contact form and tickets.
  - **Enhancement:** add one-click “Create ticket” fallback on support send failure.

- [ ] **C5 Payment flow compliance hardening**
  - **Issues:** placeholder payment method/token patterns are non-production-safe.
  - **Missing:** provider SDK tokenization-only flow and secure payment method lifecycle.
  - **Enhancement:** unify billing history and methods with one canonical API source.

### Batch D - QA rollout tasks per page-flow

- [ ] **D1 Expand guard/navigation tests**
  - Add page-flow tests for startup->auth->home transitions and protected redirects.

- [ ] **D2 Add page-level role matrix tests**
  - Validate page visibility/actions for `basid`, `silder`, `golden`.

- [ ] **D3 Execute runtime smoke in 3 profiles**
  - Run full checklist with basid/silder/golden accounts and attach evidence log.

- [ ] **D4 Release candidate verification**
  - Final check: route table consistency, analytics event integrity, no dead-end states.

