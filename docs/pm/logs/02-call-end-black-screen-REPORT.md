# Run 2/5 — Black screen after a call ends

**Date:** 2026-11-15  
**Branch:** `fix/optimistic-logout-call-blackscreen`  
**Scope:** Callee black screen after hang-up (reproduced on 2 emulators)

## Confirmed root causes (with evidence)

### 1. Duplicate incoming route left on the stack (primary black screen)

**Baseline (owner repro):** B’s NAV log pushed `/call/incoming` twice ~100 ms apart for `call_id=131`, then pushed the in-call page on accept. Hang-up only popped once → top of stack was a stale incoming page with `incomingCallProvider == null` → empty dark `Scaffold` (no widgets in a11y tree).

**Code:**

| Issue | Evidence |
| --- | --- |
| Race opens incoming twice | `IncomingCallHost._adoptAndOpenIncoming` set `_openingIncoming` *after* awaits / path checks (`incoming_call_banner.dart` ~340–359 before fix). Concurrent `ref.listen` + lifecycle/resume both passed the guard and `router.push(AppRoutes.incomingCall)`. |
| Accept stacked on top of incoming | `IncomingCallNotifier.accept` used `router.push(activeCallLocation…)` (`incoming_call_provider.dart` ~267–277 before fix), leaving the incoming route(s) underneath. |
| Single pop on leave | `leaveCallRoute` did one `context.pop()` (`call_navigation.dart` ~170–186 before fix). After hang-up, stack was `[…, incoming, incoming?, outgoing]` → one pop revealed empty incoming. |
| go_router URI vs stack mismatch | Imperative pushes can leave `uri.path` on the parent (e.g. `/chat`) while matches still contain `/call/incoming` + `/call/outgoing`. A path-only check skipped popping (verified in widget debug: `path=/chat`, `matches=[/chat,/call/incoming,/call/incoming,/call/outgoing]`). |

### 2. Non-idempotent end / 404 treated as failure

B ran end twice (`outgoing_call_page` endCall API failed @ 18:08:55 and 18:08:57) with 404 “Call not found or not active” because A already ended. `_postEndIfNeeded` reset `_endPosted = false` on failure → retried. Simultaneous sources: local End, Agora `onUserOffline quit`, Pusher `call.ended`, CallKit `actionCallEnded`.

### 3. `ref` after dispose on back from black screen

`IncomingCallPage.dispose` called `ref.read(incomingCallProvider.notifier)` (`incoming_call_page.dart:38` before fix) → `Bad state: Cannot use "ref" after the widget was disposed` when BACK popped the stale page.

### 4. Harmless Agora restore noise

`restore setEnableSpeakerphone failed AgoraRtcException(-3)` during teardown after `leaveChannel` — expected; now guarded.

## Rejected hypotheses

| Hypothesis | Verdict |
| --- | --- |
| Double `pop` below the call route emptying the navigator | Rejected for this repro: only **one** pop; the leftover was a **duplicate incoming**, not an empty root. |
| End-summary / `CallEndOverlay` stuck ModalBarrier | Rejected: overlay finishes via `onFinished → _leaveCallUi`; A left correctly; B stuck on empty incoming, not the overlay. |
| `AgoraVideoView` / `release()` deadlock as the black screen | Rejected for this repro (voice call, no video texture). Engine teardown still made optimistic. |
| `FlutterCallkitIncoming.endAllCalls` relaunching activity with no route | Not needed to explain B’s stack; CallKit end still idempotent via orchestrator. |
| `showWhenLocked` activity left on top | Not indicated by NAV/`none` stack on B. |
| PiP / minimized host full-screen black | Call was full-screen accepted, not minimized. Prior `fix/call-local-pip-black` work (`cefa988`) is unrelated. |

## End-path matrix

| Path | Before | After |
| --- | --- | --- |
| Local hang-up (End button) | `_endCall` → summary → single `pop` | `CallEndOrchestrator.beginEnd` → optimistic summary → media/API background → `leaveCallRoutes` pops **all** call UI |
| Remote Agora `onUserOffline quit` | Same as local `_endCall` (could race) | Orchestrator no-ops second end; first path leaves once |
| Pusher `call.ended` / signaling | Could race with local end + 404 retry | Inactive 404 = success; orchestrator dedupes |
| CallKit / notification hang-up | `hangUpFromSystem` teardown; page might still be up | Orchestrator; page uses captured `GoRouter` to leave |
| Ring timeout (caller) | `_postEnd` + leave | Unchanged policy via `OutgoingCallEnd`; leave uses `leaveCallRoutes` |
| Decline before connect | Clears incoming state; page may pop itself | Incoming dedupe + dispose-safe notifier; no stacked ghost |
| Accept then remote/local end | Incoming still under outgoing | Accept **`pushReplacement`**; leave pops any leftover incoming |
| Simultaneous both sides hang-up | Double API end, 404 noise, possible double UI leave | First `beginEnd` wins; 404 success; single navigation |
| Empty / splash-under-call stack | Single pop → dead splash / black | `go(home)` fallback when cannot pop or splash under call |

