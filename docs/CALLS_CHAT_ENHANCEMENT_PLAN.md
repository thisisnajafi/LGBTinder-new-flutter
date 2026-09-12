---
# Calls & Chat Enhancement Plan
> Generated: 2026-09-11
> Audited by: Claude (Sonnet 4.6)
> Status key: [ ] pending · [x] done · [!] blocked
---

## Audit Summary

The live call path is already a working Agora + Pusher + CallKit stack, not a stub. Flutter’s real UI is a single full-screen `OutgoingCallPage` (`lib/features/calls/pages/outgoing_call_page.dart`) used for outgoing, incoming-accepted, voice, and video. Signaling is complete on both sides: Laravel `CallController` exposes initiate / accept / reject / end / busy plus `POST /api/calls/{callId}/agora-token`; Pusher events `call.incoming`, `call.accepted`, `call.rejected`, `call.ended`, and `call.busy` are broadcast with `broadcastAs()` on `private-call.{id}` plus user channels. Native incoming UI is wired through `CallKitService` + `fcm_background_handler.dart`. Chat is similarly mature: `ChatPage` uses `ListView.builder`, date badges, inline `CallHistoryBubble`, optimistic send, pagination with scroll compensation, reply preview, long-press action sheet, voice waveform playback, and image Hero open.

The main gaps are quality and completeness, not missing endpoints. Agora’s handler in `AgoraService` covers join/leave, user join/offline, mute video, error, network quality, and token expiry — but not `onConnectionStateChanged`, `onRemoteVideoStateChanged`, `onLocalVideoStateChanged`, `onWarning`, `onRtcStats`, `onFirstRemoteVideoFrame`, `onAudioVolumeIndication`, or `onAudioRouteChanged`. The call screen is one large `setState` tree (timer ticks rebuild video). Permissions are requested only inside `AgoraService.initialize()` after the backend call already exists. Busy is an API + event, but Flutter only auto-busies a second *incoming banner*, not an in-progress `OutgoingCallPage`. Call duration is computed from `started_at` (ring time included), not `answered_at`. `_qualityFromScore` maps Agora `QualityType.index` backwards (unknown/excellent look “good”; good looks “poor”), and `CallQualityMonitor` then forces `'bad'` because `getCallStats()` has no bitrate. `CallState.copyWith` cannot clear `activeCall`. Lock-screen Decline often never hits `POST reject`. Several screens/widgets are dead duplicates (`VideoCallScreen`, `VoiceCallScreen`, `call_controls.dart`, `call_timer.dart`, `features/chat/.../message_bubble.dart`, `chat_input.dart`).

Chat animations are basic or absent on the live widgets: send/receive have no slide/fade, typing dots exist without `disableAnimations`, the send button already morphs mic→send, reply preview does not slide, long-press is a bottom sheet (not a scaled blur menu), there is no jump-to-bottom FAB, no unread separator, no reactions, no link previews, and `MessageReplyWidget` still uses `Icons.close`. Logging is inconsistent: Pusher uses `AppLogger`, but CallKit, incoming-call accept/reject, Agora callbacks, and `CallQualityMonitor` still use `debugPrint` or silent `catch (_) {}`.

Overall quality is production-capable for the happy path (ring → accept → talk → hang up, chat send/receive, missed-call job at 45s) and needs a focused pass on Agora lifecycle, reconnection, atomic Riverpod state, native return-to-call, and chat micro-interactions.

---

## Enhancement Categories
### Category 1: Call System — Missing Features
### Category 2: Call System — UI & Animation
### Category 3: Call System — Performance & Code Quality
### Category 4: Call System — Native Device Integration
### Category 5: Chat — Animations & Micro-interactions
### Category 6: Chat — UX Enhancements
### Category 7: Chat — Performance
### Category 8: Cross-cutting — Logging & Error Handling

---

## Full Enhancement List

### CALL-FEAT-001: Complete Agora callback implementation
**Category:** Call System — Missing Features
**Priority:** Critical
**Effort:** Large (> 6h)
**Scope:** Flutter only
**Affects:** `lib/shared/services/agora_service.dart`, `lib/features/calls/pages/outgoing_call_page.dart`, `lib/shared/services/call_quality_monitor.dart`
**Depends on:** none
**Current state:**
`AgoraService.initialize()` (lines 61–100) registers `RtcEngineEventHandler` with: `onJoinChannelSuccess`, `onLeaveChannel`, `onUserJoined`, `onUserOffline`, `onUserMuteVideo`, `onError`, `onNetworkQuality`, `onTokenPrivilegeWillExpire`, `onRequestToken`, `onConnectionLost`. Public callbacks are `onConnectionStateChanged(bool)`, `onRemoteUserJoined`, `onRemoteUserLeft`, `onRemoteVideoMuted`, `onError`, `onNetworkQuality`, `onTokenRefreshRequired`. `OutgoingCallPage._joinAgoraChannel()` (346–438) wires those to `setState`. Missing SDK callbacks: `onConnectionStateChanged` (real Agora enum), `onRemoteVideoStateChanged`, `onLocalVideoStateChanged`, `onWarning`, `onRtcStats`, `onFirstRemoteVideoFrame`, `onAudioVolumeIndication`, `onAudioRouteChanged`, `onRejoinChannelSuccess`. `onUserOffline` ignores `UserOfflineReasonType` (dropped vs quit). `getCallStats()` (245–256) returns only in-call flags, not bitrate/loss/fps — so `CallQualityMonitor._startQualityMonitoring()` never gets real stats.
**Problem:**
Users see a generic “Connection failed” or a remote video that never appears. There is no reconnecting UI, no speaking ring, no camera-failure state, and dropped vs hang-up cannot be distinguished. After 8s of remote leave, the call auto-ends (`_remoteLeftTimer`).
**Enhancement:**
Implement the missing handlers on the main isolate. Map connection states to UI: connecting / reconnecting overlay / connected / failed. Use `UserOfflineReasonType.userOfflineDropped` → “Reconnecting…” vs `userOfflineQuit` → end call. Drive remote placeholder from `onRemoteVideoStateChanged`. Translate `ErrorCodeType` to user-facing copy. Enable `enableAudioVolumeIndication` and expose speaking uid. Forward `onRtcStats` into `CallQualityMonitor`. Log every callback via `AppLogger` (see LOG-001).
**Acceptance criteria:**
- [x] All listed Agora callbacks are registered in `AgoraService` and invoked on the UI isolate
- [x] Dropped remote user shows reconnecting for up to 8s; quit ends the call with “Call ended”
- [x] Camera failure shows a placeholder, not a black tile
- [x] `onError` never surfaces raw SDK strings; `AppLogger.error` always records the code

---

### CALL-FEAT-002: Concurrent call detection (busy state)
**Category:** Call System — Missing Features
**Priority:** High
**Effort:** Medium (2–6h)
**Scope:** Both
**Affects:** `incoming_call_provider.dart` `present()` (47–82), `CallService::busy()`, `CallService::assertNoActiveCallBetween()`, `OutgoingCallPage`
**Depends on:** none
**Current state:**
Any local live session (banner, `callProvider.activeCall`, minimized session, Agora in-call) POSTs `/busy` on a *different* `call.incoming` and does not show a second banner/CallKit. Backend `assertNoLiveCallConflict` rejects initiate if *either* user has initiating|ringing|active with anyone. Same-pair still returns the rejoin message. `CallBusy` payload unchanged.
**Problem:**
A user on an active video call can still receive a second ring. The new caller is not reliably told “busy”; they may sit in ringing until the 45s miss job.
**Enhancement:**
Treat any non-idle local session (`OutgoingCallPage` mounted / `callProvider.activeCall` live / incoming banner showing) as busy. On `call.incoming` while busy: `POST /{callId}/busy`, do not show a second banner, optionally a missed-call local notification. Backend: reject initiate if *either* participant has `STATUS_ACTIVE|RINGING|INITIATING` with anyone. Keep `CallBusy` payload as today (`call_id`, `call_type`, `status`).
**Acceptance criteria:**
- [x] Second incoming while on a call never joins Agora; caller receives `call.busy`
- [x] Backend initiate fails with a clear validation error if either user is already in a live call
- [x] First call is uninterrupted

---

### CALL-FEAT-003: Call timeout and missed call
**Category:** Call System — Missing Features
**Priority:** High
**Effort:** Small (< 2h)
**Scope:** Both
**Affects:** `CheckMissedCall.php`, `UpdateMissedCalls.php`, `incoming_call_provider.dart` auto-dismiss, `CallHistoryBubble`, chat timeline
**Depends on:** CALL-UI-010
**Current state:**
**Done.** Shared 45s timeout: `Call::RING_TIMEOUT_SECONDS` / Flutter `CallRingTimeout`. `CheckMissedCall` and cron `calls:update-missed` both call `CallService::markMissedIfUnanswered` (atomic ringing|initiating → `missed`, `CallEnded` with `status` + caller/receiver ids). Flutter banner, CallKit, and outgoing page dismiss UI only — no `POST reject`. Chat upserts the missed bubble from the event payload so a later GET cannot skip or overwrite it.
**Problem:**
Caller vs callee can disagree (rejected vs missed). Cron can double-process after the 45s job. Flutter reject-on-timeout is the wrong terminal status for “nobody answered”.
**Enhancement:**
Single source of truth: 45s ringing timeout. Flutter timeout should dismiss UI only (or call a dedicated missed endpoint) — do **not** `POST reject`. Align `UpdateMissedCalls` to 45s or remove it in favor of the job. Keep inline chat bubbles; ensure timeline refresh on `call.ended` with status missed.
**Acceptance criteria:**
- [x] Unanswered call is `missed` after ~45s on both clients
- [x] No `rejected` status from timeout
- [x] Chat thread shows a missed-call bubble without a refresh race

---

### CALL-FEAT-004: Call reconnection handling
**Category:** Call System — Missing Features
**Priority:** High
**Effort:** Medium (2–6h)
**Scope:** Flutter only
**Affects:** `agora_service.dart`, `outgoing_call_page.dart`
**Depends on:** CALL-FEAT-001
**Current state:**
Overlay + `onRejoinChannelSuccess` exist from CALL-FEAT-001. No retry cap, no media restore, no hang-up after failed reconnect. `connectivity_plus` was unused on the call page.
**Problem:**
A brief network blip ends or freezes the call with no recovery.
**Enhancement:**
On Agora reconnecting / connection lost during active call: overlay “Reconnecting…” with an animated indicator (`disableAnimations` respected). Auto-rejoin up to 3 times; then end with “Connection lost” and `POST end`. Restore speaker/mute/camera after rejoin.
**Acceptance criteria:**
- [x] Transient drops show reconnecting UI and recover without hanging up
- [x] After 3 failed retries the call ends with a user-visible reason
- [x] Mute/camera/speaker state is preserved across rejoin

---

### CALL-FEAT-005: Call quality degradation warning
**Category:** Call System — Missing Features
**Priority:** Medium
**Effort:** Small (< 2h)
**Scope:** Flutter only
**Affects:** `outgoing_call_page.dart` lines 384–389, 441–446, 655–676
**Depends on:** CALL-UI-007
**Current state:**
**Done.** `CallQualityToast` shows for Agora quality 4–5 (`bad` / `vbad`) and auto-hides after 3s (`callQualityToastHold`) with `snackbarTransition`. `CallQualityToastGate` rising-edge + 5s debounce prevents spam. Poor (3) stays on CALL-UI-007 bars only. Hidden while reconnecting. Copy/colors from theme tokens + warning SVG.
**Problem:**
The chip stays on screen and never explains recovery. Excellent/good has no indicator at all.
**Enhancement:**
Keep a subtle toast for quality 4–5 that auto-hides after 3s (`AppAnimations.snackbarTransition`). Pair with CALL-UI-007 bars. Do not toast on every quality tick — debounce 5s.
**Acceptance criteria:**
- [x] Poor/very-poor shows a toast that dismisses after 3s
- [x] Toasts are debounced; no spam
- [x] Copy and colors come from theme tokens, not hardcoded hex

---

