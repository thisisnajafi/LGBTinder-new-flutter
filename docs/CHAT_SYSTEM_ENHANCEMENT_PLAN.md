# Chat System Enhancement Plan — Telegram Grade

> Generated: 2026-09-11
> Benchmark: Telegram-level smoothness and features
> Exclusion: Stickers — not needed (backend + unused Flutter sticker bubble exist; do not expand)
> Status key: [ ] pending · [x] done · [!] blocked

---

## Audit Summary

The current chat stack is a **functional 1:1 messenger**, not a prototype. Flutter’s production path is `lib/pages/chat_list_page.dart` + `lib/pages/chat_page.dart` with widgets under `lib/widgets/chat/`. Laravel already broadcasts PascalCase events (`MessageSent`, `UserTyping`, `UserStoppedTyping`, `MessageRead`, `MessageDeleted`, `MessageEdited`, `MessageDelivered`, `MessageExpired`) on `private-conversation.{id}` (plus optional legacy `private-chat.{receiverId}`). Flutter listens to those exact names **and** dotted legacy aliases in `PusherWebSocketService._onPusherEvent` (lines 416–448). Optimistic send, SQLite outbox, typing TTL, delivered receipts, disappearing photos, pins, mute, and a match-avatar row are already present.

The biggest gaps are **quality and trust**, not missing sockets. `ChatPage` is a ~2500-line `setState` god widget: every new message rebuilds the whole chronological `ListView.builder` (not `reverse: true`). There is no “N new messages” FAB, no swipe actions, no copy/forward/reactions, no message-grouping tails, and no Telegram-grade enter animations on the live bubble (`widgets/chat/message_bubble.dart` is a `ConsumerWidget` with no send/receive slide). Self-destruct exists but the countdown is a 1-second `Timer`, not a `Stopwatch` ring. Dead duplicate widgets (`features/chat/presentation/widgets/chat_input.dart`, `features/chat/presentation/widgets/message_bubble.dart`, `widgets/chat/media_picker.dart` TODOs) still sit beside the real UI.

Real-time health is **good on names, incomplete on delivery UX**. Conversation list updates via `chatListSyncProvider` → `ChatListPreviewNotifier.applyIncomingMessage` (moves row to index 0, increments unread unless `activePeerUserId` matches). Pusher event names match backend `broadcastAs()`. `POST /api/chat/{id}/active` sets a 5-minute viewing key. History supports `before_id` pagination but **not** `after_id` catch-up. Connection state is streamed (`ConnectionStatus`) but chat UI never shows a Connecting… banner.

Animation quality is **uneven**. Messenger has `PremiumTapScale` and a 180ms section switch. Typing dots exist (`TypingIndicator`, 3 controllers, 600ms). Mic hold pulses. Sticker bubbles (excluded from this plan) pop. Production text/image bubbles do **not** animate in. Date chips exist (`ChatDateBadge`) but are not sticky. Search toggles with `setState` (no height animation, no highlight). Empty state has no Discover CTA.

---

## Pre-Enhancement Audit (Phase 0)

### Messenger Page (Conversation List)

- List implementation: `ListView.separated` in `_buildConversationList` (`chat_list_page.dart` ~448)
- Real-time list updates: **YES** — `chatListSyncProvider` applies Pusher `MessageSent` / read / delivered / edited / deleted / expired / presence; `applyIncomingMessage` prepends the row
- Conversation sort: by latest message: **YES** (incoming message becomes index 0; initial API order from `getChatUsers`)
- Unread badge: **implemented** (`ChatListItem` primary pill, `99+`)
- Online dot: **done (CHAT-MSG-005)** — 10px fill `Color(0xFF22C55E)` + 2px card ring (`ChatOnlineDot`); last-seen empty preview via `ChatPresenceCopy` / `intl`; live updates from `userPresenceCacheProvider` without list heartbeat rebuilds
- Typing in list: **implemented** (`chat['is_typing']` OR `chatProvider.typingUsers`; `TypingIndicator` replaces preview)
- Animations: tap scale on tiles; section switch `AnimatedContainer` 180ms; **slide-to-top 350ms easeOutCubic** (`ChatListReorderList`); **no** unread bounce; **swipe mute/delete/pin** (`ChatListSwipeRow`)
- Search: **done (CHAT-MSG-003 + CHAT-BE-009)** — height 0→56 250ms; local name+preview filter; submit opens `MessageSearchScreen` (300ms debounce, `conversation_id`).
- Match avatar row: **done (CHAT-MSG-008)** — `onMatchTap` → `_openPeerChat` (premium sheet / tablet embed)
- Pull-to-refresh: **YES** (`PremiumRefreshScope` / `PremiumTabPageLayout.onRefresh` → `_refreshMessenger`)

### Chat Thread Page

- Message list: `ListView.builder`: **YES** (`chat_page.dart` ~2370) — **not** `reverse: true`; chronological oldest→newest
- Scroll-to-bottom on new message: **YES (smart)** — `_isNearBottom(threshold: 180)` then `_scrollToBottom` 300ms `easeOut`; if scrolled up: jump FAB + unseen badge (CHAT-RT-002)
- Pagination (load older): **implemented** — `_onScroll` when `pixels <= 120`; `_historyPageSize = 30`; cursor/`before_id`
- Pusher subscription lifecycle: connect user channels at login (`connectForUser`); on thread open `openConversation` → `private-conversation.{id}` + `private-user.status.{peerId}`; dispose **debounces 900ms** then `unsubscribeConversation`; app resume reconnects in `cache_lifecycle_listener.dart`
- Active chat tracking for notifications: **YES (peer user id, not conversation id)** — `ChatPusherLifecycleState.activePeerUserId` + `ActiveChatPeerBridge` prefs
- Keyboard handling: `resizeToAvoidBottomInset: true` (~2287); **no** `AnimatedPadding` on the list — likely acceptable, not Telegram-smooth
- Typing indicator: **implemented** in-thread (`ChatPeerTypingIndicator`) and in list; outbound debounce 500ms start / 3s stop; dispose and focus-lost send `typing: false`

### Message Bubbles

| Type | Implemented | Has Animation | Notes |
|------|-------------|---------------|-------|
| Text | YES (`widgets/chat/message_bubble.dart`) | NO enter anim | Reply quote + edited flag + ticks; no linkify |
| Image | YES | Hero to `ChatImageViewer` | Fixed height 200; `OptimizedImage`; viewer uses `NetworkImage` (no cache, no gallery swipe) |
| Voice | YES (`VoiceMessagePlayer`) | waveform / play | Speed 1×/1.5×/2×; `audioplayers` |
| Self-destruct image | YES partial | NO pulse on flame | Preview/expired widgets; viewer 1s timer; FLAG_SECURE via method channel; **no iOS screenshot event** |
| Profile link | YES (`_ProfileLinkBubble`) | NO | Card + navigate profile |
| Call event | YES (`CallHistoryBubble`) | NO | Merged into timeline |
| System message | PARTIAL | NO | Call/match not a dedicated centered system style; screenshot-detected **missing** |
| Sticker | YES (unused for this plan) | pop 300ms | **Do not enhance** |

### Real-Time Events (Pusher)

| Event | Backend `broadcastAs()` | Flutter listens to | Match? |
|-------|-------------------------|--------------------|--------|
| MessageSent | `MessageSent` (`chat_broadcasting.events.message_sent`) | `MessageSent` + `message.sent` | **YES** |
| TypingStarted | `UserTyping` (not `TypingStarted`) | `UserTyping` + `user.typing` | **YES** (name is `UserTyping`) |
| TypingStopped | `UserStoppedTyping` | `UserStoppedTyping` + `user.stopped_typing` | **YES** |
| MessageRead | `MessageRead` | `MessageRead` + `message.read` | **YES** |
| MessageDeleted | `MessageDeleted` | `MessageDeleted` + `message.deleted` | **YES** |
| MessageExpired | `MessageExpired` | `MessageExpired` + `message.expired` | **YES** |
| MessageDelivered | `MessageDelivered` | `MessageDelivered` + `message.delivered` | **YES** |
| MessageEdited | `MessageEdited` | `MessageEdited` + `message.edited` | **YES** |
| MessageReacted | `MessageReacted` | `MessageReacted` + `message.reacted` | **YES** |

Channels: Flutter `private-conversation.{id}`, `private-user.{userId}`, `private-chat.{userId}`, `private-user.status.{peerId}`. Backend `PrivateChannel('conversation.{id}')` → `private-conversation.{id}`. Auth: `onAuthorizer` → `POST {origin}/broadcasting/auth` with Sanctum bearer.

### Notification Bug

- Active chat ID tracked: **YES (peer user id)** / conversation id stored in lifecycle but **not** used by FCM
- Notification suppressed when in chat: **PARTIAL** — Flutter FCM foreground/background skip local banner if `type==message` and `sender_id` == active peer
- FCM foreground handler: `PushNotificationService._setupMessageHandlers` `FirebaseMessaging.onMessage` → `_shouldSuppressMessageAlert` → else `_showLocalNotification`
- **Root causes:** (1) OneSignal visible push skipped FCM data-only path. (2) `connectForUser` drops `activePeerUserId` from state. (3) Empty thread may never call `openConversation`.

### Performance Observations

1. `ChatPage` holds messages as `List<Map<String, dynamic>>` and `setState`s the entire list (typing is isolated; messages are not).
2. `ListView.builder` missing `reverse: true`, `cacheExtent`, `addAutomaticKeepAlives: false`.
3. Duplicate unused chat widgets still compiled into the tree as dead code.
4. `ChatImageViewer` uses uncached `NetworkImage`.
5. Image bubbles: fixed 200px height, no `memCacheWidth`.
6. `debugPrint` in `ChatPusherLifecycleNotifier` instead of `AppLogger`.
7. Dedup is O(n) `indexWhere` on maps, not `Map<id, index>`.
8. `_showGroupSummaryNotification` is an empty stub (comment only).
9. Pagination poll every 8s when Pusher is disconnected (good fallback; can hammer API).
10. `_filteredChats` getter is filtered **per ListView row** → O(n²).
11. `_chatToMap` omits `last_message_from_me` / read / delivered — ticks only after preview seed.
12. Two message stores: `ChatState.currentMessages` vs `ChatPage._messages` (live UI ignores Riverpod).
13. `ChatState.copyWith` cannot null `currentChatUserId`.
14. Outbound queue flush targets `ChatNotifier`, not `ChatPage`.
15. History SQL SELECT omits `delivered_at`, `edited_at`, `reply_to_message_id` (`ChatMessageHistoryService` ~212–217).
16. `GET /chat/search` filters `conversation_id` (CHAT-BE-009).
17. Video bubbles open `ChatVideoViewer` and interrupt in-thread voice (CHAT-IMG-007).
18. `ChatMatchesRow` uses `_openPeerChat` (premium + tablet) (CHAT-MSG-008).
19. `AppIcons.send` / `bellSlash` still point at legacy `assets/images/icons/`; outline `notification-slash.svg` is missing.
20. `PusherWebSocketService.dispose` closes StreamControllers before `disconnect()` finishes.

### TODO comments found (chat-related)

- `lib/widgets/chat/mention_text_widget.dart:65` — Extract user ID from mention
- `lib/widgets/chat/media_picker.dart:48` — Implement image picker
- `lib/widgets/chat/media_picker.dart:54` — Implement video picker
- `lib/widgets/chat/media_picker.dart:60` — Implement file picker
- `lib/widgets/chat/audio_recorder_widget.dart:51` — Start actual audio recording
- `lib/widgets/chat/audio_recorder_widget.dart:59` — Stop recording and get audio path
- `lib/widgets/chat/audio_player_widget.dart:45` — Implement actual audio playback

(Production path already uses `image_picker` + `record` + `VoiceMessagePlayer`. Those TODO files are **dead duplicates**.)

### Empty catch blocks (chat + notification path)

- `chat_list_page.dart` ~132, ~173 — swallow match/cache errors
- `chat_page.dart` ~189 — typing-stop on dispose
- `chat_list_preview_provider.dart` ~29 — `catchUpChatListFromApi`
- `conversation_mute_cache_provider.dart` ~71
- `pinned_count_provider.dart` ~13
- `chat_info_cache.dart` ~142
- `chat_visual_media.dart` ~98, ~119
- `message_input.dart` ~158 — voice start failure
- `pusher_websocket_service.dart` ~231, ~277, ~779, ~820
- `fcm_background_handler.dart` ~20
- `notification_navigation.dart` ~45, ~234
- `chat_conversation_info_page.dart` ~141
- Several `catch (e) { AppLogger.warning('Silently caught exception'...) }` in `chat_page.dart` (~304, ~650)

### Pusher channel/event mismatches

**None on canonical names.** Flutter additionally accepts legacy dotted names. Keep both until `CHAT_BROADCAST_LEGACY_CHANNELS` is turned off.

### Design tokens (chat-relevant)

- Colors: `AppColors` in `lib/core/theme/app_colors.dart` — `accentViolet` `#8B5CF6`, `accentPink` `#EC4899`, `onlineGreen` `#2ECC71`, surfaces, `brandGradient`
- Radius: `AppRadius` 6 / 12 / 16 / 24 / 32 / 999 (`border_radius_constants.dart`)
- Spacing: 4px base (`spacing_constants.dart`)
- Motion: `AppAnimations` (`animation_constants.dart`) — tap 130ms, page 300ms, modal 250ms, `curveDefault = easeOutCubic`, `animationsEnabled` respects `disableAnimations`
- Typography: `AppTypography` / `Theme.textTheme` (Inter)

### Chat-relevant packages (`pubspec.yaml`)

- `pusher_channels_flutter: ^2.4.0`
- `dio: ^5.4.0`
- `flutter_riverpod: ^2.5.1`
- `cached_network_image: ^3.3.1`
- `image_picker: ^1.0.7`
- `file_picker: ^8.1.2`
- `audioplayers: ^6.0.0` (just_audio removed)
- `record: ^6.1.0`
- `flutter_local_notifications: ^17.0.0`
- `firebase_messaging: ^15.1.3`
- `intl: ^0.19.0` — **no `timeago`**
- `lottie: >=3.0.0 <3.3.0`, `animations: ^2.0.8`
- `shared_preferences: ^2.2.2`
- `connectivity_plus: ^5.0.2`
- `photo_view: ^0.14.0`
- `flutter_image_compress: ^2.1.0`
- `permission_handler: ^11.1.0`
- `url_launcher: ^6.2.2`

### Chat-relevant SVG inventory

