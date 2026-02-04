# ANR (Application Not Responding) Debugging Guide — Startup & Background

Senior Flutter + Android checklist for fixing ANR during app startup and after `FlutterFirebaseMessagingBackgroundService` starts. Covers Firebase init, background message handler rules, and main-thread blocking.

---

## 0. Background message handler (Firebase FCM) — CRITICAL for “ANR after background service started”

The handler passed to `FirebaseMessaging.onBackgroundMessage` runs in a **separate Dart isolate**. It must **never** touch the main isolate or any API that requires it.

| Rule | Why |
|------|-----|
| **Top-level function only** | Required by Flutter; must be `@pragma('vm:entry-point')` and defined outside `main()`. |
| **No UI / widgets / BuildContext** | Background isolate has no Flutter context; any use causes crashes or ANR. |
| **No navigation** | Navigation runs on main isolate. |
| **No SharedPreferences sync** | Prefer no SharedPreferences in handler; if you must, use only async and keep work minimal. |
| **No heavy JSON parsing** | Large or complex parsing can block the background isolate and delay main-thread work if the platform bridges back. |
| **No Firebase APIs that require main isolate** | Most Firebase calls in the handler are isolate-safe; avoid anything that touches plugins that assume main thread. |

**Current project:** The handler in `lib/main.dart` is a single top-level function that only logs the message ID. No UI, no context, no navigation, no heavy work. If you add logic there, keep it to minimal, isolate-safe work (e.g. small JSON, enqueue for main isolate later).

**Registration:** `onBackgroundMessage` must be **registered before `runApp()`** (Firebase requirement). In this project, `Firebase.initializeApp()` and `FirebaseMessaging.onBackgroundMessage(...)` are called in `main()` before `runApp()`. Only `PushNotificationService().initialize()` is deferred to `addPostFrameCallback` so the first frame can paint quickly.

---

## 1. Firebase initialization failure (“Failed to load FirebaseOptions from resource”)

### 1.1 Verify `google-services.json` exists and package name

| What to do | How |
|------------|-----|
| **Check file exists** | Ensure `android/app/google-services.json` exists. If it does **not** exist, you must add it (see “If you need to do something” below). |
| **Package name** | Open `google-services.json` and find the `client` entry for Android. Its `client_info.android_client_info.package_name` must be **exactly** `com.lgbtfinder` (same as `applicationId` in `android/app/build.gradle.kts`). |

**If `google-services.json` is missing:**

