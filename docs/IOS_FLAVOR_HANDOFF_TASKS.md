# iOS readiness and flavor handoff — tasks

Checklist for preparing `lgbtindernew/` so a Mac can produce a production iOS build, and so development, staging, and production stay separate on Android and iOS.

## Windows work already done

The project side of Parts B and the text side of Part C are in the tree. Do not run `flutter create`. Do not duplicate the nine Xcode configurations again. They are already in `ios/Runner.xcodeproj/project.pbxproj`.

Still yours, outside the repo: Part A (Apple account, Firebase downloads, staging API host) and Part C on a Mac (`pod install`, signing, device, TestFlight).

| Flavor | Android id | iOS bundle id | API origin |
| --- | --- | --- | --- |
| development | `com.lgbtfinder.dev` | `com.lgbtfinder.dev` | Android emulator `http://10.0.2.2:8000`, otherwise `http://127.0.0.1:8000`. Override with `--dart-define=API_ORIGIN=http://<lan-ip>:8000` |
| staging | `com.lgbtfinder.staging` | `com.lgbtfinder.staging` | None yet. The app throws until you pass `--dart-define=API_ORIGIN=https://<staging-host>` |
| production | `com.lgbtfinder` | `com.lgbtfinder` | `https://api.lgbtfinder.com`. Passing `API_ORIGIN` is a startup error |

Run from `lgbtindernew`:

```powershell
.\scripts\flutter-flavor.ps1 -Flavor development
.\scripts\flutter-flavor.ps1 -Flavor production -Action apk
```

VS Code launch configs are `development`, `staging`, and `production`.

The real `google-services.json` files are gitignored. This machine still has the production file at `android/app/src/production/google-services.json`. Development and staging have local placeholder copies so Gradle can select a client. Replace those two with downloads from Firebase before those flavors talk to Firebase. Commit the `*.example` files only. The old `android/app/google-services.json` and `dart_defines.json` are staged for removal from git. They stay on disk. `dart_defines.json` disagreed with the Laravel Pusher key, so the flavor config uses the key from `lgbtinder-backend/.env`.

کار ویندوز داخل پروژه انجام شده است. نه پیکربندی Xcode از قبل داخل پروژه هستند و نباید دوباره ساخته شوند. شناسهٔ تولید همان `com.lgbtfinder` است و API تولید همان `https://api.lgbtfinder.com` است. استیجینگ تا وقتی `--dart-define=API_ORIGIN=https://...` ندهید بالا نمی‌آید. ثبت‌نام اپل، دانلود فایربیس، و `pod install` روی مک هنوز کار خود شماست.

iOS readiness today is about 32/100. The `ios/` folder exists. `Podfile`, Firebase iOS config, entitlements, and flavors do not. No files in the app were changed by the audit.

Do the browser actions in Part A first. Several of them take one to two business days. Windows code work in Part B can start in parallel after the bundle ids below are accepted. Mac work in Part C starts only after Part B is in the repo and the six Firebase files exist.

## Locked decisions

Keep these. Changing them later means new store listings and new Firebase apps.

| Flavor | Android application id | iOS bundle id | Launcher name |
| --- | --- | --- | --- |
| production | `com.lgbtfinder` | `com.lgbtfinder` | LGBTFinder |
| staging | `com.lgbtfinder.staging` | `com.lgbtfinder.staging` | LGBTFinder Staging |
| development | `com.lgbtfinder.dev` | `com.lgbtfinder.dev` | LGBTFinder Dev |

- Production stays `com.lgbtfinder`. Do not switch production to `com.lgbtfinder.app`. That id is a different app and drops the Firebase Android client already registered in project `lgbtfinder-fa8e5`.
- Keep Firebase project `lgbtfinder-fa8e5` as production. Create separate Firebase projects for development and staging.
- Minimum iOS version for this app is 15.0.
- Flavor names are exactly `development`, `staging`, and `production` on Android, iOS, and the Flutter CLI.
- Xcode needs nine build configurations: Debug, Profile, and Release for each flavor. Names look like `Debug-development` and `Release-production`.
- Flutter commands always pass both flags, for example `flutter run --flavor development --target lib/main_development.dart`.
- The in-app design system does not change. Flavors change environment, ids, Firebase files, logging, and launcher icons.
- Do not run `flutter create` again. It overwrites `AppDelegate.swift`, `Info.plist`, and `project.pbxproj`.
- Real Firebase files, keystores, `key.properties`, `dart_defines.json`, `.p8`, `.p12`, and provisioning profiles stay out of git. Commit placeholders only.

Supply these values yourself. They are not in the repo:

- Development API origin
- Staging API origin
- Which existing Pusher key is production (`lib/core/config/pusher_config.dart` and `dart_defines.json` currently disagree)

---

## Part A — Do these in a browser on Windows

Apple enrollment and Firebase registration do not need a Mac.

### A1. Apple Developer Program

