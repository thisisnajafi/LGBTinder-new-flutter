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

