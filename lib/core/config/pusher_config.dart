import '../constants/api_endpoints.dart';

/// Pusher Channels configuration for real-time chat.
///
/// The app key is public (same value as backend `PUSHER_APP_KEY`).
/// The running key can be overridden at runtime from `/api/realtime/config`
/// so admin-updated credentials stay in sync with the mobile client.
class PusherConfig {
  PusherConfig._();

  static const String _defaultAppKey = 'bcf8236559a0fc82dcb9';
  static const String _defaultCluster = 'us3';

  static const String _compileTimeAppKey = String.fromEnvironment(
    'PUSHER_APP_KEY',
    defaultValue: _defaultAppKey,
  );

  static const String _compileTimeCluster = String.fromEnvironment(
    'PUSHER_APP_CLUSTER',
    defaultValue: _defaultCluster,
  );

  static String? _runtimeAppKey;
  static String? _runtimeCluster;

  static String get appKey {
    final runtime = _runtimeAppKey?.trim() ?? '';
    if (runtime.isNotEmpty) return runtime;
    return _compileTimeAppKey;
  }

  static String get cluster {
    final runtime = _runtimeCluster?.trim() ?? '';
    if (runtime.isNotEmpty) return runtime;
    if (hasRemoteKey) return '';
    return _compileTimeCluster;
  }

  static bool get hasRemoteKey {
    final runtime = _runtimeAppKey?.trim() ?? '';
    return runtime.isNotEmpty;
  }

  static bool get hasRemotePair {
    final key = _runtimeAppKey?.trim() ?? '';
    final cluster = _runtimeCluster?.trim() ?? '';
    return key.isNotEmpty && cluster.isNotEmpty;
  }

  /// Laravel Sanctum broadcasting auth (no /api prefix).
  static String get authEndpoint => '${ApiEndpoints.apiOrigin}/broadcasting/auth';

  static String get remoteConfigUrl => '${ApiEndpoints.baseUrl}/realtime/config';

  static bool get isConfigured {
    if (appKey.isEmpty) return false;
    if (hasRemoteKey) return hasRemotePair;
    return cluster.isNotEmpty;
  }

  /// Apply a remote key/cluster pair. A key change without a cluster clears
  /// the old cluster so a recovered key cannot keep `us3`.
  static void applyRemote({String? key, String? cluster}) {
    final nextKey = key?.trim();
    final nextCluster = cluster?.trim();
    final applyingKey = nextKey != null && nextKey.isNotEmpty;
    final applyingCluster = nextCluster != null && nextCluster.isNotEmpty;
    final keyChanged = applyingKey && nextKey != appKey;

    if (applyingKey) {
      _runtimeAppKey = nextKey;
    }

    if (applyingCluster) {
      _runtimeCluster = nextCluster;
    } else if (keyChanged) {
      _runtimeCluster = null;
    }
  }

  static void resetRuntime() {
    _runtimeAppKey = null;
    _runtimeCluster = null;
  }

  static String? parseKeyFromAuthError(String message) {
    final match = RegExp(
      r"Invalid key in subscription auth data: '([^']+)'",
    ).firstMatch(message);
    return match?.group(1);
  }
}
