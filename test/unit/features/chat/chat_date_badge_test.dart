import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/widgets/chat/chat_date_badge.dart';
import 'package:lgbtindernew/widgets/chat/chat_sticky_date_header.dart';

void main() {
  group('ChatDateBadgeInserter', () {
    test('inserts a date pill when the calendar day changes', () {
      final now = DateTime(2026, 8, 21, 18);
      final items = [
        {
          'kind': 'message',
          'text': 'yesterday',
          'timestamp': DateTime(2026, 8, 20, 10),
        },
        {
          'kind': 'message',
          'text': 'today a',
          'timestamp': DateTime(2026, 8, 21, 11),
        },
        {
          'kind': 'message',
          'text': 'today b',
          'timestamp': DateTime(2026, 8, 21, 12),
        },
      ];

      final wrapped = ChatDateBadgeInserter.wrap(items, now: now);

      expect(wrapped.length, 5);
      expect(wrapped[0]['kind'], ChatDateBadgeInserter.kind);
      expect(wrapped[0]['label'], 'Yesterday');
      expect(wrapped[1]['text'], 'yesterday');
      expect(wrapped[2]['kind'], ChatDateBadgeInserter.kind);
      expect(wrapped[2]['label'], 'Today');
      expect(wrapped[3]['text'], 'today a');
      expect(wrapped[4]['text'], 'today b');
    });

    test('labelForChronologicalIndex walks back to the day pill', () {
      final now = DateTime(2026, 8, 21, 18);
      final wrapped = ChatDateBadgeInserter.wrap(
        [
          {
            'kind': 'message',
            'text': 'yesterday',
            'timestamp': DateTime(2026, 8, 20, 10),
          },
          {
            'kind': 'message',
            'text': 'today',
            'timestamp': DateTime(2026, 8, 21, 11),
          },
        ],
        now: now,
      );

      expect(ChatStickyDate.labelForChronologicalIndex(wrapped, 1), 'Yesterday');
      expect(ChatStickyDate.labelForChronologicalIndex(wrapped, 3), 'Today');
    });
  });
}
