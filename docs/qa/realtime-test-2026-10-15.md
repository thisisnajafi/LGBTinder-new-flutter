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
- Status: Open – user must tap "Install" on the phone during install, or enable Developer options → "Install via USB" + "USB debugging (Security settings)" (latter also needed for adb taps/typing on MIUI).

### RT-007 – uiautomator returns stale dump ("could not get idle state") on Discover
- Feature: QA tooling, emulator. Discover screen animates continuously, so uiautomator never sees idle and returns the previous screen. Screenshots are reliable.
- Severity: Low · Status: Info

