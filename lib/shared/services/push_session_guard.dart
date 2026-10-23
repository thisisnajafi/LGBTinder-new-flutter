import 'token_storage_service.dart';

/// Push messages are only shown while a user is signed in on this device.
/// Works in the FCM background isolate (secure storage, no Riverpod).
class PushSessionGuard {
  PushSessionGuard._();

  /// Overridable for tests.
  static Future<String?> Function() readAuthToken =
      () => TokenStorageService().getAuthToken();

  static Future<bool> hasLocalSession() async {
    try {
      final token = await readAuthToken();
      return token != null && token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
