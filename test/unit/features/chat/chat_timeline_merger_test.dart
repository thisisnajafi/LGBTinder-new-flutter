import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/utils/chat_timeline_merger.dart';

void main() {
  group('ChatTimelineMerger', () {
    test('merges messages and calls chronologically', () {
      final t1 = DateTime(2026, 5, 24, 10, 0);
      final t2 = DateTime(2026, 5, 24, 10, 5);
      final t3 = DateTime(2026, 5, 24, 10, 10);

      final result = ChatTimelineMerger.merge(
        messages: [
          {'id': 1, 'text': 'Hi', 'timestamp': t1},
          {'id': 2, 'text': 'Later', 'timestamp': t3},
        ],
        calls: [
          {'call_id': 99, 'timestamp': t2},
        ],
      );

      expect(result, hasLength(3));
      expect(result[0]['kind'], 'message');
      expect(result[1]['kind'], 'call');
      expect(result[2]['kind'], 'message');
    });

    test('deduplicates call entries by call_id', () {
      final t = DateTime(2026, 5, 24, 12);

      final result = ChatTimelineMerger.merge(
        messages: [],
        calls: [
          {'call_id': 5, 'timestamp': t},
          {'call_id': 5, 'timestamp': t.add(const Duration(seconds: 1))},
        ],
      );

      expect(result.where((e) => e['kind'] == 'call'), hasLength(1));
    });

    test('tags all items with kind', () {
      final result = ChatTimelineMerger.merge(
        messages: [
          {'id': 1, 'timestamp': DateTime(2026, 1, 1)},
        ],
        calls: [
          {'call_id': 2, 'timestamp': DateTime(2026, 1, 2)},
        ],
      );

      expect(result.every((e) => e['kind'] == 'message' || e['kind'] == 'call'), isTrue);
    });
  });
}
