import 'dart:async';

import '../../../shared/services/pusher_websocket_service.dart';

/// Manages visibility of a peer typing indicator with a client-side safety timeout.
///
/// Pusher [UserTyping] shows the indicator; [UserStoppedTyping] or [hideAfter]
/// (default 6s) hides it if the server stop event is missed.
class TypingIndicatorController {
  TypingIndicatorController({
    this.hideAfter = const Duration(seconds: 6),
    this.onVisibilityChanged,
  });

  final Duration hideAfter;
  final void Function(bool isVisible)? onVisibilityChanged;

  Timer? _hideTimer;
  bool _isVisible = false;

  bool get isVisible => _isVisible;

  void onTypingEvent(
    TypingEvent event, {
    required int peerUserId,
    int? conversationId,
  }) {
    if (event.userId != peerUserId) return;
    if (conversationId != null &&
        event.conversationId != null &&
        event.conversationId != conversationId) {
      return;
    }

    _hideTimer?.cancel();
    if (event.isTyping) {
      _setVisible(true);
      _hideTimer = Timer(hideAfter, () => _setVisible(false));
    } else {
      _setVisible(false);
    }
  }

  void _setVisible(bool value) {
    if (_isVisible == value) return;
    _isVisible = value;
    onVisibilityChanged?.call(value);
  }

  void dispose() {
    _hideTimer?.cancel();
  }
}
