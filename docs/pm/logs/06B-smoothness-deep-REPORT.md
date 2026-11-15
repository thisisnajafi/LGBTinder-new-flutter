# 06B — Smoothness deep pass — REPORT

Branch: `fix/optimistic-logout-call-blackscreen` (nothing committed, nothing pushed).
Scope: Task B of `docs/pm/prompts/06-flutter-claude-bundle.md`.
Nothing here was measured on a device: the app was not run (QA does that). "Expected gain" is an estimate from what the code no longer does per frame, not a profiler number.

## 1. Review of the 8 earlier fixes (`03-smoothness-REPORT.md`)

| # | Earlier fix | Verdict | Notes |
|---|---|---|---|
| 1 | `last_seen_widget.dart` made stateless (no 1 s ticker) | OK | Online state is event driven (`PresenceFreshness` has no local expiry), so nothing goes stale. The relative "last seen 5 min ago" text only advances when the header rebuilds. Left as is. |
| 2 | `chat_header.dart` `_HeaderAvatar` stateless | OK | No regression found. |
| 3 | `chat_list_item.dart` locked preview: blur replaced by static dots | **Fixed (visual)** | The dots were a visible downgrade from the blurred text. Now `FrostedTextPlaceholder`: soft smudged bars that follow the word lengths of the hidden message. Still no `ImageFiltered`, and the text is never laid out. |
| 4 | `notification_tile.dart` restricted like: blurred avatar replaced by an icon | **Fixed (visual)** | Now the liker's photo decoded 8 px wide and stretched inside the gradient ring. It reads as a heavy blur; the face is not recoverable. The icon remains while loading, on error, and when there is no photo. |
| 5 | `swipeable_card.dart` `carouselEnabled` off-tab pause | OK | Kept, and still wired after the Discover work in Task C. |
| 6 | `chat_list_page.dart` per-row `.select` | OK | No regression found. |
| 7 | `home_page.dart` connectivity watch removed | OK | Extended by fix B3 below. |
| 8 | `app_router.dart` `platformPredictivePage` for likes-received / matches | OK | No regression found. |

## 2. New fixes, ranked by expected gain

| Rank | Area | Fix | Why it was slow | Expected gain | Files |
|---|---|---|---|---|---|
| B1 | Opening a chat, chat scroll | Chat header capsule no longer uses a live `BackdropFilter` (σ 22). It paints a flat frost tint instead. | A backdrop blur behind the header is recomputed on every frame the page repaints: during the route transition and during every scroll frame. The wallpaper under it blurs to a flat colour anyway (measured: the blurred wallpaper varies by about 3 levels per channel). | High. Removes one full-width blur pass per frame on the busiest screen. | `core/widgets/premium/premium_hero_header.dart` |
| B2 | Chat scroll with media | Photo bubble placeholder no longer uses `ImageFiltered` (σ 12). The 20×20 preview is stretched with smooth filtering. Local photos are decoded at bubble size (`cacheWidth`). | One offscreen blur per unloaded photo bubble while scrolling. For a just-sent local photo the blur stayed under the loaded image for good. Local camera photos were decoded at full size. | High for media-heavy threads; large memory drop for sent photos. | `widgets/chat/chat_bubble_photo.dart`, `features/chat/utils/chat_image_placeholder.dart` |
| B3 | Tab switches, idle cost | Hidden home tabs are wrapped in `TickerMode(enabled: false)`. | `IndexedStack` keeps hidden tabs mounted with their animations ticking: shimmer, pulses, the Discover ambient background. They scheduled frames nobody could see. | Medium to high. Fewer frames built while on another tab, less battery, smoother tab-switch animation. | `pages/home_page.dart` |
| B4 | Own and other-user profile | Profile hero cover no longer uses `ImageFiltered` (σ 28) on a full-size photo. The cover is decoded 12 px wide and stretched. | The blur sat at the top of the scrolling profile and was re-run while the header was on screen; the photo under it was decoded at display size only to be blurred. | Medium. One blur pass and one large decode removed per profile open. | `core/widgets/premium/premium_hero_header.dart`, `core/widgets/frosted_placeholders.dart` |
| B5 | Profiles, discover detail sheet, chat info | Decode-size caps (`memCacheWidth`) on five places that decoded full uploads: other-user hero photo, profile photo carousel, discover detail sheet grid, chat user-info photo strip, shared-media grid. | A 4000 px upload was decoded at full size to fill a 72 px thumbnail: slow first frame, memory spikes, image-cache eviction. | Medium. Faster first paint of photo grids, much lower memory. | `core/utils/image_decode_size.dart` (new), `widgets/cards/profile_detail_sheet.dart`, `features/profile/presentation/widgets/other_user_profile/other_user_profile_sections.dart`, `features/profile/widgets/profile_photo_carousel.dart`, `widgets/chat/chat_user_info_panel.dart`, `pages/chat_conversation_info_page.dart` |
| B6 | Other-user profile | Optimistic Like: the button turns to "Liked" on tap, with a haptic (respects the haptics setting); it is restored and an error is shown if the request fails. Double taps are ignored. Superlike is not optimistic (it spends a balance) but a double tap can no longer send two. | The button gave no feedback until the server answered, and each extra tap sent another request. | Perceived latency drops from one round trip to zero. | `core/utils/optimistic_action.dart` (new), `pages/profile_page.dart`, `own_profile/profile_hero_section.dart`, `other_user_profile/other_user_profile_view.dart` |
| B7 | Chat list, notifications | Frosted placeholders (see fixes 3 and 4 in section 1). | Restores the look without bringing the blur back. | Neutral cost versus the dots/icon; visual parity with the original design. | `core/widgets/frosted_placeholders.dart` (new), `widgets/chat/chat_list_item.dart`, `features/notifications/presentation/widgets/notification_tile.dart` |

