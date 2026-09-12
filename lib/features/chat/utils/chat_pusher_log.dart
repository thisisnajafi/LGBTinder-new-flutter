import '../../../core/services/app_logger.dart';

/// Chat Pusher event logs (LOG-003). Tag floor is [LogLevel.info].
class ChatPusherLog {
  ChatPusherLog._();

  static const tag = 'ChatPusher';
  static const int previewMaxChars = 20;

  /// First [previewMaxChars] characters of [body]. No names or extra fields.
  static String preview(String? body) {
    final text = (body ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) return '';
    final clipped = String.fromCharCodes(text.runes.take(previewMaxChars));
    return clipped;
  }

  static String eventLine({
    required String eventType,
    int? conversationId,
    String? body,
  }) {
    final conv = (conversationId != null && conversationId > 0)
        ? conversationId.toString()
        : 'none';
    return 'Chat event: $eventType conversation_id=$conv preview="${preview(body)}"';
  }

  static int? conversationIdOf(Map<String, dynamic> data) {
    final nested = data['data'];
    final message = data['message'];
    final fromNested = nested is Map ? nested['conversation_id'] : null;
    final fromMessage = message is Map ? message['conversation_id'] : null;
    final raw = data['conversation_id'] ?? fromMessage ?? fromNested;
    final parsed = int.tryParse(raw?.toString() ?? '') ?? 0;
    return parsed > 0 ? parsed : null;
  }

  static String? bodyOf(Map<String, dynamic>? json) {
    if (json == null) return null;
    final content = json['content']?.toString();
    if (content != null && content.trim().isNotEmpty) return content;
    final message = json['message']?.toString();
    if (message != null && message.trim().isNotEmpty) return message;
    final text = json['text']?.toString();
    if (text != null && text.trim().isNotEmpty) return text;
    return null;
  }

  static void logEvent({
    required String eventType,
    int? conversationId,
    String? body,
  }) {
    AppLogger.info(
      eventLine(
        eventType: eventType,
        conversationId: conversationId,
        body: body,
      ),
      tag: tag,
    );
  }
}
