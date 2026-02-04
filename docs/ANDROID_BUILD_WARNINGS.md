# Android build warnings (Java/Kotlin)

## What you see

When you run `flutter run` or `flutter build apk`, the build log can show many lines like:

- `warning: 'fun queryIntentActivities(...)' is deprecated. Deprecated in Java.`
- `warning: unchecked cast of 'kotlin.Any?' to 'kotlin.collections.Map<...>'`
- `warning: only safe (?.) or non-null asserted (!!.) calls are allowed on a nullable receiver`

These appear under paths like:

- `Pub\Cache\hosted\pub.dev\share_plus-7.2.2\android\...`
- `Pub\Cache\hosted\pub.dev\stripe_android-11.5.0\android\...`
- `Pub\Cache\hosted\pub.dev\video_compress-3.1.4\android\...`
- etc.

## Why they appear

1. **They are not from your app code**  
   They come from **third‑party Android plugin code** (share_plus, video_compress, record_android, flutter_stripe, etc.) inside the Pub cache.

2. **They are warnings, not errors**  
   The build still succeeds. The last line usually says something like:  
   `Note: Some input files use or override a deprecated API.`

3. **Types of warnings**
   - **Deprecation:** Plugin code uses older Java/Android APIs that are now deprecated.
   - **Unchecked cast / nullable receiver:** Kotlin strictness in plugin code.

## Can we “fix” them?

- **In this project:** No. That code lives in packages under `Pub\Cache\hosted\pub.dev\`. Editing it would be overwritten on the next `flutter pub get` or package update.
- **Proper fix:** Package maintainers need to update their Android/Kotlin code. You can:
  - Upgrade packages when new versions are available: `flutter pub upgrade`
  - Open an issue or PR on the plugin’s repo if you want to help.

## What we did in this project

- In `android/app/build.gradle.kts`, Kotlin is configured so that dependency warnings don’t turn into build errors.
- These warnings are safe to ignore for normal development and release builds.

## If you want fewer warnings in the log

- Run release builds when you don’t need full logs: `flutter build apk --release`.
- Upgrade dependencies from time to time: `flutter pub upgrade` (test the app after upgrading).
