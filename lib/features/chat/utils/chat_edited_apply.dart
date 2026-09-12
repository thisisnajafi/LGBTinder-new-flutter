/// In-place row merge for PATCH / Pusher `MessageEdited` (CHAT-FEAT-004).
class ChatEditedApply {
  ChatEditedApply._();

  static List<Map<String, dynamic>> apply({
    required List<Map<String, dynamic>> messages,
    required int messageId,
    required String content,
    required DateTime editedAt,
    Map<String, dynamic>? extra,
  }) {
    return [
      for (final row in messages)
        _sameId(row['id'], messageId)
            ? patchRow(
                row,
                content: content,
                editedAt: editedAt,
                extra: extra,
              )
            : row,
    ];
  }

  static Map<String, dynamic> patchRow(
    Map<String, dynamic> row, {
    required String content,
    required DateTime editedAt,
    Map<String, dynamic>? extra,
  }) {
    return {
      ...row,
      if (extra != null) ...extra,
      'text': content,
      'is_edited': true,
      'edited_at': editedAt,
    };
  }

  static bool _sameId(dynamic id, int messageId) {
    if (id is int) return id == messageId;
    return int.tryParse(id?.toString() ?? '') == messageId;
  }
}
