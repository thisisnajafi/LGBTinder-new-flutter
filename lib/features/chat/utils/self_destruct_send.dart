/// Shared self-destruct send constants and bubble copy (CHAT-SD-001 / CHAT-SD-002).
class SelfDestructSend {
  SelfDestructSend._();

  static const String messageType = 'disappearing_image';

  static const List<int> durationOptionsSeconds = [5, 10, 30, 60];

  /// Fallback view window when the server omits remaining/total seconds.
  static const int defaultViewSeconds = 10;

  /// Flame pulse: 1.0 → 1.15 → 1.0 over 2s (CHAT-SD-002).
  static const Duration flamePulseDuration = Duration(seconds: 2);

  static const double flamePulsePeak = 1.15;

  static String formatDuration(int seconds) => '${seconds}s';

  static String senderLabel({required bool openedByPeer}) {
    return openedByPeer ? 'Opened' : 'Waiting to be opened';
  }

  /// Receiver, not yet opened (State 1).
  static String receiverUnopenedLabel(int? durationSeconds) {
    if (durationSeconds != null && durationSeconds > 0) {
      return 'Photo • Tap to view • disappears in ${formatDuration(durationSeconds)}';
    }
    return 'Photo • Tap to view';
  }

  /// State 3 after viewing vs State 4 expired without a view.
  static String expiredLabel({required bool viewed}) {
    return viewed ? 'Photo expired' : 'Photo no longer available';
  }

  static int? displayDurationSeconds({
    required bool isSent,
    required bool openedByPeer,
    int? expiresInSeconds,
    int? remainingSeconds,
  }) {
    if (isSent && !openedByPeer) {
      return (expiresInSeconds != null && expiresInSeconds > 0)
          ? expiresInSeconds
          : remainingSeconds;
    }
    if (openedByPeer && remainingSeconds != null && remainingSeconds > 0) {
      return remainingSeconds;
    }
    return null;
  }

  /// Duration shown in the unopened receiver sentence (expires window).
  static int? receiverPreviewDurationSeconds({
    int? expiresInSeconds,
    int? remainingSeconds,
  }) {
    if (expiresInSeconds != null && expiresInSeconds > 0) {
      return expiresInSeconds;
    }
    if (remainingSeconds != null && remainingSeconds > 0) {
      return remainingSeconds;
    }
    return null;
  }
}
