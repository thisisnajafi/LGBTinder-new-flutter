# 04 — Discover page redesign and polish — REPORT

Task C of `06-flutter-claude-bundle.md` (spec: `docs/pm/prompts/04-discover-redesign.md`).
Branch `fix/optimistic-logout-call-blackscreen`. Nothing committed or pushed. No backend, dependency, signing, `google-services` or Codemagic change. The app was not run on a device; everything below is from code, analyzer and tests.

## Result

The swipe card now gets the height the greeting card used to take, drag feedback runs without rebuilding the card, and a swipe the server fails to take puts the profile back instead of losing it silently.

Three things found on the way that were not cosmetic:

- **A failed swipe was lost.** The card was removed optimistically and stayed removed when the request failed with a server error. It is now restored (details in "Optimistic swipes").
- **The front card could stay a skeleton for seconds, or for good.** The stack waited for every photo of the front profile plus the first photo of the two cards behind it, with no time limit, before showing the card. It now waits for the first photo only, for at most 1.5 s.
- **Every swipe re-downloaded the photos of the stack.** The prefetch used `downloadFile`, which asks the server each time even when the photo is on disk. It now uses `getSingleFile`, which returns the cached file.

## Design decisions, before → after

| Element | Before | After | Why |
|---|---|---|---|
| Header | Title bar, then a separate greeting card, then a passport banner when active. | One 56 dp row: avatar ("View my profile"), greeting + first name, then Passport / Notifications / Filters. | The card is the hero. The greeting card and the banner are gone; their height goes to the card. |
| Passport / quota / upgrade | Passport as a full-width inline section; swipe quota inside the greeting card. | One row of slim chips (32 dp visual, 48 dp touch): passport place with "return" action, swipes left today, Upgrade. Collapses to an 8 dp gap when there is nothing to show. | Same information at a fraction of the height. The row scrolls sideways instead of overflowing at large text. |
| Header touch targets | 44 dp. | 48 dp on Discover (other pages keep `CompactPageHeader` defaults). | Spec: min 48 dp. |
| Card scrim | Five-stop gradient, clear at the top, 92 % black at the bottom. | Six stops: a light band at the top (36 % black) under the photo indicator and chips, clear middle, 90 % black at the bottom. | The indicator and chips now sit at the top, so the top needs contrast too. AA for white text on any photo without darkening the face area. |
| Card chips | Match %, reasons and badges in mixed styles; reasons could wrap. | One chip style (28 dp, pill). At most two reasons plus a "+N" chip; long labels ellipsize. | Spec: 2–3 chips, overflow handled. |
| Photo indicator | Vertical strip on the right edge. | Thin horizontal segments at the top, RTL-aware, announced as "Photo i of n". | Subtle, does not sit over the photo's subject; the familiar pattern. |
| Photo switching | Next photo decoded on tap. | The neighbour photo is pre-cached at the card's decode width; taps at either end do nothing instead of wrapping; selection haptic. | No blank frame on tap. |
| Bio | Up to three lines, cut with an ellipsis. | Two lines, then a "more" label for long bios. | Tidy truncation; the full text is in the profile sheet. |
| Pull-up grabber | Overlapped the last text line. | Part of the text column. | Fixes the overlap at large text. |
| Drag | `setState` on every pointer move rebuilt the whole stack. | Drag offset is a `ValueNotifier`; only a `Transform` over a cached subtree changes per frame. | 60 fps: no layout and no card rebuild while dragging (a test asserts the card is not rebuilt). |
| Swipe stamps | LIKE / NOPE faded in over 80 px through an `Opacity` widget, recomputed in the per-move rebuild. No scale. | LIKE / NOPE / SUPER fade and scale in with drag progress (dead zone 12 px, full at 80 px), driven by `FadeTransition` / `ScaleTransition`. | Spec: fade and scale with progress, opacity and transform only. The dead zone stops the stamp flickering on a tap. |
| Release below threshold | Snapped back to the centre in one frame. | Spring (`SpringSimulation`, stiffness 420, damping 30) that carries the finger's velocity; the card can be caught mid-spring. | Natural spring-back. |
| Commit | Exit restarted from the centre and faded out. | Exit continues from the release point and rotation; no fade. | No visible jump at release. |
| Cards behind | Static until the front card was gone; drawn through `Opacity`. | Scale up and move forward with drag progress; dimmed by a flat scrim in the page colour. | Spec ("next card scales up"); no `Opacity` layer. |
| Action bar | Like, Pass and Super Like at one size, Rewind smaller; locked rewind was a dead, greyed button; hidden while loading. | Like / Pass 64 dp, Super Like 52 dp, Rewind 48 dp. Press-scale and haptic (follows the app haptics setting). Locked rewind shows a lock badge and opens the paywall. Shown disabled under the skeleton, so nothing jumps when cards arrive. | Spec: primary actions larger; locked state for plan-gated actions. |
| Failed-swipe message | None. | A small notice over the top of the card for 3 s. It takes no touches. | Non-blocking by construction. A `SnackBar` was tried first and rejected: the page test showed it sits on the action bar and swallows taps on Like and Pass. |
| Loading | Skeleton, then cards, with the action bar appearing late. | Skeleton with the action bar already in place; the front card appears as soon as its first photo is on disk or after 1.5 s. | See "Result". |
| Empty state | Three actions; two of them were announced twice by screen readers. | Same three actions, each ≥ 48 dp, one announcement each, icons per case. | Spec: keep the three actions. |
| Offline | Generic empty state. | "No internet connection" with **Try again** / **Adjust filters**, wi-fi-off icon; uses the same connectivity state as the banner. | Consistent with the connectivity banner. |
| Ambient particles | An `AnimatedBuilder` rebuilt a `CustomPaint` every frame, in the same layer as the page. | The painter listens to the animation and sits in its own `RepaintBoundary`. | The always-running background no longer repaints the page above it. |