## Fixes implemented

1. **`CallEndOrchestrator`** (`lib/features/calls/utils/call_end_orchestrator.dart`) — idempotent `beginEnd` / `markEnded` per call id; `isInactiveEndSuccess` for 404/not-active; incoming present policy helper.
2. **`leaveCallRoutes`** — pop while top stack match is call UI; fallback `go(home)`; uses top **match** location, not stale `uri.path`.
3. **Incoming dedupe** — `_openingIncoming` set before any await; `shouldPresentIncomingRoute` + `_presentedIncomingCallId`.
4. **Accept replaces incoming** — `openActiveCallReplacingIncoming` → `pushReplacement` when top is incoming.
5. **Incoming dispose** — cache notifier in `initState`; never `ref` in `dispose`.
6. **404 end = success** — `CallNotifier.endCall` + `_postEndIfNeeded` / system hang-up.
7. **Agora speaker restore** — skip during teardown / treat `-3` as benign.

## Files changed

- `lib/features/calls/utils/call_end_orchestrator.dart` **(new)**
- `lib/features/calls/utils/call_navigation.dart`
- `lib/features/calls/pages/incoming_call_page.dart`
- `lib/features/calls/pages/outgoing_call_page.dart`
- `lib/features/calls/providers/incoming_call_provider.dart`
- `lib/features/calls/providers/call_provider.dart`
- `lib/features/calls/providers/active_call_session_provider.dart`
- `lib/features/calls/presentation/widgets/incoming_call_banner.dart`
- `lib/shared/services/agora_service.dart`
- `test/unit/features/calls/call_end_orchestrator_test.dart` **(new)**
- `test/widget/features/calls/call_end_navigation_test.dart` **(new)**

## Tests & results

```
flutter analyze <changed files>     → No issues found
flutter test (calls suites)         → 210 passed, 1 failed (pre-existing)
```

**New tests:** double end, remote+local race, disposed-widget leave via router, empty stack → home, replace incoming, 404 success, incoming present dedupe.

**Pre-existing failure (unchanged by this run):**  
`test/unit/features/calls/call_primary_photo_test.dart` — `IncomingCallData prefers primary_image_url over avatar crop` (expects primary URL, gets avatar crop). Unrelated to call-end navigation.

## Residual risks

- go_router imperative stack vs URI drift can still surprise other call navigations that only read `uri.path` (e.g. some restore checks); call leave/present now use match stack.
- Orchestrator is process-global; a theoretically reused numeric call id after process lifetime without reset would no-op end (server ids are monotonic; `reset` exists for tests).
- Cold-start CallKit accept path still depends on Splash seating home under the call; not re-validated on device in this run.
- Manual 2-emulator QA below still required for voice/video × end sources.

## Manual QA script (2 emulators × 3 repeats)

**Devices:** Emulator A = caller, Emulator B = callee. Both logged in, chat open with each other.

For **each** of voice and video, repeat the block **3 times**:

1. **End from A (caller)**  
   A starts call from chat → B accepts in-app incoming → talk ~5–10 s → A taps End.  
   **Expect:** A returns to chat; B returns to chat (or previous non-call screen). No black screen. No FATAL on Back.

2. **End from B (callee)**  
   Same setup → B taps End.  
   **Expect:** both leave call UI once; no duplicate end spam / no stuck overlay.

3. **End from notification / CallKit ongoing**  
   Connect call → use ongoing-call notification Hang Up (or CallKit end) on one side.  
   **Expect:** both sides tear down; foreground UI leaves call routes.

4. **Decline**  
   A calls → B taps Decline on incoming.  
   **Expect:** B never opens in-call; A sees declined/ended; no leftover incoming route.

5. **Ring timeout**  
   A calls → B does not accept until timeout (~45 s).  
   **Expect:** incoming dismisses; A leaves ringing UI; no black screen.

6. **Regression: killed/background accept (spot-check once per type)**  
   B backgrounded or killed → A calls → B accepts from system incoming UI.  
   **Expect:** lands on in-call (home under call if cold start); hang-up returns to a real screen, not Splash/black.

**Pass criteria:** 0 black screens, 0 `ref after disposed` fatals, Back from post-call screen stays on chat/home, NAV never leaves a lone `/call/incoming` with null provider state.