| Need | Status |
|------|--------|
| send | FOUND `assets/icons/outline/send.svg` (`AppIcons.send`) |
| attach | FOUND `attach-circle.svg` (`AppIcons.attach`) |
| camera / image / gallery | FOUND |
| voice/mic | FOUND `microphone.svg` |
| delete | FOUND `trash.svg` |
| reply | **MISSING** SVG — uses `AppIcons.message`; no `reply.svg` |
| copy | FOUND `copy.svg` |
| forward | FOUND `forward.svg` but `AppIcons.forward` is **`arrow-right`** (wrong glyph) |
| check / check-check | ticks are **CustomPainter** — no double-tick SVG |
| clock pending | FOUND `clock.svg` but sending uses `CircularProgressIndicator` |
| lock | FOUND |
| flame | FOUND `assets/icons/outline/flame.svg` (`AppIcons.flame`) — used on SD send + sender bubble |
| mute | `AppIcons.bellSlash` → legacy `notification-slash.svg` **missing from outline bundle** |
| send | FOUND outline, but `AppIcons.send` still points at **legacy** `assets/images/icons/send.svg` |
| timer / mute / phone / video / search / back / more / emoji / link / download | FOUND |

---

## Enhancement Categories

### Category 1: Real-Time Messaging Core
Optimistic send polish, Pusher ingest, typing, receipts, delivered, list updates, connection UX.

### Category 2: Real-Time Image & Media Delivery
Upload progress, client thumbnail, progressive load, full-screen gallery, permissions.

### Category 3: Self-Destructing Images
Send flow polish, bubble states, accurate countdown, expiry event, screenshot warning.

### Category 4: Notification Suppression Fix
Global active chat, FCM skip, backend Redis + skip OneSignal, in-app banner.

### Category 5: Messenger Page UI & Animations
Reorder animation, badge bounce, search, empty state, presence, swipe actions.

### Category 6: Chat Thread Animations & Micro-interactions
Send/receive motion, typing bubble, jump-to-bottom FAB, sticky dates, context menu, keyboard.

### Category 7: Message Bubbles — Design & Animation
Tails, ticks, linkify, edited, reply quote, voice, system, delete tombstone.

### Category 8: Chat Input — UX & Animation
Send morph, attachment sheet, voice lock, reply/edit bars.

### Category 9: Message Features (Reply, Delete, Copy, Forward)
Delete for everyone, copy, reactions, edit, pin.

### Category 10: Chat Performance & Code Quality
ListView settings, provider split, image memory, dedup map, dispose, logging, dead code.

### Category 11: Backend — Real-Time & Delivery
Event completeness, delivered, link preview, pin (exists — verify), active suppression, mute skip, `after_id`.

### Category 12: Offline & Edge Cases
Outbox (exists — extend), missed messages, retry UX.

---

## Full Enhancement List

### CHAT-RT-001: Optimistic message sending

**Category:** Real-Time Messaging Core  
**Priority:** Critical  
**Effort:** Medium (2–6h)  
**Scope:** Flutter  
**Affects:** `lib/pages/chat_page.dart` (`_handleSend`, `_optimisticMap`, `_replaceOptimisticMessage`, `_isOptimisticMatch` ~557–636, ~1358+)  
**Depends on:** none  
**Telegram equivalent:** message appears instantly before server confirms  
**Current state:** Text/image/voice append immediately with UUID `client_id` (`ChatClientIds.next()`). Sending status is clock SVG. Success maps temp→server via `ChatOptimistic.replaceWithServer` (keeps one row if Pusher already echoed). Retry reuses the same `client_id`. Backend stores/echoes `client_id` on `POST /chat/send` and `MessageSent`.  
**Problem:** Epoch ids can collide; sending spinner is not a clock; no UUID; image progress overlay incomplete.  
**Enhancement:** Generate UUID `tempId`. Status clock SVG while pending. On success map tempId→server id. On Pusher echo match `client_id` then id. Keep existing outbox path.  
**Acceptance criteria:**
- [x] Outgoing text appears in the same frame as send tap (no wait for HTTP)
- [x] No duplicate bubble when `MessageSent` echoes the same `client_id`
- [x] Failed bubble shows retry; tap resends same `client_id`

---

### CHAT-RT-002: Real-time message delivery via Pusher

**Category:** Real-Time Messaging Core  
**Priority:** Critical  
**Effort:** Medium (2–6h)  
**Scope:** Both  
**Affects:** `pusher_websocket_service.dart` `_handleMessageSent` ~481; `chat_page.dart` `_ingestRemoteMessage` ~557; `chat_list_preview_provider.dart` `applyIncomingMessage` ~307; `ChatBroadcastChannels.php`  
**Depends on:** CHAT-RT-001, CHAT-PERF-004  
**Telegram equivalent:** messages appear instantly for recipient  
**Current state:** Payload parsed from `data['message']` plus event `sender`; `Message.fromJson` maps `client_id`, media URLs, reply, expires. Incoming inserts without refresh. Duplicate server ids merge in place. Scrolled-up users get a 52px jump FAB + unseen badge.  
**Problem:** Scrolled-up users miss new messages visually; first-ever conversation row may lack avatar until hydrate.  
**Enhancement:** Keep event names. Add unseen-count when `!_isNearBottom`. Animate insert (CHAT-THREAD-002). Ensure `ChatBroadcastPayload::message` includes `client_id`, media URLs, reply, expires fields (verify payload vs Flutter `Message.fromJson`).  
**Acceptance criteria:**
- [x] Incoming Pusher message appears without refresh
- [x] If not at bottom, FAB badge increments (CHAT-THREAD-004)
- [x] Duplicate id never creates a second row

---

### CHAT-RT-003: Typing indicator — real-time

**Category:** Real-Time Messaging Core  
**Priority:** High  
**Effort:** Small (< 2h)  
**Scope:** Both  
**Affects:** `ChatTypingService.php`; `POST /api/chat/typing` + `POST /api/chat/{id}/typing`; `chat_page.dart` `_onTypingChanged` ~690; `chat_typing_providers.dart`  
**Depends on:** none  
**Telegram equivalent:** “{name} is typing…” instantly  
**Current state:** Backend TTL 5s + `ExpireTypingIndicatorJob`. Flutter start debounce **500ms**, stop after 3s idle, empty composer, focus lost, or dispose (`AppLogger` on failure). Receive auto-hide **6s**. Events `UserTyping` / `UserStoppedTyping`.  
**Problem:** Spec mismatch (400 vs 500); dispose catch empty; no animated bubble enter in list (dots only).  
**Enhancement:** Debounce 500ms. On focus lost / dispose send `typing: false` with `AppLogger`. Keep 6s receive hide. Typing bubble uses CHAT-THREAD-003.  
**Acceptance criteria:**
- [x] Peer sees dots within ~1s of typing
- [x] Dots clear within 6s without heartbeat
- [x] Dispose always sends typing false (logged on failure)

---

### CHAT-RT-004: Read receipts — real-time

**Category:** Real-Time Messaging Core  
**Priority:** High  
**Effort:** Medium (2–6h)  
**Scope:** Both  
**Affects:** `ChatReadReceiptService.php`; `POST /api/chat/read` + `/{id}/read`; `chat_page.dart` `_markAsRead` ~1277 (empty catch); `_initializePusherListeners` read handler ~330; `MessageStatusIndicator`  
**Depends on:** none  
**Telegram equivalent:** ticks turn blue when read  
**Current state:** Open chat clears list unread immediately, then `POST /chat/{id}/read` (fallback `/chat/read`). Failures logged with `AppLogger`. Pusher `MessageRead` matches int/string ids and sets `is_read`/`is_delivered`. Ticks: clock while sending; CustomPainter single/double; read color lerps 300ms unless Reduce Motion. History `mark_as_read: true` on fetch.  
**Problem:** Silent mark-as-read failures; ticks don’t animate; pending uses spinner not clock.  
**Enhancement:** Log mark-as-read failures. Animate tick color 300ms. Map sending → clock SVG.  
**Acceptance criteria:**
- [x] Opening a thread marks unread 0 in list
- [x] Sender ticks go double+read color on `MessageRead` without refresh
- [x] Tick color interpolates 300ms unless `disableAnimations`

---

### CHAT-RT-005: Message delivered status via Pusher

**Category:** Real-Time Messaging Core  
**Priority:** Medium  
**Effort:** Small (< 2h)  
**Scope:** Both  
**Affects:** `POST /api/chat/delivered` (`ChatController::markDelivered`); `ChatDeliveryReceiptService.php`; `chat_page.dart` `_ackIncomingDelivered` ~1655; `chatListSyncProvider` also acks  
**Depends on:** CHAT-RT-004  
**Telegram equivalent:** single tick → double tick  
**Current state:** **Done (CHAT-RT-005).** Recipient acks on ingest + history; `ChatService` dedupes ids in-memory (releases on HTTP failure). Sender applies `MessageDelivered` with string/int id match and does not skip when `_currentUserId` is still null. List preview `applyPeerDelivered` sets double grey ticks for last outgoing. Backend `markDelivered` no-ops already-delivered rows and does not rebroadcast.  
**Problem:** —  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Sender sees double grey tick when recipient’s app receives Pusher message
- [x] No extra HTTP spam for already-delivered ids

---

### CHAT-RT-006: Real-time conversation list updates

**Category:** Real-Time Messaging Core  
**Priority:** High  
**Effort:** Medium (2–6h)  
**Scope:** Flutter  
**Affects:** `chat_list_preview_provider.dart` `applyIncomingMessage`; `chat_list_page.dart` `_filteredChats`  
**Depends on:** CHAT-MSG-001  
**Telegram equivalent:** conversation jumps to top  
**Current state:** **Done (CHAT-RT-006).** `applyIncomingMessage` prepends the row; unread increments only when the peer is not `activePeerUserId`. Avatar/name hydrate from sender payload (incoming only), then `peerAvatarCacheProvider`, then profile fetch. Stale `seedFromMaps` / `getChatUsers` catch-up keeps a newer live preview at the top. List tiles keep identity via `ValueKey` on `ChatListReorderRow`. Slide-to-top is **done (CHAT-MSG-001)**.  
**Problem:** —  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Message to a background conversation moves that row to top without opening the thread
- [x] Unread increments only if that peer is not `activePeerUserId`

---

### CHAT-RT-007: Pusher connection state management

**Category:** Real-Time Messaging Core  
**Priority:** High  
**Effort:** Medium (2–6h)  
**Scope:** Flutter  
**Affects:** `pusher_websocket_service.dart` `connectionStream`; `ChatPusherLifecycleNotifier.reconnect`; `cache_lifecycle_listener.dart`; chat header  
**Depends on:** CHAT-OFFLINE-002  
**Telegram equivalent:** Connecting… / tap to reconnect  
**Current state:** **Done (CHAT-RT-007).** Seeded `connectionStatus` + `chatConnectionBannerProvider`. Grey strip on messenger (`chat_list_page`) and thread (`chat_page` under header): Waiting for network / Connecting… / Tap to reconnect. 400ms show-debounce (hidden is immediate). Exponential backoff 500ms→30s in `reconnect()`; in-flight guard so `disconnect()` does not recurse. Manual banner tap and app resume use `reconnect(manual: true)`. Lifecycle logs via `AppLogger`. Missed messages: `_pollRemoteMessages` uses `after_id` catch-up (CHAT-OFFLINE-002).  
**Problem:** —  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Banner visible within 1s of disconnect
- [x] On reconnect, missed messages merge (existing poll on `connected`; full `after_id` is CHAT-OFFLINE-002)
- [x] No `debugPrint` in lifecycle notifier

---

### CHAT-IMG-001: Real-time image message delivery

**Category:** Real-Time Image & Media Delivery  
**Priority:** High  
**Effort:** Large (> 6h)  
**Scope:** Both  
**Affects:** `chat_page.dart` `_pickAndSendMedia` ~2085; `ChatImageUploadService.php`; `POST /api/chat/{id}/upload-image`; bubble image branch  
**Depends on:** CHAT-RT-001, CHAT-IMG-002  
**Telegram equivalent:** image appears instantly with upload progress  
**Current state:** **Done (CHAT-IMG-001).** Optimistic local `Image.file` thumbnail + Dio `onSendProgress` circular arc (0–100%). Arc fades at 100% (`feedbackShort`; `Duration.zero` if Reduce Motion). Failed send: red close SVG overlay, tap retries. Progress lives in `chatImageUploadProgressProvider` so ticks do not rebuild the whole thread. Recipient list preview already uses `chatMessagePreviewText` → “Photo” on `MessageSent`. Backend `POST /chat/{id}/upload-image` already returns `media_path` / `media_url`; `MessageSent` already includes `media_url`.  
**Problem:** —  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Sender sees local image immediately with 0–100 overlay
- [x] Recipient receives image via Pusher without opening the chat first (list preview “Photo”)

---

### CHAT-IMG-002: Image thumbnail generation client-side

**Category:** Real-Time Image & Media Delivery  
**Priority:** Medium  
**Effort:** Medium (2–6h)  
**Scope:** Both  
**Affects:** `_compressImageIfNeeded`; `ChatImageUploadService` already makes 200px server thumbs  
**Depends on:** CHAT-IMG-001  
**Telegram equivalent:** tiny blur placeholder  
**Current state:** **Done (CHAT-IMG-002).** Client generates a 20×20 JPEG (`ChatImagePlaceholder.fromFile` via `FlutterImageCompress`) plus PNG/JPEG header probe for aspect ratio. Optimistic bubble stores `placeholder_data_uri` / `media_width` / `media_height`. `ChatBubblePhoto` reserves height from aspect (clamped 120–320, fallback 200) and shows `ImageFiltered` blur until the local/network frame arrives. Incoming messages use `media_thumbnail_url` as the blur source. Placeholder is carried across optimistic→server replace. Backend unchanged (local-only data URI).  
**Enhancement:** Generate tiny JPEG, show blurred until CDN loads. Optional send `placeholder` fields if backend accepts; otherwise keep local-only.  
**Acceptance criteria:**
- [x] Optimistic bubble never shows a grey empty box for images
- [x] No layout shift when full image replaces blur (aspect ratio reserved)

---

### CHAT-IMG-003: Progressive image loading in bubbles

**Category:** Real-Time Image & Media Delivery  
**Priority:** Medium  
**Effort:** Small (< 2h)  
**Scope:** Flutter  
**Affects:** `message_bubble.dart` image `OptimizedImage` ~370–388  
**Depends on:** CHAT-IMG-002, CHAT-PERF-003  
**Telegram equivalent:** blur → sharp  
**Current state:** **Done (CHAT-IMG-003).** `ChatBubblePhoto` keeps the IMG-002 reserved aspect box. Network frames use `CachedNetworkImage` `fadeInDuration` ≤200ms (`AppAnimations.imageFadeIn`; `Duration.zero` if Reduce Motion), `memCacheWidth/Height: 800`, and the 20×20 / thumbnail blur as placeholder (download spinner off so blur is not replaced). Local `Image.file` fades the sharp frame over the same blur box.  
**Enhancement:** Aspect-ratio box; `CachedNetworkImage` `fadeInDuration` 200ms; `memCacheWidth/Height: 800`; placeholder from thumb or dominant color.  
**Acceptance criteria:**
- [x] Full image fades in ≤200ms when cached/network completes
- [x] No jump in bubble height

