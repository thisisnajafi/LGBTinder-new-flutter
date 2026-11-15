# Claude run — Flutter bundle: Discover redesign + smoothness deep pass + review of logout/call fixes

You are a senior Flutter engineer, performance specialist and UI designer working in `E:\1 - laravel\1 - LGBTinder\lgbtindernew` (Flutter 3.x, Riverpod 2, go_router 13, Agora, CallKit, Pusher). Branch `fix/optimistic-logout-call-blackscreen` is checked out. Earlier passes were done by a smaller model; you are the deep, expensive pass — be thorough and finish all three tasks in this single run. Do not commit, push or switch branches.

Work in this order and keep each task's changes coherent:

---
## Task A — Review & harden the earlier fixes (do first; correctness before polish)
Inputs: `docs/pm/prompts/01-optimistic-logout.md`, `docs/pm/prompts/02-call-end-black-screen.md` (both contain measured baseline evidence), `docs/pm/logs/02-call-end-black-screen-REPORT.md`, the logout report if present (`docs/pm/logs/01-optimistic-logout-REPORT.md`), and `git diff main...HEAD` plus uncommitted changes.
1. Logout: verify the tap→logged-out-screen path has **no network or slow awaits** (baseline was ~3.4 s while the HTTP call took 0.4 s). Verify session-epoch protection (late background completion cannot wipe a new login), provider invalidation (user B never sees user A data), no global 401 handler/redirect triggered by the background logout, and that the API logger redacts `password`, `password_confirmation`, `token`, `refresh_token`, `Authorization`. Fix gaps.
2. Calls: verify the incoming-route de-dup (Pusher + FCM + CallKit sources, same call_id), accept-replaces-incoming, idempotent end, `leaveCallRoutes` never pops below the call or leaves a lone `/call/incoming`, no `ref` in `dispose` anywhere under `lib/features/calls` and call screens, and video-call path (AgoraVideoView unmounted before engine release). Also check the incoming flow from background/killed state and from the in-app banner/overlay (`incoming_call_overlay.dart`, `incoming_call_banner.dart`). Fix gaps; add tests for anything you fix.
Acceptance A: findings table (OK / fixed / risk) with file:line; tests added/updated pass.

---
## Task B — Smoothness deep pass
Inputs: `docs/pm/logs/03-smoothness-REPORT.md` (8 fixes already done), `docs/PERFORMANCE_SMOOTHNESS_TASK_LIST.md`.
1. Review the 8 fixes for regressions. Two of them changed visuals (blurred locked previews in `chat_list_item.dart` and `notification_tile.dart` replaced by static dots/icon): keep the visual intent close to the original (e.g. a pre-blurred/cheap gradient placeholder, or blur cached once via `RepaintBoundary`/`ImageFiltered` outside the scroll item) — the owner should not perceive a downgrade.
2. Find and fix the next tier of jank on: app start → home shell, tab switches, opening chat, chat scroll with media, profile/other-user profile, settings, page transitions. Look for sync work in build, un-sized image decodes (`cacheWidth`/`memCacheWidth`), `shrinkWrap` lists, missing `const`/keys, providers rebuilding whole pages, animations running off-screen, heavy `initState` work during route transitions (defer until after the transition), `saveLayer`-heavy effects in scroll items.
3. Optimistic reactions where low-risk (e.g. like/unlike on profiles/likes list, send message already optimistic?): implement only with rollback-on-error.
Acceptance B: ranked table of fixes with expected gain; no visual regressions; tests pass.

---
## Task C — Discover page redesign/polish
Full spec is in `docs/pm/prompts/04-discover-redesign.md` — read it and implement it (design direction, performance constraints, accessibility labels to keep, optimistic swipe actions with rollback, empty/loading/error states, light/dark, RTL, 1.3× text scale). Current state on device: header "Discover" + 3 round icon buttons, a greeting card, big rounded photo card with chips/name/city/distance/bio, 4 circular action buttons, floating pill bottom nav; empty state card "No one nearby right now" with Update location / Increase distance + retry / Adjust filters.
Acceptance C: as listed in that file; keep the semantics labels "Open filters", "Notifications", "Passport — change discovery location", "View my profile".

---
## Global verification
- `flutter analyze` (report counts; changed files must be clean), then `flutter test` for: `test/unit/features/calls`, `test/widget/features/calls`, auth/logout tests, `test/unit/features/smoothness`, discover/cards tests, chat list/notification perf tests, plus any you add. List pre-existing failures separately (known: `call_primary_photo_test` primary_image_url case; `chat_list_page_test` SharedPreferences not initialized — fix the harness if trivial).
- Do NOT run the app on devices; QA will do that afterwards.

## Constraints
No backend changes; no new heavy dependencies; don't touch signing/production google-services/Codemagic; no secrets in logs.

## Reports (one per task)
- `docs/pm/logs/06A-review-logout-calls-REPORT.md`
- `docs/pm/logs/06B-smoothness-deep-REPORT.md`
- `docs/pm/logs/04-discover-redesign-REPORT.md`
Each: findings/design decisions, files changed, tests and results, risks, manual QA checklist. End your final message with `FLUTTER_BUNDLE_DONE`.
