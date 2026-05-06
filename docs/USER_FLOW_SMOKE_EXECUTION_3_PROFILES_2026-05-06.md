# User Flow Smoke Execution - 3 Profiles (2026-05-06)

## Scope
- Source checklist: `docs/USER_FLOW_SMOKE_TEST_CHECKLIST.md`
- Profiles required: `basid`, `silder`, `golden`

## Execution Status
- **Overall:** BLOCKED
- **Reason:** Flutter dependency resolution fails before runtime execution.
- **Error:** `402 Payment Required trying to find package dio at https://mirror-flutter.runflare.com.`

## Environment Gate
- [ ] `flutter pub get` passes
- [ ] app launches on target device
- [ ] backend reachable with test accounts

## Profile Evidence Matrix

### Basid
- [ ] Splash -> expected destination
- [ ] Protected route redirect behavior
- [ ] Paywall behavior for premium features
- [ ] FeatureLocked -> plans -> compare tiers path
- [ ] Empty-state escalation paths
- [ ] Notes/evidence:

### Silder
- [ ] Splash -> expected destination
- [ ] Protected route redirect behavior
- [ ] Access to silder-level features
- [ ] Denial of golden-only features
- [ ] Subscription status/manage routing
- [ ] Notes/evidence:

### Golden
- [ ] Splash -> expected destination
- [ ] Protected route redirect behavior
- [ ] Access to all gated features
- [ ] Subscription status/manage routing
- [ ] Notifications/chats/deep-link sanity
- [ ] Notes/evidence:

## Cross-Profile Checks
- [ ] Legacy route normalization verified
- [ ] Pending-intent resume after auth verified
- [ ] Analytics events emitted for auth/paywall/plans/tier-compare
- [ ] No dead-end navigation states

## Blocker Detail
- Runtime smoke cannot start until dependency mirror issue is fixed.
- Existing blocking evidence is also documented in `docs/USER_FLOW_SMOKE_EXECUTION_2026-05-06.md`.

## Next Action After Unblock
1. Resolve mirror/package access.
2. Run smoke checklist with basid/silder/golden accounts.
3. Attach screenshots/log excerpts per checklist section.
4. Update this file to PASS/FAIL with issue list.