### CALL-FEAT-006: Agora token refresh before expiry
**Category:** Call System — Missing Features
**Priority:** High
**Effort:** Small (< 2h)
**Scope:** Flutter only
**Affects:** `agora_service.dart` 91–122, `outgoing_call_page.dart` 390–401, `CallSignalingService.fetchAgoraToken`, backend `AgoraTokenService` TTL 3600
**Depends on:** none (mostly done)
**Current state:**
`onTokenPrivilegeWillExpire` / `onRequestToken` call `_refreshToken()` → `renewToken`. Page fetches `POST /calls/{id}/agora-token`. Proactive timer fires 5 minutes before `expiresAt`. Empty tokens are not passed to `renewToken`. Failed refresh is logged and shown once if the call then drops.
**Problem:**
If the refresh callback is cleared in `dispose` mid-call, or `expiresAt` is in the past, the call can still drop at 1 hour. Empty token is renewed silently.
**Enhancement:**
Do not call `renewToken` with empty string. Schedule a fallback refresh 5 minutes before `expiresAt`. Keep handlers attached for the whole session. Log success/failure (LOG-001 / LOG-002).
**Acceptance criteria:**
- [x] Token renews before 3600s without dropping media
- [x] Failed refresh is logged and shown once if the call then fails
- [x] `renewToken` is never called with an empty token

---

### CALL-FEAT-007: Screen wake lock during calls
**Category:** Call System — Native Device Integration
**Priority:** High
**Effort:** Small (< 2h)
**Scope:** Flutter only
**Affects:** `outgoing_call_page.dart` 340, 516, 587; pubspec `wakelock_plus: ^1.2.8`
**Depends on:** none (mostly done)
**Current state:**
`CallWakeLock` enables on `OutgoingCallPage` mount (ringing included). Disable on hang-up and always in `dispose` (`force`). Not disabled when backgrounded. Enable is idempotent.
**Problem:**
Outgoing ringing can still sleep the screen before answer. Background policy is undefined.
**Enhancement:**
Enable wake lock as soon as `OutgoingCallPage` mounts; disable only when the route is popped / call ended. Keep lock while backgrounded so voice calls continue (do **not** disable on background). Log enable/disable with `AppLogger`.
**Acceptance criteria:**
- [x] Screen stays awake from ringing through hang-up
- [x] Wake lock is always released in `dispose` even on error
- [x] No double-enable crash

---

### CALL-FEAT-008: Permission pre-check before call initiation
**Category:** Call System — Missing Features
**Priority:** Critical
**Effort:** Medium (2–6h)
**Scope:** Flutter only
**Affects:** `agora_service.dart` `_requestPermissions` 124–136, `OutgoingCallPage._startOutgoing` 240–278, `incoming_call_provider.accept`
**Depends on:** none
**Current state:**
Mic (and camera for video) are requested inside `AgoraService.initialize()`, which runs in `_joinAgoraChannel()` **after** `initiateCall` has already created a ringing call. Denied throws `Exception('Microphone permission is required…')` which `_userFacingCallError` maps to “Connection failed”. No settings bottom sheet. Permanently denied is not distinguished. Incoming accept has the same order.
**Problem:**
Callee already rings while the caller is stuck in the OS permission dialog. Denial looks like a network failure.
**Enhancement:**
Check/request permissions **before** `POST /initiate` and **before** `POST /accept`. If denied: explanation sheet with “Open Settings” (`openAppSettings()`), never start signaling. If permanently denied, skip the OS prompt and go straight to Settings. Do not let Agora initialize on denial.
**Acceptance criteria:**
- [x] No backend initiate/accept occurs without granted mic (and camera for video)
- [x] Denied state shows a sheet, not “Connection failed”
- [x] Opening Settings is offered when permanently denied

---

### CALL-FEAT-009: Record duration from answered_at, not started_at
**Category:** Call System — Missing Features
**Priority:** High
**Effort:** Small (< 2h)
**Scope:** Backend only
**Affects:** `VideoCallService::endCall()` lines 197–207, `Call` model `duration_seconds`, chat `CallLogLabels`
**Depends on:** none
**Current state:**
`VideoCallService::endCall()` stores `talkDurationSeconds` = `ended_at - answered_at` (0 if never answered). Unanswered `CallService::end()` still forces `duration_seconds = 0`. `Call` accessor uses the same talk-time formula. No migration change.
**Problem:**
Chat bubbles show inflated “Voice call · 3m 24s” including 45s of ringing.
**Enhancement:**
Duration = `ended_at - answered_at` when `answered_at` is set; else 0. Add a test in `CallSignalingTest` / `CallVoiceVideoE2ETest`. Do **not** edit existing migrations.
**Acceptance criteria:**
- [x] Connected call duration excludes ringing
- [x] Missed/rejected/cancelled stay at 0 seconds
- [x] Feature test covers the answered path

---

### CALL-UI-001: Outgoing call pulsing ring animation
**Category:** Call System — UI & Animation
**Priority:** High
**Effort:** Medium (2–6h)
**Scope:** Flutter only
**Affects:** `outgoing_call_page.dart` (no AnimationController today), `call_stage_placeholder.dart`
**Depends on:** none
**Current state:**
Three concentric rings around the callee avatar while Connecting/Ringing (`CallOutgoingPulseRings`). One 2400ms `AnimationController` with three 1800ms intervals staggered 300ms. Stops on accept/decline/end. Reduce Motion is a static ring. Controller disposed. `RepaintBoundary` around the painter.
**Problem:**
The ringing screen feels dead compared to the rest of the app.
**Enhancement:**
Three concentric circles from the avatar, staggered 300ms, scale 1.0→2.0 and fade 1.0→0.0 over 1800ms, infinite. One `AnimationController` with three `Interval`s. Stop immediately on `_callConnected`. Respect `MediaQuery.disableAnimations`. Dispose the controller. `RepaintBoundary` around the painter/rings. SVG avatar only; theme colors at 20% opacity.
**Acceptance criteria:**
- [x] Rings pulse while status is Ringing/Connecting
- [x] Rings stop on accept/decline/end
- [x] Reduce Motion shows a static ring or none
- [x] Controller is disposed

---

### CALL-UI-002: Call connect transition animation
**Category:** Call System — UI & Animation
**Priority:** Medium
**Effort:** Medium (2–6h)
**Scope:** Flutter only
**Affects:** `outgoing_call_page.dart` `_onCallAccepted` (322–344)
**Depends on:** CALL-UI-001
**Current state:**
`CallConnectHost` plays a one-shot 400ms `easeOutCubic` on `setConnected(true)`: pulse rings collapse (scale 1→0.6 + fade), stage fades/scales in (0.92→1), timer fades up from 12px. Reduce Motion and an already-connected first frame jump to t=1. Pulse freeze (no controller reset) so the last ring frame collapses.
**Problem:**
Connect is a hard cut to video/controls.
**Enhancement:**
On `call.accepted`: collapse pulsing rings (400ms `easeOutCubic`), fade/scale in remote video or avatar, fade the timer in from below. Skip if `disableAnimations`.
**Acceptance criteria:**
- [x] Connect transition runs once when the call becomes active
- [x] Timer is hidden until connected, then fades in
- [x] Reduce Motion skips to the connected layout

---

### CALL-UI-003: Call end transition animation
**Category:** Call System — UI & Animation
**Priority:** Medium
**Effort:** Medium (2–6h)
**Scope:** Flutter only
**Affects:** `_endCall`, `_onCallEnded`, `_onCallRejected`, `leaveCallRoute`
**Depends on:** none
**Current state:**
Hang-up / remote end / decline / busy: Agora dispose + end POST start immediately. 300ms fade-to-black + summary card (call-type SVG, reason, `CallDurationFormatter.formatLong` when connected). Auto-dismiss 3s then `leaveCallRoute`. Reduce Motion: skip fade, card 1s.
**Problem:**
Users cannot see duration or why the call ended.
**Enhancement:**
On hang-up / `call.ended`: 300ms fade to black, summary card slides up (duration via `CallDurationFormatter.formatLong`, call-type SVG, reason: declined / missed / ended / busy / connection lost). Auto-dismiss after 3s then `leaveCallRoute`. Reduce Motion: skip fade, show card 1s.
**Acceptance criteria:**
- [x] Connected calls show duration on the summary card
- [x] Route pops only after the card (or Reduce Motion timeout)
- [x] Agora leave still happens immediately so media stops

---

### CALL-UI-004: Mute/unmute micro-animation
**Category:** Call System — UI & Animation
**Priority:** Medium
**Effort:** Small (< 2h)
**Scope:** Flutter only
**Affects:** `outgoing_call_page.dart` `_CallActionButton`, `_toggleMute` 538–541
**Depends on:** none
**Current state:**
`CallMuteButton` → `_CallActionButton`: 150ms `AnimatedSwitcher` icon crossfade, press scale `AppAnimations.buttonPressScale` (130ms), muted `AnimatedContainer` 200ms `colorScheme.error` @ 20%. Reduce Motion uses `Duration.zero` and skips press scale. Tokens: `callMuteIconCrossfade`, `callMuteTint`.
**Problem:**
Mute state is easy to miss on video.
**Enhancement:**
150ms icon crossfade + press scale `AppAnimations.buttonPressScale`. Muted: `AnimatedContainer` 200ms background `colorScheme.error` at 20% opacity. SVG only.
**Acceptance criteria:**
- [x] Icon morphs; muted button is error-tinted
- [x] Animation skipped when Reduce Motion is on

---

### CALL-UI-005: Speaking indicator animation
**Category:** Call System — UI & Animation
**Priority:** Medium
**Effort:** Medium (2–6h)
**Scope:** Flutter only
**Affects:** `agora_service.dart`, header avatar in `outgoing_call_page.dart`, PiP in `agora_call_video_layer.dart`
**Depends on:** CALL-FEAT-001
**Current state:**
`enableAudioVolumeIndication` + `onAudioVolumeIndication` drive `localSpeakingProvider` / `remoteSpeakingProvider`. `CallSpeakingRing` pulses scale 1.0→1.12, opacity 0.8→0, 400ms (`callSpeakingPulse`). Header + voice avatar = remote; PiP / local placeholder = local. `RepaintBoundary` around the painter. Reduce Motion: static ring. Controller disposed.
**Problem:**
On voice calls it is unclear who is talking.
**Enhancement:**
`enableAudioVolumeIndication`. Pulse ring scale 1.0→1.12, opacity 0.8→0, 400ms, while volume > threshold; stop at 0. Local and remote. `RepaintBoundary`. Reduce Motion: static ring while speaking.
**Acceptance criteria:**
- [x] Active speaker’s avatar pulses; silence stops the animation
- [x] Works for local and remote
- [x] No pulse when Reduce Motion is on (static indicator only)

---

### CALL-UI-006: Video PiP (picture-in-picture) local preview
**Category:** Call System — UI & Animation
**Priority:** High
**Effort:** Medium (2–6h)
**Scope:** Flutter only
**Affects:** `agora_call_video_layer.dart` (PiP at 150–180)
**Depends on:** CALL-PERF-002
**Current state:**
Local preview is a draggable PiP that defaults to **bottom-right** above controls. Drag lifts to 1.05, then snaps to the nearest corner (`elasticOut` 400ms, or linear 200ms with Reduce Motion). Tap toggles small/large (3:4). Long-press flips the camera. `AgoraVideoView` stays in `RepaintBoundary`; controllers are not recreated.
**Problem:**
PiP can cover the remote face and is easy to lose off the controls.
**Enhancement:**
Default bottom-right above controls. Drag start scale 1.05; drag end snap to nearest corner (`Curves.elasticOut` 400ms) unless Reduce Motion (linear 200ms). Tap toggles 120×160 vs 160×213 (use spacing tokens / breakpoints, not magic if possible). Long press → `switchCamera`. Wrap each `AgoraVideoView` in `RepaintBoundary`.
**Acceptance criteria:**
- [x] PiP snaps to a corner after drag
- [x] Tap resizes; long-press flips camera
- [x] Remote/local video does not flash green on control rebuilds

---