---

### CHAT-IMG-004: Image message tap → full-screen viewer

**Category:** Real-Time Image & Media Delivery  
**Priority:** High  
**Effort:** Large (> 6h)  
**Scope:** Flutter  
**Affects:** `chat_upgrade_widgets.dart` `ChatImageViewer` ~12–50; `message_bubble.dart` Hero  
**Depends on:** none  
**Telegram equivalent:** expand, pinch, swipe album, download  
**Current state:** **Done (CHAT-IMG-004).** `ChatImageViewer` is a thread album: Hero tag `chat_image_{id}`, `InteractiveViewer` 0.5–5×, cached `lgbtfinderCachedImageProvider` / `Image.file`, `PageView` of gallery images, 3s auto-hide chrome, swipe-down dismiss, download via MethodChannel `com.lgbtfinder/gallery_save` (MediaStore / PhotoKit) after permission (Settings sheet if denied).  
**Enhancement:** Hero tag `chat_image_{messageId}`. `InteractiveViewer` 0.5–5×. Cached provider. PageView of conversation images. Download with permission. Auto-hide chrome 3s. Swipe down dismiss.  
**Acceptance criteria:**
- [x] Pinch-zoom works; swipe down closes
- [x] Adjacent images in the same chat are swipeable
- [x] Download saves to gallery after permission

---

### CHAT-IMG-005: Inline image send permission check

**Category:** Real-Time Image & Media Delivery  
**Priority:** Medium  
**Effort:** Small (< 2h)  
**Scope:** Flutter  
**Affects:** `_pickAndSendMedia`, `_handleVoiceRecordStart`; `permission_handler` already in pubspec  
**Depends on:** none  
**Telegram equivalent:** never fail silently  
**Current state:** **Done (CHAT-IMG-005).** Camera / gallery / mic are checked with `permission_handler` before `ImagePicker` or the voice recorder. Denied or permanently denied shows `ChatMediaPermissionSheet` with **Open Settings**. Voice denial returns `false` so the composer never enters the recording bar. Picker failures re-show the sheet.  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Denied permission never looks like a no-op
- [x] Settings button opens OS settings

---

### CHAT-SD-001: Self-destruct image send flow

**Category:** Self-Destructing Images  
**Priority:** High  
**Effort:** Medium (2–6h)  
**Scope:** Flutter  
**Affects:** `chat_page.dart` `_handleMediaTap` ~1947, `_handleMediaLongPress` ~1984, `_startSelfDestructPhotoFlow`, `SelfDestructDurationSheet`  
**Depends on:** CHAT-SD-006  
**Telegram equivalent:** view-once photo  
**Current state:** **Done (CHAT-SD-001).** Long-press attachment: Photo / Self-Destruct Photo (`AppIcons.flame`). Duration pills 5/10/30/60. Sender bubble: flame + `{n}s` + “Waiting to be opened”, never the image. API still sends `disappearing_image` + `expires_in_seconds`. Bold flame + remaining glyphs are CHAT-SD-006.  
**Problem:** No flame icon; long-press does not show Photo vs SD menu (already goes to SD).  
**Enhancement:** Long-press menu: Photo / Self-Destruct Photo (flame). Duration pills 5/10/30/60. Sender bubble copy as specified.  
**Acceptance criteria:**
- [x] Sender bubble shows flame + duration, not the image
- [x] Duration sent as `expires_in_seconds` on API

---

### CHAT-SD-002: Self-destruct bubble states — receiver side

**Category:** Self-Destructing Images  
**Priority:** High  
**Effort:** Medium (2–6h)  
**Scope:** Flutter  
**Affects:** `message_bubble.dart` `_SelfDestructPreviewBubble` / `_SelfDestructExpiredBubble` ~314; `self_destruct_viewer.dart`  
**Depends on:** CHAT-SD-003  
**Telegram equivalent:** unopened / viewing / expired  
**Current state:** **Done (CHAT-SD-002).** Receiver unopened: dark bubble, pulsing flame, “Photo • Tap to view • disappears in {N}s”. Viewer is view-only (InteractiveViewer pinch/pan off, no share/download, FLAG_SECURE, SVG close). Ring color drains primary→amber→error. After viewing, bubble is “Photo expired”; server-expired never-viewed is “Photo no longer available”; both IgnorePointer. Smooth 100ms Stopwatch ring remains CHAT-SD-003.  
**Problem:** —  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Unopened / viewing / expired / never-viewed copy match spec
- [x] Expired bubble is non-tappable

---

### CHAT-SD-003: Self-destruct countdown accuracy

**Category:** Self-Destructing Images  
**Priority:** High  
**Effort:** Medium (2–6h)  
**Scope:** Flutter  
**Affects:** `self_destruct_viewer.dart` `_startCountdown` ~100 (`Timer.periodic` 1s); `POST /api/chat/messages/{id}/view`  
**Depends on:** none  
**Telegram equivalent:** honest timer  
**Current state:** **Done (CHAT-SD-003).** Viewer uses `Stopwatch` + 100ms ticks. Remaining starts from `expires_at` (fallback `remaining_seconds`). At 0: fade 300ms → “Photo has disappeared” 1s → pop expired. Reduce Motion skips fade/hold (`Duration.zero`).  
**Problem:** —  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Ring motion is visually smooth (~10 fps+)
- [x] Close aligns with server remaining time, not tap time

---

### CHAT-SD-004: Self-destruct Pusher expiry propagation

**Category:** Self-Destructing Images  
**Priority:** High  
**Effort:** Small (< 2h)  
**Scope:** Both  
**Affects:** `SelfDestructMessageService::expireMessage` broadcasts `MessageExpired`; `chat_page.dart` ~354; `DeleteExpiredMessages` command  
**Depends on:** none  
**Telegram equivalent:** view-once becomes expired for both  
**Current state:** **Done (CHAT-SD-004).** `MessageExpired` already broadcasts from `SelfDestructMessageService::expireMessage` (job + view window). Flutter keeps the row, matches int/string ids, clears media, and crossfades preview → expired in 300ms (`receiptTick`; `Duration.zero` when Reduce Motion).  
**Problem:** —  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Both clients show expired bubble when job/view window ends
- [x] Row remains in history

---

### CHAT-SD-005: Screenshot detection and warning

**Category:** Self-Destructing Images  
**Priority:** Low  
**Effort:** Large (> 6h)  
**Scope:** Both  
**Affects:** `screenshot_protection.dart` (Android FLAG_SECURE only); new iOS notification; new backend route + system message  
**Depends on:** CHAT-BE-001, CHAT-BUBBLE-007  
**Telegram equivalent:** screenshot notice  
**Current state:** **Done (CHAT-SD-005).** Viewer enables Android `FLAG_SECURE`. iOS `userDidTakeScreenshotNotification` closes the viewer and `POST /chat/messages/{id}/screenshot-detected`. Backend inserts a `system` notice (`screenshot`) and broadcasts `ScreenshotDetected` + `MessageSent`. Centered muted row: “They took a screenshot” / “You took a screenshot”.  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Android screenshots of viewer are blocked (FLAG_SECURE)
- [x] iOS screenshot closes viewer and notifies sender

---

### CHAT-SD-006: Flame SVG for self-destruct

**Category:** Self-Destructing Images  
**Priority:** Medium  
**Effort:** Small (< 2h)  
**Scope:** Flutter  
**Affects:** `assets/icons/` + `AppIcons`; `chat_page.dart` timer icon; SD bubbles  
**Depends on:** none  
**Telegram equivalent:** fire/view-once glyph  
**Current state:** **Done (CHAT-SD-006).** Outline `assets/icons/outline/flame.svg` (`AppIcons.flame`) on send/expired; bold `assets/icons/bold/flame.svg` (`AppIcons.flameBold`) on the unopened receiver pulse. No Material `Icons.*` flame.  
**Problem:** —  
**Enhancement:** —  
**Acceptance criteria:**
- [x] No `Icons.*` Material flame
- [x] SD entry points use the same glyph

---

### CHAT-NOTIF-001: Track active chat conversation ID globally

**Category:** Notification Suppression Fix  
**Priority:** Critical  
**Effort:** Small (< 2h)  
**Scope:** Flutter  
**Affects:** `active_chat_peer_bridge.dart`; `chat_pusher_providers.dart` `openConversation`/`closeConversation`; new `active_chat_provider.dart`  
**Depends on:** none  
**Telegram equivalent:** no banner while looking at that chat  
**Current state:** Tracks **peer user id** and **conversation id** in Riverpod (`activeChatSessionProvider`) + SharedPreferences (`active_chat_peer_user_id`, `active_chat_conversation_id`). `markActiveChat` runs at the start of `openConversation` (even if Pusher is off). 900ms close debounce still clears both. FCM still matches peer only (CHAT-NOTIF-002).  
**Problem:** `connectForUser` (~141–145) still rebuilds `ChatPusherLifecycleState` **without copying `activePeerUserId`** — reconnect/login can wipe suppress (CHAT-NOTIF-006). Empty match chat may not call `openConversation` until history returns an id (CHAT-NOTIF-007).  
**Enhancement:** Preserve `activePeerUserId` in `connectForUser` (CHAT-NOTIF-006). Set peer **immediately in ChatPage.initState** (CHAT-NOTIF-007). Add conversation-id provider. POST `/active` (CHAT-NOTIF-003). Heartbeat 3 min.  
**Acceptance criteria:**
- [x] While `ChatPage` for user 42 is open, `ActiveChatPeerBridge.isActivePeer(42)` is true
- [x] After leave + 900ms, it is false
- [x] Conversation id provider non-null when subscribed

---

### CHAT-NOTIF-002: Suppress FCM notifications for active chat

**Category:** Notification Suppression Fix  
**Priority:** Critical  
**Effort:** Small (< 2h)  
**Scope:** Flutter  
**Affects:** `push_notification_service.dart` `_shouldSuppressMessageAlert` ~526; `fcm_background_handler.dart` `_shouldSuppressBackgroundMessage`  
**Depends on:** CHAT-NOTIF-001  
**Telegram equivalent:** no OS banner in open chat  
**Current state:** Suppress if chat payload (`message` / `chat` / `new_message`) AND (muted OR active peer OR active `conversation_id`). Foreground also `POST /chat/read` for the open peer. Logs with tag `Notifications`.  
**Problem:** OneSignal visible banners used to bypass this; chat pushes are now data-only (CHAT-NOTIF-005). Mute/active skip on the backend is still CHAT-NOTIF-003.  
**Enhancement:** Also match `conversation_id`. Log with `AppLogger` tag `Notifications`. On suppress, `markAsRead` (already opened).  
**Acceptance criteria:**
- [x] Foreground FCM for the open peer never calls `_showLocalNotification`
- [x] Other peers still notify

---

### CHAT-NOTIF-003: Backend-side notification suppression

**Category:** Notification Suppression Fix  
**Priority:** Critical  
**Effort:** Medium (2–6h)  
**Scope:** Backend  
**Affects:** new route `POST /api/chat/{conversationId}/active`; Redis TTL 5 min; `ChatController::sendMessage` before `sendNewMessagePush` ~501; mute check  
**Depends on:** CHAT-NOTIF-001  
**Telegram equivalent:** server knows you’re looking  
**Current state:** Redis/cache `chat:active:{userId}:{conversationId}` TTL 5 min. `POST /api/chat/{conversationId}/active` sets/clears it. `sendNewMessagePush` skips FCM/OneSignal when the recipient is active **or** muted. Flutter heartbeats every 3 min while a real conversation id is open.  
**Enhancement:** Redis `chat:active:{userId}:{conversationId}` TTL 5 min. Skip push if active OR muted (`ChatConversationMuteService`). Heartbeat from Flutter every 3 min. `active:false` deletes key.  
**Acceptance criteria:**
- [x] Feature test: recipient with active key does not call OneSignal/FCM
- [x] Mute skip also covered by test

---

### CHAT-NOTIF-004: In-app notification banner for other conversations

**Category:** Notification Suppression Fix  
**Priority:** High  
**Effort:** Medium (2–6h)  
**Scope:** Flutter  
**Affects:** new overlay widget; `FirebaseMessaging.onMessage`; Pusher `messageStream` when not active peer  
**Depends on:** CHAT-NOTIF-002  
**Telegram equivalent:** top banner  
**Current state:** **Done (CHAT-NOTIF-004).** Foreground chat payloads skip OS local toasts when an in-app banner can show. Slide-down 72px strip (`InAppChatBannerHost` under `IncomingCallHost`): avatar + name + preview, max 2 stacked, same-peer replace. Tap → `go_router` chat. Auto-dismiss 4s (`AppAnimations.inAppChatBannerHold`); swipe up dismisses. Open/muted chats stay suppressed (CHAT-NOTIF-002). Pusher + FCM share `message_id` so they do not double-banner. Reduce Motion jumps the slide.  
**Problem:** —  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Message from another chat while in a thread shows in-app banner, not a second OS toast (if FCM data-only)
- [x] Auto-dismiss 4s; swipe up dismisses

---

### CHAT-NOTIF-005: Stop OneSignal visible pushes for open/muted chats

**Category:** Notification Suppression Fix  
**Priority:** Critical  
**Effort:** Medium (2–6h)  
**Scope:** Backend  
**Affects:** `app/Services/PushNotificationService.php` `send()` ~52–58 (OneSignal first), `sendViaOneSignal` ~78  
**Depends on:** CHAT-NOTIF-003  
**Telegram equivalent:** no duplicate OS notification  
**Current state:** Chat `type=message` skips visible OneSignal. Prefers FCM data-only when `device_token` exists; otherwise silent OneSignal (`content_available`, no headings/contents). Flutter still shows a local banner when the chat is not open (CHAT-NOTIF-002).  
**Problem:** OneSignal used to send `headings`+`contents` and skip FCM, so the app could not suppress OS banners.  
**Enhancement:** For `type=message`, either: (a) data-only OneSignal (`content_available`, no headings) + let the app display, or (b) skip OneSignal and use FCM data-only only. Prefer (b) if player-id users still have `device_token`. Always skip when CHAT-NOTIF-003 active/muted.  
**Acceptance criteria:**
- [x] User in open chat receives **zero** OS banners for that conversation
- [x] Background (app killed, not in chat) still notifies

---

