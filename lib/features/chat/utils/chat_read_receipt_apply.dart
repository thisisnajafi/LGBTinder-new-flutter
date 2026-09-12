import '../../../core/constants/animation_constants.dart';
import 'chat_optimistic.dart';

/// Applies a Pusher `MessageRead` event onto the open thread (CHAT-RT-004).
class ChatReadReceiptApply {
  ChatReadReceiptApply._();

  static const Duration tickColorDuration = AppAnimations.receiptTick;

  static List<Map<String, dynamic>> apply({
    required List<Map<String, dynamic>> messages,
    required List<int> messageIds,
  }) {
    if (messageIds.isEmpty) return messages;
    return messages.map((msg) {
      if (msg['is_sent'] != true) return msg;
      final matches = messageIds.any(
        (id) => ChatOptimistic.sameMessageId(msg['id'], id),
      );
      if (!matches) return msg;
      return {
        ...msg,
        'is_read': true,
        'is_delivered': true,
      };
    }).toList();
  }
}

/// Applies a Pusher `MessageDelivered` event onto the open thread (CHAT-RT-005).
class ChatDeliveryReceiptApply {
  ChatDeliveryReceiptApply._();

  static List<Map<String, dynamic>> apply({
    required List<Map<String, dynamic>> messages,
    required List<int> messageIds,
  }) {
    if (messageIds.isEmpty) return messages;
    return messages.map((msg) {
      if (msg['is_sent'] != true) return msg;
      final matches = messageIds.any(
        (id) => ChatOptimistic.sameMessageId(msg['id'], id),
      );
      if (!matches) return msg;
      return {
        ...msg,
        'is_delivered': true,
      };
    }).toList();
  }
}