### CALL-UI-007: Network quality signal indicator
**Category:** Call System — UI & Animation
**Priority:** Medium
**Effort:** Small (< 2h)
**Scope:** Flutter only
**Affects:** `outgoing_call_page.dart` header, `agora_service.dart` `onNetworkQuality`
**Depends on:** CALL-FEAT-001
**Current state:**
4-bar `CallNetworkSignal` in `OutgoingCallHeader` (voice + video). Fill: excellent 4 / good 3 / poor 2 / bad 1. Colors: 1–2 `feedbackSuccess`, 3 `feedbackWarning`, 4–5 `feedbackError`. `AnimatedContainer` 300ms (`callSignalBar`); Reduce Motion `Duration.zero`. Watches `networkQualityProvider` only.
**Problem:**
Users cannot glance at signal the way they do on a phone call.
**Enhancement:**
4-bar indicator top-right. Fill from Agora quality 1=excellent→5=poor. Colors: 1–2 `feedbackSuccess`, 3 `feedbackWarning`, 4–5 `feedbackError`. `AnimatedContainer` 300ms per bar. No hardcoded hex (except documented online green if needed). Hide or freeze when Reduce Motion.
**Acceptance criteria:**
- [x] Bars update with Agora quality
- [x] Colors are semantic tokens
- [x] Indicator is present on voice and video

---

### CALL-UI-008: In-app incoming call overlay
**Category:** Call System — UI & Animation
**Priority:** High
**Effort:** Small (< 2h)
**Scope:** Flutter only
**Affects:** `incoming_call_banner.dart`, `IncomingCallHost`, `incoming_call_provider.dart`
**Depends on:** none (mostly done)
**Current state:**
Foreground Pusher `call.incoming` → `IncomingCallBanner` (~80px, `easeOutBack` 400ms). Decline `POST reject`. 45s timeout dismisses UI only (no reject). Accept → `openActiveCallPage`. Background uses CallKit. Legacy overlay remains `@Deprecated`.
**Problem:**
Height is not 80px; curve is not `easeOutBack` 400ms; accept from banner does not play connect animation (CALL-UI-002).
**Enhancement:**
Polish to spec: ~80px content height, `Curves.easeOutBack` 400ms (or `AppAnimations` token if added), keep SVG + theme colors. Timeout dismiss without `POST reject` (CALL-FEAT-003). Accept → `openActiveCallPage`.
**Acceptance criteria:**
- [x] Foreground incoming always shows the banner, never a second full-screen until accept
- [x] Decline hits reject API; timeout does not
- [x] Animation respects Reduce Motion

---

### CALL-UI-009: Call controls auto-hide on video calls
**Category:** Call System — UI & Animation
**Priority:** High
**Effort:** Small (< 2h)
**Scope:** Flutter only
**Affects:** `outgoing_call_page.dart` `_buildControlSheet` (728–828)
**Depends on:** none
**Current state:**
`CallHudHost` + `CallHudPolicy` auto-hide video HUD (header + quality chip + controls) after 4s idle once connected. Stage tap / control press resets idle. Voice never auto-hides. Reduce Motion: fade duration zero. Reconnecting overlay and PiP stay outside the fade. Dead `call_controls.dart` unchanged.
**Problem:**
Controls cover the remote video for the whole call.
**Enhancement:**
Video only: hide after 4s idle; tap stage to show and reset timer. `AnimatedOpacity` 250ms. Voice: never auto-hide. Header (name/timer/signal) may hide with controls on video. Reduce Motion: instant hide/show.
**Acceptance criteria:**
- [x] Video controls hide after 4s and return on tap
- [x] Voice controls stay visible
- [x] End button remains reachable (tap to reveal)

---

### CALL-UI-010: Call history inline in chat thread
**Category:** Call System — UI & Animation
**Priority:** Medium
**Effort:** Small (< 2h)
**Scope:** Flutter only
**Affects:** `call_history_bubble.dart`, `call_log_labels.dart`, `chat_page.dart` `_redialCall` 1108–1118, `ChatTimelineMerger`
**Depends on:** CALL-FEAT-009
**Current state:**
Tap on an inline call bubble shows `showCallRedialConfirmSheet` (“Call {name}?”) then starts the same voice/video type. Labels unchanged. Duration is talk time from CALL-FEAT-009 (`ended_at − answered_at`).
**Problem:**
Accidental redial from the thread. Duration includes ring time (CALL-FEAT-009).
**Enhancement:**
Confirmation bottom sheet before redial (“Call {name}?” voice/video). Keep existing label copy. After CALL-FEAT-009, duration matches talk time.
**Acceptance criteria:**
- [x] Tap shows confirm sheet then starts the same call type
- [x] Missed/declined use error vs muted colors as today
- [x] Connected bubbles show talk duration only

---

### CALL-PERF-001: Agora engine lifecycle management
**Category:** Call System — Performance & Code Quality
**Priority:** Critical
**Effort:** Medium (2–6h)
**Scope:** Flutter only
**Affects:** `agora_service.dart` `initialize`/`leaveChannel`/`dispose`, `outgoing_call_page.dart` `dispose` 562–598
**Depends on:** none
**Current state:**
Singleton `AgoraService`. `initialize` skips if same appId. `leaveChannel` → `stopPreview`. `dispose` → `leaveChannel` + `release()`. Page `dispose` always `unawaited(_agoraService.dispose())`, so the next call must re-create the engine. Order does not explicitly `disableVideo` before `release`. No `AppLogger` on lifecycle steps. `OutgoingCallPage.dispose` also `endCall` if still live — can race with `_endCall`.
**Problem:**
Leaked engines / double-release / joining with a released engine causes green frames and “engine not initialized”.
**Enhancement:**
One engine per session: create on join, teardown `leaveChannel → stopPreview → disableVideo → release` on end. Guard concurrent dispose/end. Log each step (`tag: 'Agora'`). Do not leave a live engine after pop.
**Acceptance criteria:**
- [x] Two sequential calls never share a released engine
- [x] `flutter analyze` clean; no dispose/end double-POST storms (idempotent end is OK)
- [x] Lifecycle logs visible in AppLogger

---

### CALL-PERF-002: RepaintBoundary on video tiles
**Category:** Call System — Performance & Code Quality
**Priority:** Critical
**Effort:** Small (< 2h)
**Scope:** Flutter only
**Affects:** `agora_call_video_layer.dart` `_buildMainStage` / `_buildLocalStage`
**Depends on:** none
**Current state:**
Comment at lines 15–16 notes controllers are kept to avoid green frames. `AgoraVideoView` is **not** wrapped in `RepaintBoundary`. Parent `OutgoingCallPage` `setState` every 1s for the timer.
**Problem:**
Timer and mute rebuilds can repaint the video texture.
**Enhancement:**
`RepaintBoundary` around each `AgoraVideoView` and around PiP. Split timer out of the page (CALL-PERF-003) so video does not rebuild on ticks.
**Acceptance criteria:**
- [x] Mute/timer updates do not recreate video controllers (already true) and do not repaint the texture
- [x] Both local and remote views are isolated

---

### CALL-PERF-003: Call state provider granularity
**Category:** Call System — Performance & Code Quality
**Priority:** High
**Effort:** Medium (2–6h)
**Scope:** Flutter only
**Affects:** `outgoing_call_page.dart` (all flags in State), `call_provider.dart` `CallState` (monolithic history+duration+flags)
**Depends on:** none
**Current state:**
Atomic providers: `callTimerProvider`, `isMutedProvider`, `isSpeakerOnProvider`, `isCameraOnProvider`, `callStatusProvider`, `networkQualityProvider`, `remoteUserJoinedProvider`. Live chrome (`CallLiveVideoStage`, `OutgoingCallHeader`, `CallMuteButton`, …) watches only its slice. `CallState.copyWith` sentinel clears `activeCall` / `error` / `incomingCallId`. `Call.isActive` is `active` or `connected`. Dead `CallTimer` still writes unused `CallState.callDuration` if mounted.
**Problem:**
Every second the whole scaffold (including video stack) rebuilds. Violates “no setState in feature screens” for new work. After hang-up, `activeCall` can remain set and block a new call.
**Enhancement:**
Atomic Riverpod providers for the live session: `callStatusProvider`, `callTimerProvider`, `isMutedProvider`, `isSpeakerOnProvider`, `isCameraOnProvider`, `networkQualityProvider`, `remoteUserJoinedProvider`. `OutgoingCallPage` becomes a composition of `Consumer` widgets. Timer widget watches only `callTimerProvider`. Do not keep a second duration in `CallState` for the live screen. Fix `copyWith` with `ValueGetter` / sentinel so nullables can clear. Treat `'active'` and `'connected'` as live.
**Acceptance criteria:**
- [x] Timer ticks do not rebuild `AgoraCallVideoLayer`
- [x] Mute only rebuilds the mute control
- [x] No new `setState` on `OutgoingCallPage` for those fields
- [x] `endCall` clears `activeCall` to null

---

### CALL-PERF-004: Audio session configuration
**Category:** Call System — Performance & Code Quality
**Priority:** Medium
**Effort:** Medium (2–6h)
**Scope:** Flutter only
**Affects:** `agora_service.dart` `joinChannel` 159–165, `_toggleSpeaker` 543–546
**Depends on:** CALL-NATIVE-003
**Current state:**
**Done.** Voice joins with `setDefaultAudioRouteToSpeakerphone(false)` + `setEnableSpeakerphone(false)` (earpiece). Video uses speaker. `LiveCallUiState.isSpeakerOn` defaults false; video pages `reset(speakerOn: true)`. `CallSpeakerPill` follows `onAudioRoutingChanged` (headphone SVG + “Headphones” on BT/wired). `restoreMediaAudioSession` after `leaveChannel` returns the OS session to earpiece/default so in-app media is not stuck on speaker.
**Problem:**
Voice calls blast speakerphone; Bluetooth routing is invisible.
**Enhancement:**
Voice default: earpiece (`setEnableSpeakerphone(false)`). Video default: speaker. Toggle updates UI. On `onAudioRouteChanged`, swap speaker icon for `AppIcons` headphone when BT. Restore routing after `leaveChannel`.
**Acceptance criteria:**
- [x] Voice starts on earpiece; video on speaker
- [x] Speaker button reflects actual route
- [x] After hang-up, media sounds use the normal session

---

### CALL-PERF-005: Remove print() and silent catch blocks
**Category:** Call System — Performance & Code Quality
**Priority:** Medium
**Effort:** Small (< 2h)
**Scope:** Flutter only
**Affects:** CallKit, incoming call, quality monitor, sound service, chat page pagination
**Depends on:** LOG-001, LOG-002
**Current state:**
`debugPrint` and empty `catch (_) {}` removed from listed call/chat files. Failures log via `AppLogger.warning` (tags: `CallKit`, `IncomingCall`, `IncomingCallHandler`, `outgoing_call_page`, `SoundService`, `chat_page`). Swallow-and-continue kept for prefs, CallKit end, dispose, and pagination fallback.
**Problem:**
Failures are invisible in production logs.
**Enhancement:**
Replace `debugPrint` with `AppLogger`. Every catch logs `AppLogger.warning` or `.error` with tag. Keep swallow-and-continue where needed (prefs, CallKit end) but never empty.
**Acceptance criteria:**
- [x] No empty `catch` in call/chat files listed above
- [x] No `debugPrint` in those call services
- [x] `flutter analyze` clean

---

### CALL-PERF-006: Remove unused dual call/chat UI
**Category:** Call System — Performance & Code Quality
**Priority:** Medium
**Effort:** Medium (2–6h)
**Scope:** Flutter only
**Affects:** `lib/screens/video_call_screen.dart`, `lib/screens/voice_call_screen.dart`, `lib/features/calls/presentation/widgets/call_controls.dart`, `call_timer.dart`, `lib/widgets/common/incoming_call_overlay.dart`, `lib/features/chat/presentation/widgets/message_bubble.dart`, `chat_input.dart` (listed in `tool/unreachable.json`)
**Depends on:** none
**Current state:**
Dead copies are documented at file top with the canonical live path (CALL-PERF-006). Not deleted — router still only mounts `OutgoingCallPage`. Live chat uses `widgets/chat/message_bubble.dart` + `message_input.dart`.
**Problem:**
Enhancements get applied to the wrong file (already happened: scale animation lives on unused `features/chat/.../message_bubble.dart`).
**Enhancement:**
Do not delete in this plan’s first pass unless explicitly commanded. Document canonical files. Optional follow-up: delete unreachable screens after confirming `tool/unreachable.json`.
**Acceptance criteria:**
- [x] This plan’s implementations only touch the live files named in each item
- [x] A short “canonical files” comment is added at the top of dead files OR they are deleted in a dedicated item when commanded

