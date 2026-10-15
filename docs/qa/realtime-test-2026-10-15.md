# Realtime QA – 2026-10-15

Devices: emulator-5554 (Pixel_Play AVD), VGJVOBHE59KNV4JB (Xiaomi 2201117SG)
Backend: production https://api.lgbtfinder.com (default for non-flavored/production builds). Pusher key bcf8236559a0fc82dcb9, cluster us3.
Build: debug, --flavor production --target lib/main_production.dart

## Issues

### RT-001 – Only one test account exists; two-device tests are blocked
- Feature: all two-party realtime (chat, typing, read receipts, presence, match, calls)
- Devices: both
- Steps: search repo/seeders/.env for test credentials.
- Expected: two non-marketing QA accounts.
- Actual: only `TestUserSeeder` (thisisnajafi@yahoo.com, prod user id 741, login OK). Other seeded users (password123) are `is_fake` marketing accounts; admin seeders are real people's accounts. Using either would violate rules.
- Severity: Blocker (for QA)
- Evidence: database/seeders/TestUserSeeder.php, SevenThirtySevenUsersSeeder.php (`is_fake => true`)
- Status: Open – needs user to supply a second test account

### RT-002 – Local backend can't send FCM
- Feature: push notifications
- Actual: backend `.env` FIREBASE_CREDENTIALS is empty; local server/MySQL were not running. Only production can be used for FCM.
- Severity: Low (env)
- Status: Info

### RT-003 – Physical phone dropped off adb
- Feature: all (device B)
- Device: VGJVOBHE59KNV4JB (Xiaomi 2201117SG)
- Steps: phone was listed as `device` at 17:12; during APK install it went `offline` and then disappeared from `adb devices` (still missing at 17:43 after an adb server restart).
- Expected: phone stays listed as `device`.
- Actual: not listed; APK not installed on phone.
- Severity: Blocker (env)
- Evidence: adb output "device offline" / "device 'VGJVOBHE59KNV4JB' not found"
- Status: Resolved (18:41, phone reconnected)

### RT-004 – Android build fails with default JDK 11
- Feature: build
- Actual: `flutter build apk` failed: "Android Gradle plugin requires Java 17 … currently using Java 11 (C:\Program Files\Zulu\zulu-11-jre)". Fixed for this PC by `flutter config --jdk-dir "C:\Program Files\Java\jdk-17.0.2"`.
- Severity: Low (env)
- Status: Worked around (global flutter config changed)

### RT-005 – Production build logs give no realtime connection state
- Feature: websocket (Pusher)
- Device: emulator
- Actual: production flavor logs only `PusherChannelsFlutter: Start …` (twice: at app start and after login); no connected/subscribed state is logged, so connection can't be verified from logcat. Can't confirm subscription success.
- Severity: Low (observability)
- Evidence: logcat --pid, 17:41:30 and 17:42:28
- Status: Open

## Results so far (emulator only, account thisisnajafi@yahoo.com / id 741, production backend)
- Install + launch + onboarding + login: PASS (emu-01…emu-06)
- Chat list loads existing conversation with "Message read" receipt state shown: PASS (emu-07)
- Pusher client starts: PASS (connection state unverified, RT-005)
- Two-device features: NOT RUN (RT-001, RT-003)

## Session 2 (18:41)
- adb devices: both listed (`VGJVOBHE59KNV4JB device`, `emulator-5554 device`). RT-003 → Resolved.
- Emulator: logged out of test account, "Continue with Google" → account picker → profnajafi3@gmail.com, no password/2FA. Home shows "Hello, Abolfazl". PASS (emu-10, emu-11, emu-12)

### RT-006 – LGBTFinder app is not installed on the phone; MIUI blocks adb install
- Feature: all (device B)
- Device: VGJVOBHE59KNV4JB
- Steps: `pm list packages` (incl. -3 -u) → no com.lgbtfinder (no package with lgbt/finder except unrelated ones). `adb install -r app-production-debug.apk` → MIUI "Install this app via USB?" dialog; tapping Install via `adb shell input tap` has no effect.
- Expected: app present and logged in as asdasd@asd.com (per user).
- Actual: app absent; install fails `INSTALL_FAILED_USER_RESTRICTED: Install canceled by user` (2 attempts).
- Severity: Blocker (env)
- Evidence: ph-00-install.png, adb output
- Status: Resolved (19:07)