### CHAT-MSG-001: Conversation tile slide-to-top animation

**Category:** Messenger Page UI & Animations  
**Priority:** Medium  
**Effort:** Medium (2–6h)  
**Scope:** Flutter  
**Affects:** `chat_list_page.dart` list; `ChatListItem`; `chat_list_preview_provider.dart`  
**Depends on:** CHAT-RT-006  
**Telegram equivalent:** row slides to top  
**Current state:** **Done (CHAT-MSG-001).** `ChatListReorderList` tracks the last painted id order. Rows that change slot (including a new top row) translate from the previous Y by `rowStride` over 350ms `easeOutCubic`. First hydrate does not play. Reduce Motion uses `Duration.zero`.  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Reorder is animated when animations enabled
- [x] Instant jump when `disableAnimations`

---

### CHAT-MSG-002: Unread badge animation

**Category:** Messenger Page UI & Animations  
**Priority:** Low  
**Effort:** Small (< 2h)  
**Scope:** Flutter  
**Affects:** `chat_list_item.dart` unread `Container` ~207–227  
**Depends on:** none  
**Telegram equivalent:** badge pop  
**Current state:** **Done (CHAT-MSG-002).** `ChatUnreadBadge` bounces with `easeOutBack` scale + digit slide-up over 250ms (`Duration.zero` if Reduce Motion). Counts above 99 still show `99+`.  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Count change animates; 99+ still works

---

### CHAT-MSG-003: Messenger page search

**Category:** Messenger Page UI & Animations  
**Priority:** Medium  
**Effort:** Medium (2–6h)  
**Scope:** Flutter  
**Affects:** `chat_list_page.dart` `_showSearch`, `_searchQuery`, `_buildSearchField` ~376  
**Depends on:** none  
**Telegram equivalent:** search chats  
**Current state:** **Done (CHAT-MSG-003 + CHAT-BE-009).** `ChatListSearchField` animates height 0→56 over 250ms `easeOutCubic` (`Duration.zero` if Reduce Motion). Filter stays local (`ChatListFilter` on name / first / last / preview). Matching substrings use `ColorScheme.primary`. No chats → “No conversations yet”; query with zero hits → “No conversations found”. Trailing X (and header toggle) close and clear. Submitting the field opens `MessageSearchScreen` (`GET /api/chat/search`, 300ms debounce, `conversation_id`).  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Filter is instant (no API)
- [x] Matching substring uses primary color
- [x] X closes and clears

---

### CHAT-MSG-004: Messenger page empty state

**Category:** Messenger Page UI & Animations  
**Priority:** Low  
**Effort:** Small (< 2h)  
**Scope:** Flutter  
**Affects:** `chat_list_empty.dart`; `chat_list_page.dart` empty branch  
**Depends on:** none  
**Telegram equivalent:** empty inbox CTA  
**Current state:** **Done (CHAT-MSG-004).** Inbox empty state keeps the swipe copy and adds **Discover People** (`EmptyState` + `GradientButton`) → Discover tab (`HomeTabRoutes` tab 0). Search-no-hits hides the CTA. Hidden whenever any conversation is listed.  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Empty list shows CTA that navigates to discover
- [x] Hidden when any conversation exists

---

### CHAT-MSG-005: Online presence in conversation list

**Category:** Messenger Page UI & Animations  
**Priority:** Medium  
**Effort:** Medium (2–6h)  
**Scope:** Flutter  
**Affects:** `ChatListItem` / `ChatOnlineDot`; `chat_presence_copy.dart`; `user_presence_cache_provider.dart`; `syncUserStatusSubscriptions`  
**Depends on:** none  
**Telegram equivalent:** green dot + last seen  
**Current state:** **Done (CHAT-MSG-005).** 10px `#22C55E` pip (`ChatOnlineDot`) + 2px card ring. Rows `select` `userPresenceCacheProvider[userId]` so the dot / empty preview update without rebuilding the list. Presence heartbeats no longer call `applyPeerPresence`. Online chip uses live `presenceByUser` overlay. Empty preview is `Active recently` / `Last seen …` via `intl` `DateFormat.MMMd`.  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Dot updates without refreshing the list
- [x] Color is `AppColors.onlineGreen` **or** documented `#22C55E` only

---

### CHAT-MSG-006: Conversation swipe actions

**Category:** Messenger Page UI & Animations  
**Priority:** Medium  
**Effort:** Medium (2–6h)  
**Scope:** Both  
**Affects:** `chat_list_item.dart` (no Dismissible); mute APIs already `PUT/DELETE /api/chat/conversations/{userId}/mute`; pin APIs `PUT/DELETE /api/chat/conversations/{userId}/pin`  
**Depends on:** none  
**Telegram equivalent:** swipe mute/delete/pin  
**Current state:** **Done (CHAT-MSG-006).** Swipe right reveals Pin + Mute (`PUT/DELETE /api/chat/conversations/{userId}/pin` and mute). Swipe left confirms, then hides locally (`chatListHiddenPeersProvider`) with a 5s Undo snackbar. No conversation-delete API — hide is session-only. Long-press still opens Pin/Unpin. Pinned rows sort first (`ChatListFilter`) and show a bookmark.  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Mute swipe hits existing mute API
- [x] Delete asks confirm; Undo restores if we only hide locally pending API
- [x] Conversation pin swipe hits `PUT/DELETE /api/chat/conversations/{userId}/pin`

---

### CHAT-THREAD-001: Message send animation

**Category:** Chat Thread Animations & Micro-interactions  
**Priority:** Medium  
**Effort:** Medium (2–6h)  
**Scope:** Flutter  
**Affects:** `widgets/chat/message_bubble.dart` (Stateless/Consumer — no enter anim). Duplicate `features/.../message_bubble.dart` has unused elastic scale — **do not** switch to it.  
**Depends on:** CHAT-PERF-001  
**Telegram equivalent:** slide up from composer  
**Current state:** **Done (CHAT-THREAD-001).** New outgoing rows play `ChatMessageEnterAnimation`: `Offset(0.15, 0.3)` → 0, fade, scale 0.85→1, 220ms `easeOutCubic`. `ChatMessageEnterGate` skips history/pagination (`markAll`). Reduce Motion sets controller `Duration.zero` and jumps to t=1. Production bubble stays `widgets/chat/message_bubble.dart`.  
**Enhancement:** New outgoing only: offset (0.15, 0.3), fade, scale 0.85→1, 220ms `easeOutCubic`. History loads: no anim (`isNew` flag).  
**Acceptance criteria:**
- [x] Only newly sent/received (not pagination) animate
- [x] `disableAnimations` → Duration.zero

---

### CHAT-THREAD-002: Message receive animation

**Category:** Chat Thread Animations & Micro-interactions  
**Priority:** Medium  
**Effort:** Small (< 2h)  
**Scope:** Flutter  
**Affects:** same bubble wrapper  
**Depends on:** CHAT-THREAD-001  
**Telegram equivalent:** slide in from left  
**Current state:** **Done (CHAT-THREAD-002).** Incoming rows use `ChatMessageEnterAnimation` with `Offset(-0.15, 0.1)` → 0, fade, 260ms `easeOutBack`. Pusher ingest does not `markAll` first so `takeNew` plays; cache/history/pagination call `markAll`. Reduce Motion is `Duration.zero`.  
**Enhancement:** Incoming: Offset(-0.15, 0.1), 260ms `easeOutBack`.  
**Acceptance criteria:**
- [x] Pusher incoming uses receive anim; cache hydrate does not

---

### CHAT-THREAD-003: Typing indicator bubble

**Category:** Chat Thread Animations & Micro-interactions  
**Priority:** Medium  
**Effort:** Small (< 2h)  
**Scope:** Flutter  
**Affects:** `typing_indicator.dart` (opacity pulse, 3 controllers); `chat_peer_typing_indicator.dart`  
**Depends on:** CHAT-RT-003  
**Telegram equivalent:** bouncing dots  
**Current state:** **Done (CHAT-THREAD-003).** One `AnimationController` + `Interval` stagger; dots `translateY` to `-chatTypingDotBounce` (6px). Reduce Motion is static. Switcher exit 200ms. If the viewport is at the latest message, appearing typing pins scroll to 0. Controllers disposed. Feature presentation duplicate unused (CHAT-PERF-008).  
**Enhancement:** translateY -6px stagger; single controller + Intervals; if at bottom, scroll to reveal. Exit 200ms.  
**Acceptance criteria:**
- [x] Dots bounce vertically
- [x] Controllers disposed (already) — keep that

---

### CHAT-THREAD-004: Scroll to bottom button

**Category:** Chat Thread Animations & Micro-interactions  
**Priority:** Medium  
**Effort:** Medium (2–6h)  
**Scope:** Flutter  
**Affects:** `chat_page.dart`, `chat_jump_to_bottom_fab.dart`  
**Depends on:** CHAT-RT-002  
**Telegram equivalent:** down arrow + unread count  
**Current state:** **Done (CHAT-THREAD-004).** 52px SVG chevron FAB via `ChatThreadJumpFabLayer` when scrolled >200px from latest (`ChatUnseenIncoming.fabThreshold`). Badge = `unseenCount` of new peer rows while scrolled up. Hidden at bottom (`showFab` false, scale 0, unseen cleared). Tap `_jumpToLatest` → `animateTo(0)` in 300ms (`chatJumpToBottomScroll`); reverse list latest is pixel 0, not max extent.  
**Enhancement:** 52px FAB when >200px from bottom; unread badge; tap animates to latest 300ms.  
**Acceptance criteria:**
- [x] FAB hidden at bottom
- [x] Badge equals unseen incoming count since last at-bottom

---

### CHAT-THREAD-005: Date separator chips

**Category:** Chat Thread Animations & Micro-interactions  
**Priority:** Medium  
**Effort:** Medium (2–6h)  
**Scope:** Flutter  
**Affects:** `chat_date_badge.dart`; `ChatDateBadgeInserter` in timeline  
**Depends on:** none  
**Telegram equivalent:** floating date  
**Current state:** **Done (CHAT-THREAD-005).** `ChatStickyDateHeader` overlay pins the day at the visual top of the reverse thread. `ChatDateBadge` uses elevated light/dark surface + `textPrimary*` (not always-dark `surfaceElevatedDark`). Inline day pills remain in the list.  
**Enhancement:** Sticky overlay. Theme surface, not hardcoded dark.  
**Acceptance criteria:**
- [x] Current day chip sticks while scrolling that day
- [x] Light mode chip is readable

---

### CHAT-THREAD-006: Jump to replied message

**Category:** Chat Thread Animations & Micro-interactions  
**Priority:** Low  
**Effort:** Medium (2–6h)  
**Scope:** Flutter  
**Affects:** `ChatReplyJump`; `chat_page.dart` `_jumpToRepliedMessage`; `ChatReplyHighlight`; load-older `before_id`  
**Depends on:** CHAT-OFFLINE-002  
**Telegram equivalent:** tap quote → original  
**Current state:** **Done (CHAT-THREAD-006).** Tap quote uses `ChatReplyJump` (`ensureVisible` + reverse-list estimate). If the original is not in the loaded thread, paginate `before_id` (max 12 pages) with the load-older spinner + *Finding original message…*, then jump. 800ms primary wash on the original (`ChatReplyHighlight`); Reduce Motion skips the fade. Still-missing originals snackbar *Original message is not loaded yet*. Concurrent jumps are ignored; in-flight load-older is shared.  
**Enhancement:** Tap quote → `Scrollable.ensureVisible` / index lookup; highlight 800ms. If not loaded, paginate `before_id` until found.  
**Acceptance criteria:**
- [x] Tap quote scrolls to original when in list
- [x] Missing original shows a short loading then jumps or snackbar

---

### CHAT-THREAD-007: Long-press context menu

**Category:** Chat Thread Animations & Micro-interactions  
**Priority:** Medium  
**Effort:** Medium (2–6h)  
**Scope:** Flutter  
**Affects:** `chat_page.dart` `_showMessageActions` ~1618 — `AppActionBottomSheet` Reply / Edit / Delete only. **No** haptic, blur, copy, forward, report.  
**Depends on:** CHAT-FEAT-001, CHAT-FEAT-002, CHAT-FEAT-003, CHAT-THREAD-008  
**Telegram equivalent:** blur + floating menu  
**Current state:** **Done (CHAT-THREAD-007).** Floating `ChatMessageContextMenu`: haptic medium, `ImageFilter.blur(3,3)`, menu scale 0→1 `easeOutBack` 250ms. Bubble lifts to **1.05** while open. Actions: React (UI), Reply (`AppIcons.reply`), Forward (`AppIcons.forward`, CHAT-THREAD-008), Copy, Edit (own text), Delete (own), Report (incoming). Reduce Motion skips scale/blur. Tap outside reverse-animates. SVG only.  
**Enhancement:** Haptic medium; blur; scale 1.05; menu items per spec (no stickers).  
**Acceptance criteria:**
- [x] Long-press never uses `Icons.*`
- [x] Tap outside dismisses with reverse anim

---

### CHAT-THREAD-008: Message forward flow

**Category:** Chat Thread Animations & Micro-interactions  
**Priority:** Low  
**Effort:** Large (> 6h)  
**Scope:** Both  
**Affects:** `POST /chat/messages/{id}/forward`; `ChatMessageForwardService`; `ChatForwardSheet`; `ChatForwardedHeader`  
**Depends on:** CHAT-BE-001  
**Telegram equivalent:** forward sheet  
**Current state:** **Done (CHAT-THREAD-008).** `POST /api/chat/messages/{id}/forward` copies text/media to one or more `canChat` peers (max 20). Attribution is snapshotted (`forwarded_from_name` / user / message id); re-forwards keep the original author. Self-destruct, system, expired, and non-participants are rejected. Ineligible recipients are skipped (`not_eligible`). Flutter: long-press **Forward** (`AppIcons.forward` glyph, not `arrow-right`) opens a multi-select chat picker; bubbles show italic *Forwarded from {name}*.  
**Enhancement:** Backend forward endpoint + “Forwarded from” header. Picker sheet from conversation list.  
**Acceptance criteria:**
- [x] Forward to one or more matches creates messages with attribution
- [x] Cannot forward to non-chat-eligible users

---

### CHAT-THREAD-009: Unread message separator line

**Category:** Chat Thread Animations & Micro-interactions  
**Priority:** Medium  
**Effort:** Medium (2–6h)  
**Scope:** Flutter  
**Affects:** `chat_page.dart` `_loadMessages` / `_markAsRead` (marks all immediately — separator never has a chance)  
**Depends on:** CHAT-RT-004  
**Telegram equivalent:** “N unread messages”  
**Current state:** **Done (CHAT-THREAD-009 / CALLS CHAT-UX-003).** Unread count is captured before mark-as-read; `ChatUnreadSeparatorBar` inserts once per open and hides after scroll-past / jump-to-latest.  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Returning to a chat with unread shows the separator once
- [x] After scroll-past it does not return in that session

