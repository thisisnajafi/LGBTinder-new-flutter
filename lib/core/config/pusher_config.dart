import '../constants/api_endpoints.dart';

/// Pusher Channels configuration for real-time chat.
///
/// The app key is public (same value as backend `PUSHER_APP_KEY`).
/// Override at build time when needed:
/// `flutter run --dart-define=PUSHER_APP_KEY=... --dart-define=PUSHER_APP_CLUSTER=us3`
class PusherConfig {
  PusherConfig._();

  static const String _defaultAppKey = 'bcf8236559a0fc82dcb9';
  static const String _defaultCluster = 'us3';

  static const String appKey = String.fromEnvironment(
    'PUSHER_APP_KEY',
    defaultValue: _defaultAppKey,
  );

  static const String cluster = String.fromEnvironment(
    'PUSHER_APP_CLUSTER',
    defaultValue: _defaultCluster,
  );

  /// Laravel Sanctum broadcasting auth (no /api prefix).
  static String get authEndpoint => '${ApiEndpoints.apiOrigin}/broadcasting/auth';

  static bool get isConfigured => appKey.isNotEmpty;
}
