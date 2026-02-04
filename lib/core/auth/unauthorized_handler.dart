import 'package:flutter/foundation.dart';

/// Global handler invoked when the API returns 401 Unauthenticated.
/// Set from the app root (e.g. MyApp) to log out and redirect to welcome.
/// DioClient calls [invoke] when it clears tokens due to 401.
class UnauthorizedHandler {
  UnauthorizedHandler._();

  static VoidCallback? _onUnauthorized;
  static bool _redirecting = false;

  /// Set the callback to run when the user is no longer authenticated (401).
  /// Typically: logout + redirect to welcome screen.
  static void setCallback(VoidCallback callback) {
    _onUnauthorized = callback;
  }

  /// Invoke the registered callback. Call from the UI thread (e.g. via
  /// [WidgetsBinding.instance.addPostFrameCallback]) so navigation is safe.
  /// Only runs once per "burst" of 401s to avoid multiple overlapping redirects.
  static void invoke() {
    if (_onUnauthorized == null || _redirecting) return;
    _redirecting = true;
    if (kDebugMode) {
      debugPrint('🔐 UnauthorizedHandler: session invalid, redirecting to welcome');
    }
    _onUnauthorized!();
    // Reset after a delay so a future 401 (e.g. after re-login and expiry) can trigger again
    Future.delayed(const Duration(seconds: 2), () {
      _redirecting = false;
    });
  }
}