---

### CHAT-THREAD-010: Smooth keyboard handling

**Category:** Chat Thread Animations & Micro-interactions  
**Priority:** High  
**Effort:** Small (< 2h)  
**Scope:** Flutter  
**Affects:** `chat_page.dart` Scaffold `resizeToAvoidBottomInset: false`; `ChatKeyboardInsetPad`; `ChatKeyboardAnchor`  
**Depends on:** none  
**Telegram equivalent:** no jump  
**Current state:** **Done (CHAT-THREAD-010).** Scaffold does not resize. `ChatKeyboardInsetPad` applies `viewInsets.bottom` with `AnimatedPadding` 250ms `easeOutCubic` (`Duration.zero` if Reduce Motion). `LayoutBuilder` ticks `jumpTo(maxScrollExtent)` while the pad animates if the user was already near the latest message. Mid-thread stays put. Composer `SafeArea` uses consumed `padding` (0 when the keyboard is up) so it does not double the inset.  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Opening keyboard keeps last message visible if user was at bottom
- [x] No double-padding (scaffold + extra)

---

### CHAT-BUBBLE-001: Bubble tail design + grouping

**Category:** Message Bubbles — Design & Animation  
**Priority:** High  
**Effort:** Medium (2–6h)  
**Scope:** Flutter  
**Affects:** `MessageBubbleChrome` radii: sent bottomRight **zero**, received bottomLeft **zero** (~36–48) — square corner, **not** a painted tail. No `isLastInGroup`.  
**Depends on:** none  
**Telegram equivalent:** tail on last in group  
**Current state:** **Done (CHAT-BUBBLE-001).** Consecutive same-sender runs (`ChatBubbleGrouping`); only last-in-group uses the sharp outer corner (sent `bottomRight` / received `bottomLeft` zero). Mid-run bubbles are fully rounded. Not a painted tail.  
**Enhancement:** CustomPainter/ClipPath 8px tail; consecutive same-sender grouping; 18px radius, 4px tail corner.  
**Acceptance criteria:**
- [x] Only last-in-group shows tail
- [x] Theme colors only (gradient outgoing already)

---

### CHAT-BUBBLE-002: Message timestamp display

**Category:** Message Bubbles — Design & Animation  
**Priority:** High  
**Effort:** Small (< 2h)  
**Scope:** Flutter  
**Affects:** bubble meta row + `MessageStatusIndicator`  
**Depends on:** CHAT-RT-004  
**Telegram equivalent:** HH:mm + ticks inside bubble  
**Current state:** **Done (CHAT-BUBBLE-002).** `AppDateTime.formatChatTime` is Telegram `HH:mm`. Shared `ChatBubbleMetaRow` (`labelSmall`, no hardcoded fontSize) on text/image/voice, sticker, profile, locked, premium-blur, and self-destruct preview/expired. Sending/queued = clock SVG; sent/delivered/read ticks; tick painter wrapped in `RepaintBoundary`. Feature presentation bubble still hardcodes fontSize 11/16 — delete or stop using that file (CHAT-PERF-008).  
**Enhancement:** Clock SVG pending; animate tick color; 11px via `labelSmall` not hardcoded. Feature presentation bubble still hardcodes fontSize 11/16 — delete or stop using that file (CHAT-PERF-008).  
**Acceptance criteria:**
- [x] Every bubble has time
- [x] Outgoing has pending/sent/delivered/read states

---

### CHAT-BUBBLE-003: Text message link detection

**Category:** Message Bubbles — Design & Animation  
**Priority:** Low  
**Effort:** Medium (2–6h)  
**Scope:** Both  
**Affects:** text bubble; `url_launcher` already present; **no** link-preview API  
**Depends on:** CHAT-BE-003  
**Telegram equivalent:** tappable links + preview card  
**Current state:** **Done (CHAT-UX-004 / CHAT-BE-003).** Live `ChatLinkedText` + OG card from `GET /api/link-preview`.  
**Enhancement:** Detect URL/phone/email; preview card from backend.  
**Acceptance criteria:**
- [x] URL opens external browser
- [x] Preview card only when endpoint returns data

---

### CHAT-BUBBLE-004: Edited message indicator

**Category:** Message Bubbles — Design & Animation  
**Priority:** Medium  
**Effort:** Small (< 2h)  
**Scope:** Flutter  
**Affects:** `ChatBubbleMetaRow`; `PATCH /api/chat/message`; `MessageEdited` listener; `ChatEditedApply`  
**Depends on:** CHAT-FEAT-004, CHAT-INPUT-005  
**Telegram equivalent:** “edited”  
**Current state:** **Done (CHAT-BUBBLE-004).** Italic muted `edited` sits next to HH:mm. Sender PATCH and peer `MessageEdited` both `ChatEditedApply.patchRow` (`text` + `is_edited` + `edited_at`) without replacing the row.  
**Enhancement:** —  
**Acceptance criteria:**
- [x] After PATCH, both clients show new text + edited label

---

### CHAT-BUBBLE-005: Reply bubble design

**Category:** Message Bubbles — Design & Animation  
**Priority:** Medium  
**Effort:** Small (< 2h)  
**Scope:** Flutter  
**Affects:** `message_bubble.dart` reply container ~454; `MessageReplyWidget` input bar  
**Depends on:** CHAT-THREAD-006  
**Telegram equivalent:** quoted header  
**Current state:** **Done (CHAT-BUBBLE-005).** In-bubble `ChatReplyQuote`: 3px accent bar, 44px height, name + one-line preview, tap jumps via `Scrollable.ensureVisible` (estimated reverse-list pixels if the original is off-screen). Missing originals paginate then snackbar *Original message is not loaded yet* (CHAT-THREAD-006). Composer reply bar remains `MessageReplyWidget`.  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Quote shows name + one-line preview
- [x] Tap triggers jump

---

### CHAT-BUBBLE-006: Voice message bubble design

**Category:** Message Bubbles — Design & Animation  
**Priority:** Medium  
**Effort:** Medium (2–6h)  
**Scope:** Flutter  
**Affects:** `voice_message_player.dart`; `voice_waveform_bars.dart`  
**Depends on:** none  
**Telegram equivalent:** waveform + speed  
**Current state:** **Done (CHAT-BUBBLE-006).** Width is **min 120** and grows with duration up to the bubble cap. Playhead is a 100ms `CustomPainter` inside `RepaintBoundary` (CHAT-ANIM-011). Speed chip cycles **1 / 1.5 / 2**. Incoming play fires a read receipt once (`onListened` → `markAsRead`). Position `setState` stays inside `VoiceMessagePlayer`, so the thread list does not rebuild. Reduce Motion skips play/pause morph and idle waveform motion.  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Playback does not rebuild the whole message list
- [x] Speed cycles 1 / 1.5 / 2

---

### CHAT-BUBBLE-007: System message bubbles

**Category:** Message Bubbles — Design & Animation  
**Priority:** Low  
**Effort:** Small (< 2h)  
**Scope:** Flutter  
**Affects:** `ChatSystemMessage`; `CallHistoryBubble`; `chat_message_list_tile.dart`  
**Depends on:** CHAT-SD-005  
**Telegram equivalent:** centered service message  
**Current state:** **Done (CHAT-BUBBLE-007).** Screenshot / match / call rows share `ChatSystemMessage`: centered muted `labelSmall` + 14px SVG, no bubble card chrome. Missed calls keep `feedbackError`.  
**Enhancement:** —  
**Acceptance criteria:**
- [x] System rows have no chat-bubble chrome

---

### CHAT-BUBBLE-008: Deleted message tombstone

**Category:** Message Bubbles — Design & Animation  
**Priority:** Medium  
**Effort:** Small (< 2h)  
**Scope:** Flutter  
**Affects:** `chat_page.dart` `MessageDeleted` handler ~397 **removes** the row  
**Depends on:** CHAT-FEAT-001  
**Telegram equivalent:** “This message was deleted”  
**Current state:** **Done (CHAT-BUBBLE-008).** `ChatDeletedTombstone` keeps the row id and shows italic muted “This message was deleted” (no bubble chrome, SVG `AppIcons.block`).  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Delete-for-everyone does not leave a hole without explanation

---

### CHAT-INPUT-001: Send button morph animation

**Category:** Chat Input — UX & Animation  
**Priority:** Medium  
**Effort:** Small (< 2h)  
**Scope:** Flutter  
**Affects:** `widgets/chat/message_input.dart` — rebuilds on text; mic when empty, send when text  
**Depends on:** none  
**Telegram equivalent:** attach/mic → send  
**Current state:** **Done (CHAT-INPUT-001).** Live `MessageInput` morphs mic↔send with fade + scale 0.8→1, 180ms `easeOutBack` (`ChatSendMorphIcon`). Empty = attach + hold-mic; non-empty hides attach and shows send. Reduce Motion is `Duration.zero` (no fade/scale). SVG only.  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Empty = mic (hold) + attach; non-empty = send
- [x] Animations respect reduce motion

---

### CHAT-INPUT-002: Attachment bottom sheet

**Category:** Chat Input — UX & Animation  
**Priority:** Medium  
**Effort:** Medium (2–6h)  
**Scope:** Flutter  
**Affects:** `_handleMediaTap` three actions (camera/gallery/SD) via `AppActionBottomSheet`  
**Depends on:** CHAT-SD-001  
**Telegram equivalent:** attachment grid  
**Current state:** **Done (CHAT-INPUT-002).** Telegram 6-cell attach grid (`ChatAttachmentSheet`): Camera, Gallery, Voice, File, Profile, Self-Destruct. Surface + 20px top radius; SVG cells with 44px min touch; stagger 50ms. File maps photo/video/voice; unsupported files snackbar. Profile uses existing `profile_link`. No stickers in this sheet. Hold-mic on the composer is unchanged.  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Sheet uses surface + 20px top radius
- [x] Each cell SVG + label, 44px min touch

---

### CHAT-INPUT-003: Voice record UX

**Category:** Chat Input — UX & Animation  
**Priority:** Medium  
**Effort:** Large (> 6h)  
**Scope:** Flutter  
**Affects:** `message_input.dart` hold-to-record, slide cancel threshold 72, mic pulse 900ms; `chat_page.dart` `_handleVoiceRecord*`  
**Depends on:** CHAT-IMG-005  
**Telegram equivalent:** hold, slide cancel, slide lock  
**Current state:** **Done (CHAT-INPUT-003).** Hold-to-record; slide left ≥72px cancels (haptic, no send). Slide up ≥72px locks hands-free; release does not send. Locked: send on tap, trash discards. Live 30-bar waveform. Reduce Motion skips mic pulse.  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Slide left cancels without sending
- [x] Lock mode sends on tap, discard on trash

---

### CHAT-INPUT-004: Reply preview in input area

**Category:** Chat Input — UX & Animation  
**Priority:** Medium  
**Effort:** Small (< 2h)  
**Scope:** Flutter  
**Affects:** `MessageReplyWidget` shown when `_repliedToMessage != null` (`chat_page.dart` ~2463)  
**Depends on:** none  
**Telegram equivalent:** reply bar  
**Current state:** **Done (CHAT-INPUT-004).** `MessageReplyWidget` animates 0→56px over 250ms `easeOutCubic` (`chatReplyPreview`); Reduce Motion snaps. Close is SVG (`AppIcons.close`, 44px). Opening reply focuses the composer; X calls `ChatComposerNotifier.clear()` (reply id → null).  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Opening reply focuses composer
- [x] X clears reply id

---

### CHAT-INPUT-005: Edit mode in input area

**Category:** Chat Input — UX & Animation  
**Priority:** Medium  
**Effort:** Small (< 2h)  
**Scope:** Flutter  
**Affects:** `_editingMessageId`; hint “Edit message…”; send calls `_submitEdit`  
**Depends on:** CHAT-FEAT-004  
**Telegram equivalent:** editing bar  
**Current state:** **Done (CHAT-INPUT-005).** Pencil SVG (`chat-edit-pencil`) + send morph to `tickCircle`; attach/voice hidden while editing. Cancel (`composer.clear()` + empty field) restores the empty composer. Confirm still PATCH via `_submitEdit`.  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Cancel restores empty composer
- [x] Confirm PATCH then clears edit mode

---

### CHAT-FEAT-001: Message delete — for everyone

**Category:** Message Features  
**Priority:** Medium  
**Effort:** Medium (2–6h)  
**Scope:** Both  
**Affects:** `DELETE /api/chat/message`; `_deleteOwnMessage`; Pusher `MessageDeleted`  
**Depends on:** CHAT-BUBBLE-008  
**Telegram equivalent:** delete for everyone  
**Current state:** **Done (CHAT-FEAT-001).** Confirm sheet: Delete for me (`DELETE` hide via `for_everyone: false` / `message_hides`) or Delete for everyone (sender, 24h). Soft-delete + `MessageDeleted.for_everyone`; history returns tombstones; after 24h only hide-for-me. Incoming menus still have no Delete.  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Peer sees tombstone, not a missing hole
- [x] After 24h only delete-for-me (hide locally)

---

### CHAT-FEAT-002: Message copy to clipboard

**Category:** Message Features  
**Priority:** Medium  
**Effort:** Small (< 2h)  
**Scope:** Flutter  
**Affects:** `_showMessageActions` — **Copy missing**  
**Depends on:** CHAT-THREAD-007  
**Telegram equivalent:** copy  
**Current state:** **Done (CHAT-FEAT-002).** Context menu Copy (`AppIcons.copy`) writes trimmed text; 2s “Copied” snackbar (`chatCopySnackbarHold`). Copy is text-only — image/video/voice/sticker/profile_link hide it even with a caption.  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Text messages copy; media types hide Copy

---

### CHAT-FEAT-003: Message reactions

**Category:** Message Features  
**Priority:** Low  
**Effort:** Large (> 6h)  
**Scope:** Both  
**Affects:** `ChatReactionChips`; `POST /api/chat/messages/{id}/react`; `MessageReacted`; `ChatMessageReactionService`  
**Depends on:** CHAT-BE-001, CHAT-THREAD-007  
**Telegram equivalent:** emoji chips  
**Current state:** **Done (CHAT-FEAT-003).** POST toggle (same emoji un-reacts; one reaction per user). `MessageReacted` fans out counts. Flutter context-menu ❤️😂😮😢😡👍, chips under both bubbles with 220ms easeOutBack pop (Reduce Motion → `Duration.zero`). Live patch + local payload persist. Orphan `message_reaction_bar.dart` removed.  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Both users see the same counts live
- [x] Toggle same emoji un-reacts

