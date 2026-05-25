import '../constants/api_endpoints.dart';

/// Pusher Channels configuration for real-time chat.
///
/// Override at build time:
/// `flutter run --dart-define=PUSHER_APP_KEY=your_key --dart-define=PUSHER_APP_CLUSTER=mt1`
class PusherConfig {
  PusherConfig._();

  static const String appKey = String.fromEnvironment(
    'PUSHER_APP_KEY',
    defaultValue: '',
  );

  static const String cluster = String.fromEnvironment(
    'PUSHER_APP_CLUSTER',
    defaultValue: 'mt1',
  );

  /// Laravel Sanctum broadcasting auth (no /api prefix).
  static String get authEndpoint => '${ApiEndpoints.apiOrigin}/broadcasting/auth';

  static bool get isConfigured => appKey.isNotEmpty;
}
