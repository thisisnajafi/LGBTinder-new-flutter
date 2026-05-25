/// Outbound message delivery state for optimistic UI updates.
enum MessageDeliveryStatus {
  sending,
  queued,
  sent,
  failed,
}

extension MessageDeliveryStatusX on MessageDeliveryStatus {
  bool get isSending => this == MessageDeliveryStatus.sending;
  bool get isQueued => this == MessageDeliveryStatus.queued;
  bool get isFailed => this == MessageDeliveryStatus.failed;
  bool get isSent => this == MessageDeliveryStatus.sent;
}