---

### CHAT-FEAT-004: Message edit

**Category:** Message Features  
**Priority:** Medium  
**Effort:** Small (< 2h)  
**Scope:** Both  
**Affects:** `PATCH /api/chat/message`; `ChatMessageEditService`; already in long-press if own text  
**Depends on:** CHAT-INPUT-005  
**Telegram equivalent:** edit  
**Current state:** **Done (CHAT-FEAT-004).** PATCH edit + Pusher `MessageEdited` already in place. UI hides Edit after **24h** (`editWindow`, same as `EDIT_WINDOW_HOURS`). Remaining time is a menu subtitle and composer title (`19h left` / `Editing · 19h left`). Over-window API 422 returns the unified envelope with “This message can no longer be edited.” Live patches keep `edited_at` / `is_edited` on the same row. Pencil bar + send→check is CHAT-INPUT-005.  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Edit >24h rejected with API error shown
- [x] Pusher updates other client in place

---

### CHAT-FEAT-005: Message pin

**Category:** Message Features  
**Priority:** Low  
**Effort:** Medium (2–6h)  
**Scope:** Both  
**Affects:** `POST /api/chat/pin-message` / `unpin-message`; `PinnedMessagesBanner`; `chatPinnedBannerProvider`; context menu  
**Depends on:** CHAT-THREAD-007  
**Telegram equivalent:** pin bar  
**Current state:** **Done (CHAT-FEAT-005).** Pin / Unpin on the bubble menu (`AppIcons.bookmark`). Banner height 0→48 without reloading the thread (`chatPinnedBannerProvider`). Tap jumps via CHAT-THREAD-006. MVP one pin (new pin unpins the previous). Unpin hits `POST /chat/unpin-message`.  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Pin from menu updates banner without full reload
- [x] Unpin via existing unpin endpoint

---

### CHAT-PERF-001: ListView.builder with correct settings

**Category:** Chat Performance & Code Quality  
**Priority:** High  
**Effort:** Medium (2–6h)  
**Scope:** Flutter  
**Affects:** `chat_page.dart`; `ChatThreadListView`  
**Depends on:** none  
**Telegram equivalent:** reverse chat list  
**Current state:** **Done (CHAT-PERF-001).** `ChatThreadListView` is `reverse: true` (pixel 0 = latest). Chronological storage is mapped with `ChatThreadScroll.chronologicalIndex`. Near-latest is `pixels <= 200`; load-older at `maxScrollExtent - 120`. Keyboard pin and jump-to-latest use pixel 0. Reverse list is anchored at the latest row so prepending older history does not need a pixel delta. `ValueKey` remains `client_id` / `id`. `cacheExtent` 1000, keep-alives off, repaint boundaries on.  
**Enhancement:** —  
**Acceptance criteria:**
- [x] `ValueKey` on every bubble (already via client_id/id)
- [x] flutter analyze clean
- [x] Load-older still works after reverse change

---

### CHAT-PERF-002: Provider granularity — no full list rebuilds

**Category:** Chat Performance & Code Quality  
**Priority:** High  
**Effort:** Large (> 6h)  
**Scope:** Flutter  
**Affects:** `ChatPage` local `_messages` setState; `chat_provider.dart` blob `typingUsers`+`currentChatUserId`; `chat_providers.dart`  
**Depends on:** CHAT-PERF-001  
**Telegram equivalent:** independent composer vs list  
**Current state:** **Done (CHAT-PERF-002).** `chatThreadMessagesProvider` / `messagesProvider(peerId)` holds timeline rows; the reverse list watches `select(rows)` only. Typing lives in `chatTypingUsersProvider` (not `ChatState`). Jump FAB / at-bottom is `chatThreadViewportProvider` + `isAtBottomProvider`. Mark-as-read writes `conversationReadStateProvider`. Composer still has its own `TextEditingController`. Full `_messages` ownership moved in CHAT-PERF-007.  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Typing does not rebuild message tiles
- [x] Input text does not rebuild list (already mostly true if we extract list widget)

---

### CHAT-PERF-003: Image memory limit

**Category:** Chat Performance & Code Quality  
**Priority:** Low  
**Effort:** Small (< 2h)  
**Scope:** Flutter  
**Affects:** `OptimizedImage` / `CachedNetworkImage` in bubbles and viewer  
**Depends on:** CHAT-IMG-003  
**Telegram equivalent:** downsampled decode  
**Current state:** **Done (CHAT-PERF-003).** Bubble photos decode at display×DPR and cap at `memCacheWidth` 800 (`ChatImageMemory.bubbleMaxDecode`). Viewer uses cached `lgbtfinderCachedImageProvider` with a 1920 longest-side cap so pinch-zoom stays sharp.  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Chat images pass memCacheWidth 800

---

### CHAT-PERF-004: Message deduplication

**Category:** Chat Performance & Code Quality  
**Priority:** Critical  
**Effort:** Small (< 2h)  
**Scope:** Flutter  
**Affects:** `_ingestRemoteMessage`, `_isOptimisticMatch`, `ChatTimelineMerger`  
**Depends on:** none  
**Telegram equivalent:** one bubble per id  
**Current state:** **Done (CHAT-PERF-004).** Persistent `ChatMessageIndex` maps server id and `client_id` → row index. Ingest hits are O(1) and update in place; list rebuilds dirty the index. `ChatOptimistic.replaceWithServer` and `ChatTimelineMerger.withInFlightOptimistic` use a single pass / client_id set so send+echo never duplicates. Text+time optimistic match remains a rare linear fallback.  
**Problem:** —  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Sending then receiving echo never duplicates
- [x] Lookup O(1) for id hits

---

### CHAT-PERF-005: Dispose all subscriptions and controllers

**Category:** Chat Performance & Code Quality  
**Priority:** Critical  
**Effort:** Medium (2–6h)  
**Scope:** Flutter  
**Affects:** `chat_page.dart` dispose ~160 (good: many cancels); `TypingIndicator`; `VoiceMessagePlayer`; `MessageInput`; `SelfDestructViewer`; `ChatPusherLifecycleNotifier`; `pusher_websocket_service.dispose`  
**Depends on:** none  
**Telegram equivalent:** no leaked sockets  
**Current state:** **Done (CHAT-PERF-005).** ChatPage cancels Pusher/call/presence subs, typing timers, voice recorder, and schedules conversation unsubscribe immediately on dispose (900ms debounce). Voice `AudioPlayer` stream subscriptions are cancelled. Typing dots cancel stagger timers before disposing controllers. Pusher closes event controllers only after `disconnect()`. Lifecycle `onDispose` unsubscribes the open conversation.  
**Problem:** —  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Leaving a chat unsubscribes conversation channel after debounce
- [x] No AnimationController without dispose

---

### CHAT-PERF-006: Remove all silent catch blocks and print()

**Category:** Chat Performance & Code Quality  
**Priority:** Medium  
**Effort:** Medium (2–6h)  
**Scope:** Flutter  
**Affects:** empty catches listed in audit; `debugPrint` in `chat_pusher_providers.dart`, `chat_outbound_queue_service.dart`  
**Depends on:** none  
**Telegram equivalent:** n/a (quality)  
**Current state:** **Done (CHAT-PERF-006).** Chat-path empty `catch (_) {}` replaced with `AppLogger.warning/error` (`Chat` / `Pusher` / `Notifications`). `debugPrint` removed from message search. Swallow-and-continue kept (prefs, prefetch, dispose typing). Tag floors: `Chat`/`Pusher`/`Notifications` at warning.  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Chat-path empty `catch (_) {}` gone
- [x] `flutter analyze` zero issues

---

### CHAT-PERF-007: Split ChatPage god widget

**Category:** Chat Performance & Code Quality  
**Priority:** High  
**Effort:** Large (> 6h)  
**Scope:** Flutter  
**Affects:** `lib/pages/chat_page.dart` (~2500 lines, heavy setState)  
**Depends on:** CHAT-PERF-002  
**Telegram equivalent:** n/a  
**Current state:** **Done (CHAT-PERF-007).** Timeline + load flags live in `chatThreadMessagesProvider` (`ChatMessageIndex` + `ChatMessageEnterGate` on the notifier). `ChatMessageList` and `ChatComposerBar` own list/composer UI. ChatPage no longer `setState`s for `_messages` / reply-edit.  
**Enhancement:** Extract `ChatMessageList`, `ChatComposerBar`, notifiers. Feature screens: Riverpod only.  
**Acceptance criteria:**
- [x] `chat_page.dart` no longer owns `_messages` setState
- [x] Behavior parity (send/receive/pagination)

---

### CHAT-PERF-008: Remove or quarantine dead chat widgets

**Category:** Chat Performance & Code Quality  
**Priority:** Medium  
**Effort:** Small (< 2h)  
**Scope:** Flutter  
**Affects:** `features/chat/presentation/widgets/chat_input.dart` (hardcoded greys, `AppIcons.paperclip` may be missing); `features/chat/presentation/widgets/message_bubble.dart` (hardcoded fontSize 11/16, `Colors.grey`); `widgets/chat/media_picker.dart` TODOs; `audio_recorder_widget.dart`; `audio_player_widget.dart`; `mention_text_widget.dart` TODO  
**Depends on:** none  
**Telegram equivalent:** n/a  
**Current state:** **Done (CHAT-PERF-008).** Deleted unused `features/chat/presentation/widgets/chat_input.dart`, `features/chat/presentation/widgets/message_bubble.dart`, `widgets/chat/media_picker.dart`, `media_picker_bottom_sheet.dart`, `audio_recorder_widget.dart`, `audio_player_widget.dart`, `mention_text_widget.dart`. Live path is `widgets/chat/message_input.dart` + `widgets/chat/message_bubble.dart`.  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Production chat uses only `widgets/chat/message_input.dart` + `widgets/chat/message_bubble.dart`
- [x] No remaining TODO stubs on the live send path

---

### CHAT-BE-001: Ensure all Pusher events are dispatched

**Category:** Backend — Real-Time & Delivery  
**Priority:** Critical  
**Effort:** Medium (2–6h)  
**Scope:** Backend  
**Affects:** `config/chat_broadcasting.php`; `app/Events/*`; `ChatService::broadcastMessageSent`  
**Depends on:** none  
**Telegram equivalent:** complete event set  
**Current state:** **Done (CHAT-BE-001).** Catalog test asserts every 1:1/call/match Event `broadcastAs()` equals `config/chat_broadcasting.php`. Call + match names go through `ChatBroadcastChannels::eventName()`. Flutter `ChatPusherEventNames` covers every config `events` + `legacy_events` value (`call.initiated` → `call.incoming`; `presence.updated` is listen-only). `MessageReacted` is live (CHAT-FEAT-003); `ScreenshotDetected` is live (CHAT-SD-005). Payload already includes `content`/`message`, `client_id`, `is_delivered`, width/height, `duration_seconds`.  
**Enhancement:** Do not rename `UserTyping` to `TypingStarted`. Add events only when features ship. Document in `docs/CHAT_PUSHER_CONVENTIONS.md`. Payload completeness audit vs `Message.fromJson`.  
**Acceptance criteria:**
- [x] Unit tests assert `broadcastAs()` strings
- [x] Flutter switch handles every `broadcastAs` in config `events`

---

### CHAT-BE-002: Message delivered endpoint

**Category:** Backend — Real-Time & Delivery  
**Priority:** Low  
**Effort:** Small (< 2h)  
**Scope:** Backend  
**Affects:** `POST /api/chat/delivered` **exists** (`markDelivered`, throttle 60/min)  
**Depends on:** none  
**Telegram equivalent:** delivered receipt  
**Current state:** **Done (CHAT-BE-002).** Batch `POST /api/chat/delivered` plus alias `POST /api/chat/messages/{id}/delivered` both call `markDelivered`. Flutter keeps the batch path.  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Existing tests in `ChatMessageEditAndDeliveredTest` still pass
- [x] Broadcast `MessageDelivered` payload includes `message_ids`

---

### CHAT-BE-003: Link preview endpoint

**Category:** Backend — Real-Time & Delivery  
**Priority:** Low  
**Effort:** Medium (2–6h)  
**Scope:** Backend  
**Affects:** new `GET /api/link-preview`  
**Depends on:** none  
**Telegram equivalent:** OG card  
**Current state:** `GET /api/link-preview?url=` (auth, `throttle:link_preview` 30/min). `LinkPreviewService` fetches OG tags, caches 24h (5 min on empty), rejects private/loopback URLs. Envelope `{success,message,data,meta}`.  
**Enhancement:** OG fetch, cache 24h, 30/min throttle, `{success,message,data,meta}`.  
**Acceptance criteria:**
- [x] Invalid URL 422
- [x] Repeat URL hits cache

---

### CHAT-BE-004: Message pin endpoint

**Category:** Backend — Real-Time & Delivery  
**Priority:** Low  
**Effort:** Small (< 2h)  
**Scope:** Backend  
**Affects:** pin/unpin/get **already in** `routes/api.php` 489–493  
**Depends on:** none  
**Telegram equivalent:** pin  
**Current state:** **Done (CHAT-BE-004).** Canonical Flutter path is `POST /chat/pin-message` and `POST /chat/unpin-message`. REST aliases `POST /chat/{conversationId}/pin/{messageId}` and `/unpin/{messageId}` call the same actions.  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Existing pin tests pass
- [x] Flutter menu uses one canonical path

---

### CHAT-BE-005: Active chat suppression endpoint

**Category:** Backend — Real-Time & Delivery  
**Priority:** High  
**Effort:** Medium (2–6h)  
**Scope:** Backend  
**Affects:** new `POST /api/chat/{conversationId}/active`  
**Depends on:** CHAT-NOTIF-003  
**Telegram equivalent:** n/a (server support)  
**Current state:** `POST /api/chat/{conversationId}/active` sets/clears `chat:active:{userId}:{conversationId}` (TTL 5 min). Auth required. Non-participant 403. Unknown conversation 404. Flutter heartbeat every 3 min (CHAT-NOTIF-003).  
**Enhancement:** As CHAT-NOTIF-003. Middleware: auth + conversation participant.  
**Acceptance criteria:**
- [x] `active:true` sets Redis TTL 5 min
- [x] `active:false` deletes key
- [x] Non-participant 403

---

### CHAT-BE-006: Skip push when conversation muted

