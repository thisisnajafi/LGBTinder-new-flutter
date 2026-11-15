# Claude run 2/5 — Black screen after a call ends (LGBTFinder Flutter)

You are a senior Flutter engineer in `E:\1 - laravel\1 - LGBTinder\lgbtindernew` (Riverpod 2, go_router 13, `agora_rtc_engine 6.5.x`, `flutter_callkit_incoming 2.x`, Pusher signaling, FCM). Branch `fix/optimistic-logout-call-blackscreen` is checked out and already contains run 1 (optimistic logout, see `docs/pm/logs/01-optimistic-logout-REPORT.md`); do not undo it. This is one of very few expensive runs: finish root cause + fix + tests in this run.

## Problem (owner report)
When a voice/video call ends, the app **sometimes** gets stuck on a black screen (user has to kill the app). Intermittent → almost certainly a race.

## Root cause first
Read the whole call flow end to end before changing anything:
- Screens: `lib/screens/voice_call_screen.dart`, `lib/screens/video_call_screen.dart`, `lib/features/calls/pages/outgoing_call_page.dart`, `incoming_call_page.dart`, `lib/widgets/common/incoming_call_overlay.dart`, `lib/features/calls/presentation/widgets/*` (esp. `call_end_overlay.dart`, `agora_call_video_layer.dart`, `call_connect_transition.dart`, `call_reconnecting_overlay.dart`, `messenger_active_call_banner.dart`).
- Navigation/ending: `lib/features/calls/utils/call_navigation.dart`, `outgoing_call_end.dart`, `minimized_call_remote_end.dart`, `call_ring_timeout.dart`, `call_conflict_resolver.dart`, `call_local_busy.dart`, `call_rejoin_policy.dart`.
- State: `lib/features/calls/providers/*` (`active_call_session_provider`, `agora_rtc_session_provider`, `call_end_summary_provider`, `live_call_ui_provider`, `call_provider`, `incoming_call_provider`).
- Services: `lib/shared/services/agora_service.dart`, `incoming_call_handler.dart`, `incoming_call_channel.dart`, `call_quality_monitor.dart`, `call_token_refresh.dart`, `lib/features/calls/data/services/*` (`call_kit_service`, `callkit_pending_flusher`, `callkit_terminal_request`, `call_signaling_service`, `call_service`).
- Router config and any overlay/PiP host for minimized calls; Android `MainActivity` / manifest flags relevant to lock screen (`showWhenLocked`, `turnScreenOn`) and CallKit full-screen intent.
- Git history for prior attempts: `git log --oneline -30 -- lib/features/calls lib/screens/*call*` (there was a `fix/call-local-pip-black` branch, already merged — read what it changed so you don't repeat it).

Enumerate every path that can end a call: local hang-up, remote hang-up via Pusher, remote hang-up via FCM/CallKit event, CallKit/ConnectionService "end" button / notification, ring timeout, network drop / Agora `onUserOffline` / `onConnectionStateChanged` failed, token expiry, app backgrounded/minimized (PiP banner) then ended, decline before connect, both sides hanging up simultaneously. For each, trace: who pops/navigates, how many times, what overlays/dialogs/end-summary sheets are shown, when the Agora engine is `leaveChannel`/`release`d and on which isolate/thread, and when the `AgoraVideoView`/texture is disposed relative to the widget tree.

Hypotheses to confirm or reject with evidence (cite file:line): double `pop` (popping the route under the call screen → black/empty navigator), `pop` on an empty stack or on a stale context after `mounted` false, `go` vs `pop` mismatch with go_router, end overlay/summary dialog pushed after the call route is already gone and never dismissed, `release()` awaited synchronously while the video view still renders (black texture / engine deadlock), `FlutterCallkitIncoming.endAllCalls` relaunching/bringing activity to front with no route, `showWhenLocked` activity left on top, PiP/minimized host leaving a full-screen black container, a `ModalBarrier`/`Hero`/transition stuck because an exception was thrown during dispose.

## Fix requirements
- One idempotent `endCall(reason)` orchestration (guarded by call id + "ending/ended" state) that every path funnels into; a second end request for the same call is a no-op.
- Navigation away from the call UI happens exactly once, using a navigator/router reference that is valid even if the triggering widget is disposed; never pop below the call route (use `popUntil` the call route / `canPop` checks or `go` to a safe fallback route like the chat or home if the stack is empty).
- UI leaves the call screen immediately (optimistic); backend `end` request, Agora `leaveChannel`+`release`, CallKit end, wake-lock release, audio route reset run in the background with timeouts and error capture, in the correct order (unmount video views before releasing the engine, or ensure release cannot block the UI thread).
- Any end-summary sheet/overlay is shown on the destination screen only if mounted, and always dismissible.
- Works for both caller and callee, voice and video, and when ended from either side or from the CallKit notification.
- No regression for incoming call accept from killed/background state.

## Tests
- Unit/widget tests for the orchestrator: double end, remote+local simultaneous end, end while screen already disposed, end with empty navigator stack → falls back to a safe route, release throwing/timeouts doesn't block navigation.
- Run `flutter analyze` and `flutter test` for calls tests (`test/**/call*`), fix what you break; report pre-existing failures separately.

## Constraints
No backend changes, no new dependencies unless unavoidable, do not commit/push/switch branches, do not touch signing/production google-services/Codemagic. Never log tokens.

## Report
Write `docs/pm/logs/02-call-end-black-screen-REPORT.md`: the confirmed root cause(s) with file:line evidence, rejected hypotheses, the end-path matrix (path → before → after), files changed, tests and results, residual risks, and a precise 2-emulator manual QA script (caller A, callee B; voice & video; end from A, end from B, end from notification, decline, ring-timeout; repeated 3×). End your final message with `RUN2_DONE`.

## Baseline evidence (reproduced 2026-11-15 on 2 emulators on the first try)
Caller A (asdasd, Android 16) voice-calls callee B (avin, Android 13) from the chat page; B accepts from the in-app incoming screen (Pusher `call.incoming`); after ~8 s A taps End call.
- A: returns to chat correctly (`[NAV] unknown -> chat`). Its screenshot is black only because chat_page holds FLAG_SECURE (ScreenshotProtection) - expected, not the bug.
- B: stuck on an EMPTY dark screen (no widgets in the accessibility tree) = the owner's "black screen".
- B's NAV log: `none -> unknown` at 18:08:09.880 AND again at 18:08:09.987 (the incoming call page is pushed TWICE, ~100 ms apart, for the same call_id=131), `none -> unknown` at 18:08:42.066 (accept -> in-call page), then only ONE pop at 18:08:56.830 (`unknown -> none`). The duplicate incoming route stays on the stack and renders nothing.
- B ran the end flow twice: `[outgoing_call_page] endCall API failed` at 18:08:55.001 and again at 18:08:57.245 (both 404 "Call not found or not active" because A already ended it), plus `onUserOffline quit` and Pusher `call.ended` and CallKit `actionCallEnded` all arriving for the same call.
- Pressing BACK on B: `[NAV] unknown -> none` then FATAL `Bad state: Cannot use "ref" after the widget was disposed` at `_IncomingCallPageState.dispose (lib/features/calls/pages/incoming_call_page.dart:38)`.
- `restore setEnableSpeakerphone failed AgoraRtcException(-3)` on both sides during teardown (harmless but should be guarded).
Fix all of these: de-duplicate incoming-call presentation per call_id (Pusher + FCM + CallKit sources), make accept REPLACE the incoming route (not push on top of it), make end idempotent and pop back to the route that was below the call UI (or a safe fallback), never call `ref` in `dispose` (cache notifiers in initState), and treat 404 "not active" on end as success.