- [ ] Open [developer.apple.com](https://developer.apple.com) and confirm the team has an active Apple Developer Program membership (99 USD per year).
- [ ] If it does not, enroll as an individual (personal Apple ID, legal name, address, credit card) or as an organization (D-U-N-S number and someone who can bind the company).
- [ ] Wait for identity verification. This usually takes one to two business days. TestFlight and App Store uploads stay blocked until the membership is active.

A free Apple ID can run the simulator later. It cannot create these App IDs or distribution certificates.

### A2. App IDs

In Certificates, Identifiers & Profiles, register three explicit App IDs:

- [ ] `com.lgbtfinder`
- [ ] `com.lgbtfinder.staging`
- [ ] `com.lgbtfinder.dev`

On each App ID, enable:

- [ ] Push Notifications
- [ ] Background Modes, with Voice over IP and Remote notifications selected

Leave these off until the product actually uses them:

- Sign in with Apple (`sign_in_with_apple` is in `pubspec.yaml` and has no call site in `lib/` yet)
- Associated Domains (no universal-link host yet)
- Always location, Contacts, and Face ID (the app does not use them)

### A3. APNs key

- [ ] In the same portal, create one Key with Apple Push Notifications service (APNs) enabled.
- [ ] Download the `.p8` file once. Apple will not show it again.
- [ ] Store the `.p8`, the Key ID, and the Team ID in the team password manager.
- [ ] Do not commit the `.p8`.

One key covers all three apps, including VoIP pushes. You do not need a separate VoIP certificate if the backend sends token-based APNs with this key.

### A4. Firebase

- [ ] Keep project `lgbtfinder-fa8e5` as production.
- [ ] Create a development Firebase project.
- [ ] Create a staging Firebase project.
- [ ] In production, keep the existing Android app `com.lgbtfinder`. Register an iOS app with bundle id `com.lgbtfinder`.
- [ ] In staging, register Android `com.lgbtfinder.staging` and iOS `com.lgbtfinder.staging`.
- [ ] In development, register Android `com.lgbtfinder.dev` and iOS `com.lgbtfinder.dev`.
- [ ] Download three `google-services.json` files and three `GoogleService-Info.plist` files. Store them in the password manager until Part B has the destination folders.

Add SHA-1 certificates so Google Sign-In works per flavor:

- [ ] Development: SHA-1 of the debug keystore (and the CI debug keystore, if CI installs dev builds)
- [ ] Staging: SHA-1 of the staging upload keystore
- [ ] Production: SHA-1 of the existing production upload keystore

Then:

- [ ] Upload the same APNs `.p8` (Key ID + Team ID) to Cloud Messaging on the iOS app in each of the three Firebase projects.

`Firebase.initializeApp()` with no options is correct once each build receives its own config file. Do not hardcode production Firebase options in Dart.

### A5. Environment values

- [ ] Write down the development API origin.
- [ ] Write down the staging API origin.
- [ ] Production origin stays `https://api.lgbtfinder.com`.
- [ ] Compare the Pusher key in `lib/core/config/pusher_config.dart` with the key in `dart_defines.json`. Confirm with the backend which value production broadcasts with. Assign the other key to development or staging, or retire it.
- [ ] Agora App ID stays on the token endpoint. The flavor only needs to call the API that issues that token.

### A6. App Store Connect and Play

- [ ] In App Store Connect, create the production app for bundle id `com.lgbtfinder`.
- [ ] Create the subscription group, subscription products, and consumable products. iOS product ids do not have to match Google Play ids. Each product needs a price, a localization, and a review screenshot. Subscriptions need a duration.
- [ ] Create a staging App Store Connect app for `com.lgbtfinder.staging` if QA will use TestFlight or test purchases on that bundle id. Duplicate the products there. StoreKit products belong to one bundle id.
- [ ] In Google Play Console, create the app `com.lgbtfinder.staging` when staging needs an internal track. Production stays the existing `com.lgbtfinder` listing. Give staging its own upload keystore.
- [ ] Create the Play real-time developer notifications Pub/Sub topic and link it in Play Console only after the backend webhook URL is deployed and reachable from Google.

Purchases are tested on a physical iPhone with a Sandbox Apple ID. The simulator is not a purchase test.

### A7. Backend call path

Give the backend the `.p8` when the server work starts. The server must branch by platform:

- [ ] Android callee: keep the current FCM data message.
- [ ] iOS callee: send an APNs VoIP push. Push type is `voip`. Topic is `<bundle-id>.voip`.
  - Development: `com.lgbtfinder.dev.voip`
  - Staging: `com.lgbtfinder.staging.voip`
  - Production: `com.lgbtfinder.voip`
- [ ] The app must register the PushKit VoIP token separately from the FCM token on the existing device-registration API.
- [ ] The VoIP payload must include the call id and caller fields CallKit already expects.
- [ ] Do not also send a normal alert for the same ring.

The iOS app must report the call to CallKit immediately when the VoIP push arrives. Apple terminates apps that receive a VoIP push and do not report a call.

---

## Part B — Windows work, in order

Do this in `lgbtindernew/` before anyone opens the project on a Mac.

### B1. Dart flavor layer

- [ ] Add a flavor config object with flavor name, API origin, display name, log floor, Pusher key, Pusher cluster, optional Agora App ID override, and Google web client id.
- [ ] Add `lib/main_development.dart`, `lib/main_staging.dart`, and `lib/main_production.dart`. Each sets its config, then calls the shared bootstrap in `lib/main.dart`.
- [ ] Each entry point asserts Flutter’s `appFlavor` equals its own flavor, so a development entry point cannot start inside the production application id.
- [ ] Move only the API origin out of `lib/core/constants/api_endpoints.dart`. Keep every path. `baseUrl` reads the active origin.
- [ ] Point `PusherConfig`, `GoogleAuthConfig`, and `dio` at the active config.
- [ ] Point `AppLogger` at the config: development verbose, staging warning and above, production error and fatal. Leave `kDebugMode` for Flutter’s own framework dump only.
- [ ] Stop using `dart_defines.json` and the hardcoded Pusher fallback as the source of truth. Add `dart_defines.json` to `.gitignore`.
- [ ] Update `.vscode/launch.json` so the current one-click run is `--flavor development --target lib/main_development.dart`.

`flutter_dotenv` is already unused. Do not add a new runtime package for flavors.

### B2. Android flavors

Edit `android/app/build.gradle.kts` (Kotlin DSL, not a new Groovy file).

- [ ] Add one flavor dimension named `environment`.
- [ ] Add flavors `development` (application id suffix `.dev`, app name `LGBTFinder Dev`), `staging` (suffix `.staging`, name `LGBTFinder Staging`), and `production` (no suffix, name `LGBTFinder`).
- [ ] Change the manifest label from the literal `LGBTFinder` to `@string/app_name`, with a default string in `src/main`.
- [ ] Leave min SDK, target SDK, multidex, desugaring, Agora JNI excludes, and release minify as they are.
- [ ] Keep release signing on `android/key.properties`. Debug development builds keep the debug keystore. Staging distribution uses a separate upload keystore. Production keeps the current upload keystore.
- [ ] When CI needs it, allow Gradle to read the same four keystore fields from environment variables if `key.properties` is absent. Never put passwords in the Gradle file.

Source sets:

- [ ] Create `android/app/src/development`, `android/app/src/staging`, and `android/app/src/production`.
- [ ] Put each flavor’s `google-services.json` in that flavor directory.
- [ ] Move the current `android/app/google-services.json` into `src/production`. Do not leave a copy at the module root. A root copy becomes a fallback and a dev build can initialize production Firebase.
- [ ] Add badged launcher icons for development and staging. Production keeps the clean icon.
- [ ] Confirm the leftover `com.example` and `com.example.lgbtindernew` Kotlin folders under `src/main/kotlin` are unused, and do not copy them into flavor source sets.
- [ ] Commit `google-services.json.example` placeholders. Gitignore the real flavor json files. `key.properties`, `*.jks`, and `*.keystore` are already ignored.

### B3. iOS text files

- [ ] Raise the deployment target from 13.0 to 15.0 in the Xcode project settings and in `ios/Flutter/AppFrameworkInfo.plist`.
- [ ] Rewrite usage strings in `ios/Runner/Info.plist` so they match LGBTFinder and cover every real use:
  - Camera: video calls, profile photos, and identity verification
  - Microphone: voice and video calls, and voice messages
  - Photo library read: choose pictures for chat and profile
  - Photo library add: save photos downloaded from chat
  - Location when in use: nearby people and safety features the user turns on
  - Bluetooth: headset audio during calls
- [ ] Add `ITSAppUsesNonExemptEncryption` = false if the app only uses standard HTTPS.
- [ ] Keep background modes `voip`, `audio`, and `remote-notification`.
- [ ] Do not add always-location, contacts, or Face ID strings.
- [ ] If the development API is plain HTTP on a LAN address, allow local networking only on the development configuration. Production and staging stay HTTPS-only.
- [ ] Plan the Google Sign-In URL scheme per flavor. The scheme is the reversed client id from that flavor’s `GoogleService-Info.plist`, plus `GIDClientID`. Do not share the production reversed client id across flavors.

Podfile and Firebase layout:

- [ ] Write `ios/Podfile`. Platform is iOS 15.0. Map Debug to `:debug`, and Profile plus Release (including every flavor variant) to `:release`. Use static linkage: `use_frameworks! :linkage => :static`. Install pods with the Flutter iOS helper. In `post_install`, force every pod target to iOS 15.0 and define permission_handler macros on the pod targets: camera, microphone, photos, location when in use, notifications, and Bluetooth.
- [ ] Add `ios/Flutter` xcconfig files for all nine configurations. Each includes the existing Debug or Release xcconfig, then sets `FLUTTER_TARGET`, `PRODUCT_BUNDLE_IDENTIFIER`, `APP_DISPLAY_NAME`, and `APP_FLAVOR`. Profile includes the Release xcconfig.
- [ ] Create `ios/config/development`, `ios/config/staging`, and `ios/config/production` with placeholder `GoogleService-Info.plist` files. Gitignore the real plists.
- [ ] Add `ios/scripts/copy-google-service-info.sh`. It reads `APP_FLAVOR`, copies `ios/config/<flavor>/GoogleService-Info.plist` to the path Firebase reads, and fails the build if the flavor or the file is missing.
- [ ] Add shared schemes `development.xcscheme`, `staging.xcscheme`, and `production.xcscheme` under `ios/Runner.xcodeproj/xcshareddata/xcschemes/`. The scheme name is the flavor name. Run uses `Debug-<flavor>`. Archive uses `Release-<flavor>`. Keep `Runner.xcscheme`.
- [ ] Leave the actual duplication of the nine rows inside `project.pbxproj` for Xcode on the Mac. Hand-editing that file is easy to corrupt. The xcconfig files those rows must reference are committed here.
- [ ] Add badged iOS app-icon sets for development and staging. Point `ASSETCATALOG_COMPILER_APPICON_NAME` at them from the flavor xcconfigs. Production keeps `AppIcon`.

### B4. Command wrappers

- [ ] Add PowerShell scripts for Windows: run each flavor on Android, build a release APK per flavor, and build an app bundle per flavor.
- [ ] Add a Makefile for the Mac with the same commands, plus iOS run and `flutter build ipa` per flavor.
- [ ] Every wrapper passes both `--flavor` and `--target`.

### B5. Prove Android before the Mac handoff

- [ ] Install development and production on one device. They sit side by side, with different names and icons.
- [ ] Development calls the development origin. Production still calls `https://api.lgbtfinder.com` with application id `com.lgbtfinder`.
- [ ] A bare `flutter run` with no flavor fails.
- [ ] `flutter run --flavor production --target lib/main_development.dart` fails the flavor assert.

---

## Part C — Mac work, in order

Start here only after Part B is committed and the six real Firebase files are in the password manager.

### C1. Machine setup

- [ ] Install Xcode from the Mac App Store. Open it once and accept the license.
- [ ] Point the command line tools at that Xcode (`xcode-select`). If needed, accept the license with `sudo xcodebuild -license`.
- [ ] Install CocoaPods with Homebrew (`brew install cocoapods`), not system Ruby. Confirm `pod --version` is 1.15 or newer.
- [ ] Install the same Flutter stable channel this repo uses. `flutter doctor` must show a green Xcode check. Android Studio is optional on this Mac.

### C2. Project setup

- [ ] Clone the repo.
- [ ] Place the six real Firebase files over the placeholders:
  - `android/app/src/<flavor>/google-services.json`
  - `ios/config/<flavor>/GoogleService-Info.plist`
- [ ] Confirm production Android package name is `com.lgbtfinder` and the production plist bundle id is `com.lgbtfinder`.
- [ ] From `lgbtindernew/ios`, run `pod install`. It must create `Pods/` and `Runner.xcworkspace`.
- [ ] If pods fail on a deployment target, both the Podfile and the Xcode configs must say 15.0.
- [ ] If pods fail on non-modular headers or duplicate symbols, the Podfile must still be using static frameworks.

### C3. Xcode

- [ ] Open `ios/Runner.xcworkspace`. Do not open `Runner.xcodeproj`.
- [ ] Duplicate build configurations until all nine exist: `Debug-development`, `Profile-development`, `Release-development`, and the same trio for staging and production.
- [ ] Copy Debug settings when duplicating Debug flavors, and Release settings when duplicating Release and Profile flavors. Debug is the one that includes the simulator.
- [ ] Set each configuration’s base configuration to the matching xcconfig committed in Part B.
- [ ] Confirm the three shared schemes. Xcode may rewrite scheme identifiers on first open. They must stay in `xcshareddata`, not in gitignored `xcuserdata`.
- [ ] Add a Run Script build phase on the Runner target, before Compile Sources, that runs `ios/scripts/copy-google-service-info.sh`.
- [ ] Select the Apple team on every Runner configuration. Start with automatic signing.
- [ ] Confirm each configuration’s bundle id matches the table at the top of this file.

If signing says the profile is missing: the App ID is not registered, or Push Notifications was enabled after the profile was created. Toggle automatic signing off and on, or delete the stale profile in the portal and let Xcode create it again.

### C4. Verify

Simulator first. It proves compile, flavor, Firebase init, and UI. It does not prove push, VoIP, or purchases.

- [ ] `flutter run --flavor development --target lib/main_development.dart` on the iOS simulator.

Then a physical device:

- [ ] Run the development flavor on a device.
- [ ] Accept camera, microphone, photos, location, and notifications.
- [ ] Sign in with Google.
- [ ] Place a call against the development backend.
- [ ] Send a test FCM message to the development iOS app.
- [ ] Receive an incoming call while the app is killed (VoIP push).
- [ ] Run staging and production far enough to confirm bundle id, home-screen name, icon, and API origin. Production and staging must look different before any upload.

### C5. TestFlight

- [ ] `flutter build ipa --flavor staging --target lib/main_staging.dart`
- [ ] Upload with Xcode Organizer or Transporter to the staging App Store Connect app.
- [ ] Install from TestFlight and repeat the device checks that QA cares about.
- [ ] Archive production only from `--flavor production --target lib/main_production.dart` when a store build is intended.

### C6. Certificates for a second Mac or for CI

Day-to-day device runs stay on automatic signing.

- [ ] For CI, export the Apple Distribution certificate as a `.p12` and download the distribution provisioning profile for each flavor.
- [ ] Store the `.p12`, its password, and the profiles as CI secrets. Do not commit them.

---

## Part D — CI, when you set it up

Not required for the first Mac build.

- [ ] Android jobs run on Linux. Matrix flavors `development`, `staging`, and `production`. Command is `flutter build appbundle --flavor <flavor> --target lib/main_<flavor>.dart`.
- [ ] The job writes `key.properties` from secrets at the start and deletes it at the end. It writes that flavor’s `google-services.json` into the flavor source set. Logs must not print those files.
- [ ] iOS jobs run on macOS. Same flavor matrix, command `flutter build ipa`. The job installs the distribution certificate and profile into a temporary keychain and uses manual signing for the archive.
- [ ] The production workflow is protected and accepts only `--flavor production` and `lib/main_production.dart`.
- [ ] Development output is a direct install. Staging output goes to the internal Play track and TestFlight. Production output goes to the public Play track and App Store Connect.

---

## Failure points that cost a day

- CocoaPods installed from system Ruby against a new Xcode.
- A configuration named `Debug-dev` instead of `Debug-development`.
- Opening `Runner.xcodeproj` instead of `Runner.xcworkspace`.
- Enabling Push Notifications on the App ID after the provisioning profile was issued.
- Testing push, killed-state calls, or billing on the simulator and treating that as a client bug.
- Leaving `google-services.json` at `android/app/google-services.json` so every flavor loads production Firebase.
- Running `flutter create` and losing the gallery and screenshot code in `AppDelegate.swift`.

---

# فارسی — کارهایی که باید انجام دهید

این فهرست همان کارهاست. آمادگی iOS الان حدود ۳۲ از ۱۰۰ است. پوشهٔ `ios/` هست. `Podfile`، پیکربندی iOS فایربیس، entitlements، و flavor نیستند.

اول بخش الف را در مرورگر انجام دهید. ثبت‌نام اپل یک تا دو روز کاری طول می‌کشد. کار ویندوز در بخش ب می‌تواند بعد از قبول شناسه‌های زیر موازی شروع شود. کار مک در بخش پ فقط بعد از کامیت بخش ب و آماده بودن شش فایل فایربیس شروع می‌شود.

## تصمیم‌های ثابت

| Flavor | شناسه اندروید | Bundle آی‌اواس | نام لانچر |
| --- | --- | --- | --- |
| production | `com.lgbtfinder` | `com.lgbtfinder` | LGBTFinder |
| staging | `com.lgbtfinder.staging` | `com.lgbtfinder.staging` | LGBTFinder Staging |
| development | `com.lgbtfinder.dev` | `com.lgbtfinder.dev` | LGBTFinder Dev |

- تولید روی `com.lgbtfinder` می‌ماند. آن را به `com.lgbtfinder.app` عوض نکنید. آن شناسه اپ دیگری است و کلاینت اندروید فایربیس در پروژهٔ `lgbtfinder-fa8e5` را از دست می‌دهد.
- پروژهٔ فایربیس `lgbtfinder-fa8e5` تولید بماند. برای توسعه و استیجینگ پروژهٔ جدا بسازید.
- حداقل iOS این اپ ۱۵.۰ است.
- نام flavorها دقیقاً `development` و `staging` و `production` است.
- Xcode به نه پیکربندی نیاز دارد: Debug و Profile و Release برای هر flavor. مثل `Debug-development` و `Release-production`.
- دستور فلاتر همیشه هر دو پرچم را دارد. مثال: `flutter run --flavor development --target lib/main_development.dart`.
- سیستم طراحی داخل اپ عوض نمی‌شود.
- `flutter create` را دوباره اجرا نکنید. `AppDelegate.swift` و `Info.plist` و `project.pbxproj` بازنویسی می‌شوند.
- فایل واقعی فایربیس، keystore، `key.properties`، `dart_defines.json`، `.p8`، `.p12`، و پروفایل وارد گیت نمی‌شوند. فقط placeholder کامیت می‌شود.

این مقدارها را خودتان باید بدهید. در مخزن نیستند:

- مبدأ API توسعه
- مبدأ API استیجینگ
- کدام کلید Pusher مال تولید است. مقدار `lib/core/config/pusher_config.dart` با `dart_defines.json` یکی نیست.

---

## بخش الف — در مرورگر، روی ویندوز

### الف۱. برنامهٔ توسعه‌دهندهٔ اپل

- [ ] در [developer.apple.com](https://developer.apple.com) ببینید تیم عضویت فعال Apple Developer Program دارد یا نه (سالی ۹۹ دلار).
- [ ] اگر ندارد، به عنوان فرد ثبت‌نام کنید (Apple ID، نام قانونی، آدرس، کارت) یا به عنوان سازمان (شمارهٔ D-U-N-S و کسی که حق امضای شرکت را دارد).
- [ ] منتظر تأیید هویت بمانید. معمولاً یک تا دو روز کاری. تا عضویت فعال نشود TestFlight و اپ‌استور بسته است.

Apple ID رایگان بعداً شبیه‌ساز را اجرا می‌کند. این سه App ID و گواهی توزیع را نمی‌سازد.

### الف۲. App ID

سه App ID صریح ثبت کنید:

- [ ] `com.lgbtfinder`
- [ ] `com.lgbtfinder.staging`
- [ ] `com.lgbtfinder.dev`

روی هر کدام روشن کنید:

- [ ] Push Notifications
- [ ] Background Modes با Voice over IP و Remote notifications

این‌ها را تا وقتی محصول واقعاً استفاده نکرده خاموش بگذارید:

- Sign in with Apple (بسته در `pubspec.yaml` هست و در `lib/` هنوز صدا زده نشده)
- Associated Domains
- مکان همیشگی، مخاطبان دستگاه، و Face ID

### الف۳. کلید APNs

- [ ] یک Key با قابلیت Apple Push Notifications service بسازید.
- [ ] فایل `.p8` را همان لحظه دانلود کنید. اپل دوباره نشانش نمی‌دهد.
- [ ] `.p8` و Key ID و Team ID را در مدیر رمز تیم بگذارید.
- [ ] `.p8` را کامیت نکنید.

یک کلید برای هر سه اپ کافی است، از جمله پوش VoIP.

### الف۴. فایربیس

- [ ] پروژهٔ `lgbtfinder-fa8e5` تولید بماند.
- [ ] یک پروژهٔ فایربیس برای توسعه بسازید.
- [ ] یک پروژهٔ فایربیس برای استیجینگ بسازید.
- [ ] در تولید، اپ اندروید `com.lgbtfinder` را نگه دارید. اپ iOS با bundle id برابر `com.lgbtfinder` ثبت کنید.
- [ ] در استیجینگ اندروید `com.lgbtfinder.staging` و iOS همان bundle را ثبت کنید.
- [ ] در توسعه اندروید `com.lgbtfinder.dev` و iOS همان bundle را ثبت کنید.
- [ ] سه فایل `google-services.json` و سه فایل `GoogleService-Info.plist` را دانلود کنید و تا آماده شدن پوشه‌های بخش ب در مدیر رمز نگه دارید.

SHA-1 را اضافه کنید تا ورود گوگل روی هر flavor کار کند:

- [ ] توسعه: SHA-1 کلید دیباگ (و کلید دیباگ CI اگر CI بیلد توسعه نصب می‌کند)
- [ ] استیجینگ: SHA-1 کلید آپلود استیجینگ
- [ ] تولید: SHA-1 کلید آپلود فعلی تولید

بعد:

- [ ] همان `.p8` را با Key ID و Team ID در Cloud Messaging اپ iOS هر سه پروژه آپلود کنید.

### الف۵. مقدارهای محیط

- [ ] مبدأ API توسعه را بنویسید.
- [ ] مبدأ API استیجینگ را بنویسید.
- [ ] مبدأ تولید همان `https://api.lgbtfinder.com` می‌ماند.
- [ ] کلید Pusher داخل `pusher_config.dart` را با کلید `dart_defines.json` مقایسه کنید. با بک‌اند معلوم کنید تولید با کدام broadcast می‌کند. کلید دیگر مال توسعه یا استیجینگ است، یا کنار گذاشته می‌شود.
- [ ] App ID آگورا روی endpoint توکن می‌ماند. flavor فقط باید به APIای وصل شود که آن توکن را می‌دهد.

### الف۶. App Store Connect و Play

- [ ] در App Store Connect اپ تولید را برای `com.lgbtfinder` بسازید.
- [ ] گروه اشتراک، محصولات اشتراک، و محصولات مصرفی را بسازید. شناسهٔ iOS لازم نیست با Play یکی باشد. هر محصول قیمت، ترجمه، و اسکرین‌شات بازبینی می‌خواهد. اشتراک مدت می‌خواهد.
- [ ] اگر QA روی TestFlight یا خرید با bundle استیجینگ کار می‌کند، اپ `com.lgbtfinder.staging` را هم بسازید و محصولات را آنجا تکرار کنید. محصول StoreKit به یک bundle id بسته است.
- [ ] در Play Console وقتی استیجینگ ترک داخلی می‌خواهد اپ `com.lgbtfinder.staging` را بسازید. تولید همان لیست فعلی `com.lgbtfinder` است. استیجینگ keystore آپلود جدا دارد.
- [ ] تاپیک Pub/Sub اعلان لحظه‌ای Play را فقط بعد از بالا بودن و دردسترس بودن webhook بک‌اند بسازید و در Play وصل کنید.

خرید را روی آیفون فیزیکی با Apple ID سندباکس تست کنید. شبیه‌ساز تست خرید نیست.

### الف۷. مسیر تماس در بک‌اند

وقتی کار سرور شروع شد، `.p8` را به بک‌اند بدهید. سرور باید بر اساس پلتفرم شاخه شود:

- [ ] کالِی اندروید: همان پیام دادهٔ FCM فعلی.
- [ ] کالِی iOS: پوش VoIP از APNs. نوع پوش `voip`. تاپیک `<bundle-id>.voip`.
  - توسعه: `com.lgbtfinder.dev.voip`
  - استیجینگ: `com.lgbtfinder.staging.voip`
  - تولید: `com.lgbtfinder.voip`
- [ ] اپ باید توکن VoIP پوش‌کیت را جدا از توکن FCM روی API ثبت دستگاه بفرستد.
- [ ] payload باید شناسهٔ تماس و فیلدهای تماس‌گیرنده را داشته باشد.
- [ ] برای همان زنگ، هشدار معمولی هم نفرستید.

اپ iOS باید با رسیدن پوش VoIP فوراً تماس را به CallKit گزارش کند. اپل اپی را که پوش VoIP بگیرد و تماس گزارش نکند می‌بندد.

---

## بخش ب — کار ویندوز، به ترتیب

این کارها در `lgbtindernew/` است، قبل از باز کردن پروژه روی مک.

### ب۱. لایهٔ دارت

- [ ] یک شیء پیکربندی flavor بسازید: نام flavor، مبدأ API، نام نمایشی، کف لاگ، کلید Pusher، کلاستر Pusher، App ID اختیاری Agora، و شناسهٔ وب گوگل.
- [ ] `lib/main_development.dart` و `lib/main_staging.dart` و `lib/main_production.dart` را اضافه کنید. هر کدام پیکربندی خودش را می‌گذارد و بعد بوت مشترک `lib/main.dart` را صدا می‌زند.
- [ ] هر نقطهٔ ورود `appFlavor` را با نام خودش مقایسه می‌کند تا نقطهٔ ورود توسعه داخل شناسهٔ تولید بالا نیاید.
- [ ] فقط مبدأ API را از `lib/core/constants/api_endpoints.dart` بیرون ببرید. همهٔ مسیرها بمانند. `baseUrl` مبدأ فعال را بخواند.
- [ ] `PusherConfig` و `GoogleAuthConfig` و `dio` را به پیکربندی فعال وصل کنید.
- [ ] `AppLogger` را به پیکربندی وصل کنید: توسعه verbose، استیجینگ از warning به بالا، تولید error و fatal. `kDebugMode` فقط برای خطای خود فلاتر بماند.
- [ ] `dart_defines.json` و کلید ثابت Pusher دیگر منبع حقیقت نباشند. `dart_defines.json` را به `.gitignore` اضافه کنید.
- [ ] `.vscode/launch.json` را طوری به‌روز کنید که اجرای یک‌کلیکی فعلی `--flavor development --target lib/main_development.dart` باشد.

`flutter_dotenv` از قبل بی‌استفاده است. برای flavor بستهٔ زمان‌اجرای جدید اضافه نکنید.

### ب۲. flavor اندروید

فایل `android/app/build.gradle.kts` را ویرایش کنید. فایل Groovy جدید نسازید.

- [ ] یک بعد flavor به نام `environment` اضافه کنید.
- [ ] flavor توسعه با پسوند `.dev` و نام `LGBTFinder Dev`، استیجینگ با پسوند `.staging` و نام `LGBTFinder Staging`، و تولید بدون پسوند و نام `LGBTFinder`.
- [ ] برچسب مانیفست را از متن ثابت `LGBTFinder` به `@string/app_name` عوض کنید و رشتهٔ پیش‌فرض را در `src/main` بگذارید.
- [ ] min SDK، target SDK، multidex، desugaring، حذف JNI آگورا، و minify ریلیز را دست نزنید.
- [ ] امضای release روی `android/key.properties` بماند. دیباگ توسعه از keystore دیباگ استفاده کند. توزیع استیجینگ keystore آپلود جدا داشته باشد. تولید همان keystore فعلی را نگه دارد.
- [ ] اگر CI لازم داشت، گریدل همان چهار فیلد keystore را وقتی `key.properties` نیست از متغیر محیط بخواند. رمز را داخل فایل گریدل ننویسید.

Source set:

- [ ] `android/app/src/development` و `staging` و `production` را بسازید.
- [ ] `google-services.json` هر flavor را در پوشهٔ خودش بگذارید.
- [ ] فایل فعلی `android/app/google-services.json` را به `src/production` منتقل کنید. در ریشهٔ ماژول کپی نگذارید. کپی ریشه فایربیس تولید را به بیلد توسعه نشت می‌دهد.
- [ ] برای توسعه و استیجینگ آیکون نشان‌دار بگذارید. تولید آیکون تمیز را نگه دارد.
- [ ] پوشه‌های باقی‌ماندهٔ `com.example` و `com.example.lgbtindernew` زیر `src/main/kotlin` را بررسی کنید که استفاده نمی‌شوند و به flavor کپی نشوند.
- [ ] نمونهٔ `google-services.json.example` را کامیت کنید. json واقعی flavor را ignore کنید. `key.properties` و `*.jks` و `*.keystore` از قبل ignore هستند.

### ب۳. فایل‌های متنی iOS

- [ ] هدف استقرار را از ۱۳.۰ به ۱۵.۰ برسانید، در تنظیمات پروژهٔ Xcode و در `ios/Flutter/AppFrameworkInfo.plist`.
- [ ] متن مجوزها را در `ios/Runner/Info.plist` بازنویسی کنید تا با کار واقعی LGBTFinder بخواند:
  - دوربین: تماس تصویری، عکس پروفایل، و تأیید هویت
  - میکروفون: تماس صوتی و تصویری، و پیام صوتی
  - خواندن گالری: انتخاب عکس برای چت و پروفایل
  - افزودن به گالری: ذخیرهٔ عکس دانلودشده از چت
  - مکان هنگام استفاده: افراد نزدیک و قابلیت ایمنی که کاربر روشن می‌کند
  - بلوتوث: صدای هدست در تماس
- [ ] اگر اپ فقط HTTPS استاندارد دارد، `ITSAppUsesNonExemptEncryption` را false بگذارید.
- [ ] حالت‌های پس‌زمینهٔ `voip` و `audio` و `remote-notification` را نگه دارید.
- [ ] رشتهٔ مکان همیشگی، مخاطبان، و Face ID را اضافه نکنید.
- [ ] اگر API توسعه HTTP ساده روی شبکهٔ محلی است، اجازهٔ شبکهٔ محلی فقط روی پیکربندی توسعه باشد. تولید و استیجینگ فقط HTTPS بمانند.
- [ ] طرح URL ورود گوگل را برای هر flavor جدا در نظر بگیرید. طرح برابر شناسهٔ معکوس کلاینت داخل `GoogleService-Info.plist` همان flavor است، به‌علاوه `GIDClientID`. شناسهٔ معکوس تولید را بین flavorها مشترک نکنید.

Podfile و چیدمان فایربیس:

- [ ] `ios/Podfile` را بنویسید. پلتفرم iOS ۱۵.۰. Debug به `:debug`. Profile و Release و همهٔ انواع flavor به `:release`. لینک ایستا: `use_frameworks! :linkage => :static`. نصب pod با helper فلاتر. در `post_install` هدف استقرار هر pod را ۱۵.۰ کنید و ماکروهای permission_handler را روی خود podها بگذارید: دوربین، میکروفون، عکس، مکان هنگام استفاده، اعلان، و بلوتوث.
- [ ] برای هر نه پیکربندی یک xcconfig در `ios/Flutter` بگذارید. هر کدام xcconfig فعلی Debug یا Release را include کند و بعد `FLUTTER_TARGET` و `PRODUCT_BUNDLE_IDENTIFIER` و `APP_DISPLAY_NAME` و `APP_FLAVOR` را ست کند. Profile فایل Release را include می‌کند.
- [ ] `ios/config/development` و `staging` و `production` را با plist جای‌نگهدار بسازید. plist واقعی را ignore کنید.
- [ ] `ios/scripts/copy-google-service-info.sh` را اضافه کنید. `APP_FLAVOR` را بخواند، `ios/config/<flavor>/GoogleService-Info.plist` را به مسیر مورد انتظار فایربیس کپی کند، و اگر flavor یا فایل نباشد بیلد را بشکند.
- [ ] schemeهای اشتراکی `development.xcscheme` و `staging.xcscheme` و `production.xcscheme` را زیر `ios/Runner.xcodeproj/xcshareddata/xcschemes/` بگذارید. نام scheme همان نام flavor است. Run از `Debug-<flavor>` و Archive از `Release-<flavor>`. `Runner.xcscheme` بماند.
- [ ] تکرار واقعی نه ردیف داخل `project.pbxproj` را برای Xcode روی مک بگذارید. ویرایش دستی آن فایل پروژه را راحت خراب می‌کند. xcconfigهایی که آن ردیف‌ها باید به آن‌ها اشاره کنند اینجا کامیت می‌شوند.
- [ ] مجموعهٔ آیکون نشان‌دار iOS برای توسعه و استیجینگ اضافه کنید. `ASSETCATALOG_COMPILER_APPICON_NAME` را از xcconfig همان flavor به آن‌ها اشاره دهید. تولید `AppIcon` را نگه دارد.

### ب۴. پوشش دستور

- [ ] اسکریپت PowerShell برای ویندوز: اجرای هر flavor روی اندروید، APK ریلیز هر flavor، و app bundle هر flavor.
- [ ] Makefile برای مک با همان دستورها، به‌علاوه اجرای iOS و `flutter build ipa` برای هر flavor.
- [ ] هر پوشش هم `--flavor` بدهد هم `--target`.

### ب۵. اندروید را قبل از تحویل به مک ثابت کنید

- [ ] توسعه و تولید را روی یک دستگاه نصب کنید. کنار هم باشند، با نام و آیکون متفاوت.
- [ ] توسعه به مبدأ توسعه وصل شود. تولید همچنان به `https://api.lgbtfinder.com` با شناسهٔ `com.lgbtfinder` وصل شود.
- [ ] `flutter run` بدون flavor شکست بخورد.
- [ ] `flutter run --flavor production --target lib/main_development.dart` روی مقایسهٔ flavor شکست بخورد.

---

## بخش پ — کار مک، به ترتیب

فقط بعد از کامیت بخش ب و قرار داشتن شش فایل واقعی فایربیس در مدیر رمز شروع کنید.

### پ۱. آماده‌سازی دستگاه

- [ ] Xcode را از اپ‌استور مک نصب کنید. یک بار باز کنید و مجوز را بپذیرید.
- [ ] ابزار خط فرمان را به همان Xcode اشاره دهید. اگر لازم شد مجوز را با `sudo xcodebuild -license` بپذیرید.
- [ ] CocoaPods را با Homebrew نصب کنید (`brew install cocoapods`)، نه با Ruby سیستم. `pod --version` باید ۱.۱۵ یا جدیدتر باشد.
- [ ] همان کانال stable فلاتر این مخزن را نصب کنید. `flutter doctor` باید Xcode را سبز نشان دهد. اندروید استودیو روی این مک اختیاری است.

### پ۲. راه‌اندازی پروژه

- [ ] مخزن را clone کنید.
- [ ] شش فایل واقعی فایربیس را جای placeholder بگذارید:
  - `android/app/src/<flavor>/google-services.json`
  - `ios/config/<flavor>/GoogleService-Info.plist`
- [ ] نام پکیج اندروید تولید باید `com.lgbtfinder` باشد و bundle آی‌اواس تولید هم `com.lgbtfinder`.
- [ ] داخل `lgbtindernew/ios` دستور `pod install` را بزنید. باید `Pods/` و `Runner.xcworkspace` ساخته شود.
- [ ] اگر pod به خاطر هدف استقرار شکست، هم Podfile و هم پیکربندی Xcode باید ۱۵.۰ باشند.
- [ ] اگر pod به خاطر هدر غیرماژولار یا نماد تکراری شکست، Podfile باید هنوز روی فریم‌ورک ایستا باشد.

### پ۳. Xcode

- [ ] `ios/Runner.xcworkspace` را باز کنید. `Runner.xcodeproj` را باز نکنید.
- [ ] پیکربندی‌ها را تکرار کنید تا هر نه تا وجود داشته باشد: `Debug-development` و `Profile-development` و `Release-development`، و همین سه‌تایی برای staging و production.
- [ ] هنگام تکرار flavorهای Debug از تنظیمات Debug کپی کنید، و برای Release و Profile از تنظیمات Release. Debug همان پیکربندی‌ای است که شبیه‌ساز را دارد.
- [ ] پیکربندی پایهٔ هر کدام را روی xcconfig کامیت‌شده در بخش ب بگذارید.
- [ ] سه scheme اشتراکی را تأیید کنید. Xcode ممکن است در اولین باز شدن شناسه‌ها را بازنویسی کند. scheme باید در `xcshareddata` بماند، نه در `xcuserdata` که ignore است.
- [ ] روی هدف Runner، قبل از Compile Sources، یک فاز Run Script اضافه کنید که `ios/scripts/copy-google-service-info.sh` را اجرا کند.
- [ ] تیم اپل را روی هر پیکربندی Runner انتخاب کنید. با امضای خودکار شروع کنید.
- [ ] bundle id هر پیکربندی را با جدول بالای این فایل تطبیق دهید.

اگر امضا بگوید پروفایل نیست: App ID ثبت نشده، یا Push Notifications بعد از ساخت پروفایل روشن شده. امضای خودکار را خاموش و روشن کنید، یا پروفایل کهنه را در پورتال حذف کنید تا Xcode دوباره بسازد.

### پ۴. تأیید

اول شبیه‌ساز. کامپایل، flavor، بالا آمدن فایربیس، و UI را ثابت می‌کند. پوش و VoIP و خرید را ثابت نمی‌کند.

- [ ] روی شبیه‌ساز iOS: `flutter run --flavor development --target lib/main_development.dart`

بعد دستگاه فیزیکی:

- [ ] flavor توسعه را روی دستگاه اجرا کنید.
- [ ] دوربین، میکروفون، عکس، مکان، و اعلان را بپذیرید.
- [ ] با گوگل وارد شوید.
- [ ] یک تماس با بک‌اند توسعه بگیرید.
- [ ] یک پیام آزمایشی FCM به اپ iOS توسعه بفرستید.
- [ ] یک تماس ورودی بگیرید در حالی که اپ کشته شده (پوش VoIP).
- [ ] استیجینگ و تولید را تا حد تأیید bundle id، نام صفحهٔ خانه، آیکون، و مبدأ API اجرا کنید. تولید و استیجینگ باید قبل از هر آپلود متفاوت به نظر برسند.

### پ۵. TestFlight

- [ ] `flutter build ipa --flavor staging --target lib/main_staging.dart`
- [ ] با Organizer در Xcode یا با Transporter به اپ استیجینگ در App Store Connect بفرستید.
- [ ] از TestFlight نصب کنید و بررسی‌هایی را که برای QA مهم است تکرار کنید.
- [ ] تولید را فقط با `--flavor production --target lib/main_production.dart` آرشیو کنید، و فقط وقتی بیلد فروشگاه عمدی است.

### پ۶. گواهی برای مک دوم یا CI

اجرای روزانهٔ دستگاه روی امضای خودکار می‌ماند.

- [ ] برای CI گواهی Apple Distribution را به صورت `.p12` خروجی بگیرید و پروفایل توزیع هر flavor را دانلود کنید.
- [ ] `.p12` و رمزش و پروفایل‌ها را به صورت secret در CI بگذارید. کامیت نکنید.

---

## بخش ت — CI، وقتی خواستید راهش بیندازید

برای اولین بیلد مک لازم نیست.

- [ ] جاب اندروید روی لینوکس. ماتریس flavorهای `development` و `staging` و `production`. دستور: `flutter build appbundle --flavor <flavor> --target lib/main_<flavor>.dart`.
- [ ] job در شروع `key.properties` را از secret می‌نویسد و در پایان پاک می‌کند. `google-services.json` همان flavor را در source set می‌گذارد. لاگ نباید این فایل‌ها را چاپ کند.
- [ ] جاب iOS روی macOS. همان ماتریس. دستور `flutter build ipa`. job گواهی و پروفایل توزیع را در یک keychain موقت می‌گذارد و برای آرشیو امضای دستی استفاده می‌کند.
- [ ] workflow تولید محافظت‌شده است و فقط `--flavor production` و `lib/main_production.dart` را می‌پذیرد.
- [ ] خروجی توسعه نصب مستقیم است. خروجی استیجینگ به ترک داخلی Play و TestFlight می‌رود. خروجی تولید به ترک عمومی Play و App Store Connect می‌رود.

---

## شکست‌هایی که یک روز می‌گیرند

- نصب CocoaPods از Ruby سیستم در برابر Xcode جدید.
- پیکربندی با نام `Debug-dev` به‌جای `Debug-development`.
- باز کردن `Runner.xcodeproj` به‌جای `Runner.xcworkspace`.
- روشن کردن Push Notifications روی App ID بعد از صدور پروفایل.
- تست پوش، تماس در حالت کشته، یا خرید روی شبیه‌ساز و فرض اینکه اشکال از کلاینت است.
- ماندن `google-services.json` در `android/app/google-services.json` تا هر flavor فایربیس تولید را بار کند.
- اجرای `flutter create` و از دست رفتن کد گالری و اسکرین‌شات در `AppDelegate.swift`.