Semantic labels are unchanged: "Open filters", "Notifications", "Passport — change discovery location", "View my profile", "Like profile", "Dislike profile", "Super like profile", "Rewind last swipe".

## Optimistic swipes

No backend contract change; same endpoints and payloads.

- The card leaves at once. The request runs behind it.
- **Restored** (card back on top, short notice): 5xx, 408, no status code, any non-API exception.
- **Restored without the notice**: plan-limit errors, because the upgrade dialog already explains it.
- **Not restored**: offline (the swipe stays queued, as before) and other 4xx (the server refused it; showing the card again would loop).
- A restored swipe is also removed from the "acted on" list and from rewind, and is not counted against the daily quota.
- The local swipe-limit check no longer waits on the network when limits are not cached yet. It warms the cache and lets the swipe through; the server still enforces the limit, and a refusal restores the card.

## Performance notes

- No `BackdropFilter`, `ImageFiltered` or blur anywhere in the Discover page, card or stack. No `Opacity` widget in the stack or card (source-guard tests).
- `RepaintBoundary` around the header, the chip row, the card stack, each card, the action bar and the ambient background.
- Drag, stamps, deck progress, spring and exit run on controllers and notifiers. `setState` is not called during a drag.
- Riverpod `select` for the header (name, avatar, online) and the quota chip, so a profile or plan refresh does not rebuild the page.
- `carouselEnabled` still pauses the photo carousel off-tab.
- Next-card pre-cache now decodes at the card's width. It used to decode a full-size copy the card never read.
- Reduce Motion: no spring, no fly-out, no deck animation and no lift. The card and its stamp still follow the finger, since that is direct manipulation, and swipes commit as usual.

## Files changed (Task C)

New:
- `lib/features/discover/widgets/discover_header.dart`
- `lib/features/discover/widgets/discover_action_bar.dart`
- `lib/features/discover/widgets/discover_swipe_notice.dart`

Modified:
- `lib/pages/discovery_page.dart`
- `lib/widgets/cards/card_stack_manager.dart`
- `lib/widgets/cards/swipeable_card.dart`
- `lib/widgets/discovery/discovery_swipe_action_button.dart` (new `locked`; API-compatible for `likes_received_screen.dart` and `profile_detail_sheet.dart`)
- `lib/core/widgets/compact_page_header.dart` (new optional parameters; defaults unchanged)
- `lib/features/discover/providers/discover_cache_provider.dart`
- `lib/features/discover/utils/discovery_image_prefetch.dart`
- `lib/features/discover/widgets/discover_empty_state.dart`
- `lib/features/discover/widgets/discover_ambient_background.dart`

No longer referenced, left on disk: `discover_greeting_widget.dart` and `discover_passport_banner.dart`. Delete them once the new header is accepted.

Tests added (73):

| File | Tests | Covers |
|---|---|---|
| `test/unit/features/discover/discover_swipe_restore_test.dart` | 14 | Real notifier with fake services: failing like restores the card, retry works, limit error, offline, 422, success. |
| `test/widget/features/discover/card_stack_swipe_test.dart` | 19 | Stamps follow drag, next card grows, no rebuild while dragging, spring-back, commit from release point, flick, vertical drag, button exits, Reduce Motion, source guards. |
| `test/widget/features/discover/card_stack_reveal_test.dart` | 5 | Front card waits for the first photo only; a photo that never arrives or fails does not hold it. |
| `test/widget/features/discover/discover_action_bar_test.dart` | 8 | Semantics, order in LTR and RTL, sizes, taps, locked and disabled states, 320 dp RTL at 1.3×, dark. |
| `test/widget/features/discover/discover_empty_state_test.dart` | 6 | Three actions fire, ≥ 48 dp, exact labels, RTL at 1.3×, dark with Reduce Motion. |
| `test/widget/features/discover/discover_layout_test.dart` | 14 | Header and chips labels, heights and targets; card at RTL 1.3×, narrow card, chip overflow, bio truncation. |
| `test/widget/features/discover/discovery_page_smoke_test.dart` | 7 | The real `DiscoveryPage` with mocked services: labels, RTL 1.3× on 360×640, dark at 320 dp, like button, failing like restores the card with the notice and leaves the bar usable, drag to like, empty deck. |

All four tests the spec asks for are there (action bar semantics, empty state actions, failing repository restores the card, RTL + 1.3× without overflow). No goldens.

