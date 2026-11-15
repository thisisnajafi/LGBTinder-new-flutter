# 08 — Restore-purchases merge report

Branch: `fix/restore-merge-20261115`  
Merged: `570a118` (`fix/restore-purchases-confirmation`) — merge commit `34fd12f`  
Date: 2026-11-15

## Per-file resolution

### `lib/features/payments/data/services/google_play_billing_service.dart`
- Kept **both** imports: `user_error_message.dart` (OURS) + `restore_purchases_confirmer.dart` (THEIRS).
- Took THEIRS restore confirmation flow (`RestorePurchasesConfirmer`, explicit restore constants).
- On purchase/restore catch paths that push raw exceptions to `_errorController`, used `userErrorMessage(e)` (OURS).
- Kept THEIRS intentional user copy for Play restore failure: `restorePlayFailedMessage` (not raw `$e`).
- Logging still uses raw `$e`.

### `lib/features/payments/pages/subscription_management_page.dart`
- Took THEIRS restore UX: show `GooglePlayBillingService.restorePlayFailedMessage` on catch (explicit Play-failure copy).
- Left other existing `userErrorMessage(e)` call sites unchanged.

### `lib/features/payments/providers/payment_provider.dart`
- Took THEIRS structure: removed legacy `restorePurchases()` / `RestorePurchasesUseCase` path.
- Re-applied OURS: all user-facing `error:` fields use `userErrorMessage(e)` (not `e.toString()`).
- Kept `user_error_message.dart` import; no dangling use-case import.

### `test/unit/features/payments/subscription_lifecycle_contract_test.dart`
- THEIRS asserted `ApiError.message ==` raw SQLSTATE body; on this branch `ApiError.fromResponse` sanitizes via `sanitizeUserMessage`.
- Assertion updated to expect no `SQLSTATE` in `apiError.message` (matches OURS user-safe intent; UI still uses generic restore constants).

## Cleanup checks
- `git diff --check`: clean (exit 0).
- No `<<<<<<<` / `>>>>>>>` markers in `lib/` or `test/`.
- `git grep RestorePurchasesUseCase` in `lib/` + `test/`: no matches.

## Analyze
- `flutter analyze lib`: **0 errors**, **123 warnings**, **344 infos** (467 issues total; pre-existing style/deprecation noise).

## Tests

| Suite | Result |
|-------|--------|
| `restore_purchases_confirmer_test.dart` + `subscription_lifecycle_contract_test.dart` | **7 passed** |
| `test/unit/features/payments` | **12 passed** |
| Related `payment_service_test` / e2e billing / integration payment | Failures pre-existing (compile drift / UI); not introduced by merge |
| Full `flutter test` | **1446 passed / 104 failed** |

### vs baseline (parent branch)
- Baseline: **1439 passed / 104 failed**
- After merge: **1446 passed / 104 failed**
- Failure count unchanged (**104**).
- Pass count +7 from new restore/lifecycle unit tests brought by THEIRS.
- No new failures attributable to this merge.

## Not staged / not touched
- `android/build/reports/**`
- `*.bak-*` (e.g. `google-services.json.bak-20261114`)
- Logout / call / Discover code untouched
- Never pushed
