# Run 3/5 — Page smoothness / jank

**Date:** 2026-11-15  
**Branch:** `fix/optimistic-logout-call-blackscreen`  
**Scope:** Janky page transitions / scrolling / screen opens on main journeys  
**Prior work:** PERF task list mostly complete (`docs/PERFORMANCE_SMOOTHNESS_TASK_LIST.md`); runs 1–2 untouched.

## Ranked offenders fixed

| # | Impact × risk | File:line (before) | Symptom | Fix | Expected gain |
|---|----------------|--------------------|---------|-----|---------------|
| 1 | High × low | `last_seen_widget.dart` ~75–82 | `Timer.periodic(1s)` + `setState` while Online even though `PresenceFreshness` never locally expires | Converted to `StatelessWidget`; no ticker | Removes useless 1 Hz rebuilds on chat header / presence labels |
| 2 | High × low | `chat_header.dart` `_HeaderAvatar` ~225–232 | Same 1s ticker rebuilding avatar ring while Online | Stateless `_HeaderAvatar`; presence from parent props only | Chat open chrome stays quiet until real presence events |
| 3 | High × low | `chat_list_item.dart` ~366–371 | `ImageFiltered` blur on every locked preview row during scroll | Static dots + lock (same gate idea as message premium overlay) | Cheaper messenger list scroll for free users |
| 4 | High × low | `notification_tile.dart` ~178–185 | `ImageFiltered` blur on plan-restricted like avatars | Always use static icon gate (former reduce-motion path) | Cheaper notifications scroll |
| 5 | High × low | `swipeable_card.dart` ~199 + `IndexedStack` keeps Discover alive | Photo carousel `Timer.periodic` kept firing on off-screen Discover tab | `carouselEnabled` from `DiscoveryPage` → `CardStackManager` → `SwipeableCard` | Stops background setState while on Messenger/Profile/etc. |
| 6 | High × low | `chat_list_page.dart` ~603–604, ~337 | Parent watched full mute/pin sets + full presence map → whole list rebuild | Per-row `_ChatListConversationRow` `.select` for mute/pin; online filter selects online-id `Set` only | Mute/pin/presence noise no longer repaints every row |
| 7 | Med × low | `home_page.dart` ~259 | `ref.watch(connectivityServiceBindingProvider)` on shell | Removed; binding already lived by `ConnectivityBanner` | Connectivity side-effect ticks do not rebuild all tabs |
| 8 | Med × low | `app_router.dart` likes-received / matches | Custom 300ms `slideFadePage` (slide+fade) on frequent opens | `platformPredictivePage` (`MaterialPage`) | Cheaper push/pop; predictive back; less mid-transition work |

## Deliberately left alone

| Area | Why |
|------|-----|
| Chat thread Drift / reverse list / typing isolate | Already done in PERF phases; `chatThreadLiveSyncProvider` still needs `watch` to stay alive |
| Nav bar `BackdropFilter` (σ=10) + solid-tab setting | Already gated by Reduce Motion / Appearance; changing default look is out of scope |
| Call timers / Agora video | Call UX, not page-scroll jank; run 2 owns end-path |
| Profile wizard / secondary settings stubs | Low frequency vs Discover / Messenger / Chat |
| `toMap()` in chat list filter | Allocation cost; needs preview-model filter API (larger refactor) |
| Message bubble shadows | Visual identity; already gated / repaint-bounded |
| Full Drift / local-first for non-chat screens | Infra already marked done where it mattered |

## Files changed

- `lib/widgets/chat/last_seen_widget.dart`
- `lib/widgets/chat/chat_header.dart`
- `lib/widgets/chat/chat_list_item.dart`
- `lib/pages/chat_list_page.dart`
- `lib/pages/home_page.dart`
- `lib/pages/discovery_page.dart`
- `lib/widgets/cards/swipeable_card.dart`
- `lib/widgets/cards/card_stack_manager.dart`
- `lib/features/notifications/presentation/widgets/notification_tile.dart`
- `lib/routes/app_router.dart`
- `test/widget/widgets/chat_list_item_test.dart`
- `test/widget/notifications/notification_perf_test.dart`
- `test/unit/features/smoothness/run3_smoothness_guards_test.dart` **(new)**
- `test/unit/features/chat/chat_presence_copy_test.dart` (aligned with current `PresenceFreshness`)

## Analyze / test results

- `flutter analyze` on changed libs: **clean for our edits** (pre-existing info only: `library_private_types_in_public_api` in `app_router.dart:268`).
- **Passing:**  
  `chat_list_item_test`, `notification_perf_test`, `run3_smoothness_guards_test`, `typing_indicator_dispose_test`, `chat_presence_copy_test`.
- **Pre-existing failures (unchanged by this run):**  
  `test/widget/pages/chat_list_page_test.dart` — all cases fail with `Bad state: SharedPreferences not initialized` (test harness, not these diffs).

## Manual profile-mode checklist

```bash
flutter run --profile
# DevTools → Performance → show performance overlay
```

| Screen / action | Watch for |
|-----------------|-----------|
| Home: switch Discover ↔ Messenger ↔ Profile ×10 | No sustained red bars; Discover carousel must **not** tick while off-tab |
| Discover: swipe 10 cards | Drag frames &lt; ~16ms; no carousel work on background cards |
| Messenger: scroll 50+ rows (free account with locked previews) | No blur GPU spikes; mute/pin one row must not rebuild whole list |
| Open Matches / Likes from Discover | Platform transition (not 300ms dual slide+fade) |
| Open chat → leave Online peer open 30s | Header/avatar must **not** rebuild every second |
| Notifications: scroll plan-restricted likes | No `ImageFiltered` on restricted avatars |
| Airplane / flaky network banner | Home shell must not rebuild all tabs when connectivity binding runs |

RUN3_DONE
