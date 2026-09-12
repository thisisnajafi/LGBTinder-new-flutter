import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/features/chat/utils/chat_read_receipt_apply.dart';

void main() {
  test('MessageRead matches string ids and marks sent rows read+delivered', () {
    final next = ChatReadReceiptApply.apply(
      messages: [
        {
          'id': '10',
          'is_sent': true,
          'is_read': false,
          'is_delivered': true,
        },
        {
          'id': 11,
          'is_sent': true,
          'is_read': false,
          'is_delivered': false,
        },
        {
          'id': 12,
          'is_sent': false,
          'is_read': false,
        },
      ],
      messageIds: const [10, 12],
    );

    expect(next[0]['is_read'], isTrue);
    expect(next[0]['is_delivered'], isTrue);
    expect(next[1]['is_read'], isFalse);
    expect(next[2]['is_read'], isFalse);
  });

  test('empty message id list leaves the thread unchanged', () {
    final messages = [
      {'id': 1, 'is_sent': true, 'is_read': false},
    ];
    expect(
      ChatReadReceiptApply.apply(messages: messages, messageIds: const []),
      same(messages),
    );
  });

  test('MessageDelivered matches string ids and does not mark read', () {
    final next = ChatDeliveryReceiptApply.apply(
      messages: [
        {
          'id': '10',
          'is_sent': true,
          'is_read': false,
          'is_delivered': false,
        },
        {
          'id': 11,
          'is_sent': true,
          'is_read': true,
          'is_delivered': true,
        },
        {
          'id': 12,
          'is_sent': false,
          'is_read': false,
          'is_delivered': false,
        },
      ],
      messageIds: const [10, 12],
    );

    expect(next[0]['is_delivered'], isTrue);
    expect(next[0]['is_read'], isFalse);
    expect(next[1]['is_read'], isTrue);
    expect(next[2]['is_delivered'], isFalse);
  });

  test('empty delivered id list leaves the thread unchanged', () {
    final messages = [
      {'id': 1, 'is_sent': true, 'is_delivered': false},
    ];
    expect(
      ChatDeliveryReceiptApply.apply(messages: messages, messageIds: const []),
      same(messages),
    );
  });

  test('tick color duration is 300ms', () {
    expect(
      ChatReadReceiptApply.tickColorDuration,
      AppAnimations.receiptTick,
    );
    expect(AppAnimations.receiptTick, const Duration(milliseconds: 300));
  });
}
