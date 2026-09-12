import 'dart:async';

/// Outbound typing heartbeats for the open thread (CHAT-RT-003).
class ChatTypingOutbound {
  ChatTypingOutbound({required this.send});

  /// Delay before the first `is_typing: true` so a single keystroke is not a round-trip.
  static const Duration startDebounce = Duration(milliseconds: 500);

  /// Stop ping after the composer is idle.
  static const Duration idleStop = Duration(seconds: 3);

  final Future<void> Function(bool isTyping) send;

  Timer? _startTimer;
  Timer? _stopTimer;

  void onTextChanged(String text) {
    _stopTimer?.cancel();
    if (text.trim().isNotEmpty) {
      _startTimer?.cancel();
      _startTimer = Timer(startDebounce, () {
        unawaited(send(true));
      });
      _stopTimer = Timer(idleStop, () {
        unawaited(send(false));
      });
      return;
    }
    _startTimer?.cancel();
    unawaited(send(false));
  }

  void onFocusLost() {
    _startTimer?.cancel();
    _stopTimer?.cancel();
    unawaited(send(false));
  }

  void cancelTimers() {
    _startTimer?.cancel();
    _stopTimer?.cancel();
  }
}
