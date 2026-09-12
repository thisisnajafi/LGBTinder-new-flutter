import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Cached device label for auth requests (PERF-SCR-LOGIN-001).
///
/// [DeviceInfoPlugin] is hit at most once per process; later callers share
/// the same [Future].
class AppDeviceName {
  AppDeviceName._();

  static Future<String>? _cached;

  /// Returns a stable device name, loading it on the first call only.
  static Future<String> resolve() => _cached ??= _load();

  static Future<String> _load() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model}';
      }
      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return '${iosInfo.name} (${iosInfo.model})';
      }
    } catch (_) {}
    return 'Unknown Device';
  }

  /// Test-only: drop the memoized future.
  @visibleForTesting
  static void resetForTest() {
    _cached = null;
  }
}