---

### CALL-SEC-001: Stop shipping a hardcoded Agora App ID
**Category:** Call System — Performance & Code Quality
**Priority:** High
**Effort:** Small (< 2h)
**Scope:** Flutter only
**Affects:** `lib/core/config/agora_config.dart` lines 8–11
**Depends on:** none
**Current state:**
`AgoraConfig.appId` is `String.fromEnvironment('AGORA_APP_ID')` with an empty default. Join uses `AgoraConfig.resolveAppId(tokenData.appId)` (token first). Empty app_id fails before `RtcEngine.initialize`.
**Problem:**
A real-looking App ID is in source; wrong ID vs backend token causes join failures that look like Agora errors.
**Enhancement:**
Empty default. Prefer `app_id` from `AgoraTokenData` (already passed into `initialize(appId: tokenData.appId)`). Fail fast in UI if missing.
**Acceptance criteria:**
- [x] No App ID constant in the Flutter repo
- [x] Join uses the token endpoint’s `app_id`

---

### CALL-NATIVE-001: flutter_callkit_incoming complete setup
**Category:** Call System — Native Device Integration
**Priority:** Critical
**Effort:** Medium (2–6h)
**Scope:** Flutter only
**Affects:** `call_kit_service.dart`, `call_kit_event_action.dart`, `incoming_call_provider.dart` `acceptFromCallKit`
**Depends on:** CALL-FEAT-008
**Current state:**
Package `flutter_callkit_incoming: ^2.0.4`. `startListening()` before splash. Handlers: Accept → queue/`acceptFromCallKit` → `POST accept` → pending GoRouter navigation. Decline + **Timeout** → decline action. `actionCallEnded` is `dismissOnly` (does not reject — cold-start Accept emits ended). Default branch `ignore` (includes callback). Avatar passed (`avatar: data.callerAvatar ?? ''`). Type 1 video / 0 voice. Duration 45000. Ringtone from `SoundService.getCallRingtonePath()` inside empty catch. Lock-screen accept: persist extras → splash/`IncomingCallHost.consumePendingNavigation` → `openActiveCallPage` with `callee=1`. Timer on page starts only after `_onCallAccepted`.
**Problem:**
`onCallCallback` / return-from-background not wired. Timeout maps to **reject**, not missed. Empty ringtone catch hides missing assets. `debugPrint` instead of AppLogger. **`rejectFromCallKit` (incoming_call_provider.dart 242–252) only `POST reject` when `state?.callId` matches.** After a killed-app restart `state` is null, so lock-screen Decline only dismisses native UI — the caller keeps ringing.
**Enhancement:**
Wire callback to `consumePendingNavigation` / re-open `OutgoingCallPage` without re-join if already in channel. Timeout → missed (CALL-FEAT-003), not reject. Pass avatar only when non-empty. Log every native event. Labels “Voice Call” / “Video Call”. **`rejectFromCallKit` must `POST reject` using persisted extras/`IncomingCallHandler` when `state` is null** (killed-app Decline).
**Acceptance criteria:**
- [x] Lock-screen Accept joins Agora and lands on `OutgoingCallPage`
- [x] Decline from lock screen / killed app hits `POST /calls/{id}/reject` even when provider state is null
- [x] Timeout does not reject
- [x] Callback from background returns to the live call route without a second `joinChannel`

---

### CALL-NATIVE-002: Background call notification (FCM + callkit)
**Category:** Call System — Native Device Integration
**Priority:** Medium
**Effort:** Medium (2–6h)
**Scope:** Both
**Affects:** `fcm_background_handler.dart`, `PushNotificationService.php` 147–187, `CallService::initiate()` push payload 54–71
**Depends on:** CALL-NATIVE-001
**Current state:**
FCM incoming calls are data-only (`isIncomingCallPushType`) with APNS `content-available: 1` and Android high priority. Payload includes `call_id`, `caller_id`, `caller_name`, `user_name`, `call_type`, `channel_name`, `agora_channel`, `caller_avatar`. Background isolate: `IncomingCallData.fromPayload` → `CallKitService.showIncomingFromIsolate`. `toExtras` persists channel + avatar for killed-app Accept (`CallKitRestore` + SharedPreferences). Android manifest documents `POST_NOTIFICATIONS` / `USE_FULL_SCREEN_INTENT`. Like/chat/missed FCM is not CallKit.
**Problem:**
If FCM is delayed, only Pusher works in foreground. Data keys must stay in sync with `IncomingCallData.fromPayload`. Killed-app Accept depends on SharedPreferences persist.
**Enhancement:**
Verify payload always has `call_id`, `caller_name`, `caller_avatar`, `call_type`, `agora_channel` (alias of `channel_name` — already on Pusher IncomingCall). Add `agora_channel` on FCM too. Document Android `POST_NOTIFICATIONS` / full-screen intent. Test killed-app Accept restore (`restoreAcceptedCall`).
**Acceptance criteria:**
- [x] Killed app shows native incoming UI from FCM
- [x] Accept restores call id, type, avatar, channel
- [x] Non-call FCM does not show CallKit

---

### CALL-NATIVE-003: Bluetooth headset support
**Category:** Call System — Native Device Integration
**Priority:** Low
**Effort:** Small (< 2h)
**Scope:** Flutter only
**Affects:** `agora_service.dart`, speaker button on `outgoing_call_page.dart`
**Depends on:** CALL-FEAT-001, CALL-PERF-004
**Current state:**
**Done.** `AgoraService` already forwards `onAudioRoutingChanged`. `CallSpeakerPill` shows `AppIcons.headphone` + “Headphones” on BT/wired. Toggle is disabled while that route is active. Unplug restores the user’s speaker/earpiece preference via `setEnableSpeakerphone` (does not overwrite preference when BT connects).
**Problem:**
Users with BT buds still see “Speaker” and may double-route audio.
**Enhancement:**
Handle `onAudioRouteChanged`; if BT, show headphone SVG and disable speaker toggle or relabel it. Verify Agora routes automatically (no extra package unless needed).
**Acceptance criteria:**
- [x] BT connect during call updates the control icon
- [x] Disconnect restores earpiece/speaker state

---

### CALL-NATIVE-004: Return to call from notification
**Category:** Call System — Native Device Integration
**Priority:** Medium
**Effort:** Medium (2–6h)
**Scope:** Flutter only
**Affects:** `outgoing_call_page.dart` lifecycle, `messenger_active_call_banner.dart`, CallKit ongoing notification
**Depends on:** CALL-NATIVE-001
**Current state:**
In-app: `MessengerActiveCallBanner` “Tap to return” on the Calls tab only. No persistent system notification while `OutgoingCallPage` is under another route. Leaving the call route currently `dispose`s Agora (`dispose()` releases engine) — navigating away **ends** the media session.
**Problem:**
Users cannot open chat mid-call without hanging up. There is nothing to “return” to.
**Enhancement:**
Keep the engine alive when the call route is not visible (overlay or shell flag). Show a persistent notification “Active call with {name}”. Tap → `GoRouter` to existing `OutgoingCallPage` **without** `joinChannel` again. In-app banner can remain as extra.
**Acceptance criteria:**
- [x] Navigating to chat during a call does not leave the Agora channel
- [x] Notification tap restores the call screen
- [x] Hang-up from notification ends the call (POST end + leaveChannel)

---

### CHAT-ANIM-001: Message send animation
**Category:** Chat — Animations & Micro-interactions
**Priority:** Medium
**Effort:** Medium (2–6h)
**Scope:** Flutter only
**Affects:** `lib/widgets/chat/message_bubble.dart` (live), `chat_message_list_tile.dart`
**Depends on:** none
**Current state:**
Live bubble has **no** enter animation. Unused `features/chat/presentation/widgets/message_bubble.dart` has scale 0→1 (do not extend that file). Optimistic rows are appended then `_scrollToBottom()` 300ms `easeOut`.
**Problem:**
Outgoing messages pop in.
**Enhancement:**
On new outgoing only: slide `Offset(0.3,0)→0`, fade 0→1, scale 0.85→1.0, 250ms `easeOutCubic`, single controller, dispose. Skip if Reduce Motion. Use `RepaintBoundary` (already on `ChatMessageListTile`).
**Acceptance criteria:**
- [x] Only the new outgoing row animates, not the whole list
- [x] History loads without staggering every bubble
- [x] Reduce Motion: no animation

---

### CHAT-ANIM-002: Message receive animation
**Category:** Chat — Animations & Micro-interactions
**Priority:** Medium
**Effort:** Small (< 2h)
**Scope:** Flutter only
**Affects:** same as CHAT-ANIM-001
**Depends on:** CHAT-ANIM-001
**Current state:**
Incoming rows appear with no motion. If near bottom, list animates scroll 300ms.
**Problem:**
Incoming messages are easy to miss when at bottom.
**Enhancement:**
Incoming: slide `Offset(-0.3,0)→0`, fade 300ms, `Curves.easeOutBack`. Same Reduce Motion / only-new-row rules as send.
**Acceptance criteria:**
- [x] Incoming animation plays once per new id/client_id
- [x] Pagination prepend does not animate old messages

---

### CHAT-ANIM-003: Typing indicator animation
**Category:** Chat — Animations & Micro-interactions
**Priority:** Medium
**Effort:** Small (< 2h)
**Scope:** Flutter only
**Affects:** `lib/widgets/chat/typing_indicator.dart` (live, used by `ChatPeerTypingIndicator`), unused duplicate `features/chat/presentation/widgets/typing_indicator.dart`
**Depends on:** none
**Current state:**
Live: three 8px dots, opacity 0.3→1.0, 600ms reverse repeat, stagger 200ms. Controllers disposed. No `disableAnimations`. No slide in/out of the bubble. Isolated via `isUserTypingProvider` (good). Duplicate feature widget uses height bounce + hardcoded `fontSize: 14` + `Colors.grey`.
**Problem:**
Dots do not match spec (scale 1.0→1.5, 7px, primary color, 900ms cycle) and ignore Reduce Motion. Duplicate file is a trap.
**Enhancement:**
Polish live `widgets/chat/typing_indicator.dart` only: 7px primary dots, scale pulse, 150ms stagger, 900ms loop. Slide in/out with receive animation. Respect Reduce Motion (static three dots). Do not use the features/ duplicate.
**Acceptance criteria:**
- [x] Typing start/stop animates the indicator only (not message tiles)
- [x] Reduce Motion: static dots
- [x] Controllers disposed

---

### CHAT-ANIM-004: Emoji/sticker send celebration
**Category:** Chat — Animations & Micro-interactions
**Priority:** Low
**Effort:** Medium (2–6h)
**Scope:** Flutter only
**Affects:** `chat_page.dart` `_handleSend`, sticker picker
**Depends on:** none
**Current state:**
**Done.** Single-grapheme emoji (and `messageType: sticker`) bursts 4 particles from the send button (`CustomPainter` + `RepaintBoundary`, 72px / 600ms). Reduce Motion skips it. Edits do not celebrate. Stickers are on the composer media sheet.
**Problem:**
Single-emoji / sticker sends feel the same as long text.
**Enhancement:**
If text is a single emoji or type is sticker: 3–5 particles from the send button, 60–80px, fade 600ms, `CustomPainter` + controller, `RepaintBoundary`, skip if Reduce Motion.
**Acceptance criteria:**
- [x] Celebration only for sticker/single-emoji
- [x] Painter is behind a RepaintBoundary and disposed

---

