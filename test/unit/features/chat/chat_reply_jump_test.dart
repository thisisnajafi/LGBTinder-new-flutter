import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/utils/chat_reply_jump.dart';
import 'package:lgbtindernew/features/chat/utils/chat_thread_scroll.dart';
import 'package:lgbtindernew/features/chat/utils/chat_timeline_slots.dart';

void main() {
  test('replyToId reads positive server ids only', () {
    expect(ChatReplyJump.replyToId({'reply_to_message_id': 12}), 12);
    expect(ChatReplyJump.replyToId({'reply_to_message_id': '9'}), 9);
    expect(ChatReplyJump.replyToId({'reply_to_message_id': 0}), isNull);
    expect(ChatReplyJump.replyToId({'reply_to_message_id': null}), isNull);
  });

  test('visualIndex maps chronological storage onto the reverse list', () {
    final slots = ChatTimelineSlots.build(
      decoratedRows: [
        {'id': 1, 'client_id': 'a', 'text': 'old'},
        {'id': 2, 'client_id': 'b', 'text': 'new'},
      ],
    );
    expect(slots, hasLength(2));
    expect(
      ChatReplyJump.visualIndex(slots: slots, rowKey: 'c-a'),
      ChatThreadScroll.chronologicalIndex(2, 0),
    );
    expect(
      ChatReplyJump.visualIndex(slots: slots, rowKey: 'c-b'),
      0,
    );
    expect(
      ChatReplyJump.estimatedPixels(
        slots: slots,
        rowKey: 'c-b',
        maxScrollExtent: 400,
      ),
      ChatThreadScroll.latestPixels,
    );
    expect(
      ChatReplyJump.estimatedPixels(
        slots: slots,
        rowKey: 'c-a',
        maxScrollExtent: 400,
      ),
      400,
    );
  });

  testWidgets('ensureVisible jumps to the anchored original', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          );
        },
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 900, child: Text('above')),
                SizedBox(
                  key: ChatReplyJump.anchorKey(42),
                  height: 80,
                  child: const Text('original-42'),
                ),
                const SizedBox(height: 900, child: Text('below')),
              ],
            ),
          ),
        ),
      ),
    );

    final jumped = await ChatReplyJump.ensureVisible(
      42,
      context: tester.element(find.text('above')),
    );
    expect(jumped, isTrue);
    expect(find.text('original-42'), findsOneWidget);
  });

  testWidgets('ensureVisible is false when the original is missing',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Text('empty')),
      ),
    );
    final jumped = await ChatReplyJump.ensureVisible(
      99,
      context: tester.element(find.text('empty')),
    );
    expect(jumped, isFalse);
  });

  test('shouldKeepPaginating stops on found, fail, empty, or max pages', () {
    expect(ChatReplyJump.maxHistoryPages, 12);
    expect(ChatReplyJump.searchingMessage, isNotEmpty);
    expect(
      ChatReplyJump.shouldKeepPaginating(
        found: false,
        hasMore: true,
        loadFailed: false,
        pagesLoaded: 0,
      ),
      isTrue,
    );
    expect(
      ChatReplyJump.shouldKeepPaginating(
        found: true,
        hasMore: true,
        loadFailed: false,
        pagesLoaded: 1,
      ),
      isFalse,
    );
    expect(
      ChatReplyJump.shouldKeepPaginating(
        found: false,
        hasMore: false,
        loadFailed: false,
        pagesLoaded: 1,
      ),
      isFalse,
    );
    expect(
      ChatReplyJump.shouldKeepPaginating(
        found: false,
        hasMore: true,
        loadFailed: true,
        pagesLoaded: 1,
      ),
      isFalse,
    );
    expect(
      ChatReplyJump.shouldKeepPaginating(
        found: false,
        hasMore: true,
        loadFailed: false,
        pagesLoaded: 3,
        emptyPage: true,
      ),
      isFalse,
    );
    expect(
      ChatReplyJump.shouldKeepPaginating(
        found: false,
        hasMore: true,
        loadFailed: false,
        pagesLoaded: ChatReplyJump.maxHistoryPages,
      ),
      isFalse,
    );
  });
}
