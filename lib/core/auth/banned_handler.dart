import 'package:flutter/foundation.dart';

/// Invoked when the API returns 403 with `user_state: banned`.
class BannedHandler {
  BannedHandler._();

  static VoidCallback? _onBanned;
  static bool _redirecting = false;

  static void setCallback(VoidCallback callback) {
    _onBanned = callback;
  }

  static void invoke() {
    if (_onBanned == null || _redirecting) return;
    _redirecting = true;
    if (kDebugMode) {
      debugPrint('BannedHandler: account banned, redirecting');
    }
    _onBanned!();
    Future.delayed(const Duration(seconds: 2), () {
      _redirecting = false;
    });
  }
}