### CHAT-ANIM-005: Send button morph animation
**Category:** Chat — Animations & Micro-interactions
**Priority:** Medium
**Effort:** Small (< 2h)
**Scope:** Flutter only
**Affects:** `lib/widgets/chat/message_input.dart` 393–401
**Depends on:** none
**Current state:**
Live input already `AnimatedSwitcher` 180ms between `AppIcons.microphone` (empty) and `AppIcons.send` (has text). Attachment is a separate control. Unused `features/chat/.../chat_input.dart` uses grey/send without morph-to-attach.
**Problem:**
Spec asked attach↔send; product currently morphs **mic↔send** (voice-first). Changing to attach would regress hold-to-talk.
**Enhancement:**
Keep mic↔send (correct for this app). Add scale 0.8→1.0 on the switcher (`ScaleTransition`). Respect Reduce Motion (instant swap). No `Icons.*`.
**Acceptance criteria:**
- [x] Empty field shows mic; non-empty shows send
- [x] Morph is scaled 200ms easeOutCubic unless Reduce Motion

---

### CHAT-ANIM-006: Message long-press context menu
**Category:** Chat — Animations & Micro-interactions
**Priority:** Low
**Effort:** Large (> 6h)
**Scope:** Flutter only
**Affects:** `chat_page.dart` `_showMessageActions` 1618–1653, `ChatMessageListTile` onLongPress
**Depends on:** CHAT-UX-005, CHAT-UX-006
**Current state:**
Long-press → floating `ChatMessageContextMenu`: scale 0→1 from the bubble (`easeOutBack` 250ms), `ImageFilter.blur(3,3)` behind. Actions: React (persists via CHAT-UX-005), Reply, Copy, Edit (own text), Delete (own), Report (incoming). Reduce Motion skips scale/blur. Tap outside reverse-animates.
**Problem:**
Cannot copy text or react. Sheet does not match the spec’s floating menu.
**Enhancement:**
Replace sheet with a floating menu scaling 0→1 from the bubble (`easeOutBack` 250ms), blur `ImageFilter.blur(3,3)` behind. Actions: React, Reply, Copy, Delete (own), Report (other). Tap outside reverse-animates. Reduce Motion: no scale/blur.
**Acceptance criteria:**
- [x] All listed actions exist with correct visibility
- [x] Menu dismisses on outside tap
- [x] No Material `Icons.*`

---

### CHAT-ANIM-007: Reply preview slide animation
**Category:** Chat — Animations & Micro-interactions
**Priority:** Medium
**Effort:** Small (< 2h)
**Scope:** Flutter only
**Affects:** `message_reply_widget.dart`, `chat_page.dart` 2463–2476
**Depends on:** none
**Current state:**
`MessageReplyWidget` stays mounted and animates height 0→56 over `chatReplyPreview` (250ms, `easeOutCubic`). Close is `AppSvgIcon(AppIcons.close)` with a 44px target. Reduce Motion uses `Duration.zero`. Last preview text is kept while sliding out.
**Problem:**
Reply bar jumps; close icon is Material.
**Enhancement:**
`AnimatedContainer` height 0→56, 250ms easeOutCubic. Close via `AppSvgIcon` (`AppIcons.close` / `closeCircle`). Reduce Motion: instant.
**Acceptance criteria:**
- [x] Preview slides in/out
- [x] Zero `Icons.*` in this widget

---

### CHAT-ANIM-008: Message status tick animation
**Category:** Chat — Animations & Micro-interactions
**Priority:** Medium
**Effort:** Small (< 2h)
**Scope:** Flutter only
**Affects:** `lib/widgets/chat/message_status_indicator.dart`
**Depends on:** none
**Current state:**
**Done.** Live `MessageStatusIndicator` pulses 1.0→1.3→1.0 over 200ms (`chatStatusTickPulse`) once per sent→delivered / delivered→read / sent→read upgrade. Read ticks tween to `colorScheme.primary` (`receiptTick`; `Duration.zero` on Reduce Motion). History first-paint and recycled `messageId` rows do not pulse. Failed refresh SVG stays tappable.
**Problem:**
Read receipts are easy to miss.
**Enhancement:**
On sent→delivered→read: scale 1.0→1.3→1.0 over 200ms; color via `AnimatedDefaultTextStyle` / color tween to primary for read. Reduce Motion: color snap only.
**Acceptance criteria:**
- [x] Pulse plays once per status upgrade
- [x] Failed state still tappable retry

---

### CHAT-ANIM-009: Scroll-to-bottom button
**Category:** Chat — Animations & Micro-interactions
**Priority:** Medium
**Effort:** Medium (2–6h)
**Scope:** Flutter only
**Affects:** `chat_page.dart` `_isNearBottom` (threshold 180px), `_scrollToBottom`
**Depends on:** none
**Current state:**
**Done.** Live `ChatJumpToBottomFab` (52px, SVG chevron) scales 0→1 in 200ms when `maxScrollExtent - pixels > 200`, scales out in 150ms at the bottom, and shows an unseen-incoming badge. Tap `animateTo` max (300ms; jump when Reduce Motion). Auto-scroll and FAB share the 200px cutoff so 180–200px is not a dead zone.
**Problem:**
Scrolled-up users cannot jump down; new messages are silent.
**Enhancement:**
When `maxScrollExtent - pixels > 200`: show circular FAB scale 0→1 (200ms) with unread count. Tap → animateTo max. At bottom: scale out 150ms. SVG chevron. Theme colors.
**Acceptance criteria:**
- [x] FAB visible only when scrolled up >200px
- [x] Badge increments for incoming while scrolled up
- [x] Tap lands on the latest message

---

### CHAT-ANIM-010: Message swipe to reply
**Category:** Chat — Animations & Micro-interactions
**Priority:** Low
**Effort:** Medium (2–6h)
**Scope:** Flutter only
**Affects:** `ChatMessageListTile`, `_beginReply`
**Depends on:** CHAT-ANIM-007
**Current state:**
Live tiles wrap in `ChatSwipeToReply`: sent swipes left / received swipes right. Reply SVG (`AppIcons.reply`) follows. At 60px: haptic; release past threshold springs back and calls `_beginReply`. Sub-threshold snaps back with no reply. Call rows are not wrapped. Reduce Motion snaps instantly.
**Problem:**
Reply takes two taps.
**Enhancement:**
Swipe toward center (right-aligned bubbles swipe left, etc.). Reply SVG follows. At 60px: haptic + spring back + `_beginReply`. Do not swipe call bubbles.
**Acceptance criteria:**
- [x] Threshold triggers reply preview
- [x] Sub-threshold snap-back does not reply

---

### CHAT-ANIM-011: Voice message waveform playback animation
**Category:** Chat — Animations & Micro-interactions
**Priority:** Low
**Effort:** Medium (2–6h)
**Scope:** Flutter only
**Affects:** `voice_message_player.dart`, `voice_waveform_bars.dart`
**Depends on:** none
**Current state:**
Live path is one `VoiceWaveformPainter` (22 bars) inside `RepaintBoundary`. Played bars lerp to primary from muted at the playhead. `AudioPlayer` position is gated to 100ms. Idle 900ms motion runs only while playing and Reduce Motion is off. Player + waveform controllers dispose.
**Problem:**
Per-bar widgets + setState every position tick can jank on long chats.
**Enhancement:**
Replace bar row with one `CustomPainter` driven by playback position (100ms). Played = primary, remaining = muted. `RepaintBoundary`. Respect Reduce Motion (static bars + progress only).
**Acceptance criteria:**
- [x] Playhead matches audio position
- [x] Single painter repaint, not 22 AnimatedContainers
- [x] Player disposed on widget dispose (already true)

---

### CHAT-ANIM-012: Image message tap-to-expand Hero animation
**Category:** Chat — Animations & Micro-interactions
**Priority:** Medium
**Effort:** Small (< 2h)
**Scope:** Flutter only
**Affects:** `widgets/chat/message_bubble.dart` 370–388, `widgets/chat/media_viewer.dart` (`InteractiveViewer` / PhotoView)
**Depends on:** none
**Current state:**
Live path is `ChatImageViewer` + `MessageBubble` Hero (not dead `media_viewer.dart`). Tags are `chat_image_{messageId}` with `client_id` fallback — never the media URL. Barrier fades to black on the route animation; swipe-down / close `maybePop` so Hero reverses. Pinch 0.5–5× kept. Reduce Motion skips Hero and uses a zero-duration route.
**Problem:**
Hero can collide when `mediaUrl` is reused; background may not animate to black.
**Enhancement:**
Tag `chat_image_{messageId}` (fallback client_id). Animate barrier to black. Swipe down pops with Hero reverse. Pinch-zoom kept.
**Acceptance criteria:**
- [x] Open/close uses Hero without tag clashes in a thread
- [x] Pinch-zoom works; swipe down dismisses

---

### CHAT-ANIM-013: New message arrival bounce
**Category:** Chat — Animations & Micro-interactions
**Priority:** Low
**Effort:** Small (< 2h)
**Scope:** Flutter only
**Affects:** `chat_page.dart` insert + `_scrollToBottom`
**Depends on:** CHAT-ANIM-009
**Current state:**
Near-bottom new inserts call `_scrollToBottom(bounce: true)`: 300ms easeOut to pixel 0, plus a 12px spring (`ChatArrivalBounceLayer`) that only plays when `_isNearBottom`. Scrolled-up: no bounce; FAB badge still increments. Reduce Motion: jump to 0, no spring.
**Problem:**
New messages do not draw attention when already at bottom.
**Enhancement:**
If at bottom: spring slightly past then back. If scrolled up: no bounce; increment FAB badge.
**Acceptance criteria:**
- [x] Bounce only when `_isNearBottom`
- [x] Reduce Motion: existing 300ms scroll or jump

---

### CHAT-ANIM-014: Chat input expand animation
**Category:** Chat — Animations & Micro-interactions
**Priority:** Medium
**Effort:** Small (< 2h)
**Scope:** Flutter only
**Affects:** `chat_page.dart` scaffold, `MessageInput` (no `viewInsets` usage found)
**Depends on:** none
**Current state:**
**Done.** `ChatKeyboardInsetPad` pads the thread with `viewInsets.bottom` over `AppAnimations.transitionModal` (`easeOutCubic`; `Duration.zero` on Reduce Motion). Chat `Scaffold` uses `resizeToAvoidBottomInset: false` so the pad is not doubled. `ChatKeyboardAnchor` keeps `_scrollToBottom` only if the user was already near the latest message.
**Problem:**
Opening the keyboard causes a layout jump and can lose the last messages.
**Enhancement:**
Pad the column with `MediaQuery.viewInsets.bottom` via `AnimatedContainer`/`AnimatedPadding` using `AppAnimations.transitionModal`. After inset, if near bottom, `_scrollToBottom`.
**Acceptance criteria:**
- [x] Keyboard open/close does not jump mid-thread
- [x] Last messages stay visible while composing if previously at bottom

---

### CHAT-UX-001: Pull to load older messages
**Category:** Chat — UX Enhancements
**Priority:** Medium
**Effort:** Small (< 2h)
**Scope:** Flutter only
**Affects:** `chat_page.dart` `_loadMoreFromCache` / `_loadMoreMessages` 904–1070
**Depends on:** none
**Current state:**
Scroll-to-oldest (`maxScrollExtent - 120`) loads the next page. Reverse list prepends without a jump delta. Failures log via `AppLogger` and show `ChatLoadOlderRetry` (no auto-retry loop). Duplicate ids are filtered with `ChatLoadOlder.withoutExistingIds`. RefreshIndicator omitted — it would fire at the latest edge on a reverse list.
**Problem:**
Failures are silent; pull affordance may be missing.
**Enhancement:**
Keep compensation math. Log failures (LOG-003). Show a retry chip if the first page of older history fails. Optional `RefreshIndicator` at top if not already triggered by scroll.
**Acceptance criteria:**
- [x] Older messages prepend without jumping to top
- [x] Error is visible and logged
- [x] Duplicate ids are not inserted (already filtered)

---

