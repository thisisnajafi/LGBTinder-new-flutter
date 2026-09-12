import '../../data/models/message.dart';

/// Result of POST /chat/messages/{id}/forward (CHAT-THREAD-008).
class ChatForwardSkip {
  final int userId;
  final String reason;

  const ChatForwardSkip({required this.userId, required this.reason});

  factory ChatForwardSkip.fromJson(Map<String, dynamic> json) {
    return ChatForwardSkip(
      userId: json['user_id'] is int
          ? json['user_id'] as int
          : int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      reason: json['reason']?.toString() ?? 'unknown',
    );
  }
}

class ChatForwardResult {
  final List<Message> forwarded;
  final List<ChatForwardSkip> skipped;

  const ChatForwardResult({
    this.forwarded = const [],
    this.skipped = const [],
  });

  factory ChatForwardResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    final forwardedRaw = data['forwarded'];
    final skippedRaw = data['skipped'];
    return ChatForwardResult(
      forwarded: forwardedRaw is List
          ? forwardedRaw
              .whereType<Map>()
              .map((row) => Message.fromJson(Map<String, dynamic>.from(row)))
              .toList()
          : const [],
      skipped: skippedRaw is List
          ? skippedRaw
              .whereType<Map>()
              .map((row) => ChatForwardSkip.fromJson(
                    Map<String, dynamic>.from(row),
                  ))
              .toList()
          : const [],
    );
  }
}
