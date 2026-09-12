import '../data/models/message.dart';
import '../data/models/message_delivery_status.dart';
import '../data/services/chat_outbound_queue_service.dart';

/// Outbox copy + timeline helpers (CHAT-OFFLINE-001).
class ChatOutboxUi {
  ChatOutboxUi._();

  static const String sendingQueuedLabel = 'Sending queued…';
  static const String queuedSemantics = 'Message queued';

  static Map<String, dynamic> toThreadRow(QueuedChatMessage queued) {
    return {
      'id': 0,
      'client_id': queued.clientId,
      'text': queued.message,
      'is_sent': true,
      'sender_id': queued.senderId,
      'timestamp': queued.createdAt,
      'is_read': false,
      'is_delivered': false,
      'type': queued.messageType,
      'delivery_status': MessageDeliveryStatus.queued,
      'kind': 'message',
    };
  }

  static List<Map<String, dynamic>> rowsForPeer(
    List<QueuedChatMessage> pending,
    int peerUserId,
  ) {
    return [
      for (final queued in pending)
        if (queued.receiverId == peerUserId) toThreadRow(queued),
    ];
  }

  static Map<String, dynamic> markStatus(
    Map<String, dynamic> row,
    String clientId,
    MessageDeliveryStatus status,
  ) {
    if (row['client_id']?.toString() != clientId) return row;
    return {...row, 'delivery_status': status};
  }

  static Map<String, dynamic> applySent(
    Map<String, dynamic> row,
    String clientId,
    Message sent,
  ) {
    if (row['client_id']?.toString() != clientId) return row;
    return {
      ...row,
      'id': sent.id,
      'text': sent.message.isNotEmpty ? sent.message : row['text'],
      'delivery_status': MessageDeliveryStatus.sent,
      'is_read': sent.isRead,
      'is_delivered': sent.isDelivered || sent.isRead,
      'timestamp': sent.createdAt,
      'conversation_id': sent.conversationId ?? row['conversation_id'],
      'client_id': clientId,
    };
  }
}
