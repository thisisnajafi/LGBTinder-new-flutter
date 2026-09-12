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

    test('later missed status wins over a duplicate call_id', () {
      final t = DateTime(2026, 5, 24, 12);

      final result = ChatTimelineMerger.merge(
        messages: [],
        calls: [
          {'call_id': 5, 'status': 'ringing', 'timestamp': t},
          {'call_id': 5, 'status': 'missed', 'timestamp': t.add(const Duration(seconds: 1))},
        ],
      );

      expect(result.where((e) => e['kind'] == 'call'), hasLength(1));
      expect(result.single['status'], 'missed');
    });

    test('deduplicates messages by server id and client_id', () {
      final t = DateTime(2026, 5, 24, 12);

      final result = ChatTimelineMerger.merge(
        messages: [
          {'id': 0, 'client_id': 'temp-1', 'text': 'Hi', 'timestamp': t},
          {'id': 9, 'client_id': 'temp-1', 'text': 'Hi', 'timestamp': t},
          {'id': 9, 'text': 'Hi edited', 'timestamp': t, 'is_edited': true},
        ],
        calls: [],
      );

      expect(result, hasLength(1));
      expect(result.single['id'], 9);
      expect(result.single['text'], 'Hi edited');
      expect(result.single['client_id'], 'temp-1');
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

    test('same-second messages sort by id, not arrival order', () {
      final t = DateTime(2026, 8, 19, 1, 18);

      final result = ChatTimelineMerger.sortChronologically([
        {'id': 5, 'text': '5', 'timestamp': t},
        {'id': 1, 'text': '1', 'timestamp': t},
        {'id': 9, 'text': '9', 'timestamp': t},
        {'id': 2, 'text': '2', 'timestamp': t},
      ]);

      expect(result.map((item) => item['text']), ['1', '2', '5', '9']);
    });

    test('optimistic messages stay after persisted ones at the same time', () {
      final t = DateTime(2026, 8, 19, 1, 18);

      final result = ChatTimelineMerger.sortChronologically([
        {'id': 0, 'text': 'sending', 'timestamp': t},
        {'id': 12, 'text': 'sent', 'timestamp': t},
      ]);

      expect(result.map((item) => item['text']), ['sent', 'sending']);
    });

    test('keeps in-flight optimistic rows the server history does not yet include', () {
      final t = DateTime(2026, 8, 22, 2, 0);
      final merged = ChatTimelineMerger.withInFlightOptimistic(
        serverTimeline: [
          {'id': 1, 'text': 'hi', 'timestamp': t, 'kind': 'message'},
        ],
        previous: [
          {
            'id': 0,
            'client_id': 'local_1',
            'text': 'pending',
            'timestamp': t.add(const Duration(seconds: 1)),
            'delivery_status': 'sending',
          },
        ],
      );

      expect(merged, hasLength(2));
      expect(merged.last['client_id'], 'local_1');
    });

    test('drops in-flight rows once the server id is present', () {
      final t = DateTime(2026, 8, 22, 2, 0);
      final merged = ChatTimelineMerger.withInFlightOptimistic(
        serverTimeline: [
          {
            'id': 44,
            'client_id': 'local_1',
            'text': 'pending',
            'timestamp': t,
            'kind': 'message',
          },
        ],
        previous: [
          {
            'id': 0,
            'client_id': 'local_1',
            'text': 'pending',
            'timestamp': t,
            'delivery_status': 'failed',
          },
        ],
      );

      expect(merged, hasLength(1));
      expect(merged.first['id'], 44);
    });
  });
}
