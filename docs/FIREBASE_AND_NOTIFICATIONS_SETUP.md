# Firebase Setup & Push Notifications (FCM vs OneSignal)

Full step-by-step guide: what to do in Firebase, and how to choose between **Firebase Cloud Messaging (FCM)** and **OneSignal** for push notifications in LGBTinder.

---

## Part 1: Notifications — Firebase (FCM) or OneSignal?

### Current app behavior

- The app is set up to use **Firebase Cloud Messaging (FCM)** for push notifications.
- The backend has:
  - **`POST /notifications/register-device`** — expects a `device_token` (FCM token or OneSignal player ID) and `platform`.
  - **`/user/onesignal-player`** — suggests the backend can also store a OneSignal player ID.

So you can use **either**:

| Option | Use when | What you need |
|--------|----------|----------------|
| **Firebase (FCM)** | You want one provider, free, and already integrated in the app | Firebase project + Android app + Cloud Messaging + `google-services.json` |
| **OneSignal** | You want OneSignal’s dashboard, segments, A/B tests, or multi-channel | OneSignal app + (optionally) Firebase only for Android FCM under the hood |

**Recommendation:** Use **Firebase (FCM)** for this project unless you specifically need OneSignal features. The app already uses FCM; you only need to complete Firebase setup below. If you choose OneSignal later, you can add the OneSignal SDK and send the OneSignal player ID to your backend instead of (or in addition to) the FCM token.

The rest of this doc: **Part 2** = full Firebase steps; **Part 3** = optional OneSignal path.

---

## Part 2: Full step-by-step — What to do in Firebase

### Step 1: Create or open a Firebase project

