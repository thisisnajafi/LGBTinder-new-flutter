import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

    expect(
      grouping['c-a'],
      const ChatBubbleGroup(isFirstInGroup: true, isLastInGroup: false),
    );
    expect(
      grouping['c-b'],
      const ChatBubbleGroup(isFirstInGroup: false, isLastInGroup: true),
    );
    expect(grouping['c-c']!.tailed, isTrue);
    expect(grouping['c-c']!.isFirstInGroup, isTrue);
  });

  test('date badges and unread bars break a sender run', () {
    final now = DateTime(2026, 9, 11, 12);
    final yesterday = DateTime(2026, 9, 10, 12);
    final slots = ChatTimelineSlots.build(
      decoratedRows: ChatUnreadSeparator.insert(
        items: ChatDateBadgeInserter.wrap([
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
        ], now: now),
        unreadCount: 1,
      ),
    );
    final grouping = ChatBubbleGrouping.fromSlots(slots);
    expect(grouping['c-a']!.tailed, isTrue);
    expect(grouping['c-b']!.tailed, isTrue);
  });

  test('grouped chrome: large outer corners, tight inner, tail on last', () {
    const ltr = TextDirection.ltr;
    final single = MessageBubbleChrome.radius(isSent: true).resolve(ltr);
    expect(
      single.topRight,
      const Radius.circular(MessageBubbleChrome.radiusLarge),
    );
    expect(
      single.bottomRight,
      const Radius.circular(MessageBubbleChrome.radiusTail),
    );
    expect(
      single.bottomLeft,
      const Radius.circular(MessageBubbleChrome.radiusLarge),
    );

    final middle = MessageBubbleChrome.radius(
      isSent: true,
      isFirstInGroup: false,
      isLastInGroup: false,
    ).resolve(ltr);
    expect(
      middle.topRight,
      const Radius.circular(MessageBubbleChrome.radiusInner),
    );
    expect(
      middle.bottomRight,
      const Radius.circular(MessageBubbleChrome.radiusInner),
    );
    expect(
      middle.topLeft,
      const Radius.circular(MessageBubbleChrome.radiusLarge),
    );

    final received = MessageBubbleChrome.radius(isSent: false).resolve(ltr);
    expect(
      received.bottomLeft,
      const Radius.circular(MessageBubbleChrome.radiusTail),
    );
    expect(
      received.bottomRight,
      const Radius.circular(MessageBubbleChrome.radiusLarge),
    );

    // RTL mirrors the tail to the other side.
    final rtl = MessageBubbleChrome.radius(
      isSent: true,
    ).resolve(TextDirection.rtl);
    expect(
      rtl.bottomLeft,
      const Radius.circular(MessageBubbleChrome.radiusTail),
    );
  });

  test('margin: small gap inside a run, larger when sender changes', () {
    expect(
      MessageBubbleChrome.margin(isSent: true, isLastInGroup: false).bottom,
      MessageBubbleChrome.gapSameSender,
    );
    expect(
      MessageBubbleChrome.margin(isSent: true).bottom,
      MessageBubbleChrome.gapSenderChange,
    );
    expect(MessageBubbleChrome.margin(isSent: false).top, 0);
  });
}
