import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/utils/chat_unread_separator.dart';
import 'package:lgbtindernew/widgets/chat/chat_date_badge.dart';

void main() {
  group('ChatUnreadSeparator', () {
    test('does not insert when unread is 0', () {
      final items = [
        {'text': 'a', 'is_sent': false},
        {'text': 'b', 'is_sent': true},
      ];
      expect(
        ChatUnreadSeparator.insert(items: items, unreadCount: 0),
        items,
      );
    });

    test('unreadCountOfPeer reads the matching list row', () {
      expect(
        ChatUnreadSeparator.unreadCountOfPeer(
          peerUserId: 7,
          items: [
            (id: 3, unreadCount: 9),
            (id: 7, unreadCount: 4),
          ],
        ),
        4,
      );
      expect(
        ChatUnreadSeparator.unreadCountOfPeer(
          peerUserId: 1,
          items: [(id: 7, unreadCount: 4)],
        ),
        0,
      );
    });

    test('inserts before the first of the last N incoming', () {
      final items = [
        {'text': 'old', 'is_sent': false},
        {'text': 'mine', 'is_sent': true},
        {'text': 'in-1', 'is_sent': false},
        {'text': 'in-2', 'is_sent': false},
        {'text': 'in-3', 'is_sent': false},
      ];

      final out = ChatUnreadSeparator.insert(items: items, unreadCount: 2);

      expect(out.length, 6);
      expect(out[3]['kind'], ChatUnreadSeparator.kind);
      expect(out[3]['count'], 2);
      expect(out[3]['label'], '— 2 new messages —');
      expect(out[4]['text'], 'in-2');
      expect(out[5]['text'], 'in-3');
    });

    test('skips calls, date chips, and outgoing rows', () {
      final items = [
        {'kind': 'date_badge', 'label': 'Today'},
        {'kind': 'call', 'is_sent': false},
        {'text': 'mine', 'is_sent': true},
        {'text': 'in-a', 'is_sent': false},
        {'text': 'in-b', 'is_sent': false},
      ];

      final out = ChatUnreadSeparator.insert(items: items, unreadCount: 2);

      expect(out[3]['kind'], ChatUnreadSeparator.kind);
      expect(out[4]['text'], 'in-a');
      expect(out[5]['text'], 'in-b');
    });

    test('clamps the insert index when unread exceeds incoming', () {
      final items = [
        {'text': 'a', 'is_sent': false},
        {'text': 'b', 'is_sent': false},
      ];
      final out = ChatUnreadSeparator.insert(items: items, unreadCount: 9);
      expect(out[0]['kind'], ChatUnreadSeparator.kind);
      expect(out[0]['label'], '— 9 new messages —');
      expect(out[1]['text'], 'a');
    });

    test('label is singular for one unread', () {
      expect(ChatUnreadSeparator.labelForCount(1), '1 new message');
      expect(ChatUnreadSeparator.bannerLabel(1), '— 1 new message —');
    });

    test('sits after a date wrap on the first unread of the day', () {
      final now = DateTime(2026, 8, 21, 18);
      final wrapped = ChatDateBadgeInserter.wrap(
        [
          {
            'text': 'read',
            'is_sent': false,
            'timestamp': DateTime(2026, 8, 21, 10),
          },
          {
            'text': 'unread-a',
            'is_sent': false,
            'timestamp': DateTime(2026, 8, 21, 11),
          },
          {
            'text': 'unread-b',
            'is_sent': false,
            'timestamp': DateTime(2026, 8, 21, 12),
          },
        ],
        now: now,
      );

      final out = ChatUnreadSeparator.insert(items: wrapped, unreadCount: 2);
      expect(out[0]['kind'], ChatDateBadgeInserter.kind);
      expect(out[1]['text'], 'read');
      expect(out[2]['kind'], ChatUnreadSeparator.kind);
      expect(out[3]['text'], 'unread-a');
    });
  });
}
