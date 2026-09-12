/// Whether a new row should spring the thread (CHAT-ANIM-013).
class ChatArrivalBounce {
  ChatArrivalBounce._();

  static bool shouldPlay({
    required bool nearBottom,
    required bool animationsEnabled,
  }) {
    return nearBottom && animationsEnabled;
  }
}