## Global verification (all three tasks)

`flutter analyze`, whole project: 738 issues (183 errors, 156 warnings, 399 infos). `HEAD` has 739. All 183 errors are in pre-existing test files; `lib/` has none. No new issue in any changed or new file. Ten pre-existing ones remain in four touched files, on lines this work did not write: `auth_service.dart` (1 info), `profile_page.dart` (6 infos), `push_notification_service.dart` (1 info), `chat_list_page_test.dart` (1 info, 1 warning).

`flutter test`, whole suite: 1439 passed, 104 failed. The same run on an untouched checkout of `HEAD`: 1297 passed, 111 failed. The 104 failures are a subset of the 111 on `HEAD`, name for name; this work adds no failure and fixes seven (`chat_list_page_test.dart`).

| Group | Result |
|---|---|
| `test/unit/features/calls` | 207 passed, 1 failed (pre-existing) |
| `test/widget/features/calls` | 20 passed |
| `test/features/auth` (logout, session expiry) | 29 passed |
| `test/unit/features/smoothness` | 21 passed |
| Discover and cards: `test/unit/features/discover`, `test/widget/features/discover`, `test/widget/discover`, `card_stack_image_test.dart`, `compact_page_header_test.dart` | 95 passed |
| `test/e2e/discover`, `test/widget/pages/discovery_page_test.dart` | 1 passed, 14 failed (pre-existing) |
| Chat list and notification perf: `chat_list_page_test.dart`, `chat_list_item_test.dart`, `test/widget/notifications` | 24 passed |
| `test/unit/features/chat` | 319 passed, 1 failed (pre-existing) |
| `profile_detail_hero_test.dart`, `profile_page_test.dart` | 3 passed, 4 failed (pre-existing) |

Pre-existing failures in the groups above, identical on `HEAD`:

- `test/unit/features/calls/call_primary_photo_test.dart` — 1.
- `test/unit/features/chat/chat_image_upload_test.dart` — 1 ("failed image bubble shows retry overlay, not the percent").
- `test/e2e/discover/*` (10) and `test/widget/pages/discovery_page_test.dart` (4) — "SharedPreferences not initialized" in the harness. The e2e helper also looks for 56 dp `ScaleTapFeedback` buttons and a "No more profiles" text that `HEAD` does not have either, so these need a rewrite rather than a fix. `discovery_page_smoke_test.dart` covers the same ground with a working harness.
- `test/widget/pages/profile_page_test.dart` — 4.

The other 84 pre-existing failures are outside these groups: 19 test files that do not compile (`test/unit/services/*`, some e2e and integration suites) and e2e / integration flows (`auth_session_test.dart` 11, `profile_wizard_flow_test.dart` 7, `token_storage_service_test.dart` 7, and smaller ones).

## Risks

- **Not seen on a device.** Spring feel, stamp timing and the scrim over real photos are tuned from numbers, not from a screen. Expect a round of constants tuning after QA.
- **Restored card returns to the front**, even if the user has swiped further in the meantime. That is deliberate (the failed profile should not be buried), but it can surprise on a very slow connection.
- **Swipe-limit check is server-first on a cold start.** A free user at the limit can see one card leave and come back with the upgrade dialog, instead of being stopped before the swipe.
- **Front card after 1.5 s without its photo** shows the card with the photo placeholder. On a very slow connection the user sees name and bio before the photo.
- **Locked rewind now opens the paywall.** Before, it did nothing.
- **Header no longer shows the old greeting card content** beyond greeting, name and quota. If the card carried anything else product relies on, it has to move to the chip row.
- **`getSingleFile` honours the cache's validity period.** A photo replaced under the same URL shows the old file until it expires; this is already how the card itself loads photos.

## Manual QA checklist

- [ ] Swipe right, left and up on a card: LIKE / NOPE stamps follow the finger, the next card grows, up opens the profile sheet.
- [ ] Release below the threshold: card springs back; catch it mid-spring.
- [ ] Like, Pass, Super Like buttons: card leaves in the right direction, haptic fires (and does not with haptics off).
- [ ] Rewind: brings the last card back; on a plan without rewind the button shows a lock and opens the paywall.
- [ ] Match popup still appears on a mutual like.
- [ ] Airplane mode on, then swipe: swipe is kept and synced later. Server error (if it can be forced): the card comes back with the notice and Like / Pass still work while it is visible.
- [ ] Filters: open from the header, apply, clear from the active-filters bar.
- [ ] Passport: set a location, chip appears, "return" clears it; free plan does not show the header button.
- [ ] Empty state: all three actions; offline shows "No internet connection" with Try again.
- [ ] Cold start on a slow connection: the front card appears within about 1.5 s even if the photo is still loading.
- [ ] Photo taps: left / right change photo with no blank frame; indicator segments follow.
- [ ] Dark mode, RTL (Persian or Arabic), text size 1.3×: no clipped text, no overlap with the bottom navigation.
- [ ] Reduce Motion on: no spring and no fly-out, everything still works.
- [ ] Switch tabs and back: carousel pauses off-tab, no jank on return.
- [ ] Likes screen and profile detail sheet action buttons look and behave as before.
