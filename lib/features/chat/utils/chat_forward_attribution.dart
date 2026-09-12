/// Copy for the Telegram-style “Forwarded from” header (CHAT-THREAD-008).
class ChatForwardAttribution {
  ChatForwardAttribution._();

  /// Matches backend `ChatMessageForwardService::MAX_RECIPIENTS`.
  static const int maxRecipients = 20;

  static String label(String? name) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return 'Forwarded';
    return 'Forwarded from $trimmed';
  }
}
