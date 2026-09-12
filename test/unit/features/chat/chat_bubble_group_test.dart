import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/theme/border_radius_constants.dart';
import 'package:lgbtindernew/features/chat/utils/chat_bubble_group.dart';
import 'package:lgbtindernew/features/chat/utils/chat_timeline_slots.dart';
import 'package:lgbtindernew/features/chat/utils/chat_unread_separator.dart';
import 'package:lgbtindernew/widgets/chat/chat_date_badge.dart';
import 'package:lgbtindernew/widgets/chat/message_bubble.dart';

void main() {
  test('only the last bubble in a same-sender run is tailed', () {
    final slots = ChatTimelineSlots.build(
      decoratedRows: [
        {'id': 1, 'client_id': 'a', 'is_sent': true, 'text': '1'},
        {'id': 2, 'client_id': 'b', 'is_sent': true, 'text': '2'},
        {'id': 3, 'client_id': 'c', 'is_sent': false, 'text': '3'},
      ],
    );
    final grouping = ChatBubbleGrouping.fromSlots(slots);

    expect(grouping['c-a'], const ChatBubbleGroup(
      isFirstInGroup: true,
      isLastInGroup: false,
    ));
    expect(grouping['c-b'], const ChatBubbleGroup(
      isFirstInGroup: false,
      isLastInGroup: true,
    ));
    expect(grouping['c-c']!.tailed, isTrue);
    expect(grouping['c-c']!.isFirstInGroup, isTrue);
  });

  test('date badges and unread bars break a sender run', () {
    final now = DateTime(2026, 9, 11, 12);
    final yesterday = DateTime(2026, 9, 10, 12);
    final slots = ChatTimelineSlots.build(
      decoratedRows: ChatUnreadSeparator.insert(
        items: ChatDateBadgeInserter.wrap(
          [
            {
              'id': 1,
              'client_id': 'a',
              'is_sent': false,
              'text': 'old',
              'timestamp': yesterday,
            },
            {
              'id': 2,
              'client_id': 'b',
              'is_sent': false,
              'text': 'new',
              'timestamp': now,
            },
          ],
          now: now,
        ),
        unreadCount: 1,
      ),
    );
    final grouping = ChatBubbleGrouping.fromSlots(slots);
    expect(grouping['c-a']!.tailed, isTrue);
    expect(grouping['c-b']!.tailed, isTrue);
  });

  test('tailed chrome uses a sharp outer corner, grouped uses full radius', () {
    final tailedSent = MessageBubbleChrome.radius(isSent: true);
    expect(tailedSent.bottomRight, Radius.zero);
    expect(tailedSent.bottomLeft, const Radius.circular(AppRadius.radiusLG));

    final groupedSent = MessageBubbleChrome.radius(isSent: true, tailed: false);
    expect(
      groupedSent.bottomRight,
      const Radius.circular(AppRadius.radiusLG),
    );

    final tailedReceived = MessageBubbleChrome.radius(isSent: false);
    expect(tailedReceived.bottomLeft, Radius.zero);
    expect(
      tailedReceived.bottomRight,
      const Radius.circular(AppRadius.radiusLG),
    );
  });
}
