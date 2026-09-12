import '../data/models/message_delivery_status.dart';

/// Reads optimistic delivery from a timeline row map.
class ChatDeliveryStatusMap {
  const ChatDeliveryStatusMap._();

  static MessageDeliveryStatus fromMap(Map<String, dynamic> msg) {
    final raw = msg['delivery_status'];
    if (raw is MessageDeliveryStatus) return raw;
    if (raw is String) {
      switch (raw) {
        case 'sending':
          return MessageDeliveryStatus.sending;
        case 'failed':
          return MessageDeliveryStatus.failed;
        case 'queued':
          return MessageDeliveryStatus.queued;
        default:
          return MessageDeliveryStatus.sent;
      }
    }
    if (msg['is_sending'] == true) return MessageDeliveryStatus.sending;
    return MessageDeliveryStatus.sent;
  }
}
