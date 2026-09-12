/// Helpers for loading older chat history (CHAT-UX-001).
class ChatLoadOlder {
  ChatLoadOlder._();

  /// Reverse threads keep pixel 0 on the latest row, so prepending older
  /// messages grows [ScrollPosition.maxScrollExtent] and does not need a
  /// jump delta.
  static bool get needsScrollCompensation => false;

  static List<T> withoutExistingIds<T>({
    required Iterable<T> incoming,
    required int Function(T item) idOf,
    required Set<int> existingIds,
  }) {
    return [
      for (final item in incoming)
        if (!existingIds.contains(idOf(item))) item,
    ];
  }
}
