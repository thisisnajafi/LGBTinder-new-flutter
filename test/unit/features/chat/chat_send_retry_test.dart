import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/data/models/message_delivery_status.dart';
import 'package:lgbtindernew/features/chat/utils/chat_send_retry.dart';

void main() {
  Map<String, dynamic> row({int count = 0}) => {
        'client_id': 'local_1',
        'delivery_status': MessageDeliveryStatus.failed,
        ChatSendRetry.countKey: count,
      };

  test('three failures lock the bubble', () {
    var message = <String, dynamic>{
      'client_id': 'local_1',
      'delivery_status': MessageDeliveryStatus.sending,
    };
    message = ChatSendRetry.markFailed(message);
    expect(ChatSendRetry.canRetry(message), isTrue);
    expect(ChatSendRetry.count(message), 1);

    message = ChatSendRetry.markFailed(message);
    expect(ChatSendRetry.canRetry(message), isTrue);

    message = ChatSendRetry.markFailed(message);
    expect(ChatSendRetry.count(message), 3);
    expect(ChatSendRetry.canRetry(message), isFalse);
    expect(ChatSendRetry.isLocked(message), isTrue);
    expect(
      ChatSendRetry.labelFor(
        MessageDeliveryStatus.failed,
        canRetry: false,
      ),
      ChatSendRetry.lockedLabel,
    );
  });

  test('tap is allowed while under the max', () {
    expect(ChatSendRetry.canRetry(row(count: 2)), isTrue);
    expect(
      ChatSendRetry.labelFor(
        MessageDeliveryStatus.failed,
        canRetry: true,
      ),
      ChatSendRetry.retryLabel,
    );
  });
}
