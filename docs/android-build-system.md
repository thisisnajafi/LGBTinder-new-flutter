# Android Build System — LGBTFinder Flutter

Production Android build, CI/CD, and release documentation for `lgbtindernew`.

**Last updated:** 2026-06-19

---

## Current Versions

| Component | Version | Source |
|-----------|---------|--------|
| Flutter | 3.44.0 | CI pin / local SDK |
| Dart | 3.12.0 | Bundled with Flutter 3.44 |
| Android Gradle Plugin (AGP) | 8.11.1 | `android/settings.gradle.kts` |
| Gradle | 8.14 | `android/gradle/wrapper/gradle-wrapper.properties` |
| Kotlin | 2.2.20 | `android/settings.gradle.kts` |
| Java (compile) | 11 | `android/app/build.gradle.kts` |
| Java (CI) | 17 | GitHub Actions `setup-java` |
| compileSdk | 36 | Flutter 3.44 default (`flutter.compileSdkVersion`) |
| targetSdk | 36 | Flutter 3.44 default |
| minSdk | 24 (Android 7.0) | Flutter 3.44 default |
| NDK | 28.2.13676358 | Flutter 3.44 default |
| App version | 1.0.0+1 | `pubspec.yaml` |

---

## SDK Compatibility Matrix

| Android Version | API Level | Support | Notes |
|-----------------|-----------|---------|-------|
| Android 7.0 Nougat | 24 | **minSdk** | ~98%+ active devices; Flutter 3.44 floor |
| Android 8.0 Oreo | 26 | CI tested | Emulator matrix |
| Android 9 Pie | 28 | CI tested | Emulator matrix |
| Android 10 | 29 | CI tested | Scoped storage era |
| Android 11 | 30 | CI tested | |
| Android 12 | 31 | CI tested | |
| Android 13 | 33 | CI tested | Notification permission |
| Android 14 | 34 | CI tested | |
| Android 15 | 35 | CI tested | Play Store current target band |
| Latest compile | 36 | **targetSdk / compileSdk** | Play Store compliant |

### SDK selection rationale

- **minSdk 24:** Widest practical reach with Flutter 3.44 defaults. Agora RTC uses `android.ndk.suppressMinSdkVersionError=21` for NDK tooling only; runtime floor remains 24.
- **targetSdk 36:** Meets Google Play requirement (target API 35+ for new apps/updates in 2025) with headroom for Flutter tooling.
- **compileSdk 36:** Matches Flutter template; required to compile against latest Android APIs used by plugins.

---

## Build Commands

### Quick local builds

```bash
# Dependencies
flutter pub get

# Static analysis (app code only)
flutter analyze lib/ --no-fatal-infos --no-fatal-warnings

# Unit tests
flutter test test/unit/

# Split release APKs (armeabi-v7a, arm64-v8a, x86_64)
flutter build apk --release --split-per-abi

# Play Store App Bundle
flutter build appbundle --release
```

### Full production script

**Linux / macOS / CI:**

```bash
chmod +x scripts/build_android.sh
./scripts/build_android.sh
```

**Windows (PowerShell):**

```powershell
.\scripts\build_android.ps1
```

Options:

| Flag | Effect |
|------|--------|
| `--skip-tests` / `-SkipTests` | Skip `flutter test` |
| `--skip-analyze` / `-SkipAnalyze` | Skip `flutter analyze` |

### China mirror (local dev)

```powershell
.\run_flutter.ps1 build apk --release --split-per-abi
```

Sets `PUB_HOSTED_URL` and `FLUTTER_STORAGE_BASE_URL` to flutter-io.cn mirrors.

---

## Artifact Locations

| Output | Default Flutter path | Collected release path |
|--------|---------------------|------------------------|
| Split APKs | `build/app/outputs/flutter-apk/app-*-release.apk` | `build/releases/apk/` |
| App Bundle | `build/app/outputs/bundle/release/app-release.aab` | `build/releases/aab/` |
| Build summary | — | `build/releases/build-summary.txt` |

CI uploads artifacts as `android-apks`, `android-app-bundle`, and `build-releases` (14-day retention).

---

## Release Process

### 1. Version bump

Edit `pubspec.yaml`:

```yaml
version: 1.0.1+2   # versionName+versionCode
```

### 2. Release signing

1. Generate upload keystore:

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. Copy `android/key.properties.example` → `android/key.properties` (gitignored).
3. Place keystore at path referenced in `storeFile`.

Without `key.properties`, release builds use **debug signing** (local dev only — not for Play Store).

### 3. CI release signing (optional)

GitHub repository secrets:

| Secret | Description |
|--------|-------------|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded `.jks` file |
| `ANDROID_KEY_ALIAS` | Key alias |
| `ANDROID_KEY_PASSWORD` | Key password |
| `ANDROID_STORE_PASSWORD` | Keystore password |

### 4. Build and upload

```bash
./scripts/build_android.sh
```

Upload `build/releases/aab/app-release.aab` to Google Play Console.

### 5. R8 / ProGuard

Release builds enable minification and resource shrinking:

- `isMinifyEnabled = true`
- `isShrinkResources = true`
- Rules: `android/app/proguard-rules.pro`

---

## CI/CD Workflow Overview

**File:** `.github/workflows/android-ci.yml`

