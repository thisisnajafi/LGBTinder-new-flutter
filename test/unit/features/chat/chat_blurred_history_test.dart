import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/chat/utils/chat_timeline_slots.dart';

void main() {
  test('repeated blurred rows collapse to one upgrade slot at the top', () {
    final rows = [
      {'id': 1, 'is_blurred': true, 'is_sent': false},
      {'id': 2, 'is_blurred': true, 'is_sent': false},
      {'id': 3, 'is_blurred': false, 'is_sent': true, 'client_id': 'c-new'},
    ];

    final history = ChatTimelineSlots.droppingBlurred(rows);
    expect(history.collapsed, isTrue);
    expect(history.rows, hasLength(1));

    final slots = ChatTimelineSlots.build(
      decoratedRows: history.rows,
      prependOlderUpgrade: history.collapsed,
    );

    expect(slots.first.kind, ChatTimelineSlotKind.upgradeOlder);
    expect(slots.first.key, ChatTimelineSlots.upgradeOlderKey);
    expect(slots.where((slot) => slot.kind == ChatTimelineSlotKind.message), hasLength(1));
    expect(slots.last.key, 'c-c-new');
  });

  test('a thread with no blurred rows keeps every message', () {
    final rows = [
      {'id': 4, 'is_sent': true, 'client_id': 'c-a'},
      {'id': 5, 'is_blurred': false, 'is_sent': false, 'client_id': 'c-b'},
    ];

    final history = ChatTimelineSlots.droppingBlurred(rows);
    expect(history.collapsed, isFalse);
    expect(history.rows, rows);

    final slots = ChatTimelineSlots.build(decoratedRows: history.rows);
    expect(slots.every((slot) => slot.kind == ChatTimelineSlotKind.message), isTrue);
    expect(slots, hasLength(2));
  });
}