1. Go to [Firebase Console](https://console.firebase.google.com).
2. Click **“Add project”** (or select an existing project).
3. **Project name:** e.g. `LGBTinder` or `lgbtinder-production`.
4. (Optional) Enable Google Analytics; you can skip or enable.
5. Click **“Create project”** and wait until it’s ready.

---

### Step 2: Add an Android app to the Firebase project

1. On the project **Overview** (home), click the **Android** icon (“Add app” → Android).
2. **Android package name:** enter exactly:
   ```text
   com.lgbtfinder
   ```
   This must match `applicationId` in `android/app/build.gradle.kts`.
3. **App nickname:** optional (e.g. “LGBTinder Android”).
4. **Debug signing certificate SHA-1:** optional for now; you can add it later for Auth (e.g. Google Sign-In).
5. Click **“Register app”**.

---

### Step 3: Download and add `google-services.json`

1. Firebase will show a **“Download google-services.json”** button.
2. Click **Download google-services.json**.
3. Place the file in your Flutter project:
   ```text
   lgbtindernew/android/app/google-services.json
   ```
   So the path is: `android/app/` (same folder as `app/build.gradle.kts`).
4. In the Firebase console, click **“Next”** (you can skip the “Add Firebase SDK” step; Flutter uses its own plugins).
5. Click **“Next”** again, then **“Continue to console”**.

**Check:**  
- File exists at `android/app/google-services.json`.  
- Inside the file, under `client` → `client_info` → `android_client_info`, `package_name` is `com.lgbtfinder`.

---

### Step 4: Enable Cloud Messaging (FCM) for push notifications

1. In Firebase Console, open your project.
2. In the left sidebar, go to **“Build”** → **“Cloud Messaging”** (or search “Cloud Messaging”).
3. If you see **“Cloud Messaging API”** or **“Enable”**, enable it.  
   - For newer projects, FCM is often enabled by default.  
   - If there is a link to **Google Cloud Console** to enable an API, open it and enable **“Firebase Cloud Messaging API”** (or “Cloud Messaging API”) for the same project.
4. No need to create a “server key” for the Flutter app; the app uses the FCM token (device token) that Firebase generates. Your backend will use that token to send messages (via Firebase Admin SDK or HTTP v1 API).

**Summary:** Cloud Messaging is enabled and the Android app is registered; the Flutter app will get an FCM token after `Firebase.initializeApp()` and `FirebaseMessaging.instance.getToken()`.

---

### Step 5: (Optional) FlutterFire CLI — generate `firebase_options.dart`

If you want Flutter to know your Firebase config in code (e.g. for multiple environments or web):

1. Install FlutterFire CLI (one time):
   ```bash
   flutter pub global activate flutterfire_cli
   ```
2. From the **Flutter project root** (e.g. `lgbtindernew/`):
   ```bash
   flutterfire configure
   ```
3. Log in to Firebase if asked; select the project and the Android (and iOS if needed) app.
4. This creates/updates `lib/firebase_options.dart` with `DefaultFirebaseOptions`. Your current `Firebase.initializeApp()` will still work; for web you can pass options from `DefaultFirebaseOptions.currentPlatform` if needed.

You can skip this step if you only need Android and use the default `Firebase.initializeApp()` (which reads from `google-services.json` via the Google Services plugin).

---

### Step 6: Confirm Android build configuration

Already done in this project; only verify:

1. **Google Services plugin**
   - `android/settings.gradle.kts`: plugin declared (`com.google.gms.google-services`).
   - `android/app/build.gradle.kts`: plugin applied (`id("com.google.gms.google-services")`).

2. **Package name**
   - `android/app/build.gradle.kts`: `applicationId = "com.lgbtfinder"`.
   - Same value must be in `google-services.json` as the Android app’s `package_name`.

3. **Clean build**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```
   Or build APK: `flutter build apk`.

After this, “Failed to load FirebaseOptions from resource” should be fixed as long as `google-services.json` is in place and the package name matches.

---

### Step 7: How the app uses FCM (for your reference)

- **Startup:** After the first frame, the app runs `Firebase.initializeApp()` then `PushNotificationService().initialize()`.
- **Token:** The service calls `FirebaseMessaging.instance.getToken()` and sends that token to your backend via `POST /notifications/register-device` with `device_token` and `platform`.
- **Backend:** Your server should store this `device_token` per user and use it with the Firebase Admin SDK (or FCM HTTP v1) to send push notifications to the device.

So for **notifications with Firebase**, you only need to complete Steps 1–4 (and 6); Step 5 is optional.

---

## Part 3: (Optional) Using OneSignal instead of or with FCM

If you decide to use **OneSignal** for sending/delivering notifications:

### Option A: OneSignal only (replace FCM in the app)

1. Create an app at [OneSignal](https://onesignal.com).
2. Add the OneSignal Flutter SDK to `pubspec.yaml` (e.g. `onesignal_flutter`).
3. In OneSignal dashboard, add an Android app; you’ll typically add a **Firebase Server Key** or use **FCM** as the delivery channel (OneSignal can use FCM for Android delivery). So you may still need the Firebase steps above to get FCM credentials for OneSignal.
4. In the Flutter app, initialize OneSignal, get the **OneSignal player ID** (or subscription ID), and send it to your backend (e.g. `POST /user/onesignal-player` or your `register-device` endpoint with `device_token` = OneSignal player ID).
5. Send notifications from the OneSignal dashboard or OneSignal API; your backend can also call OneSignal API to send to a user by player ID.

### Option B: Keep FCM and add OneSignal

- Keep the current FCM flow (token sent to `notifications/register-device`).
- Add OneSignal SDK and also send the OneSignal player ID to the backend.
- Backend can then choose to send via FCM (your server) or via OneSignal API. Usually you pick one delivery path per app to avoid duplicate notifications.

### Summary: FCM vs OneSignal

- **Use Firebase (FCM)** if you want the simplest path and already have the app wired for FCM. Complete Part 2 above; notifications are done with FCM.
- **Use OneSignal** if you want their UI, segments, or delivery features; you’ll add the OneSignal SDK and send the OneSignal player ID to your backend, and you may still need Firebase (Part 2) for Android FCM configuration used by OneSignal.

---

## Quick checklist — Firebase only (FCM notifications)

| # | Step | Done? |
|---|------|--------|
| 1 | Create/select Firebase project at console.firebase.google.com | ☐ |
| 2 | Add Android app with package name `com.lgbtfinder` | ☐ |
| 3 | Download `google-services.json` → put in `android/app/` | ☐ |
| 4 | Enable Cloud Messaging (FCM) in Firebase / Google Cloud | ☐ |
| 5 | (Optional) Run `flutterfire configure` | ☐ |
| 6 | Confirm Google Services plugin in app/build.gradle.kts | ☐ |
| 7 | `flutter clean` → `flutter pub get` → run or build | ☐ |

After step 7, the app should start without Firebase config errors and be able to register the FCM token with your backend for push notifications. For OneSignal, use Part 3 and your backend’s OneSignal/player-id support.