```
push/PR to main ─┬─► analyze-and-test (pub get, analyze lib/, unit tests)
                 │
                 ├─► build-android (split APK + AAB, artifacts)
                 │        │
                 │        └─► compatibility-matrix (API 26–35 emulators)
                 │
                 └─► notify-telegram (always, detailed report)
```

### Jobs

| Job | Purpose |
|-----|---------|
| `analyze-and-test` | `flutter pub get`, `flutter analyze lib/`, `flutter test test/unit/` |
| `build-android` | `flutter build apk --split-per-abi`, `flutter build appbundle` |
| `compatibility-matrix` | Install APK on emulators API 26, 28–31, 33–35; launch via `monkey` |
| `notify-telegram` | Send structured build report |

### Triggers

- Push to `main` / `master`
- Pull requests to `main` / `master`
- Manual: `workflow_dispatch`

Legacy `main.yml` is deprecated; all CI runs through `android-ci.yml`.

---

## Telegram Reporting Flow

**Script:** `scripts/ci_telegram_report.sh`

Reuses existing LGBTFinder Telegram configuration:

| Setting | Default | Override |
|---------|---------|----------|
| Bot token | Project default (same as backend) | `secrets.TELEGRAM_BOT_TOKEN` |
| Chat ID | `-1002275828844` | `secrets.TELEGRAM_CHAT_ID` |

Each CI run sends:

- Project name, branch, commit SHA, author, timestamp
- Flutter version, Android SDK config, build duration
- Analyze/test results, APK/AAB status, compatibility matrix result
- GitHub Actions run URL for artifacts
- Error summary on failure

---

## Release Readiness Checklist

| Item | Status | Action |
|------|--------|--------|
| Split APK build | ✅ Configured | `flutter build apk --split-per-abi` |
| App Bundle build | ✅ Configured | `flutter build appbundle --release` |
| R8 minification | ✅ Enabled | `proguard-rules.pro` |
| Resource shrinking | ✅ Enabled | release buildType |
| Release signing | ⚠️ Local fallback | Add `android/key.properties` for production |
| Play Store targetSdk | ✅ 36 | Meets API 35+ requirement |
| Firebase | ✅ | `android/app/google-services.json` present |
| CI pipeline | ✅ | `android-ci.yml` |
| Emulator compatibility tests | ✅ | API 26–35 matrix |
| Unit tests | ⚠️ 23 failing | Outdated mocks (`isSuccess` → API changes); CI reports but does not block |
| Built-in Kotlin migration | ⚠️ Pending | Plugins still apply KGP; see Flutter migration guide |
| `android.enableJetifier` | ⚠️ Legacy | Can remove when all deps are AndroidX-native |

---

## Known Build Warnings

See also `docs/ANDROID_BUILD_WARNINGS.md`.

- **Plugin deprecation warnings** from Pub cache (share_plus, video_compress, etc.) — safe to ignore.
- **Kotlin Gradle Plugin on plugins** — tracked; migrate to Built-in Kotlin when plugins support it.
- **Agora optional native libs** — stripped via `packaging.jniLibs.excludes` to reduce APK size.

---

## Troubleshooting

### `flutter pub get` fails (authorization / pub.dev)

Use China mirrors:

```powershell
$env:PUB_HOSTED_URL="https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
flutter pub get
```

Or use `.\run_flutter.ps1 pub get`.

### AGP / Kotlin version warnings

Ensure `android/settings.gradle.kts` uses AGP ≥ 8.11.1 and Kotlin ≥ 2.2.20.

### Release build signing errors

Verify `android/key.properties` paths are relative to `android/` directory.

### CI emulator matrix timeout

Emulator jobs have 35-minute timeout. Re-run failed matrix cells individually via `workflow_dispatch`.

### NDK minSdk suppress

`gradle.properties` contains `android.ndk.suppressMinSdkVersionError=21` for Agora NDK compatibility. This does **not** lower the app minSdk below 24.

### Gradle OOM

`gradle.properties` sets `-Xmx8G`. Reduce on low-RAM machines if needed.

---

## Project Structure (Android)

```
lgbtindernew/
├── android/
│   ├── app/
│   │   ├── build.gradle.kts      # App module, signing, R8, Agora excludes
│   │   ├── proguard-rules.pro
│   │   └── google-services.json
│   ├── build.gradle.kts          # AGP/Kotlin force resolution
│   ├── settings.gradle.kts       # AGP 8.11.1, Kotlin 2.2.20
│   ├── gradle.properties
│   └── key.properties.example
├── scripts/
│   ├── build_android.sh
│   ├── build_android.ps1
│   └── ci_telegram_report.sh
├── .github/workflows/
│   └── android-ci.yml
└── build/releases/               # Collected artifacts (gitignored)
    ├── apk/
    ├── aab/
    └── build-summary.txt
```

---

## Audit Summary (2026-06-19)

### Resolved

- Upgraded AGP 8.9.1 → 8.11.1, Kotlin 2.1.0 → 2.2.20
- Added release signing via `key.properties` with debug fallback
- Production CI: analyze, test, build, emulator matrix, Telegram
- Cross-platform build scripts with artifact collection
- Documented SDK matrix and release process

### Open items

1. **Production keystore** — configure `key.properties` / GitHub secrets before Play Store upload
2. **Unit test debt** — 23 tests fail due to outdated `ApiResponse` mocks and renamed widgets
3. **Built-in Kotlin** — migrate when all plugins support `android.builtInKotlin=true`
4. **Dependency upgrades** — 101 packages have newer constrained versions (`flutter pub outdated`)
