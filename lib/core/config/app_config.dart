import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;

/// Build flavor. The name matches `--flavor` and `FLUTTER_APP_FLAVOR`.
enum AppFlavor { development, staging, production }

/// Environment values for one flavor.
///
/// Install this from `main_development.dart`, `main_staging.dart`, or
/// `main_production.dart` before the app starts. Production ignores
/// `API_ORIGIN` so a dart-define cannot retarget a store build.
class AppConfig {
  AppConfig._({
    required this.flavor,
    required this.apiOrigin,
    required this.displayName,
    required this.minimumLogLevelIndex,
    required this.pusherAppKey,
    required this.pusherCluster,
    required this.googleWebClientId,
    required this.agoraAppIdOverride,
  });

  final AppFlavor flavor;
  final String apiOrigin;
  final String displayName;

  /// Index into `LogLevel` in `app_logger.dart` (verbose = 0 … fatal = 5).
  final int minimumLogLevelIndex;

  final String pusherAppKey;
  final String pusherCluster;
  final String googleWebClientId;
  final String agoraAppIdOverride;

  static AppConfig? _current;

  static bool get isReady => _current != null;

  static AppConfig get current {
    final value = _current;
    if (value == null) {
      throw StateError(
        'AppConfig is not installed. Start the app from a flavor entry point.',
      );
    }
    return value;
  }

  static const String productionOrigin = 'https://api.lgbtfinder.com';

  /// Android emulator hostname for the host machine's `127.0.0.1:8000`.
  static const String androidEmulatorOrigin = 'http://10.0.2.2:8000';

  /// iOS simulator and desktop loopback for the local Laravel server.
  static const String loopbackOrigin = 'http://127.0.0.1:8000';

  /// Public Pusher key. Matches `lgbtinder-backend/.env` `PUSHER_APP_KEY`
  /// and the previous fallback in `PusherConfig`. The key in
  /// `dart_defines.json` is a different app and is not used.
  static const String defaultPusherAppKey = 'bcf8236559a0fc82dcb9';
  static const String defaultPusherCluster = 'us3';

  static const String defaultGoogleWebClientId =
      '904491806534-vdhds1qkgv3ijf857d67mtg41hg0elvd.apps.googleusercontent.com';

  static const int _verbose = 0;
  static const int _warning = 3;
  static const int _error = 4;

  static void installDevelopment({bool requireMatchingFlavor = true}) {
    if (requireMatchingFlavor) {
      _enforceFlavor(AppFlavor.development);
    }
    _install(
      AppConfig._(
        flavor: AppFlavor.development,
        apiOrigin: resolveDevelopmentOrigin(),
        displayName: 'LGBTFinder Dev',
        minimumLogLevelIndex: _verbose,
        pusherAppKey: defaultPusherAppKey,
        pusherCluster: defaultPusherCluster,
        googleWebClientId: defaultGoogleWebClientId,
        agoraAppIdOverride: '',
      ),
    );
  }

  static void installStaging() {
    _enforceFlavor(AppFlavor.staging);
    _install(
      AppConfig._(
        flavor: AppFlavor.staging,
        apiOrigin: resolveStagingOrigin(),
        displayName: 'LGBTFinder Staging',
        minimumLogLevelIndex: _warning,
        pusherAppKey: defaultPusherAppKey,
        pusherCluster: defaultPusherCluster,
        googleWebClientId: defaultGoogleWebClientId,
        agoraAppIdOverride: '',
      ),
    );
  }

  static void installProduction({bool requireMatchingFlavor = true}) {
    const override = String.fromEnvironment('API_ORIGIN');
    if (override.isNotEmpty) {
      throw StateError(
        'Remove --dart-define=API_ORIGIN. Production always uses $productionOrigin.',
      );
    }
    if (requireMatchingFlavor) {
      _enforceFlavor(AppFlavor.production);
    }
    _install(
      AppConfig._(
        flavor: AppFlavor.production,
        apiOrigin: productionOrigin,
        displayName: 'LGBTFinder',
        minimumLogLevelIndex: _error,
        pusherAppKey: defaultPusherAppKey,
        pusherCluster: defaultPusherCluster,
        googleWebClientId: defaultGoogleWebClientId,
        agoraAppIdOverride: '',
      ),
    );
  }

  /// Local Laravel from this repo's `.env` (`APP_URL=http://127.0.0.1:8000`).
  ///
  /// Android emulator uses `10.0.2.2`. A physical device needs
  /// `--dart-define=API_ORIGIN=http://<lan-ip>:8000`.
  static String resolveDevelopmentOrigin() {
    const override = String.fromEnvironment('API_ORIGIN');
    if (override.isNotEmpty) return override;
    if (Platform.isAndroid) return androidEmulatorOrigin;
    return loopbackOrigin;
  }

  /// There is no staging host in the repo. Pass one at build time:
  /// `--dart-define=API_ORIGIN=https://your-staging-host`.
  static String resolveStagingOrigin() {
    const override = String.fromEnvironment('API_ORIGIN');
    if (override.isEmpty ||
        override.contains('.invalid') ||
        override.contains('REPLACE_')) {
      throw StateError(
        'Staging has no API origin yet. Run with '
        '--dart-define=API_ORIGIN=https://<staging-host> '
        '--flavor staging --target lib/main_staging.dart',
      );
    }
    return override;
  }

  static void _enforceFlavor(AppFlavor expected) {
    const built = String.fromEnvironment('FLUTTER_APP_FLAVOR');
    if (built != expected.name) {
      throw StateError(
        'lib/main_${expected.name}.dart was started with flavor "$built". '
        'Use flutter run --flavor ${expected.name} '
        '--target lib/main_${expected.name}.dart',
      );
    }
  }

  static void _install(AppConfig config) {
    final existing = _current;
    if (existing != null && existing.flavor != config.flavor) {
      throw StateError(
        'AppConfig is already ${existing.flavor.name}. '
        'Refusing to switch to ${config.flavor.name}.',
      );
    }
    _current = config;
  }

  /// Used by `lib/main.dart` when `--target` is omitted.
  ///
  /// A named flavor still has to match `--flavor`. A bare `flutter run`
  /// (empty `FLUTTER_APP_FLAVOR`) uses the production API. The installed
  /// `com.lgbtfinder` build has no local Laravel server, and development
  /// (`10.0.2.2:8000`) is only for `--flavor development`.
  static void installFromProcessFlavor() {
    const built = String.fromEnvironment('FLUTTER_APP_FLAVOR');
    switch (built) {
      case 'staging':
        installStaging();
        return;
      case 'development':
        installDevelopment();
        return;
      case 'production':
        installProduction();
        return;
      case '':
        installProduction(requireMatchingFlavor: false);
        return;
      default:
        throw StateError(
          'Unknown flavor "$built". Use development, staging, or production.',
        );
    }
  }

  /// Test-only. Production entry points never call this.
  @visibleForTesting
  static void debugReset() {
    _current = null;
  }
}
