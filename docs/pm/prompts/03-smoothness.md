# Claude run 3/5 — Page smoothness / jank (LGBTFinder Flutter)

You are a senior Flutter performance engineer in `E:\1 - laravel\1 - LGBTinder\lgbtindernew` (Riverpod 2, go_router 13). Branch `fix/optimistic-logout-call-blackscreen` already contains runs 1–2 (see `docs/pm/logs/0*-REPORT.md`); do not undo them. Expensive run: finish analysis + fixes + verification here.

## Problem (owner report)
"Pages are not so smooth sometimes" — janky page transitions and scrolling, occasional stutter when opening screens.

## Approach (evidence-driven, top offenders only)
1. Read `docs/PERFORMANCE_SMOOTHNESS_TASK_LIST.md`, `docs/ANR_DEBUGGING.md`, `docs/SPLASH_ANR_AUDIT_REPORT.md` to see what was already done/planned.
2. Focus on the main user journeys: app start/splash → home shell with bottom nav, Discover (swipe cards), Matches/likes lists, Messenger list + chat page, Profile + other-user profile, Settings. Find their pages via the router.
3. Look for, with file:line evidence:
   - `ref.watch` of large providers in big build methods where `select` or splitting a widget would avoid full rebuilds; providers that rebuild whole pages on every Pusher event / timer tick / typing indicator;
   - `setState` on large subtrees, animations/timers (`Timer.periodic`, `AnimationController` repeat) running on off-screen tabs (IndexedStack keeping heavy tabs alive and animating);
   - synchronous heavy work on the UI isolate: JSON decoding of big payloads, `jsonDecode` in build, sorting/filtering large lists in build, image decoding at full resolution (missing `cacheWidth/cacheHeight`/`memCacheWidth` in `CachedNetworkImage`), `BackdropFilter`/`ImageFilter.blur` over large areas, `Opacity` / `ClipPath` / shadows in scroll items, `shrinkWrap: true` lists inside scroll views, `ListView(children: ...)` instead of builders for long lists, missing `const`, missing keys causing remounts;
   - work done during route transitions (fetching + setState in `initState` that rebuilds mid-animation) — defer with `addPostFrameCallback`/after transition, or show cached data first (stale-while-revalidate);
   - `SharedPreferences`/secure storage/sqlite reads awaited in build paths, `compute` candidates;
   - Page transitions: custom transition builders that are expensive; prefer platform defaults or cheap fades.
4. Rank the top ~8 offenders by expected impact × low risk; fix them. Do not do sweeping rewrites; behaviour and visuals must stay identical.

## Constraints
No backend changes, no new dependencies unless clearly justified, do not commit/push/switch branches, no changes to signing/production config. Keep diffs reviewable.

## Verification
- `flutter analyze` clean for changed files; `flutter test` for affected areas passes (report pre-existing failures separately).
- Where practical add a cheap regression guard (e.g. widget test asserting a list uses a builder / a provider uses select) only if it is not brittle.

## Report
Write `docs/pm/logs/03-smoothness-REPORT.md`: ranked offender table (file:line, symptom, fix, expected gain), what you deliberately left alone and why, files changed, analyze/test results, and a manual profile-mode checklist (which screens to scroll/open in `flutter run --profile` and what to watch in the performance overlay). End with `RUN3_DONE`.
