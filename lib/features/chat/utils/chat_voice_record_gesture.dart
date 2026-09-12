/// Slide-left cancel / slide-up lock math for hold-to-record (CHAT-INPUT-003).
enum ChatVoiceRecordAction { none, cancel, lock }

class ChatVoiceRecordGesture {
  ChatVoiceRecordGesture._();

  static const double cancelThreshold = 72;
  static const double lockThreshold = 72;

  /// [dx]/[dy] are current − press start. Left and up are negative.
  static ChatVoiceRecordAction resolve({
    required double dx,
    required double dy,
    double cancelAt = cancelThreshold,
    double lockAt = lockThreshold,
  }) {
    final left = dx <= -cancelAt;
    final up = dy <= -lockAt;
    if (!left && !up) return ChatVoiceRecordAction.none;
    if (left && up) {
      return dx.abs() >= dy.abs()
          ? ChatVoiceRecordAction.cancel
          : ChatVoiceRecordAction.lock;
    }
    return left ? ChatVoiceRecordAction.cancel : ChatVoiceRecordAction.lock;
  }
}