1. Go to [Firebase Console](https://console.firebase.google.com) → your project → Project settings.
2. Under “Your apps”, add an Android app with package name `com.example.lgbtindernew` (or match your `applicationId`).
3. Download `google-services.json` and place it in **`android/app/`** (same folder as `build.gradle.kts`).
4. Run **`flutterfire configure`** (see below) to keep Flutter and Firebase in sync if you use FlutterFire.

### 1.2 Google Services plugin (already applied in this project)

- **Project:** `android/settings.gradle.kts` — plugin declared: `id("com.google.gms.google-services") version "4.4.2" apply false`
- **App:** `android/app/build.gradle.kts` — plugin applied: `id("com.google.gms.google-services")` (must be applied so that `google-services.json` is processed).

If you ever remove or change the plugin, ensure it is **applied at the app level** (in `app/build.gradle.kts`), typically last in the `plugins { }` block.

### 1.3 Firebase string resources (`values.xml`)

- The **Google Services plugin** generates Firebase-related string resources (e.g. `google_app_id`, `gcm_defaultSenderId`) when you build. They live in build output (e.g. under `build/`), not in `res/values/` by default.
- **Do not** manually add or override `google_app_id` / `gcm_defaultSenderId` in `android/app/src/main/res/values/values.xml` unless you have a specific reason; let the plugin generate them from `google-services.json`.
- **If you have a custom `values.xml`:** ensure it does **not** override or remove any Firebase-related keys that the plugin expects. If in doubt, keep Firebase resources only from the plugin.

**Check after a successful build:**

- Build the app once with `google-services.json` in place and the plugin applied.
- Inspect generated resources (e.g. under `build/app/intermediates/...` or via “Merge Source” in Android Studio) and confirm `google_app_id` and `gcm_defaultSenderId` are present for your package.

---

## 2. Run FlutterFire configure (when you use FlutterFire / need options in code)

If you use FlutterFire (e.g. `DefaultFirebaseOptions`) or want Flutter to know your Firebase options:

```bash
# From project root (e.g. lgbtindernew)
flutter pub global activate flutterfire_cli
flutterfire configure
```

- This creates/updates `lib/firebase_options.dart` and ensures the Firebase project and apps (Android/iOS) are in sync.
- **After this:** ensure `Firebase.initializeApp()` is still called (see Section 4). With deferred init (already done in this project), options are still read when `Firebase.initializeApp()` runs after the first frame.

---

## 3. Firebase and background handler at startup

- **Current setup:** `Firebase.initializeApp()` and `FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler)` are called in `main()` **before** `runApp()`. This is required so the background message handler is registered when the system spawns the FCM background isolate.
- **Deferred:** Only `PushNotificationService().initialize()` (token, permissions, local notifications) runs in **`_initializePushInBackground()`** via **`WidgetsBinding.instance.addPostFrameCallback`** so the first frame can paint without waiting for push setup.
- If Firebase init is slow (e.g. missing or wrong `google-services.json`), fix config and consider `flutterfire configure` so options load quickly. Do not move `onBackgroundMessage` registration to after `runApp()` — that can cause “no handler registered” when a background message arrives early.

---

## 4. Why the UI thread is blocked — profiling startup

### 4.1 What was done in this project

- **Before:** `main()` awaited `Firebase.initializeApp()` and `PushNotificationService().initialize()` before `runApp()`, so the first frame could not paint until Firebase (and push) finished. If Firebase failed to load options or was slow, the app could ANR.
- **After:** Only light work runs before `runApp()` (system UI style, SharedPreferences). Firebase and push init run in **`addPostFrameCallback`** after the first frame.

### 4.2 Confirm main thread is blocked (Profiler / logcat / tombstone)

- **Android Studio Profiler:** Run the app, attach the CPU profiler, reproduce the freeze. Confirm the main thread is blocked for **>5 seconds** (ANR threshold). Inspect the call stack to see what is running (e.g. Firebase, WebRTC, JSON parse, file I/O).
- **logcat:**  
  `adb logcat | grep -E "ANR|am_anr|Input dispatching timeout"`  
  Reproduce the ANR and capture the lines around the timeout.
- **Tombstone:** After an ANR, the system may write a tombstone or trace. Use `adb bugreport` or device “Developer options” → “Take bug report” and open the report to find the **exact call stack** of the main thread at the time of the ANR. That stack tells you which call to fix (e.g. Firebase init, plugin, or your Dart code).

### 4.3 If ANR still happens: isolate the cause

1. **Temporarily disable**  
   In `main()` and in the first screen’s `initState()`:
   - **Firebase Messaging background handling:** Comment out `FirebaseMessaging.onBackgroundMessage(...)` (and ensure no background handler runs).
   - **WebRTC / Agora:** Comment out any init at startup (e.g. in a provider or before first frame).
   - **Synchronous I/O** on the main isolate (file read/write, heavy JSON parsing) before or right after `runApp()`.

2. **Reintroduce one by one**  
   - Re-enable Firebase (init + `onBackgroundMessage` before `runApp()`).  
   - Then push (deferred `PushNotificationService().initialize()`).  
   - Then WebRTC/other features.  
   Use **`Future.microtask()`** or **`WidgetsBinding.instance.addPostFrameCallback`** for anything not needed for the very first frame. For very heavy work (large JSON, crypto), use **isolates**.

3. **Check for**  
   - **Infinite loops** in `main()`, `initState()`, or providers that run at startup.  
   - **Heavy JSON parsing** (or other CPU work) on the main isolate before the first frame.  
   - **Blocking awaits** on the main isolate (e.g. slow network or file call before `runApp()` or before first paint).  
   - **Background handler** doing main-isolate or UI work (see Section 0).

---

## 5. Clean and rebuild

After any Gradle or Firebase config change:

```bash
cd android
# Optional: delete build dirs to force full regenerate
rm -rf app/build build .gradle
cd ..
flutter clean
flutter pub get
flutter run
# Or build
flutter build apk
```

On Windows (PowerShell):

```powershell
cd android
Remove-Item -Recurse -Force app\build, build, .gradle -ErrorAction SilentlyContinue
cd ..
flutter clean
flutter pub get
flutter run
```

- **Gradle sync:** Open the Android project in Android Studio and use “Sync Project with Gradle Files”. Resolve any errors (e.g. missing `google-services.json` or wrong package name) before assuming the app will start without ANR.

---

## 6. First frame and lazy init (1–2 second target)

- **Target:** The app should reach **first frame render within 1–2 seconds** of launch. If it does not, the startup architecture is wrong: too much work is done before or during the first frame.
- **Non-critical services** (push token, WebRTC, analytics, etc.) must be initialized **lazily after startup** (e.g. in `addPostFrameCallback` or when the feature is first used). Only the minimum required for painting the first screen (e.g. bindings, theme, SharedPreferences if needed for route) should run before `runApp()` or in the first build.
- **Inspect `main()` and every `initState()` on the startup path** (splash → auth check → first screen): no long `await`s, no `while`-loops, no synchronous file or database access, no WebRTC init, no large model loading on the main isolate. Defer with `WidgetsBinding.instance.addPostFrameCallback` or move to an isolate.

## 7. Success criteria

- **Gradle sync** completes without errors.  
- **First frame** (splash) appears quickly; only Firebase init + handler registration and SharedPreferences block before `runApp()`; push init runs after first frame.  
- **No ANR** during startup or after the FCM background service starts; background handler does no UI/context/navigation/heavy work.  
- **Firebase:** With `google-services.json` in place and the plugin applied, “Failed to load FirebaseOptions from resource” should go away after a clean build.

---

## 8. “What to do” — quick checklist

Use this when you need to fix or verify something yourself.

| # | Task | Action |
|---|------|--------|
| 1 | Add or fix Firebase config | Ensure `android/app/google-services.json` exists; package name must match `applicationId` in `android/app/build.gradle.kts` (`com.lgbtfinder`). |
| 2 | Regenerate Flutter Firebase options | Run `flutterfire configure` from project root (after `flutter pub global activate flutterfire_cli` if needed). |
| 3 | Confirm Google Services plugin | In `android/app/build.gradle.kts`, ensure `id("com.google.gms.google-services")` is present in the `plugins { }` block (already done in this project). |
| 4 | Don’t block first frame | Firebase init + `onBackgroundMessage` registration must be before `runApp()`. Defer only push (and other heavy) init in `addPostFrameCallback` or `Future.microtask`. |
| 5 | Check `values.xml` | Do not remove or override Firebase-generated strings. Rely on the plugin output; only add custom values if needed. |
| 6 | Clean rebuild after config change | Run `flutter clean`, `flutter pub get`, then rebuild; if needed, delete `android/app/build`, `android/build`, `android/.gradle` and sync again. |
| 7 | If ANR persists | Comment out Firebase Messaging background handling, then WebRTC, then other startup code; reintroduce one by one. Use Profiler / `adb logcat \| grep ANR` / tombstone to get the exact main-thread call stack. |
| 8 | Background handler | Keep `firebaseMessagingBackgroundHandler` top-level, no UI/BuildContext/navigation/SharedPreferences sync/heavy JSON; register before `runApp()`. |
| 9 | First frame 1–2 s | Defer all non-critical init; ensure first frame renders within 1–2 seconds. |
| 10 | ANR after “FCM token” / “BackgroundService started” | Push init is delayed 2s after first frame and yields between steps (permission → local notif → token → handlers). If ANR still occurs, comment out `_initializePushInBackground()` body to confirm push is the cause. |

---

## 9. Files touched in this project (for reference)

- **`android/settings.gradle.kts`** — Added `com.google.gms.google-services` plugin (apply false).  
- **`android/app/build.gradle.kts`** — Applied `com.google.gms.google-services`.  
- **`lib/main.dart`** — Firebase.initializeApp() and FirebaseMessaging.onBackgroundMessage(handler) run **before** runApp() (required by Firebase). Push init runs **2 seconds after** first frame via `Future.delayed(2, _initializePushInBackground)` so the UI stays responsive when the FCM background service starts.
- **`lib/shared/services/push_notification_service.dart`** — Removed duplicate handler; `initialize()` yields between steps (`Future.delayed(Duration.zero)`) so the main thread is not blocked for long.

If you add a new `google-services.json` or change the package name, run through the checklist above and then clean and rebuild.
