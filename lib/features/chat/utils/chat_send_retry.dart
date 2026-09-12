import '../data/models/message_delivery_status.dart';
import 'chat_delivery_status_map.dart';

/// Max-3 send retries then a locked failed bubble (CHAT-OFFLINE-003).
class ChatSendRetry {
  ChatSendRetry._();

  static const int maxAttempts = 3;
  static const String countKey = 'send_retry_count';
  static const String retryLabel = 'Retry';
  static const String lockedLabel = 'Failed to send';

  static int count(Map<String, dynamic> message) {
    final raw = message[countKey];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static bool canRetry(Map<String, dynamic> message) {
    if (ChatDeliveryStatusMap.fromMap(message) !=
        MessageDeliveryStatus.failed) {
      return false;
    }
    return count(message) < maxAttempts;
  }

  static bool isLocked(Map<String, dynamic> message) {
    return ChatDeliveryStatusMap.fromMap(message) ==
            MessageDeliveryStatus.failed &&
        count(message) >= maxAttempts;
  }

  static String? labelFor(MessageDeliveryStatus status, {required bool canRetry}) {
    if (status != MessageDeliveryStatus.failed) return null;
    return canRetry ? retryLabel : lockedLabel;
  }

  static Map<String, dynamic> markFailed(Map<String, dynamic> message) {
    return {
      ...message,
      'delivery_status': MessageDeliveryStatus.failed,
      countKey: count(message) + 1,
    };
  }
}