### CHAT-UX-002: Message timestamp grouping
**Category:** Chat — UX Enhancements
**Priority:** Medium
**Effort:** Medium (2–6h)
**Scope:** Flutter only
**Affects:** `chat_date_badge.dart` (`ChatDateBadgeInserter.wrap` used at `chat_page.dart` 2270)
**Depends on:** none
**Current state:**
Day chips use `textTheme.labelSmall`. `ChatStickyDateHeader` pins the day at the visual top of the reverse thread by reading the topmost visible row. Inline chips remain in the list.
**Problem:**
Long threads lose the day while scrolling. Hardcoded font size.
**Enhancement:**
Sticky day header (`SliverPersistentHeader` or overlay from scroll). Typography from `textTheme.labelSmall` only.
**Acceptance criteria:**
- [x] Day chip stays visible while scrolling that day
- [x] No hardcoded font sizes

---

### CHAT-UX-003: Unread message separator
**Category:** Chat — UX Enhancements
**Priority:** Medium
**Effort:** Medium (2–6h)
**Scope:** Flutter only
**Affects:** `chat_page.dart` open/load
**Depends on:** none
**Current state:**
On open, unread is peeked from the chat list **before** `clearUnreadForPeer`. `ChatUnreadSeparator.insert` places “— N new messages —” before the first of the last N incoming rows (after date wrap). `ChatUnreadSeparatorBar` uses muted `onSurfaceVariant` + `labelSmall` + dividers. First history paint scrolls to the bar (`ensureVisible`, `Duration.zero` on Reduce Motion) instead of only the latest row. Jump-to-latest hides the bar for the rest of the session.
**Problem:**
Opening a busy thread dumps you at the bottom; missed messages require manual scroll.
**Enhancement:**
On open, if unread > 0, insert a separator at the first unread and scroll to it. Clear after view. Theme muted text + divider.
**Acceptance criteria:**
- [x] Separator appears only when unread > 0 on open
- [x] Scroll lands on the separator, not only the bottom

---

### CHAT-UX-004: Link detection and preview
**Category:** Chat — UX Enhancements
**Priority:** Low
**Effort:** Large (> 6h)
**Scope:** Both
**Affects:** `widgets/chat/message_bubble.dart` text, backend OG (new, no chat reaction/link API today)
**Depends on:** none
**Current state:**
Live text bubbles use `ChatLinkedText`: http(s)/www URLs are tappable with underline (`url_launcher`, already in pubspec). Trailing punctuation is stripped. Android VIEW queries added for http/https. OG preview cards use `GET /api/link-preview` (`ChatLinkPreview.enabled = true`, 24h cache, 30/min).
**Problem:**
URLs are plain text.
**Enhancement:**
Detect URLs; tappable primary underline. Optional preview card (title, description, favicon) behind a flag; server-side OG preferred. If too large, ship tappable links only and mark preview [!] until an endpoint exists.
**Acceptance criteria:**
- [x] URLs are tappable
- [x] Preview is optional and disabled without an API
- [x] No extra packages unless listed in the mini-report

---

### CHAT-UX-005: Message reactions
**Category:** Chat — UX Enhancements
**Priority:** Low
**Effort:** Large (> 6h)
**Scope:** Both
**Affects:** long-press menu, new `POST /api/chat/messages/{id}/react`, bubble chips
**Depends on:** CHAT-ANIM-006
**Current state:**
`POST /api/chat/messages/{id}/react` toggles ❤️ 😂 😮 😢 😡 👍 (`ChatMessageReactionService`, unique per user). `MessageReacted` fans out counts (not viewer `my_reaction`). History includes `reactions` + `my_reaction`. Flutter chips under live bubbles; same-emoji tap unreacts.
**Problem:**
Users cannot react without a reply.
**Enhancement:**
Backend service (not controller logic) `{success, message, data, meta}`. Body `{ emoji }` from ❤️ 😂 😮 😢 😡 👍. Pusher fanout. UI chips under bubble with count. Do not modify old migrations; add a new one when implementing.
**Acceptance criteria:**
- [x] React/unreact persists and broadcasts
- [x] Chips render on both sides
- [x] Unified API envelope

---

### CHAT-UX-006: Copy and Report in message actions
**Category:** Chat — UX Enhancements
**Priority:** Medium
**Effort:** Small (< 2h)
**Scope:** Flutter only
**Affects:** `chat_page.dart` `_showMessageActions`
**Depends on:** CHAT-ANIM-006 (can ship on the current sheet first)
**Current state:**
Copy (text/caption) and Report (incoming only) are on the message sheet. Copy uses `Clipboard` + `Copied` snackbar. Report opens `ReportUserScreen`. Empty image/voice hide Copy. Own messages hide Report.
**Problem:**
Cannot copy a code or report abuse from the thread.
**Enhancement:**
Add Copy (text/caption) and Report (others) using existing report APIs if present. SVG icons.
**Acceptance criteria:**
- [x] Copy puts message text on the clipboard
- [x] Report visible only on others’ messages

---

### CHAT-PERF-001: Message list virtualization
**Category:** Chat — Performance
**Priority:** High
**Effort:** Small (< 2h)
**Scope:** Flutter only
**Affects:** `chat_page.dart` `ListView.builder` ~2370
**Depends on:** none
**Current state:**
`ChatThreadListView` (`ListView.builder`) with `addAutomaticKeepAlives: false`, `addRepaintBoundaries: true`, `scrollCacheExtent: 1000px`. Date/call/message rows have `ValueKey`. `ChatDateBadge` stays const-constructible. Off-screen `VoiceMessagePlayer` disposes (stops audio).
**Problem:**
Keep-alives hold State (voice players, typing) for off-screen rows.
**Enhancement:**
`addAutomaticKeepAlives: false` except the playing voice row if needed. Prefer `const` on date badges. Keep builder.
**Acceptance criteria:**
- [x] Still a `ListView.builder`
- [x] Off-screen voice players do not stay alive
- [x] No scroll jank regression on a 200-message thread

---

### CHAT-PERF-002: Image memory cache for chat images
**Category:** Chat — Performance
**Priority:** Medium
**Effort:** Small (< 2h)
**Scope:** Flutter only
**Affects:** `OptimizedImage`, `ImageCacheService`, `ChatVisualMedia.prefetchMessages`, banner `CachedNetworkImage` in incoming call
**Depends on:** none
**Current state:**
Bubbles decode at display×DPR (cap 800, width-only). Disk cache 500 objects. Flutter `ImageCache` capped at 200 images / 80 MiB. Prefetch kept. `ChatImageViewer` uses `CachedNetworkImageProvider` + `maxWidth` (cap 1920), not raw `NetworkImage`. Incoming banner avatars already use `ProfileImageWidget` `memCacheWidth`.
**Problem:**
Full-res decode of 200px-tall bubbles can OOM on long media threads. Opening an image re-downloads it.
**Enhancement:**
`memCacheWidth` / `memCacheHeight` on thumbnails. Cap `ImageCacheService` memory. Keep prefetch. Viewer must use `CachedNetworkImage` / `ImageCacheService`, not `NetworkImage`.
**Acceptance criteria:**
- [x] Bubble images decode near display size
- [x] Cache size is bounded
- [x] Full-screen viewer does not use uncached `NetworkImage`

---

### CHAT-PERF-003: Reduce unnecessary provider rebuilds
**Category:** Chat — Performance
**Priority:** Medium
**Effort:** Medium (2–6h)
**Scope:** Flutter only
**Affects:** `chat_page.dart` (large `setState` message list), `ChatPeerTypingIndicator`, `MessageInput`
**Depends on:** none
**Current state:**
Timeline lives in `chatThreadMessagesProvider`. Tiles watch `chatThreadRowProvider` by row key. Chrome (`loading` / empty / error) is a separate select. Typing is `ChatPeerTypingIndicator` / `isUserTypingProvider`. Send-button enabled state is local to `MessageInput`. Composer reply/edit is `chatComposerProvider`.
**Problem:**
Each incoming message rebuilds all bubbles.
**Enhancement:**
Move the list to a provider; tiles `select` by id. Typing/input must not rebuild the list (already mostly true for typing). New send button state lives in `MessageInput` only.
**Acceptance criteria:**
- [x] Typing indicator does not rebuild bubbles (verify with widget inspector / flags)
- [x] Send-button enabled state does not rebuild the list
- [x] Incoming message rebuilds that tile + maybe neighbors, not N tiles unnecessarily

---

### CHAT-PERF-004: Pusher message deduplication
**Category:** Chat — Performance
**Priority:** Medium
**Effort:** Small (< 2h)
**Scope:** Flutter only
**Affects:** `chat_page.dart` insert paths, `ChatTimelineMerger`, `chat_provider.addReceivedMessage` 476–507
**Depends on:** none
**Current state:**
`ChatMessageDedup` upserts by server `id` then `client_id` (no sender+text). Live page ingest uses `ChatMessageIndex` then the same client_id fallback. `ChatTimelineMerger.merge` folds duplicate messages and calls. `addReceivedMessage` updates in place instead of skipping.
**Problem:**
Optimistic send + Pusher echo can show two bubbles.
**Enhancement:**
Before insert: if `id` exists, update in place; else if `client_id` matches an optimistic row, replace it. Same in the page path, not only `chat_provider`.
**Acceptance criteria:**
- [x] Send + echo = one bubble
- [x] Edits/delivery status update the same row

---

### LOG-001: Agora callback logging
**Category:** Cross-cutting — Logging & Error Handling
**Priority:** Critical
**Effort:** Small (< 2h)
**Scope:** Flutter only
**Affects:** `agora_service.dart`
**Depends on:** CALL-FEAT-001
**Current state:**
Callbacks already used `AppLogger` after CALL-FEAT-001, but the global floor is `error`, so join/connection/warning lines never printed. Network quality logged at `info` (too noisy). `onAudioVolumeIndication` had no log. SDK 6.3.2 has no `onWarning`.
**Problem:**
Field issues are undebuggable.
**Enhancement:**
`onError` → `AppLogger.error` (code + msg, tag `Agora`). Connection-lost / token / camera → `.warning` (no SDK `onWarning`). Connection / join / offline → `.info`. Network quality, RTC stats, speaking-change → `.verbose`. Agora tag floor is `info` so those lines show in debug without enabling the whole app.
**Acceptance criteria:**
- [x] Every registered Agora callback logs at the specified level
- [x] No `print`/`debugPrint` in `agora_service.dart`

---

### LOG-002: Call signaling logging
**Category:** Cross-cutting — Logging & Error Handling
**Priority:** Medium
**Effort:** Small (< 2h)
**Scope:** Flutter only
**Affects:** `pusher_websocket_service.dart` 449–457, `call_signaling_service.dart`, `incoming_call_provider.dart`
**Depends on:** CALL-PERF-005
**Current state:**
Pusher logs every `call.incoming|accepted|rejected|ended|busy` with `Call event: … call_id=` (tag `CallSignaling`, floor `info`). `CallSignalingService` logs matched dispatch. Initiate/accept/reject/end/busy HTTP success is `AppLogger.info`; failures are `AppLogger.error`. Incoming accept/reject no longer uses `debugPrint`. Accept poll kept.
**Problem:**
Cannot tell if `call.accepted` arrived but UI missed it (hence the 2s poll `_startAcceptPoll`).
**Enhancement:**
`AppLogger.info('Call event: $eventName from user $callerId', tag: 'CallSignaling')` on every call event. Log initiate/accept/reject/end/busy HTTP success and error. Keep accept poll until signaling is proven reliable, then consider removing.
**Acceptance criteria:**
- [x] All five event names are logged with call_id
- [x] Signaling HTTP errors use AppLogger.error

---

### LOG-003: Chat Pusher event logging
**Category:** Cross-cutting — Logging & Error Handling
**Priority:** Medium
**Effort:** Small (< 2h)
**Scope:** Flutter only
**Affects:** `pusher_websocket_service.dart` `_handleMessageSent` and siblings, `chat_pusher_providers.dart`
**Depends on:** none
**Current state:**
Handlers log `Chat event: {type} conversation_id=… preview="…"` (20-char body, no extra PII) with tag `ChatPusher`. Tag floor is `info`. Presence no longer dumps the raw payload. Lifecycle connect/open/reconnect uses the same tag.
**Problem:**
Duplicate/missed messages are hard to diagnose.
**Enhancement:**
Log event type, conversation id, first 20 chars of body (no extra PII). Tag `ChatPusher`.
**Acceptance criteria:**
- [x] Each chat Pusher event logs the required fields
- [x] Previews are truncated to 20 characters