**Category:** Backend — Real-Time & Delivery  
**Priority:** High  
**Effort:** Small (< 2h)  
**Scope:** Backend  
**Affects:** `ChatController::sendMessage` ~500; `ChatConversationMuteService`  
**Depends on:** CHAT-NOTIF-003  
**Telegram equivalent:** muted chat is silent  
**Current state:** `sendNewMessagePush` skips FCM/OneSignal when `ChatConversationMuteService::isConversationMuted` (`messages` or `all`). `ChatController::sendMessage` still broadcasts `MessageSent` first. Stories/feeds mutes do not skip chat push.  
**Enhancement:** Server skip if muted.  
**Acceptance criteria:**
- [x] Muted recipient gets Pusher message, zero push

---

### CHAT-BE-007: Messages after_id catch-up

**Category:** Backend — Real-Time & Delivery  
**Priority:** High  
**Effort:** Small (< 2h)  
**Scope:** Backend  
**Affects:** `handleGetMessages` validates `before_id` only (~672)  
**Depends on:** CHAT-OFFLINE-002  
**Telegram equivalent:** fill gap after reconnect  
**Current state:** **Done (CHAT-BE-007).** `GET /chat/{id}/messages` and `/chat/history` accept `after_id` (`id > after_id`, default/max `per_page` 100). Mutually exclusive with `before_id`. Newest-first rows; `meta.pagination_type=after_id`; `meta.next_cursor.after_id` for paging. OpenAPI via Scramble `QueryParameter`; service + API tests. Flutter catch-up loop is CHAT-OFFLINE-002.  
**Enhancement:** `after_id` returns newer messages (limit 100).  
**Acceptance criteria:**
- [x] `?after_id={last}` returns only newer ids
- [x] Documented in OpenAPI/chat tests

---

### CHAT-OFFLINE-001: Offline message queue

**Category:** Offline & Edge Cases  
**Priority:** Medium  
**Effort:** Medium (2–6h)  
**Scope:** Flutter  
**Affects:** `ChatOutboundQueueService`; `chat_outbound_sync_provider.dart`; `_queueOrFailText` on `ChatPage`  
**Depends on:** none  
**Telegram equivalent:** queued clock  
**Current state:** **Done (CHAT-OFFLINE-001).** SQLite FIFO outbox (max 50); clock SVG on queued bubbles; “Sending queued…” on `ChatConnectionBanner`; `AppLogger`; flush on `connectivity_plus`.  
**Enhancement:** Clock icon for queued; “Sending queued…”; AppLogger; flush FIFO on `connectivity_plus`.  
**Acceptance criteria:**
- [x] Airplane mode send → queued → sends on reconnect
- [x] Order preserved

---

### CHAT-OFFLINE-002: Fetch missed messages on reconnect

**Category:** Offline & Edge Cases  
**Priority:** Medium  
**Effort:** Medium (2–6h)  
**Scope:** Both  
**Affects:** `chat_page.dart` `_pollRemoteMessages` page=1; no after_id  
**Depends on:** CHAT-BE-007, CHAT-RT-007  
**Telegram equivalent:** gap fill  
**Current state:** **Done (CHAT-OFFLINE-002).** On reconnect, `_pollRemoteMessages` loops `GET /chat/history?after_id=lastId` (page size 100) until empty. Dedup via existing ingest index. Empty threads still poll page 1.  
**Enhancement:** —  
**Acceptance criteria:**
- [x] 50 messages sent while offline all appear after reconnect

---

### CHAT-OFFLINE-003: Message send retry

**Category:** Offline & Edge Cases  
**Priority:** Medium  
**Effort:** Small (< 2h)  
**Scope:** Flutter  
**Affects:** `_retryFailedMessage`; `MessageStatusIndicator` failed refresh icon  
**Depends on:** CHAT-RT-001  
**Telegram equivalent:** tap to retry  
**Current state:** Retry exists; max 3 then “Failed to send”; “Retry” label under bubble.  
**Enhancement:** Visible retry label; max 3 then permanent failed.  
**Acceptance criteria:**
- [x] Three failures lock with “Failed to send”
- [x] Tap retries while under max

---

### CHAT-NOTIF-006: Preserve active peer across Pusher reconnect

**Category:** Notification Suppression Fix  
**Priority:** Critical  
**Effort:** Small (< 2h)  
**Scope:** Flutter  
**Affects:** `chat_pusher_providers.dart` `connectForUser` ~105–109; `reconnect()` ~213  
**Depends on:** CHAT-NOTIF-001  
**Telegram equivalent:** stay silent in the open chat after network blip  
**Current state:** `connectForUser` uses `setConnectedUser` / `copyWith`, so `activePeerUserId` survives reconnect. `reconnect()` restores conversation + `syncUserStatusSubscriptions` for list peers (via `ChatListPresencePeersBridge`) plus the open peer. Logs via `AppLogger`.  
**Problem:** After resume/reconnect, banners fired for the chat the user was still looking at.  
**Enhancement:** Always pass through `activePeerUserId`. `reconnect()` must call `syncUserStatusSubscriptions` for the current list peers. Never `debugPrint`.  
**Acceptance criteria:**
- [x] Reconnect while `ChatPage` is open keeps `ActiveChatPeerBridge.isActivePeer` true
- [x] List online dots still update after reconnect

---

### CHAT-NOTIF-007: Register active peer before history loads

**Category:** Notification Suppression Fix  
**Priority:** Critical  
**Effort:** Small (< 2h)  
**Scope:** Flutter  
**Affects:** `chat_page.dart` `initState` / `_subscribePusherConversation`  
**Depends on:** CHAT-NOTIF-001  
**Telegram equivalent:** empty match chat is still “open”  
**Current state:** `ChatPage.initState` calls `markActiveChat(peerUserId)` before history. Empty match chats suppress FCM immediately. Local/list conversation id is used to subscribe as soon as it is a real conversation id (not the peer user id). Leave with no conversation id still clears after 900ms.  
**Enhancement:** `ActiveChatPeerBridge.setActivePeer(widget.userId)` in `initState`. Subscribe conversation as soon as id is known.  
**Acceptance criteria:**
- [x] Opening an empty match chat suppresses FCM from that peer immediately

---

### CHAT-BE-008: History SELECT includes delivery/edit/reply fields

**Category:** Backend — Real-Time & Delivery  
**Priority:** High  
**Effort:** Small (< 2h)  
**Scope:** Backend  
**Affects:** `ChatMessageHistoryService.php` `baseQuery` select list ~212–217  
**Depends on:** none  
**Telegram equivalent:** ticks and quotes survive refresh  
**Current state:** **Done (CHAT-BE-008).** History `baseQuery` selects `delivered_at`, `edited_at`, `reply_to_message_id`, `updated_at`, `client_id` and eager-loads `replyTo.sender`. JSON includes `is_delivered` / `is_edited` / `reply_to_text` / `reply_to_name` after refresh.  
**Enhancement:** Add those columns to the select (or select `messages.*` with explicit safe list).  
**Acceptance criteria:**
- [x] History JSON includes `is_delivered` / `is_edited` / `reply_to_message_id` when DB has them
- [x] Existing history tests updated

---

### CHAT-BE-009: Fix chat search `chat_id` filter

**Category:** Backend — Real-Time & Delivery  
**Priority:** Medium  
**Effort:** Small (< 2h)  
**Scope:** Backend  
**Affects:** `ChatController::searchMessages` ~1373–1416 (`where('chat_id', $chatId)` on `messages`)  
**Depends on:** none  
**Telegram equivalent:** search in this chat  
**Current state:** **Done (CHAT-BE-009).** `GET /api/chat/search` validates `conversation_id` (`exists:conversations,id` → 422; non-participant → 403) and filters `where('conversation_id')`. Flutter sends `conversation_id` (legacy `chatId` aliased). Messenger search submit opens `MessageSearchScreen` with 300ms debounce.  
**Enhancement:** —  
**Acceptance criteria:**
- [x] `?conversation_id=` returns only that thread
- [x] Invalid id 422, not a query on a missing column conceptually

---

### CHAT-BE-010: Align message notification preference key

**Category:** Backend — Real-Time & Delivery  
**Priority:** High  
**Effort:** Small (< 2h)  
**Scope:** Backend  
**Affects:** `NotificationPermissionService::canReceiveNotification` looks up `$preferences['message']`; prefs stored as `message_notifications`  
**Depends on:** CHAT-NOTIF-003  
**Telegram equivalent:** settings actually mute chat push  
**Current state:** `canReceiveNotification('message')` reads `message`, `message_notifications`, `chat`, and `new_message`. Any of those set to `false` denies chat push.  
**Enhancement:** Read both keys; treat `message_notifications === false` as deny. Add a regression test.  
**Acceptance criteria:**
- [x] User with `message_notifications: false` receives no chat push

---

### CHAT-IMG-007: Play video messages in-thread / viewer

**Category:** Real-Time Image & Media Delivery  
**Priority:** Medium  
**Effort:** Medium (2–6h)  
**Scope:** Flutter  
**Affects:** `message_bubble.dart` video branch ~390–439 (`video_player` already in pubspec); `ChatConversationInfoPage` shared video tap ignored  
**Depends on:** CHAT-IMG-004  
**Telegram equivalent:** tap video to play  
**Current state:** **Done (CHAT-IMG-007).** Thread tap and conversation-info video tiles open `ChatVideoViewer`. `ChatMediaPlayback.interrupt()` pauses in-thread voice when another player starts.  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Tap video plays fullscreen or inline
- [x] Opening another media stops the previous player

---

### CHAT-PERF-009: Stop O(n²) messenger filter + map tick fields

**Category:** Chat Performance & Code Quality  
**Priority:** High  
**Effort:** Small (< 2h)  
**Scope:** Flutter  
**Affects:** `chat_list_page.dart` `_filteredChats` used in `isEmpty`, `itemCount`, and every `itemBuilder`; `_chatToMap` ~263  
**Depends on:** none  
**Telegram equivalent:** 60fps list  
**Current state:** **Done (CHAT-PERF-009).** `ChatListFilter.apply` walks the list once per build (filter + search). `_chatToMap` is `ChatListPreviewItem.fromChat(chat).toMap()`, so `last_message_from_me` / read / delivered / `last_message_id` seed the list before Pusher.  
**Enhancement:** Compute `_filteredChats` once per build into a local list. Include `last_message_from_me` / read / delivered in `_chatToMap`.  
**Acceptance criteria:**
- [x] One filter pass per frame
- [x] Outbound ticks show before Pusher catch-up when API provided them

---

### CHAT-MSG-008: Matches row respects premium and tablet split

**Category:** Messenger Page UI & Animations  
**Priority:** Medium  
**Effort:** Small (< 2h)  
**Scope:** Flutter  
**Affects:** `chat_matches_row.dart` `context.push` ~59; `chat_list_page.dart` hides row when `compactHeader`  
**Depends on:** none  
**Telegram equivalent:** same entry path as conversation tap  
**Current state:** **Done (CHAT-MSG-008).** `ChatMatchesRow.onMatchTap` → `_openPeerChat` / `_handleChatTap`. Row also shows on the tablet master pane (`compactHeader` no longer hides it).  
**Enhancement:** —  
**Acceptance criteria:**
- [x] Free user tapping a match sees upgrade sheet
- [x] Tablet opens the embedded `ChatPage`

---

## Implementation Order

### Tier 1 — Critical (implement first — breaks user trust if missing)

1. CHAT-NOTIF-001 — Active chat ID tracking (notification bug)
2. CHAT-NOTIF-006 — Preserve active peer across reconnect
3. CHAT-NOTIF-007 — Register active peer before history loads
4. CHAT-NOTIF-002 — Suppress FCM for active chat
5. CHAT-NOTIF-005 — Stop OneSignal visible pushes (actual OS-banner leak)
6. CHAT-NOTIF-003 — Backend notification suppression
7. CHAT-BE-005 — Active chat suppression endpoint
8. CHAT-BE-006 — Skip push when muted
9. CHAT-BE-010 — Align notification preference key
10. CHAT-RT-001 — Optimistic message sending
11. CHAT-RT-002 — Real-time message delivery fix
12. CHAT-RT-003 — Typing indicator real-time
13. CHAT-RT-004 — Read receipts real-time
14. CHAT-PERF-004 — Message deduplication
15. CHAT-PERF-005 — Dispose all subscriptions
16. CHAT-BE-001 — All Pusher events firing correctly

### Tier 2 — High (core UX quality)

14. CHAT-SD-001 — Self-destruct send flow
15. CHAT-SD-002 — Self-destruct bubble states
16. CHAT-SD-003 — Countdown accuracy
17. CHAT-SD-004 — Pusher expiry
18. CHAT-SD-006 — Flame SVG
19. CHAT-IMG-001 — Real-time image delivery
20. CHAT-IMG-002 — Client-side thumbnail
21. CHAT-IMG-003 — Progressive image loading
22. CHAT-IMG-004 — Full-screen viewer
23. CHAT-RT-006 — Real-time conversation list
24. CHAT-RT-007 — Pusher connection management
25. CHAT-NOTIF-004 — In-app notification banner
26. CHAT-THREAD-010 — Smooth keyboard handling
27. CHAT-PERF-001 — ListView settings
28. CHAT-PERF-002 — Provider granularity
29. CHAT-PERF-007 — Split ChatPage
30. CHAT-BUBBLE-001 — Bubble tail design
31. CHAT-BUBBLE-002 — Timestamp + tick display
32. CHAT-BE-007 — after_id catch-up
33. CHAT-BE-008 — History SELECT missing fields
34. CHAT-PERF-009 — Messenger O(n²) filter

### Tier 3 — Medium (polish and delight)

33. CHAT-THREAD-001 — Message send animation
34. CHAT-THREAD-002 — Message receive animation
35. CHAT-THREAD-003 — Typing bubble animation
36. CHAT-THREAD-004 — Scroll to bottom button
37. CHAT-THREAD-005 — Date separator chips
38. CHAT-THREAD-007 — Long-press context menu
39. CHAT-THREAD-009 — Unread separator
40. CHAT-MSG-001 — Conversation slide-to-top
41. CHAT-MSG-003 — Search
42. CHAT-MSG-006 — Conversation swipe actions
43. CHAT-INPUT-001 — Send button morph
44. CHAT-INPUT-002 — Attachment bottom sheet
45. CHAT-INPUT-003 — Voice record UX
46. CHAT-INPUT-004 — Reply preview
47. CHAT-FEAT-001 — Delete for everyone
48. CHAT-BUBBLE-008 — Deleted tombstone
49. CHAT-FEAT-002 — Copy to clipboard
50. CHAT-FEAT-004 — Message edit
51. CHAT-BUBBLE-005 — Reply bubble design
52. CHAT-BUBBLE-006 — Voice bubble design
53. CHAT-OFFLINE-001 — Offline queue
54. CHAT-OFFLINE-003 — Message retry
55. CHAT-PERF-006 — Silent catch blocks
56. CHAT-PERF-008 — Dead widgets
57. CHAT-INPUT-005 — Edit mode indicator
58. CHAT-IMG-007 — Video playback
59. CHAT-MSG-008 — Matches row premium/tablet
60. CHAT-BE-009 — Fix search chat_id filter

