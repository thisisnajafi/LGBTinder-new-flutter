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
- Severity: Low/Medium · Status: Open (needs longer observation)

### RT-009 – FCM message received but no notification shown while app in background
- Feature: push (FCM) · Devices: emulator sends, phone receives
- Steps: phone app → HOME (once from thread, once from chat list); emulator sends "RT test 3" (19:15) / "RT test 4" (19:17).
- Expected: system notification "Abolfazl: RT test …".
- Actual: logcat shows `c2dm.intent.RECEIVE pkg=com.lgbtfinder` and `FLTFireMsgReceiver: broadcast received for message` at 19:15:24, but `dumpsys notification` has 0 entries for com.lgbtfinder; nothing in shade. POST_NOTIFICATIONS granted, app channel importance DEFAULT. Sender shows "Message delivered".
- Likely cause: data-only FCM payload not turned into a local notification in the background isolate (or suppressed). Needs code check of background handler.
- Severity: High · Evidence: ph-09-bg-notif, ph-11-bg-notif2, logcat · Status: Open


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
- Expected: stale ringing calls expire after 45 s.  Severity: **Critical** (calls dead for that pair) · Status: Fixed locally (1f1162318058779da66d87b5f20f258775a464bf), pending deploy/retest

### RT-011 – Unanswered call is never marked missed on server
- Steps: emu calls phone (#67), nobody answers; caller UI gives up and returns to chat.
- Actual: #67 still `ringing` minutes later; would cause RT-010 again. (Caller doesn't send cancel on timeout; cron not running.)
- Severity: **High** · Evidence: history 16:07:47Z ringing, cleared manually → missed · Status: Open

### RT-012 – Accepting a video call while the camera permission prompt is up records the call as "rejected"
- Steps: first-ever video call to emu; tap Accept → Android camera permission dialog → "While using the app".
- Actual: call ends; server #64 `rejected`, "User rejected the call". Second call works.
- Severity: Medium · Status: Open
- Related: first voice call from emu while mic permission prompt was showing never rang the phone (19:18).

### RT-013 – Declining from CallKit when the app was killed doesn't reach the server
- Steps: phone app killed (`am kill`), emu calls (#70); CallKit banner shows; tap Decline.
- Actual: banner disappears, but #70 stays `ringing`, caller keeps "Ringing…" until its own timeout → stale row (RT-010).
- Severity: **High** · Status: Open

### RT-014 – Phone reported "busy" right after a video call ended remotely while call UI was minimized
- Steps: video #65, phone minimized call ("Hide call and open chat"), emu hangs up. "Active call … Tap to return" banner stayed on phone; tapping it did nothing. Next call #66 → `busy` "User is busy"; emu retry then rejoined #66's dead channel and sat at "Connecting…".
- Workaround: force-stop the app. Severity: High · Status: Open

### RT-015 – QA incident: test call placed to a non-test user
- At 19:45 the phone chat list order had changed after an app restart; my coordinate tap opened "alireza" (user 743) instead of "Abolfazl", and a video call (#71) rang ~25 s before I cancelled it via API (→ cancelled). No message was sent. User 743 may see a missed/cancelled call from asdasd.
- Status: Reported; testing stopped here.

### Other observations
- Presence: RT-008 still open. Incoming call on phone #67 right after app restart didn't show in-app (rang fine later) – possibly Pusher not yet subscribed; intermittent.
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