---

### CALL-FEAT-010: Fix inverted Agora quality mapping
**Category:** Call System — Missing Features
**Priority:** Critical
**Effort:** Small (< 2h)
**Scope:** Flutter only
**Affects:** `outgoing_call_page.dart` `_qualityFromScore` 441–446, `call_quality_monitor.dart` `_updateNetworkQuality` 205–221, `agora_service.dart` `getCallStats` 245–256
**Depends on:** CALL-FEAT-001 (for `onRtcStats`); can ship mapping fix first
**Current state:**
Agora `QualityType.index`: 0=unknown, 1=excellent, 2=good, 3=poor, 4=bad, 5=vbad. UI maps `score <= 1` → good, so **excellent/unknown look good and good (2) looks poor**. Monitor 5s timer overwrites the UI label to `'bad'` because stats keys never exist.
**Problem:**
A healthy call shows “Poor connection” / “Unstable connection” after ~5s.
**Enhancement:**
Map quality by enum name or documented index: 1–2 good, 3 fair, 4–5 bad, 0 unknown. Do not let the monitor overwrite Agora `onNetworkQuality`. Either wire `onRtcStats` into `getCallStats` or stop the dummy 5s quality rewrite.
**Acceptance criteria:**
- [x] Excellent/good Agora quality never shows the poor-connection chip
- [x] Monitor does not force `'bad'` when bitrate is missing
- [x] Unit test covers the QualityType → label map

---

### CALL-NATIVE-005: iOS VoIP background + Android phone-call FGS
**Category:** Call System — Native Device Integration
**Priority:** High
**Effort:** Medium (2–6h)
**Scope:** Flutter only
**Affects:** `ios/Runner/Info.plist`, `android/app/src/main/AndroidManifest.xml`, CallKit logo asset
**Depends on:** CALL-NATIVE-001
**Current state:**
Info.plist `UIBackgroundModes` = `voip` + `audio` + `remote-notification`. CallKit logo is `ios/Runner/Assets.xcassets/CallKitLogo.imageset` (`iconName: CallKitLogo`). Android app manifest declares `FOREGROUND_SERVICE_PHONE_CALL`, `FOREGROUND_SERVICE_MICROPHONE`, `MANAGE_OWN_CALLS`, `SYSTEM_ALERT_WINDOW`, `BLUETOOTH_CONNECT` (plugin already hosts the `phoneCall` FGS). **[!]** Apple Developer VoIP Services Certificate + PushKit provisioning are not in this repo — killed-app iOS still uses FCM data (CALL-NATIVE-002) until the portal cert exists. Do not add `.p12`/`.pem` here.
**Problem:**
Killed-app CallKit on iOS and full-screen incoming on Android 14 can fail or be killed by the OS.
**Enhancement:**
Add the background modes and FGS types required by `flutter_callkit_incoming` 2.x. Add a CallKit logo asset matching `iconName: 'CallKitLogo'`. Do not invent VoIP push certificates in code — document the Apple portal step as a blocker `[!]` if missing.
**Acceptance criteria:**
- [x] iOS Info.plist includes voip + audio background modes
- [x] Android manifest includes phone-call FGS + MANAGE_OWN_CALLS
- [x] CallKit incoming UI stays up when the app process is backgrounded

---

### CALL-BE-001: Call quota plan-key mapping
**Category:** Call System — Missing Features
**Priority:** High
**Effort:** Small (< 2h)
**Scope:** Backend only
**Affects:** `Api\CallController::getCallQuota` (raw `strtolower($activePlan->p_name)`), `VideoCallService::agoraConfigKeyFromPurchase` (correct ChatTierService map)
**Depends on:** none
**Current state:**
`GET /api/calls/quota` and `canMakeCall` both use `VideoCallService::agoraConfigKeyFromPurchase` / ChatTierService (`silver`/`silder`/`Premium` → `premium`, `golden` → `golden`, none → `free`). Remaining on initiate is **after** the quota increment. Quota still increments at ring time (missed/rejected consume a slot — anti-spam). Do not change tier spellings (`basid` | `silder` | `golden`).
**Problem:**
Silver users can see 0 remaining calls on the quota endpoint while initiate still works (or the reverse, depending on middleware).
**Enhancement:**
Use the same `agoraConfigKeyFromPurchase` / ChatTierService mapping in `getCallQuota`. Do not change tier spellings (`basid` | `silder` | `golden`). Optionally skip quota increment until the call is answered (product decision — document in notes). Fix remaining_calls to post-increment or document “remaining after this call”.
**Acceptance criteria:**
- [x] `GET /api/calls/quota` and `canMakeCall` use the same plan key
- [x] Silver is not treated as free
- [x] Feature test covers silver/premium/golden keys

---

### CALL-BE-002: Active-call GET includes ringing
**Category:** Call System — Missing Features
**Priority:** Medium
**Effort:** Small (< 2h)
**Scope:** Backend only
**Affects:** `CallController::getActiveCall` (status `active` only)
**Depends on:** none
**Current state:**
`GET /api/calls/active` returns the latest `initiating|ringing|active` call via `CallService::findLiveCallForUser`. Ended/missed/busy/rejected/cancelled are excluded.
**Problem:**
Rejoin / “already in a call” recovery cannot attach to a ringing session.
**Enhancement:**
Return the latest `initiating|ringing|active` call for the user (one row). Keep ended/missed out.
**Acceptance criteria:**
- [x] Ringing outgoing call is returned by `/active`
- [x] No ended call is returned

---

### CHAT-UX-007: Video message tap-to-play
**Category:** Chat — UX Enhancements
**Priority:** Medium
**Effort:** Small (< 2h)
**Scope:** Flutter only
**Affects:** `lib/widgets/chat/message_bubble.dart` video thumbnail (~390–439)
**Depends on:** CHAT-ANIM-012
**Current state:**
Video thumbnail + SVG play overlay opens `ChatVideoViewer` (`video_player`). Sending/failed/local files stay closed. Image Hero viewer is unchanged. `StickerPickerSheet` is still unwired to `MessageInput`.
**Problem:**
Users cannot open a video from the thread.
**Enhancement:**
Tap video bubble → existing media viewer / video player. Keep SVG play icon. Wire sticker picker only if commanded as a follow-up (not this item).
**Acceptance criteria:**
- [x] Tapping a video message opens playback
- [x] Image tap behavior is unchanged

---

## Implementation Order
Implement in this priority sequence:
(ordered by user impact and dependency)

### Tier 1 — Critical (implement first)
1. CALL-FEAT-001 — Agora callback completion
2. CALL-FEAT-010 — Fix inverted quality mapping
3. CALL-NATIVE-001 — Callkit complete setup (includes killed-app Decline API)
4. CALL-FEAT-008 — Permission pre-check
5. CALL-PERF-001 — Agora engine lifecycle
6. CALL-PERF-002 — RepaintBoundary on video
7. LOG-001 — Agora logging

### Tier 2 — High (implement second)
8. CALL-FEAT-004 — Reconnection handling
9. CALL-FEAT-006 — Token refresh
10. CALL-FEAT-007 — Wake lock
11. CALL-UI-001 — Outgoing pulsing animation
12. CALL-UI-006 — Video PiP draggable
13. CALL-UI-008 — In-app incoming overlay
14. CALL-UI-009 — Controls auto-hide
15. CALL-PERF-003 — Provider granularity + copyWith null-clear
16. CHAT-PERF-001 — List virtualization
17. CALL-FEAT-009 — Duration from answered_at
18. CALL-SEC-001 — Remove hardcoded App ID
19. CALL-NATIVE-005 — iOS VoIP + Android FGS
20. CALL-BE-001 — Quota plan-key mapping

### Tier 3 — Medium (implement third)
21. CALL-UI-002 — Connect transition
22. CALL-UI-003 — End transition
23. CALL-UI-004 — Mute micro-animation
24. CALL-UI-005 — Speaking indicator
25. CALL-UI-007 — Network quality bars
26. CALL-NATIVE-002 — Background FCM
27. CALL-NATIVE-004 — Return to call
28. CHAT-ANIM-001 — Message send animation
29. CHAT-ANIM-002 — Message receive animation
30. CHAT-ANIM-003 — Typing indicator polish
31. CHAT-ANIM-005 — Send button morph
32. CHAT-ANIM-008 — Status tick animation
33. CHAT-ANIM-009 — Scroll to bottom
34. CHAT-ANIM-014 — Keyboard input expand
35. CALL-FEAT-005 — Quality warning toast
36. CALL-PERF-004 — Audio session
37. CALL-PERF-005 — Silent catches
38. CALL-UI-010 — Call history confirm sheet
39. CHAT-ANIM-007 — Reply preview
40. CHAT-ANIM-012 — Image Hero
41. CHAT-UX-001 — Pull/load older polish
42. CHAT-UX-002 — Sticky date header
43. CHAT-UX-003 — Unread separator
44. CHAT-UX-006 — Copy/Report
45. CHAT-UX-007 — Video message tap
46. CHAT-PERF-002 — Image memory cache (incl. viewer)
47. CHAT-PERF-003 — Provider rebuilds
48. CHAT-PERF-004 — Message dedup
49. LOG-002 — Call signaling logging
50. LOG-003 — Chat event logging
51. CALL-PERF-006 — Dead UI cleanup (when commanded)
52. CALL-BE-002 — GET /active includes ringing

### Tier 4 — Enhancement (implement last)
53. CALL-FEAT-002 — Busy state detection
54. CALL-FEAT-003 — Missed call timeout alignment
55. CALL-NATIVE-003 — Bluetooth support
56. CHAT-ANIM-004 — Emoji celebration
57. CHAT-ANIM-006 — Context menu
58. CHAT-ANIM-010 — Swipe to reply
59. CHAT-ANIM-011 — Voice waveform painter
60. CHAT-ANIM-013 — New message bounce
61. CHAT-UX-004 — Link preview
62. CHAT-UX-005 — Message reactions

---