Discover-specific smoothness work (card stack, drag, precache, optimistic swipes) is in `04-discover-redesign-REPORT.md`.

## 3. Visual changes to check (no downgrade intended)

- **Chat header**: was frosted glass over the wallpaper, now a flat tint of the page background at 90 % under the same gradient. The wallpaper pattern must stay invisible behind the header, in light and dark.
- **Photo bubble placeholder**: was a gaussian blur of the 20×20 preview, now the same preview stretched smoothly. Slightly less creamy when compared side by side.
- **Profile hero cover**: was a gaussian blur of the photo, now a 12 px decode stretched. Colours match; the wash on top is unchanged.
- **Locked chat preview / restricted like avatar**: back to a blurred look (were dots / an icon after run 3).
- **Like button on another user's profile**: new "Liked" state with a filled heart.

## 4. Looked at and left alone

- Bottom nav bar `BackdropFilter`: content does scroll under it, so the blur is real; replacing it changes the design. Same decision as run 3.
- `shimmer_effect.dart` `ShaderMask`: loading-only, already inside a `RepaintBoundary`, and now muted on hidden tabs by B3.
- `shrinkWrap` lists: all 17 are short, bounded lists or grids inside sheets and detail pages. None is a long feed.
- `profile_locked_overlay.dart`, `match_found_page.dart`, `chat_message_context_menu.dart`, onboarding celebration, in-call controls: one-off overlays, not scroll items.
- Settings and notifications screens: no whole-page provider watches found.
- `screens/discovery/profile_detail_screen.dart` like handler: same non-optimistic pattern as the profile page had; not changed because it is not on the main route path. Candidate for the same `OptimisticGate`.

## 5. Tests

New: `test/unit/features/smoothness/run6_deep_pass_guards_test.dart` (18 tests): decode-size maths, `OptimisticGate` (apply, rollback, double tap, retry after failure), frosted text rhythm and no text leak, hero header without live blur, viewer Like/Liked button, source guards for the removed blurs, `TickerMode`, and decode caps.

Updated:
- `test/widget/widgets/chat_list_item_test.dart`: frosted locked preview, no hidden text, RTL + 1.3× text scale.
- `test/widget/notifications/notification_perf_test.dart`: frosted restricted avatar (decode ≤ 8 px), icon gate without a photo.
- `test/unit/features/chat/chat_image_placeholder_test.dart`: placeholder without `ImageFiltered`.
- `test/widget/screens/profile_detail_hero_test.dart`: targets the carousel image now that the cover is also an image.
- `test/widget/pages/chat_list_page_test.dart`: harness fixed (SharedPreferences provided, phone-sized surface). 7 tests pass; they failed before this run.

Results are in the "Global verification" section of `04-discover-redesign-REPORT.md` and repeated in the final summary.

## 6. Risks

- B1 assumes nothing scrolls under the chat header. That is true today (the header sits above the list in a column). If a later design lets messages pass under it, they will show through the 90 % tint faintly instead of being blurred.
- B3: an animation that is mid-flight when the user leaves a tab pauses and resumes on return. Code that awaits such an animation waits until the tab is shown again.
- B5: a landscape photo shown in a tall box can be slightly softer than before (decode is sized for photos up to 4:3). The zoomable galleries still load full size.
- B6: if the like request fails after the user has left the profile, the rollback is skipped (the page is gone) and no error is shown.
- Found while fixing the chat-list harness, not fixed: on an 800×600 surface the tablet master/detail layout gives the chat-list empty state a 220×268 pane and it overflows by 59 px. Only very small landscape tablets hit this.

## 7. Manual QA checklist

- [ ] Open a chat from the list ten times: transition is smooth, header looks like frosted glass, no wallpaper pattern behind it (light + dark).
- [ ] Scroll a thread with many photos fast, up and down: no hitching when photos enter; placeholders look blurred, then fade to the photo.
- [ ] Send a camera photo: bubble appears at once, no stutter, no black frame.
- [ ] Switch between all five tabs quickly: no stutter; shimmer or ambient animation resumes when coming back.
- [ ] Own profile and another user's profile: header background is a soft colour wash of the photo; scrolling is smooth.
- [ ] Another user's profile: tap Like → turns to "Liked" at once. In airplane mode: it turns back to "Like" and an error is shown. Double-tap sends one like.
- [ ] Chat list as a free user: locked previews look like blurred text plus a lock, never readable; RTL and large text still fit.
- [ ] Notifications as a free user: a restricted like shows a blurred avatar in the gradient ring, never a recognisable face.
- [ ] Discover detail sheet photo grid, chat info shared media, profile carousel: photos are sharp, load quickly, zoom still shows full quality.
