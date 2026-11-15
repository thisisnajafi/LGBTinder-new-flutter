# Claude run — Discover page design polish (LGBTFinder Flutter)

You are a senior Flutter product engineer + UI designer working in `E:\1 - laravel\1 - LGBTinder\lgbtindernew` (Flutter 3.x, Riverpod 2, go_router 13). Branch `fix/optimistic-logout-call-blackscreen` is checked out; it already contains call-end fixes, an optimistic logout change and smoothness work (see `docs/pm/logs/0*-REPORT.md`). Do not undo them. This is one of very few expensive runs: do the whole job (audit → design → implement → verify) in this run.

## Goal
Redesign/polish the **Discover** page so it feels modern, premium and smooth, stays 100% consistent with the app's existing design system, and has **no behaviour regressions** (swipe, like/pass/superlike/rewind, match flow, filters, passport, notifications bell, profile open, empty/error/loading states, plan limits/paywall gates).

## Read first
- Design system docs: `UI-DESIGN-SYSTEM.md`, `DESIGN-SYSTEM-AUDIT.md`, `docs/LGBT_MINIMAL_DESIGN_TASKS.md`, `docs/PAGE_LAYOUT_SYSTEM.md`, `docs/HEADER_SCROLL_ROLLOUT.md`, `docs/PERFORMANCE_SMOOTHNESS_TASK_LIST.md`, `docs/pm/logs/03-smoothness-REPORT.md`.
- Theme/tokens: find the app theme, colors, spacing, radius, typography and shared components (`lib/core/theme/**`, `lib/shared/widgets/**`, `lib/widgets/**`). Reuse them; do not invent new colors or fonts.
- Discover implementation: `lib/pages/discovery_page.dart`, `lib/widgets/cards/card_stack_manager.dart`, `lib/widgets/cards/swipeable_card.dart`, the action-button row, the greeting/header card, the passport banner, the empty state ("No one nearby right now" with Update location / Increase distance + retry / Adjust filters), and related providers under `lib/features/discover/**`.
- Current look (emulator screenshots, 2026-11-15): header "Discover" title with 3 round icon buttons (passport/map, bell, filter); a greeting card ("Good evening, <name> · Swipe and connect", optional "Passport active · Exploring Los Angeles…" row); a large rounded photo card with chips ("Match 34%", interests, "Your type"), name, city, distance pill, bio + "more"; 4 circular action buttons (rewind purple, pass red, superlike yellow, like green); floating pill bottom nav. Empty state is a centred card with a pin icon and two buttons.

## Design direction (adapt to the existing system; keep brand gradients)
1. Visual hierarchy: card is the hero. Reduce header/greeting height so the card gets more vertical space on small phones (360×640 dp) while staying balanced on tall phones; consider merging the greeting into a compact header row and showing passport status as a small chip.
2. Card: refined gradient scrim for legibility, consistent chip style (max 2–3 chips, overflow handled), name/age/verified badge typography from the theme, distance pill, tidy bio truncation, subtle photo-index indicator; smooth photo switching (tap left/right) with pre-cached next image (`precacheImage` for the next card's first photo, decode at display size via `cacheWidth`/`memCacheWidth`).
3. Swipe feedback: LIKE / NOPE / SUPER overlays that fade/scale with drag progress, slight rotation, spring-back with a physics/curve that feels natural; next card scales up underneath. All animations must use transforms/opacity only (no layout per frame), run at 60 fps, respect Reduce Motion / `MediaQuery.disableAnimations`.
4. Action bar: consistent sizes (primary like/pass larger than rewind/superlike), press-scale micro-interaction + haptic (respect existing haptics setting), disabled/locked states for plan-gated actions, safe-area aware, never overlapping the bottom nav.
5. Optimistic reactions: tapping like/pass/superlike advances the card immediately; the API call happens in the background; on failure, restore the card (or show a non-blocking toast) using the existing error handling. Do not change backend contracts.
6. Empty / loading / error states: skeleton shimmer card while loading (cheap), polished empty state that keeps the same three actions, offline state consistent with the connectivity banner.
7. Light and dark theme, RTL (Persian/Arabic) layouts, large text scale (1.3×) must all look correct — no overflow.
8. Accessibility: semantic labels on all buttons (keep existing labels used by tests/QA, e.g. "Open filters", "Notifications", "Passport — change discovery location", "View my profile"), min 48 dp touch targets, contrast AA over photos.

## Performance constraints
- No `BackdropFilter`/blur over the card during drag; no `Opacity` widget on large subtrees per frame (use `FadeTransition`/`AnimatedOpacity` or paint alpha); `RepaintBoundary` around the card stack; `const` constructors; Riverpod `select` to avoid rebuilding the page on unrelated state.
- Keep the off-tab carousel pause from run 3 (`carouselEnabled`).

## Constraints
- No backend changes, no new heavy dependencies (if you truly need one, justify in the report; prefer none). Don't touch signing, production google-services, Codemagic, or unrelated features. Do not commit, push, or switch branches. Never log tokens/passwords.
- Keep public widget APIs used elsewhere working, or update all call sites.

## Verify
- `flutter analyze` (changed files clean), run Discover/cards related tests plus `test/unit/features/smoothness/`, update/add widget tests for: action bar semantics, empty state actions, optimistic like with failing repository restores the card, RTL + 1.3 text scale no overflow (golden-free layout tests).
- Report pre-existing failures separately.

## Report
Write `docs/pm/logs/04-discover-redesign-REPORT.md`: design decisions (before → after per element), files changed, perf notes, tests/analyze results, risks, and a manual QA checklist (swipe each direction, buttons, rewind, match popup, filters, passport, empty state, dark mode, RTL). End your final message with `RUN4_DONE`.
