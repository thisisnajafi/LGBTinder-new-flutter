import 'chat_message_sheet_actions.dart';

/// Aggregated emoji counts plus the current user's pick (CHAT-UX-005).
class ChatReactionSummary {
  final Map<String, int> counts;
  final String? mine;

  const ChatReactionSummary({
    this.counts = const {},
    this.mine,
  });

  static const List<String> allowed = ChatMessageSheetActions.reactEmojis;

  bool get isEmpty => counts.isEmpty;

  factory ChatReactionSummary.fromMap(Map<String, dynamic> message) {
    return ChatReactionSummary(
      counts: parseCounts(message['reactions']),
      mine: parseMine(message['my_reaction']),
    );
  }

  factory ChatReactionSummary.fromJson(Map<String, dynamic> json) {
    return ChatReactionSummary(
      counts: parseCounts(json['counts'] ?? json['reactions']),
      mine: parseMine(json['my_reaction']),
    );
  }

  static Map<String, int> parseCounts(dynamic raw) {
    if (raw is Map) {
      final out = <String, int>{};
      raw.forEach((key, value) {
        final emoji = key.toString();
        if (emoji.isEmpty) return;
        final n = value is int
            ? value
            : int.tryParse(value?.toString() ?? '') ?? 0;
        if (n > 0) out[emoji] = n;
      });
      return out;
    }
    if (raw is List) {
      final out = <String, int>{};
      for (final item in raw) {
        if (item is! Map) continue;
        final emoji = item['emoji']?.toString();
        if (emoji == null || emoji.isEmpty) continue;
        final n = item['count'] is int
            ? item['count'] as int
            : int.tryParse(item['count']?.toString() ?? '') ?? 1;
        if (n > 0) out[emoji] = n;
      }
      return out;
    }
    return const {};
  }

  static String? parseMine(dynamic raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  /// Same emoji toggles off; a different emoji replaces the previous one.
  ChatReactionSummary toggle(String emoji) {
    final next = Map<String, int>.from(counts);
    if (mine == emoji) {
      final n = (next[emoji] ?? 1) - 1;
      if (n <= 0) {
        next.remove(emoji);
      } else {
        next[emoji] = n;
      }
      return ChatReactionSummary(counts: next, mine: null);
    }
    if (mine != null) {
      final n = (next[mine!] ?? 1) - 1;
      if (n <= 0) {
        next.remove(mine!);
      } else {
        next[mine!] = n;
      }
    }
    next[emoji] = (next[emoji] ?? 0) + 1;
    return ChatReactionSummary(counts: next, mine: emoji);
  }

  static ChatReactionSummary applyEvent({
    required ChatReactionSummary current,
    required int reactorId,
    required int currentUserId,
    required Map<String, int> counts,
    required String emoji,
    required bool reacted,
  }) {
    var mine = current.mine;
    if (reactorId == currentUserId) {
      mine = reacted ? emoji : null;
    }
    return ChatReactionSummary(counts: counts, mine: mine);
  }
}

/// POST /chat/messages/{id}/react payload.
class ChatReactionResult {
  final int messageId;
  final int? conversationId;
  final int userId;
  final String emoji;
  final bool reacted;
  final Map<String, int> counts;
  final String? myReaction;

  const ChatReactionResult({
    required this.messageId,
    this.conversationId,
    required this.userId,
    required this.emoji,
    required this.reacted,
    required this.counts,
    this.myReaction,
  });

  factory ChatReactionResult.fromJson(Map<String, dynamic> json) {
    return ChatReactionResult(
      messageId: json['message_id'] is int
          ? json['message_id'] as int
          : int.tryParse(json['message_id']?.toString() ?? '') ?? 0,
      conversationId: json['conversation_id'] == null
          ? null
          : (json['conversation_id'] is int
              ? json['conversation_id'] as int
              : int.tryParse(json['conversation_id'].toString())),
      userId: json['user_id'] is int
          ? json['user_id'] as int
          : int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      emoji: json['emoji']?.toString() ?? '',
      reacted: json['reacted'] == true,
      counts: ChatReactionSummary.parseCounts(json['counts']),
      myReaction: ChatReactionSummary.parseMine(json['my_reaction']),
    );
  }

  ChatReactionSummary get summary => ChatReactionSummary(
        counts: counts,
        mine: myReaction,
      );
}