### RT-007 – uiautomator returns stale dump ("could not get idle state") on Discover
- Feature: QA tooling, emulator. Discover screen animates continuously, so uiautomator never sees idle and returns the previous screen. Screenshots are reliable.
- Severity: Low · Status: Info


## Session 3 (19:04) – phone installed (debug build, install via USB accepted), asdasd@asd.com logged in; emulator = Google account "Abolfazl" (profnajafi3@gmail.com). Existing conversation between both reused. RT-006 → Resolved (adb input works).

| Test | Result | Evidence |
|---|---|---|
| Presence: both show "Online" in list/header | PASS | emu-13-chats, ph-04-chats |
| Typing emu→phone ("is typing" in phone header) | PASS | ph-06-typing |
| Typing phone→emu | PASS | uiautomator header "asdasd · is typing" |
| Chat emu→phone "RT test 1" live (~≤5s incl. tooling) | PASS | ph-07-recv1 |
| Read receipt live on emu ("Message read") | PASS | emu-15-sent1 |
| Chat phone→emu "RT test 2" + live "Message read" on phone | PASS | emu-17-recv2, ph-08-sent2 |
| Presence goes offline when phone app backgrounded | FAIL | RT-008 |
| FCM push, phone app backgrounded | FAIL | RT-009 |

### RT-008 – Peer stays "Online" after app is backgrounded
- Feature: presence · Devices: phone (bg) → emulator (observer)
- Steps: phone in thread → HOME; wait 25 s; read emulator header.
- Expected: "Last seen…"/offline within a short grace.  Actual: still "Online" after 25 s (may be a deliberate grace period – confirm intended timeout).
- Severity: Low/Medium · Status: Fixed locally (7d6e2e720313f7faf63be0db1031da1f8f46d311, 5a55c7e9f4e63be8dddd71cc4831f4abb1168686), pending deploy/retest

### RT-009 – FCM message received but no notification shown while app in background
- Feature: push (FCM) · Devices: emulator sends, phone receives
- Steps: phone app → HOME (once from thread, once from chat list); emulator sends "RT test 3" (19:15) / "RT test 4" (19:17).
- Expected: system notification "Abolfazl: RT test …".
- Actual: logcat shows `c2dm.intent.RECEIVE pkg=com.lgbtfinder` and `FLTFireMsgReceiver: broadcast received for message` at 19:15:24, but `dumpsys notification` has 0 entries for com.lgbtfinder; nothing in shade. POST_NOTIFICATIONS granted, app channel importance DEFAULT. Sender shows "Message delivered".
- Likely cause: data-only FCM payload not turned into a local notification in the background isolate (or suppressed). Needs code check of background handler.
- Severity: High · Evidence: ph-09-bg-notif, ph-11-bg-notif2, logcat · Status: Fixed locally (61ed02ca604f491cc83fac388d234483515c4840, 104f3d09ca2baa35a6d3b435d584a4fc24531b33), pending deploy/retest


## Session 3b – Calls (19:18–19:46)
Note: chat and in-call screens set FLAG_SECURE → screenshots are black; evidence = uiautomator text, Agora logs, `/api/calls/history`.

