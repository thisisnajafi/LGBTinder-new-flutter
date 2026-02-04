# Firebase google-services.json — package name

The app uses package name **`com.lgbtfinder`** (Android `applicationId` and namespace). Your `android/app/google-services.json` must have the same package name in `client.client_info.android_client_info.package_name`.

---

## Current status

- **App:** `applicationId` and `namespace` = **`com.lgbtfinder`** (in `android/app/build.gradle.kts`).
- **MainActivity:** `android/app/src/main/kotlin/com/lgbtfinder/MainActivity.kt` with `package com.lgbtfinder`.
- If your `google-services.json` has `"package_name": "com.lgbtfinder"`, no change is needed; rebuild and run.

---

## If you need a new google-services.json

1. Go to [Firebase Console](https://console.firebase.google.com) → project **lgbtfinder-c2bdc**.
2. Project settings (gear) → **Your apps** → **Add app** → **Android**.
3. **Android package name:** `com.lgbtfinder`.
4. Register app → **Download google-services.json** → save as `lgbtindernew/android/app/google-services.json`.
5. Rebuild: `flutter clean` → `flutter pub get` → `flutter run` (or `run_flutter.bat run`).