## Progress Tracker
| ID | Title | Priority | Status | Notes |
|----|-------|----------|--------|-------|
| CALL-FEAT-001 | Agora callbacks | Critical | [x] | Handlers + reconnect overlay + quit vs drop + rtc stats. SDK 6.3.2 has no onWarning; warnings logged via connection/camera. |
| CALL-FEAT-002 | Busy detection | High | [x] | Local session POSTs busy; initiate rejects if either user is live |
| CALL-FEAT-003 | Missed call timeout | High | [x] | Shared 45s; Flutter dismisses UI only; chat upserts missed |
| CALL-FEAT-004 | Reconnection | High | [x] | Overlay + 3 rejoins + media restore; then Connection lost |
| CALL-FEAT-005 | Quality toast | Medium | [x] | 3s toast on quality 4–5; 5s debounce; bars stay |
| CALL-FEAT-006 | Token refresh | High | [x] | Proactive 5min timer; empty token skipped; fail shown once |
| CALL-FEAT-007 | Wake lock | High | [x] | Enable on mount; force-disable in dispose; keep in background |
| CALL-FEAT-008 | Permission pre-check | Critical | [x] | Gate before initiate/accept; settings sheet on permanent deny |
| CALL-FEAT-009 | Duration answered_at | High | [x] | Talk time = ended_at − answered_at |
| CALL-FEAT-010 | QualityType mapping | Critical | [x] | Enum-name map + monitor never overwrites Agora; unit test added |
| CALL-UI-001 | Outgoing pulse | High | [x] | 3 rings 1800ms/300ms stagger; Reduce Motion static |
| CALL-UI-002 | Connect transition | Medium | [x] | 400ms easeOutCubic; timer fade-up; Reduce Motion skip |
| CALL-UI-003 | End transition | Medium | [x] | Fade + summary card; Agora stops immediately; Reduce Motion 1s |
| CALL-UI-004 | Mute animation | Medium | [x] | Crossfade + error tint + press scale; Reduce Motion skips |
| CALL-UI-005 | Speaking indicator | Medium | [x] | Pulse ring on header/voice/PiP; Reduce Motion static; volume ticks isolated |
| CALL-UI-006 | Video PiP | High | [x] | Bottom-right default; snap; tap resize; long-press flip |
| CALL-UI-007 | Signal bars | Medium | [x] | 4-bar header indicator; semantic colors; Reduce Motion freeze |
| CALL-UI-008 | Incoming overlay | High | [x] | 80px banner; easeOutBack 400ms; timeout ≠ reject |
| CALL-UI-009 | Controls auto-hide | High | [x] | Video 4s idle; voice always on; stage tap reveals |
| CALL-UI-010 | Call history in chat | Medium | [x] | Confirm sheet before redial; talk duration; error vs muted |
| CALL-PERF-001 | Engine lifecycle | Critical | [x] | leave→stopPreview→disableVideo→release; idempotent dispose/end |
| CALL-PERF-002 | Video RepaintBoundary | Critical | [x] | Local/remote/PiP + page layer isolated |
| CALL-PERF-003 | Atomic providers | High | [x] | Slice providers; copyWith clears activeCall; isActive includes active |
| CALL-PERF-004 | Audio session | Medium | [x] | Voice earpiece; video speaker; BT headphone icon; restore after leave |
| CALL-PERF-005 | Silent catches | Medium | [x] | AppLogger on listed call/chat swallows; no debugPrint |
| CALL-PERF-006 | Dead UI cleanup | Medium | [x] | Canonical comments on dead files; not deleted |
| CALL-SEC-001 | Hardcoded App ID | High | [x] | Empty dart-define; join uses token app_id |
| CALL-NATIVE-001 | Callkit setup | Critical | [x] | Killed-app Decline POSTs reject; timeout ≠ reject; callback skips re-join |
| CALL-NATIVE-002 | Background FCM | Medium | [x] | agora_channel+caller_name on FCM; CallKitRestore extras; like/chat ≠ CallKit |
| CALL-NATIVE-003 | Bluetooth | Low | [x] | Headphone icon; toggle locked on BT; restore speaker pref |
| CALL-NATIVE-004 | Return to call | Medium | [x] | Persistent notification + minimize keeps Agora; tap restores without join |
| CALL-NATIVE-005 | iOS VoIP + Android FGS | High | [x] | Background modes + FGS types + CallKitLogo; VoIP cert is Apple-portal [!] |
| CALL-BE-001 | Quota plan key | High | [x] | Shared agoraConfigKey; remaining after increment |
| CALL-BE-002 | GET /active ringing | Medium | [x] | initiating\|ringing\|active; ended excluded |
| CHAT-ANIM-001 | Send animation | Medium | [x] | New outgoing only; gate skips history; Reduce Motion off |
| CHAT-ANIM-002 | Receive animation | Medium | [x] | New incoming slide/fade once; history/pagination gated |
| CHAT-ANIM-003 | Typing polish | Medium | [x] | 7px primary scale pulse; receive slide in/out; Reduce Motion static |
| CHAT-ANIM-004 | Emoji celebration | Low | [x] | 4 particles from send; skip Reduce Motion; stickers on media sheet |
| CHAT-ANIM-005 | Send morph | Medium | [x] | Mic↔send scale 0.8→1, 200ms; Reduce Motion instant |
| CHAT-ANIM-006 | Context menu | Low | [x] | Scale-from-bubble + blur; React UI; Copy/Delete/Report visibility |
| CHAT-ANIM-007 | Reply slide | Medium | [x] | Height 0→56 250ms; SVG close; Reduce Motion instant |
| CHAT-ANIM-008 | Tick pulse | Medium | [x] | 1→1.3→1 once per upgrade; read→primary; Reduce Motion color snap |
| CHAT-ANIM-009 | Jump to bottom | Medium | [x] | FAB >200px; badge while scrolled up; tap animateTo max |
| CHAT-ANIM-010 | Swipe reply | Low | [x] | Toward center; 60px haptic + spring; call rows skipped |
| CHAT-ANIM-011 | Waveform painter | Low | [x] | One CustomPainter; 100ms gate; Reduce Motion static |
| CHAT-ANIM-012 | Image Hero | Medium | [x] | chat_image_{id\|clientId}; black barrier; swipe-down Hero pop |
| CHAT-ANIM-013 | Arrival bounce | Low | [x] | 12px spring at latest edge; skip if scrolled up / Reduce Motion |
| CHAT-ANIM-014 | Keyboard pad | Medium | [x] | AnimatedPadding viewInsets 250ms; pin if at bottom; no double pad |
| CHAT-UX-001 | Load older | Medium | [x] | Reverse prepend; retry chip + log; duplicate ids filtered |
| CHAT-UX-002 | Date grouping | Medium | [x] | Sticky overlay; labelSmall; Today/Yesterday/date |
| CHAT-UX-003 | Unread separator | Medium | [x] | Peek unread before clear; insert + scroll to bar; jump-to-latest hides |
| CHAT-UX-004 | Link preview | Low | [x] | Tappable URLs + OG card via GET /link-preview |
| CHAT-UX-005 | Reactions | Low | [x] | POST react toggle + MessageReacted + chips both sides |
| CHAT-UX-006 | Copy/Report | Medium | [x] | Copy text/caption + Report others via ReportUserScreen |
| CHAT-UX-007 | Video tap-to-play | Medium | [x] | Thumbnail opens ChatVideoViewer; images unchanged |
| CHAT-PERF-001 | ListView.builder | High | [x] | keepAlives off; cache 1000px; ValueKeys |
| CHAT-PERF-002 | Image cache | Medium | [x] | Display-size decode; ImageCache 200/80MiB; viewer cached maxWidth |
| CHAT-PERF-003 | Rebuild reduction | Medium | [x] | Tiles select by row key; chrome/slots isolated |
| CHAT-PERF-004 | Dedup | Medium | [x] | id then client_id; merger folds messages; no text match |
| LOG-001 | Agora logging | Critical | [x] | Callbacks + Agora tag floor info; quality/stats verbose |
| LOG-002 | Signaling logging | Medium | [x] | Five events + HTTP ok/error; CallSignaling floor info; poll kept |
| LOG-003 | Chat Pusher logging | Medium | [x] | Type + conversation_id + 20-char preview; ChatPusher floor info |

---

## Canonical files (do not enhance the dead copies)

**Live calls:** `outgoing_call_page.dart`, `agora_service.dart`, `agora_call_video_layer.dart`, `incoming_call_banner.dart`, `incoming_call_provider.dart`, `call_kit_service.dart`, `call_signaling_service.dart`, `call_history_bubble.dart`, `app_router.dart` `/call/outgoing`.

**Dead calls:** `lib/screens/video_call_screen.dart`, `lib/screens/voice_call_screen.dart`, `call_controls.dart`, `call_timer.dart`, `widgets/common/incoming_call_overlay.dart`.

**Live chat:** `lib/pages/chat_page.dart`, `lib/widgets/chat/message_bubble.dart`, `message_input.dart`, `chat_message_list_tile.dart`, `typing_indicator.dart`, `voice_message_player.dart`.

**Dead chat:** `lib/features/chat/presentation/widgets/message_bubble.dart`, `chat_input.dart` (unreachable.json).

**Backend calls:** `App\Http\Controllers\Api\CallController`, `App\Services\CallService`, `VideoCallService`, `AgoraTokenService`, `AgoraService::generateChannelName` (`call_{min}_{max}_{time}`), events in `app/Events/Call*.php`, `CheckMissedCall` (45s). Legacy `CallInitiated` (`call.initiated`) is unused by Flutter (listens for `call.incoming` only). Legacy `app/Http/Controllers/CallController.php` is not the API.

---

## Constraints Reference
These constraints apply to every enhancement:
- NO Icons.* — AppSvgIcon / AppIcons SVG assets only
- NO hardcoded hex — AppColors / Theme.of(context) only
  Exception: Color(0xFF22C55E) for online/connected status
- NO hardcoded font sizes — textTheme only
- NO setState in feature screens — Riverpod only
- All animations: check MediaQuery.disableAnimations first
- All AnimationControllers: disposed in dispose()
- All Agora engine calls: on the main thread via WidgetsBinding
- All error logging: AppLogger not print()
- Do not touch `LGBTinder-flutter/`
- Do not modify existing migrations — new files only
- Tier spellings: basid | silder | golden — never change
- Backend envelope: `{success, message, data, meta}`
- Business logic in Services, not controllers

### Design tokens (from audit)
- Animation: `AppAnimations` in `lib/core/constants/animation_constants.dart` (tap 130ms, page 300ms, modal 250ms, feedback 180ms, `curveDefault` = easeOutCubic, `buttonPressScale` = 0.97)
- Radius: `AppRadius` XS 6 / SM 12 / MD 16 / LG 24 / XL 32 / Round 999
- Spacing: `AppSpacing` 4px grid
- Colors: `AppColors` (rose `#F43F5E`, violet `#8B5CF6`, success `#2ECC71`, error `#E11D48`) — consume via the class, never paste hex in widgets
- Call icons present: `call`, `call-incoming`, `call-outgoing`, `call-slash` (missed), `video`, `video-slash`, `microphone`, `microphone-slash`, `camera`, `camera-slash`, `volume-high`, `volume-low`, `volume-mute`, `speaker`, `headphone`, `wifi`
- Sounds (referenced by `SoundService`; `assets/sounds/` declared in pubspec): `call_ringback.wav`, `call_busy.wav`, `call_end.wav`, `call_connect.wav`, `ringtone_default.wav`, `ringtone_pride.wav`, `ringtone_classic.wav`. Workspace glob found **zero** wav files — generate via `scripts/generate_default_sounds.py` if missing (see `docs/SOUNDS_ASSET_GUIDE.md`).
- Packages: `agora_rtc_engine >=6.3.0 <6.5.0`, `flutter_callkit_incoming ^2.0.4`, `audioplayers ^6.0.0`, `permission_handler ^11.1.0`, `wakelock_plus ^1.2.8`, `connectivity_plus ^5.0.2`, `lottie >=3.0.0 <3.3.0`, `animations ^2.0.8`, `record ^6.1.0`. `just_audio` removed.

### TODO comments found (calls + chat)
- `lib/widgets/chat/mention_text_widget.dart:65` — Extract user ID from mention
- `lib/widgets/chat/media_picker.dart:48` — Implement image picker
- `lib/widgets/chat/media_picker.dart:54` — Implement video picker
- `lib/widgets/chat/media_picker.dart:60` — Implement file picker
- `lib/widgets/chat/audio_recorder_widget.dart:51` — Start actual audio recording
- `lib/widgets/chat/audio_recorder_widget.dart:59` — Stop recording and get audio path
- `lib/widgets/chat/audio_player_widget.dart:45` — Implement actual audio playback
- Live voice path uses `VoiceRecorderOverlay` + `VoiceMessagePlayer` instead of those stub widgets
- No TODOs under `lib/features/calls/`
- OpenAPI dump still mentions TODO push/websocket on an old CallController path — not the live `Api\CallController`

### Empty / silent catch blocks (calls + chat)
- `call_kit_service.dart:174` ringtone path
- `outgoing_call_page.dart:197` accept poll, `:575` dispose messenger
- `incoming_call_provider.dart:61` markBusy, `:236` getCall, `:282` GoRouter
- `incoming_call_handler.dart:104,115,123,160` prefs
- `fcm_background_handler.dart:20` Firebase already init
- `sound_preferences_provider.dart:236,280,283,310,313`
- `chat_page.dart:189,967,1067,1323,1920,2150`
- `conversation_mute_cache_provider.dart:71`
- `messenger_calls_provider.dart:148`
- `chat_list_preview_provider.dart:29`
- `chat_visual_media.dart:119`

### Missing AppLogger (key operations)
- All Agora `RtcEngineEventHandler` callbacks
- CallKit native events and ringtone failure
- Incoming accept/reject/acceptFromCallKit
- `CallQualityMonitor` start/stop/errors
- Pusher `call.*` dispatch
- Chat Pusher message/typing/read (preview)
- `SoundService` play/init failures (`debugPrint`)

---

*End of document.*
