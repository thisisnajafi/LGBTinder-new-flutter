# 08 — Resolve restore-purchases merge (Cursor auto)

You are in the LGBTFinder Flutter repo on local branch `fix/restore-merge-20261115` (created from `fix/optimistic-logout-call-blackscreen`).
A merge of `fix/restore-purchases-confirmation` (570a118) is IN PROGRESS (`git merge --no-ff --no-commit 570a118`). Do NOT abort it, do NOT reset, do NOT push, do NOT touch other branches.

## Conflicted files (only these 3)
- lib/features/payments/data/services/google_play_billing_service.dart
- lib/features/payments/pages/subscription_management_page.dart
- lib/features/payments/providers/payment_provider.dart

## What each side did
- OURS (HEAD, from release commit a9028a9): only replaced raw error strings with `userErrorMessage(e)` (import `core/errors/user_error_message.dart`) so users never see raw exceptions. That is the ONLY payments change on our side.
- THEIRS (570a118, restore fix): restore succeeds ONLY when the backend confirms with HTTP 200 (new `RestorePurchasesConfirmer`), a 422 is surfaced as an error, timeout / empty restore / Play failures are handled with explicit messages, and the legacy restore path (`RestorePurchasesUseCase`, `restore_purchases_use_case.dart`) is REMOVED.

## Resolution rules
1. Take THEIRS' logic/structure for every hunk (restore confirmation flow, new states, removed legacy use case + its import/provider wiring).
2. Re-apply OURS' intent on top: wherever an error string built from a raw exception (`'...: $e'`, `e.toString()`) is shown to the user or pushed to `_errorController`, use `userErrorMessage(e)` instead. Keep explicit, intentional user messages from THEIRS (e.g. restore 422 / timeout / nothing-to-restore texts) as they are. Logging (`_log(...)`) may keep raw `$e`.
3. Keep the `user_error_message.dart` import where used; remove imports of deleted files (`restore_purchases_use_case.dart`). No dangling references anywhere in lib/ or test/ (`git grep RestorePurchasesUseCase`).
4. Do not change anything outside payments unless required to compile. Do not touch logout/call/Discover code.

## Verify (record exact numbers)
- `git diff --check` and no `<<<<<<<`/`>>>>>>>` markers left.
- `flutter analyze lib` -> must be 0 errors (report warnings/info count).
- `flutter test test/unit/features/payments/restore_purchases_confirmer_test.dart test/unit/features/payments/subscription_lifecycle_contract_test.dart`
- `flutter test test/unit/features/payments` (and any `test/**/billing*`/`*payment*` tests you find)
- full `flutter test` -> report pass/fail totals. Baseline on the parent branch: 1439 passed / 104 failed (all pre-existing). Any failure NOT in the pre-existing set must be fixed or explained.

## Finish
- `git add` the resolved files and `git commit --no-edit` (merge commit message: "Merge fix/restore-purchases-confirmation (570a118): backend-confirmed restore; keep userErrorMessage + logout/call/Discover"). Do NOT stage android/build/reports/** or *.bak-* files.
- Write docs/pm/08-restore-merge-REPORT.md: per-file resolution summary, analyze result, test numbers vs baseline, any new failures. Commit it in a second commit.
- Never push. Never print secrets.
