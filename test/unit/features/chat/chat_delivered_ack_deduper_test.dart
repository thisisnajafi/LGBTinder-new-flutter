import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/utils/chat_delivered_ack_deduper.dart';

void main() {
  test('take returns only new positive ids', () {
    final deduper = ChatDeliveredAckDeduper();

    expect(deduper.take(const [1, 1, 0, -4, 2]), [1, 2]);
    expect(deduper.take(const [1, 2, 3]), [3]);
    expect(deduper.contains(1), isTrue);
    expect(deduper.contains(3), isTrue);
  });

  test('release allows a later retry of the same ids', () {
    final deduper = ChatDeliveredAckDeduper();

    expect(deduper.take(const [10, 11]), [10, 11]);
    deduper.release(const [10]);
    expect(deduper.take(const [10, 11]), [10]);
  });
}
