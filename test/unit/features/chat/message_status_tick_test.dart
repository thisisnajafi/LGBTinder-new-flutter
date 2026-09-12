import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/data/models/message_delivery_status.dart';
import 'package:lgbtindernew/widgets/chat/message_status_indicator.dart';

void main() {
  group('MessageStatusTick.resolve', () {
    test('queued and sending map to sending', () {
      expect(
        MessageStatusTick.resolve(
          deliveryStatus: MessageDeliveryStatus.sending,
          isRead: false,
          isDelivered: false,
        ),
        MessageReadState.sending,
      );
      expect(
        MessageStatusTick.resolve(
          deliveryStatus: MessageDeliveryStatus.queued,
          isRead: true,
          isDelivered: true,
        ),
        MessageReadState.sending,
      );
    });

    test('failed wins over delivered flags', () {
      expect(
        MessageStatusTick.resolve(
          deliveryStatus: MessageDeliveryStatus.failed,
          isRead: true,
          isDelivered: true,
        ),
        MessageReadState.failed,
      );
    });

    test('read beats delivered beats sent', () {
      expect(
        MessageStatusTick.resolve(
          deliveryStatus: MessageDeliveryStatus.sent,
          isRead: true,
          isDelivered: true,
        ),
        MessageReadState.read,
      );
      expect(
        MessageStatusTick.resolve(
          deliveryStatus: MessageDeliveryStatus.sent,
          isRead: false,
          isDelivered: true,
        ),
        MessageReadState.delivered,
      );
      expect(
        MessageStatusTick.resolve(
          deliveryStatus: MessageDeliveryStatus.sent,
          isRead: false,
          isDelivered: false,
        ),
        MessageReadState.sent,
      );
    });
  });

  group('MessageStatusTick.shouldPulse', () {
    test('pulses once per delivered/read upgrade', () {
      expect(
        MessageStatusTick.shouldPulse(
          MessageReadState.sent,
          MessageReadState.delivered,
        ),
        isTrue,
      );
      expect(
        MessageStatusTick.shouldPulse(
          MessageReadState.delivered,
          MessageReadState.read,
        ),
        isTrue,
      );
      expect(
        MessageStatusTick.shouldPulse(
          MessageReadState.sent,
          MessageReadState.read,
        ),
        isTrue,
      );
      expect(
        MessageStatusTick.shouldPulse(
          MessageReadState.sending,
          MessageReadState.delivered,
        ),
        isTrue,
      );
    });

    test('does not pulse sending, failed, or same-state rebuilds', () {
      expect(
        MessageStatusTick.shouldPulse(
          MessageReadState.sending,
          MessageReadState.sent,
        ),
        isFalse,
      );
      expect(
        MessageStatusTick.shouldPulse(
          MessageReadState.failed,
          MessageReadState.sent,
        ),
        isFalse,
      );
      expect(
        MessageStatusTick.shouldPulse(
          MessageReadState.read,
          MessageReadState.read,
        ),
        isFalse,
      );
      expect(
        MessageStatusTick.shouldPulse(
          MessageReadState.read,
          MessageReadState.delivered,
        ),
        isFalse,
      );
    });
  });
}