| Call test | Result | Evidence |
|---|---|---|
| Voice emu→phone, phone fg: in-app incoming screen, accept, both timers run | PASS (#63, 64 s) | ph-26-incoming-voice, uiautomator "00:08"/"00:11" |
| Mute (phone) toggles to "Unmute microphone" | PASS (UI); no peer-side mute indicator | uiautomator |
| Speaker toggle routes audio to speaker | PASS | dumpsys audio "Active communication device … type:speaker" |
| Hang-up from phone ends both sides | PASS | #63 ended |
| Video phone→emu, accept on emu | PASS on 2nd try (#65, 214 s); 1st try FAIL (RT-012) | Agora log `onRemoteVideoStateChanged … Decoding` on emu |
| Remote video decoded (emu receives phone video) | PASS | emu Agora log 19:29:54 |
| Camera off/on (emu) | PASS | Agora `localVideoStreamStateStopped` → `Capturing/Encoding`; peer UI "Camera is off" |
| Flip camera | UI only, not verified (no log, secure screen) | – |
| Hang-up from emu ends both | PASS (#65, #69) | history, ph-45-after-remote-hangup |
| Decline (phone fg) → caller sees "Call Declined" | PASS (#68) | emu toast text |
| Missed call (no answer) | FAIL server side (RT-011); client shows entry after manual end | #67 |
| Call history / missed list on phone (Calls tab) | PASS | ph-42-calls-tab "Abolfazl Najafi, 3 missed calls" |
| Incoming while phone app in background (CallKit heads-up, Accept) | PASS (#69) | ph-44-bg-incoming-callkit |
| Incoming while phone app process killed (FCM wakes app, CallKit) | PASS ring | #70, pid restarted, notif posted |
| Decline from CallKit while app was killed | FAIL (RT-013) | #70 stayed ringing |
| Incoming with emu in background | NOT RUN (aborted, see RT-015) | – |
| Video emu→phone, voice phone→emu (separately) | partially: video phone→emu, voice emu→phone done; reverse dirs not completed | – |

### RT-010 – Stale "ringing" call blocks all calls between a pair ("There is already an active call with this user")
- Feature: calls · Devices: both
- Evidence: `/api/calls/history` → call #62 (742→745 audio) `status=ringing` since 2026-09-05T08:00:30Z. Every new call either direction failed with "There is already an active call with this user" (emu 19:19, phone 19:21) until I ended #62 via `POST /api/calls/end` as the receiver (→ missed).
- Root cause: (a) `CallService::assertNoLiveCallConflict` treats RINGING/INITIATING as live, but the app's `_rejoinActiveCall` uses `/calls/active`, which only returns ACTIVE → the app can't rejoin or clear it; (b) the `calls:update-missed` safety net (RING_TIMEOUT_SECONDS=45) is clearly not running on production (row 41 days old).
- Expected: stale ringing calls expire after 45 s.  Severity: **Critical** (calls dead for that pair) · Status: Fixed locally (1f1162318058779da66d87b5f20f258775a464bf, 921c32fd65c1bd7db34b1fce46f09f3eecbdcf4a), pending deploy/retest

### RT-011 – Unanswered call is never marked missed on server
- Steps: emu calls phone (#67), nobody answers; caller UI gives up and returns to chat.
- Actual: #67 still `ringing` minutes later; would cause RT-010 again. (Caller doesn't send cancel on timeout; cron not running.)
- Severity: **High** · Evidence: history 16:07:47Z ringing, cleared manually → missed · Status: Fixed locally (0b653479f46164ab0a299ee97c531f19128bd0d4, 6b2cbf72a46ee119eca586afd7a8b5f4b7fb6ffe), pending deploy/retest

### RT-012 – Accepting a video call while the camera permission prompt is up records the call as "rejected"
- Steps: first-ever video call to emu; tap Accept → Android camera permission dialog → "While using the app".
- Actual: call ends; server #64 `rejected`, "User rejected the call". Second call works.
- Severity: Medium · Status: Fixed locally (42cc63ec1f10fbd0b85e7659f21fde9a5e558421), pending deploy/retest
- Related: first voice call from emu while mic permission prompt was showing never rang the phone (19:18).

### RT-013 – Declining from CallKit when the app was killed doesn't reach the server
- Steps: phone app killed (`am kill`), emu calls (#70); CallKit banner shows; tap Decline.
- Actual: banner disappears, but #70 stays `ringing`, caller keeps "Ringing…" until its own timeout → stale row (RT-010).
- Severity: **High** · Status: Fixed locally (043fc86f5abab418786c8f84ff9d98039c8e3141), pending deploy/retest

### RT-014 – Phone reported "busy" right after a video call ended remotely while call UI was minimized
- Steps: video #65, phone minimized call ("Hide call and open chat"), emu hangs up. "Active call … Tap to return" banner stayed on phone; tapping it did nothing. Next call #66 → `busy` "User is busy"; emu retry then rejoined #66's dead channel and sat at "Connecting…".
- Workaround: force-stop the app. Severity: High · Status: Fixed locally (e4e257078c6fec2ba52495e7e28fa1898ebab8e6), pending deploy/retest

### RT-015 – QA incident: test call placed to a non-test user
- At 19:45 the phone chat list order had changed after an app restart; my coordinate tap opened "alireza" (user 743) instead of "Abolfazl", and a video call (#71) rang ~25 s before I cancelled it via API (→ cancelled). No message was sent. User 743 may see a missed/cancelled call from asdasd.
- Status: Reported; testing stopped here.

### Other observations
- Presence: RT-008 fixed locally, pending deploy/retest. Incoming call on phone #67 right after app restart didn't show in-app (rang fine later) – possibly Pusher not yet subscribed; intermittent.
- Phone shows "Network quality unknown" while emu shows "excellent" in the same call (minor).
- Agora remote video briefly `Frozen (NetworkCongestion)` then recovered (network, not app).

## Needs deploy/approval

### RT-010 – production scheduler cron

Do not change the production server from this change set. After the backend commit `1f1162318058779da66d87b5f20f258775a464bf` is deployed, the Laravel app still only expires stale calls on a schedule when cron invokes the scheduler.

Exact crontab line (every minute, from the Laravel root; production path used in the deploy checklist is `/var/www/lgbtinder-backend`):

```
* * * * * cd /var/www/lgbtinder-backend && php artisan schedule:run >> /dev/null 2>&1
```

The task's required command is `* * * * * php artisan schedule:run` (run as the app user, working directory = the deployed backend). `calls:update-missed` is already registered every minute in `routes/console.php` (the schedule Laravel 12 actually runs) and in `app/Console/Kernel.php`.

How to verify after deploy:

1. `crontab -l` (or `sudo crontab -l -u www-data`) contains `* * * * * php artisan schedule:run`.
2. From the backend root, `php artisan schedule:list` shows `calls:update-missed` with expression `* * * * *`.
3. `php artisan calls:update-missed` prints success and marks `ringing`/`initiating` rows with `started_at` older than 45 seconds as `missed`, and `active` rows with no activity older than 4 hours (`Call::ACTIVE_STALE_SECONDS`) as `ended`.
4. `php artisan schedule:run` once, then confirm a fresh stale ringing row (or the log line `Call marked as missed`) updates. A row left `ringing` for days means this cron is not firing.

### RT-008 – presence heartbeat expiry

Do not change the production server from this change set. Chat "Online" now expires 20 seconds after the last heartbeat (`UserPresenceService::PRESENCE_TTL_SECONDS`). The app sends offline on `AppLifecycleState.paused` and online on resume, and the chat header switches to "Last seen" on that broadcast or when the 20s TTL elapses locally.

`presence:expire-stale` broadcasts `user.status` (offline) for heartbeats older than that TTL. It is registered every minute in `routes/console.php` and `app/Console/Kernel.php`. It runs only when cron already invokes the scheduler. No new crontab line.

Exact crontab line (same as RT-010; production path `/var/www/lgbtinder-backend`):

```
* * * * * cd /var/www/lgbtinder-backend && php artisan schedule:run >> /dev/null 2>&1
```

How to verify after the backend is deployed:

1. `php artisan schedule:list` shows `presence:expire-stale` with expression `* * * * *`.
2. `php artisan presence:expire-stale` prints `Expired N stale presence record(s).` and, for a user whose last heartbeat is older than 20 seconds, broadcasts `user.status` with `is_online: false` and the existing `last_seen`.
3. With the scheduler cron firing, a peer who backgrounds (or whose offline POST never arrives) is no longer "Online" after the 20 second TTL plus at most one minute for the catch-up broadcast.

## Session 4 – Retest after fixes (23:27–23:55)
Backend pushed aaca4a6..7d6e2e7 (approved) → GitHub Actions "LGBTFinder Backend" run 38796149700: test ✔, deploy ✔; migration 2026_10_15_140000 ran. App: new debug build (HEAD 1015fff) installed on emulator + phone (no wipe). App NOT pushed.
Scheduler cron: NOT added – no SSH access to the VPS from the PC (deploy key/host only in GitHub secrets VPS_SSH_KEY/VPS_HOST/VPS_USER). Needed on VPS as the web user:
`* * * * * cd /var/www/backend && php artisan schedule:run >> /dev/null 2>&1` (APP_PATH = VPS_APP_PATH secret, default /var/www/backend), then verify `php artisan schedule:list` shows calls:update-missed and presence:expire-stale.

| Test | Result | Evidence |
|---|---|---|
| Presence Online (both) | PASS | headers |
| Presence offline when phone backgrounded (RT-008) | PASS – "Last seen just now" within 8 s; Online again on resume | uiautomator |
| Typing both ways | PASS | "is typing" headers |
| Chat both ways + live read receipts | PASS | "RT retest 1/2 … Message read" |
| Background message push (RT-009) | PASS – "New Message! 💬 / Abolfazl Najafi sent you a message" (2 entries posted – check for duplicate) | dumpsys notification, ph-53-bg-push |
| Voice emu→phone fg: ring, accept, mute, speaker, hang-up from emu | PASS (#72, 31 s) | history |
| Video phone→emu: ring, accept, camera off/on | PASS (#73 46 s, #74 32 s) | Agora local video Stopped→Capturing→Encoding |
| Flip camera | NOT VERIFIED (no log; secure screen) | – |
| Minimized call + remote hang-up clears banner; next call rings (RT-014) | PASS (#74 → #75 rang) | uiautomator |
| Decline fg | PASS (#75 rejected) | history |
| No answer → server missed (RT-011) | PASS (#76 missed, end=caller-timeout) | history |
| Decline from CallKit with app killed (RT-013) | PASS (#77 rejected) | history |
| Incoming call with app in background (CallKit banner) | **FAIL – regression RT-016** (#78, #79) | ph-56/57, logcat |
| Stale-ringing server timeout (RT-010) | Covered by backend tests; no stale call seen in retest; cron not installed | – |
| Permission-prompt accept (RT-012) | NOT RETESTED (permissions already granted on both devices) | – |
| Likes / match notifications | NOT RUN (accounts already matched; Discover empty) | – |

### RT-016 – Regression: no CallKit incoming banner while app is in background
- Steps: after RT-013 test (app killed, declined from banner), phone HOME; emu calls (#78 23:49, #79 23:52).
- Expected: CallKit heads-up (worked in session 3, #69). Actual: FCM delivered (`FLTFireMsgReceiver: broadcast received` 23:50:01, pid 2818) but no notification posted; call times out as missed. Foreground ringing still works (#72, #75).
- Suspect: RT-013 (043fc86) / RT-012 (42cc63e) changes to the CallKit/background handler. Severity: **High** · Status: Fixed locally (06f03d8284d72f81e614c00eefb04a82937ce24d), pending deploy/retest

### RT-017 – One background chat message posts two system notifications
- Feature: push (FCM) · Devices: emulator sends, phone receives
- Steps: phone app backgrounded; one chat message arrives.
- Expected: one shade entry. Actual: two entries, both title "New Message! 💬" and body "Abolfazl Najafi sent you a message" (FCM notification payload plus the RT-009 local notification).
- Severity: Medium · Evidence: dumpsys notification, ph-53-bg-push · Status: Fixed locally (5c5f68c9fdf8b0de7806aa662def992c4bb82d06), pending deploy/retest

## Session 5 — two emulators (2026-10-16 ~00:45–01:05 Tehran)
emulator-5554 Pixel_Play = user 742; emulator-5556 Pixel_Play13 = user 745 (asdasd). Build with 06f03d8 + 5c5f68c. All calls 742<->745 only (verified in history).

| Test | Result | Evidence |
|---|---|---|
| Presence / Online | PASS | both headers "Online" |
| Typing | PASS | 5554 header "is typing" |
| Chat delivery | PASS | "RT_emu_test_1" shown on 5554 |
| Background notification exactly 1 (RT-017) | PASS | dumpsys: single lgbtfinder_messages record |
| Background incoming banner (RT-016) | PASS | callkit_incoming_channel_id, category=call, call #80 745->742 |
| Banner decline | PASS | #80 rejected "User rejected the call" |
| Missed call | PASS | #81 missed caller-timeout + callkit_missed notification |
| Voice call accept | PASS | #82 active, both sides timer |
| Minimize + remote hang-up | PASS | "Active call… Tap to return" pill, then #82 ended dur=50, pill cleared |
| Video call | PASS | #83 Agora onRemoteVideoStateDecoding, ended dur=33 |
| RT-012 initiate without permission (fresh install 5556) | PASS | mic/camera prompts shown, call proceeded (#80, #83) |
| RT-012 accept after pm revoke (5554) | PARTIAL | accept from banner (#86) showed mic then camera prompts, both granted; ring timeout (45s) expired during prompts so not connected. Not an app bug per se; consider pausing ring timeout / longer window while prompting |

Notes: #85 was auto-declined right after the revoke-relaunch (CallkitKilledAction "Persisted decline 85") with no decline tap — needs a look (possible stale queued decline). Presence `user.status` events arrive every ~2 s on 5554 (noisy). Screenshots: rt-shots/emu-*, emu2-*.