### Tier 4 — Enhancement (Telegram parity)

61. CHAT-SD-005 — Screenshot detection
62. CHAT-RT-005 — Delivered status polish
63. CHAT-THREAD-006 — Jump to replied message
64. CHAT-THREAD-008 — Message forward
65. CHAT-MSG-002 — Unread badge animation
66. CHAT-MSG-004 — Empty state
67. CHAT-MSG-005 — Online presence updates
68. CHAT-BUBBLE-003 — Link detection
69. CHAT-BUBBLE-004 — Edited indicator
70. CHAT-BUBBLE-007 — System message bubbles
71. CHAT-FEAT-003 — Message reactions
72. CHAT-FEAT-005 — Message pin
73. CHAT-IMG-005 — Permission check
74. CHAT-BE-002 — Delivered endpoint alias
75. CHAT-BE-003 — Link preview endpoint
76. CHAT-BE-004 — Pin endpoint aliases
77. CHAT-OFFLINE-002 — Missed messages on reconnect
78. CHAT-PERF-003 — Image memory limit

---

## Progress Tracker

| ID | Title | Tier | Status | Notes |
|----|-------|------|--------|-------|
| CHAT-NOTIF-001 | Active chat ID | 1 | [x] | `activeChatSessionProvider` + prefs conversation id |
| CHAT-NOTIF-006 | Preserve peer on reconnect | 1 | [x] | `copyWith` + list presence resync |
| CHAT-NOTIF-007 | Active peer before history | 1 | [x] | `primeActivePeer` in initState; subscribe when id known |
| CHAT-NOTIF-002 | Suppress FCM | 1 | [x] | Peer + conversation_id; mark-as-read on open chat |
| CHAT-NOTIF-005 | OneSignal visible leak | 1 | [x] | Chat pushes are FCM/silent OS |
| CHAT-NOTIF-003 | Backend suppression | 1 | [x] | Redis active key + mute skip in sendNewMessagePush |
| CHAT-BE-005 | /active endpoint | 1 | [x] | POST; TTL 5 min; 403 non-participant |
| CHAT-BE-006 | Mute skip push | 1 | [x] | sendNewMessagePush skips; MessageSent still fires |
| CHAT-BE-010 | Pref key `message` vs `message_notifications` | 1 | [x] | Both keys deny chat push |
| CHAT-RT-001 | Optimistic send | 1 | [x] | UUID client_id + clock SVG; backend echo |
| CHAT-RT-002 | Pusher ingest | 1 | [x] | Ingest + jump FAB unseen badge; sender avatar |
| CHAT-RT-003 | Typing | 1 | [x] | 500ms start; 6s hide; dispose logs stop |
| CHAT-RT-004 | Read receipts | 1 | [x] | Log failures; 300ms tick color; string-id match |
| CHAT-PERF-004 | Dedup map | 1 | [x] | O(1) id + client_id index; echo does not duplicate |
| CHAT-PERF-005 | Dispose | 1 | [x] | 900ms unsub; player/typing timers cancelled |
| CHAT-BE-001 | Pusher events | 1 | [x] | Catalog + Flutter names; reactions deferred |
| CHAT-SD-001 | SD send | 2 | [x] | Long-press Photo/SD; pills 5/10/30/60; sender flame+duration |
| CHAT-SD-002 | SD states | 2 | [x] | Unopened pulse + 4 copy states; view-only viewer; color drain |
| CHAT-SD-003 | Countdown | 2 | [x] | Stopwatch + 100ms ring; expires_at; fade then disappeared copy |
| CHAT-SD-004 | Expiry event | 2 | [x] | Keep row; 300ms fade; string/int id match |
| CHAT-SD-006 | Flame SVG | 2 | [x] | Outline + bold flame; unopened receiver uses bold |
| CHAT-IMG-001 | Image delivery | 2 | [x] | Local thumb + 0–100 arc; list preview Photo |
| CHAT-IMG-002 | Client thumb | 2 | [x] | 20×20 JPEG blur + reserved aspect |
| CHAT-IMG-003 | Progressive load | 2 | [x] | Fade ≤200ms + memCache 800; height reserved |
| CHAT-IMG-004 | Viewer | 2 | [x] | Album swipe, pinch, cached, download, swipe-down |
| CHAT-RT-006 | List realtime | 2 | [x] | Jump-to-top + unread skip open thread; cache hydrate |
| CHAT-RT-007 | Connection UX | 2 | [x] | Connecting… / tap to reconnect; backoff |
| CHAT-NOTIF-004 | In-app banner | 2 | [x] | 72px stack-2; 4s; swipe up; no OS toast |
| CHAT-THREAD-010 | Keyboard | 2 | [x] | AnimatedPadding 250ms; pin ticks; no double pad |
| CHAT-PERF-001 | ListView | 2 | [x] | reverse:true; load-older at max extent |
| CHAT-PERF-002 | Providers | 2 | [x] | List watches rows; typing/viewport split |
| CHAT-PERF-007 | Split ChatPage | 2 | [x] | List+composer extracted; rows via notifier |
| CHAT-BUBBLE-001 | Tails/group | 2 | [x] | Sharp corner on last-in-group only |
| CHAT-BUBBLE-002 | Time + ticks | 2 | [x] | HH:mm labelSmall + clock; ticks on outgoing |
| CHAT-BE-007 | after_id | 2 | [x] | GET messages?after_id= last; max 100 |
| CHAT-BE-008 | History SELECT fields | 2 | [x] | delivered/edited/reply/client_id on history |
| CHAT-PERF-009 | Messenger O(n²) filter | 2 | [x] | One-pass filter; ticks in _chatToMap |
| CHAT-THREAD-001 | Send anim | 3 | [x] | Offset(0.15,0.3) 220ms; gate skips history |
| CHAT-THREAD-002 | Receive anim | 3 | [x] | Offset(-0.15,0.1) 260ms; cache gated |
| CHAT-THREAD-003 | Typing bounce | 3 | [x] | translateY -6 Interval stagger; exit 200ms |
| CHAT-THREAD-004 | Jump FAB | 3 | [x] | 52px; >200px; badge=unseen; hidden at bottom |
| CHAT-THREAD-005 | Sticky dates | 3 | [x] | Overlay sticky; light/dark elevated chip |
| CHAT-THREAD-007 | Context menu | 3 | [x] | Blur + 1.05 lift; SVG; reverse dismiss |
| CHAT-THREAD-009 | Unread sep | 3 | [x] | `ChatUnreadSeparator` / CALLS CHAT-UX-003 |
| CHAT-MSG-001 | Slide-to-top | 3 | [x] | 350ms easeOutCubic; Reduce Motion jumps |
| CHAT-MSG-003 | Search polish | 3 | [x] | 0→56 250ms; primary highlight; X clears |
| CHAT-MSG-006 | Swipe | 3 | [x] | Reveal Pin+Mute; pin API; hide/undo |
| CHAT-INPUT-001 | Send morph | 3 | [x] | 180ms easeOutBack fade+scale; attach hides when text |
| CHAT-INPUT-002 | Attach grid | 3 | [x] | 6 SVG cells; 20px radius; 44px; stagger 50ms; no stickers |
| CHAT-INPUT-003 | Voice lock | 3 | [x] | Slide-left cancel; slide-up lock; tap send / trash discard |
| CHAT-INPUT-004 | Reply anim | 3 | [x] | 0→56 250ms; auto-focus; X clears reply id |
| CHAT-FEAT-001 | Delete everyone | 3 | [x] | Confirm sheet; 24h unsend; hide-for-me; peer tombstone |
| CHAT-BUBBLE-008 | Tombstone | 3 | [x] | Italic muted; id kept (wired with FEAT-001) |
| CHAT-FEAT-002 | Copy | 3 | [x] | Clipboard + 2s Copied; media types hide Copy |
| CHAT-FEAT-004 | Edit polish | 3 | [x] | 24h window in UI; remaining-time subtitle; edited_at in-place |
| CHAT-BUBBLE-005 | Reply design | 3 | [x] | 3px/44px quote; tap jumps or snackbar if unloaded |
| CHAT-BUBBLE-006 | Voice design | 3 | [x] | Width≥120 by duration; 100ms painter; listen→read; 1/1.5/2x |
| CHAT-OFFLINE-001 | Outbox UX | 3 | [x] | Clock + Sending queued…; FIFO flush; AppLogger |
| CHAT-OFFLINE-003 | Retry max 3 | 3 | [x] | Retry label; 3 fails lock Failed to send |
| CHAT-PERF-006 | Logging | 3 | [x] | Empty catch → AppLogger; Chat/Pusher/Notifications tags |
| CHAT-PERF-008 | Dead widgets | 3 | [x] | Deleted unused chat widgets |
| CHAT-INPUT-005 | Edit bar | 3 | [x] | Pencil + send→tick; cancel clears |
| CHAT-IMG-007 | Video playback | 3 | [x] | Viewer + interrupt voice |
| CHAT-MSG-008 | Matches row gate | 3 | [x] | `_openPeerChat`; shown on tablet |
| CHAT-BE-009 | Search conversation_id | 3 | [x] | Filter + 422/403; messenger submit |
| CHAT-SD-005 | Screenshot | 4 | [x] | FLAG_SECURE; iOS notify + system row |
| CHAT-RT-005 | Delivered polish | 4 | [x] | Deduped POST /chat/delivered; string-id ticks; no second MessageDelivered |
| CHAT-THREAD-006 | Jump to reply | 4 | [x] | Paginate before_id + 800ms wash |
| CHAT-THREAD-008 | Forward | 4 | [x] | POST /messages/{id}/forward + picker |
| CHAT-MSG-002 | Badge bounce | 4 | [x] | 250ms easeOutBack + 99+ |
| CHAT-MSG-004 | Empty CTA | 4 | [x] | Discover People → tab 0 |
| CHAT-MSG-005 | Presence copy | 4 | [x] | 10px `#22C55E` + last-seen empty preview |
| CHAT-BUBBLE-003 | Links | 4 | [x] | Tappable + OG card |
| CHAT-BUBBLE-004 | Edited label | 4 | [x] | Italic muted next to time |
| CHAT-BUBBLE-007 | System bubbles | 4 | [x] | Centered labelSmall + 14px SVG |
| CHAT-FEAT-003 | Reactions | 4 | [x] | POST toggle + MessageReacted + chip pop |
| CHAT-FEAT-005 | Pin from menu | 4 | [x] | Menu Pin/Unpin; bar 0→48; jump |
| CHAT-IMG-005 | Permissions | 4 | [x] | Sheet + Open Settings before picker/mic |
| CHAT-BE-002 | Delivered alias | 4 | [x] | Batch + POST /messages/{id}/delivered |
| CHAT-BE-003 | Link preview | 4 | [x] | GET /link-preview OG cache |
| CHAT-BE-004 | Pin aliases | 4 | [x] | Body canonical; REST pin/unpin aliases |
| CHAT-OFFLINE-002 | Reconnect gap | 4 | [x] | after_id loop until empty |
| CHAT-PERF-003 | memCache | 4 | [x] | Bubble cap 800; viewer 1920 |

---

## Constraints Reference

- NO stickers — explicitly excluded (do not expand `StickerMessageService` / `_StickerBubble`)
- NO Icons.* — AppSvgIcon only
- NO hardcoded hex — AppColors / Theme.of(context) only  
  Exception: `Color(0xFF22C55E)` for online dot **or** keep `AppColors.onlineGreen` after aligning it
- NO hardcoded font sizes — textTheme only
- NO setState in feature screens — Riverpod only (`ChatPage` still uses setState for header/presence; timeline is CHAT-PERF-007)
- All animations: check `MediaQuery.disableAnimations` / `AppAnimations.animationsEnabled`
- All AnimationControllers: disposed in dispose()
- All StreamSubscriptions: cancelled in dispose()
- All Pusher channels: unsubscribed in dispose() of chat thread (after debounce)
- RepaintBoundary around every CustomPainter (`MessageStatusIndicator` painter needs wrapping)
- AppLogger for all logging — never print() / debugPrint()
- Response shape: `{success, message, data, meta}`
- Do not touch `LGBTinder-flutter/`
- Do not modify existing migrations
- Tier spellings: basid | silder | golden — never change
- Production widgets: `lib/widgets/chat/message_bubble.dart` + `lib/widgets/chat/message_input.dart` (not the features/ duplicates)

### Backend chat routes (authenticated `prefix chat`)

| Method | Path | Action |
|--------|------|--------|
| POST | `/chat/send` | sendMessage (throttle:messages) |
| POST | `/chat/{conversationId}/upload-image` | uploadImage |
| POST | `/chat/{conversationId}/upload-voice` | uploadVoice |
| POST | `/chat/messages/{messageId}/view` | viewMessage (self-destruct) |
| GET | `/chat/history` | getChatHistory |
| GET | `/chat/{conversationId}/messages` | getConversationMessages (`before_id`, `after_id`) |
| GET | `/chat/users` | getChatUsers |
| DELETE | `/chat/message` | deleteMessage |
| PATCH | `/chat/message` | editMessage |
| POST | `/chat/delivered` | markDelivered |
| POST | `/chat/messages/{id}/delivered` | markMessageDelivered (CHAT-BE-002 alias) |
| POST | `/chat/typing` | setTyping |
| POST | `/chat/{conversationId}/typing` | setConversationTyping |
| POST | `/chat/read` | markAsRead |
| POST | `/chat/{conversationId}/read` | markConversationAsRead |
| POST | `/chat/online` | setOnlineStatus |
| POST/GET | pin-message / unpin / pinned-messages / pinned-count | pins (canonical) |
| POST | `/chat/{conversationId}/pin/{messageId}` | pinConversationMessage (CHAT-BE-004 alias) |
| POST | `/chat/{conversationId}/unpin/{messageId}` | unpinConversationMessage (CHAT-BE-004 alias) |
| GET | `/chat/search` | searchMessages |
| GET/PUT/DELETE | `/chat/conversations/{userId}/mute` | mute |
| POST | `/chat/{id}/active` | setConversationActive |
| POST | `/chat/messages/{id}/forward` | ChatController@forwardMessage (CHAT-THREAD-008) |
| POST | `/chat/messages/{id}/react` | ChatController@reactToMessage (CHAT-FEAT-003) |
| GET | `/link-preview` | `LinkPreviewController@show` (CHAT-BE-003) |
| POST | `/chat/messages/{id}/screenshot-detected` | ChatController@screenshotDetected (CHAT-SD-005) |

In-chat presence route: **NO**

---

*End of document.*
