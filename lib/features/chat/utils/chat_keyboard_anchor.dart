import 'chat_thread_scroll.dart';

/// Pins the chat list to the latest row while the keyboard inset changes.
class ChatKeyboardAnchor {
  bool? _pinned;

  bool get isPinned => _pinned == true;

  /// Latch [nearBottom] on the first positive inset so mid-thread does not jump.
  bool shouldPinToBottom({
    required double insetBottom,
    required bool nearBottom,
  }) {
    if (insetBottom <= 0) {
      final wasPinned = _pinned == true;
      _pinned = null;
      return wasPinned || nearBottom;
    }
    _pinned ??= nearBottom;
    return _pinned!;
  }

  /// Offset to jump to so the latest row stays in view, or null if already there.
  static double? pinnedExtent({
    required double pixels,
    double epsilon = 1,
  }) {
    return ChatThreadScroll.pinnedLatestPixels(
      pixels: pixels,
      epsilon: epsilon,
    );
  }
}
