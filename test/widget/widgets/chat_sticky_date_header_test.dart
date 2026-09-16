import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/theme/app_colors.dart';
import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/features/chat/utils/chat_thread_scroll.dart';
import 'package:lgbtindernew/widgets/chat/chat_date_badge.dart';
import 'package:lgbtindernew/widgets/chat/chat_sticky_date_header.dart';
import 'package:lgbtindernew/widgets/chat/chat_thread_list_view.dart';

void main() {
  testWidgets('ChatDateBadge uses textTheme.labelSmall', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: ChatDateBadge(label: 'Today')),
      ),
    );

    final text = tester.widget<Text>(find.text('Today'));
    expect(
      text.style?.fontSize,
      AppTheme.lightTheme.textTheme.labelSmall?.fontSize,
    );
    expect(text.style?.color, AppColors.textPrimaryLight);

    final decoration = tester
        .widget<Container>(
          find.descendant(
            of: find.byType(ChatDateBadge),
            matching: find.byType(Container),
          ),
        )
        .decoration as BoxDecoration;
    expect(decoration.color, AppColors.surfaceElevatedLight);
    expect(decoration.color, isNot(AppColors.surfaceElevatedDark));
  });

  testWidgets('ChatDateBadge is readable in dark mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(body: ChatDateBadge(label: 'Today')),
      ),
    );

    final text = tester.widget<Text>(find.text('Today'));
    expect(text.style?.color, AppColors.textPrimaryDark);

    final decoration = tester
        .widget<Container>(
          find.descendant(
            of: find.byType(ChatDateBadge),
            matching: find.byType(Container),
          ),
        )
        .decoration as BoxDecoration;
    expect(decoration.color, AppColors.surfaceElevatedDark.withValues(alpha: 0.88));
  });

  testWidgets('sticky chip follows the day at the top of a reverse thread',
      (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final listKey = GlobalKey();
    final now = DateTime(2026, 8, 21, 18);
    final items = <Map<String, dynamic>>[
      {
        'kind': 'message',
        'text': 'yesterday-1',
        'timestamp': DateTime(2026, 8, 20, 10),
      },
      {
        'kind': 'message',
        'text': 'yesterday-2',
        'timestamp': DateTime(2026, 8, 20, 11),
      },
      for (var i = 0; i < 8; i++)
        {
          'kind': 'message',
          'text': 'today-$i',
          'timestamp': DateTime(2026, 8, 21, 12, i),
        },
    ];
    final timeline = ChatDateBadgeInserter.wrap(items, now: now);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SizedBox(
            height: 400,
            child: Stack(
              children: [
                ChatThreadListView(
                  key: listKey,
                  controller: controller,
                  itemCount: timeline.length,
                  itemBuilder: (context, visualIndex) {
                    final item = timeline[
                        ChatThreadScroll.chronologicalIndex(
                      timeline.length,
                      visualIndex,
                    )];
                    if (item['kind'] == ChatDateBadgeInserter.kind) {
                      return const SizedBox(height: 0);
                    }
                    return SizedBox(
                      height: 80,
                      child: Text(item['text'] as String),
                    );
                  },
                ),
                ChatStickyDateHeader(
                  controller: controller,
                  timeline: timeline,
                  listKey: listKey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final sticky = find.byKey(const ValueKey('chat-sticky-date'));
    expect(sticky, findsOneWidget);
    expect(
      tester.widget<ChatDateBadge>(sticky).label,
      'Today',
    );

    controller.jumpTo(120);
    await tester.pump();
    await tester.pump();
    expect(
      tester.widget<ChatDateBadge>(sticky).label,
      'Today',
    );

    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();
    await tester.pump();

    expect(
      tester.widget<ChatDateBadge>(sticky).label,
      'Yesterday',
    );
  });

  testWidgets('short reverse thread pins the day under the header, not mid-list',
      (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final listKey = GlobalKey();
    final now = DateTime(2026, 9, 16, 18);
    final timeline = ChatDateBadgeInserter.wrap(
      [
        {
          'kind': 'message',
          'text': 'hello',
          'timestamp': DateTime(2026, 9, 5, 11),
        },
        {
          'kind': 'message',
          'text': 'there',
          'timestamp': DateTime(2026, 9, 5, 12),
        },
      ],
      now: now,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SizedBox(
            height: 400,
            child: Stack(
              key: const ValueKey('chat-thread-stack'),
              children: [
                ChatThreadListView(
                  key: listKey,
                  controller: controller,
                  itemCount: timeline.length,
                  itemBuilder: (context, visualIndex) {
                    final item = timeline[
                        ChatThreadScroll.chronologicalIndex(
                      timeline.length,
                      visualIndex,
                    )];
                    if (item['kind'] == ChatDateBadgeInserter.kind) {
                      return const SizedBox(height: 0);
                    }
                    return SizedBox(
                      height: 56,
                      child: Text(item['text'] as String),
                    );
                  },
                ),
                ChatStickyDateHeader(
                  controller: controller,
                  timeline: timeline,
                  listKey: listKey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final sticky = find.byKey(const ValueKey('chat-sticky-date'));
    expect(sticky, findsOneWidget);
    expect(tester.widget<ChatDateBadge>(sticky).label, '5 Sep');
    expect(find.text('5 Sep'), findsOneWidget);

    final stack = find.byKey(const ValueKey('chat-thread-stack'));
    final stackTop = tester.getTopLeft(stack).dy;
    final stickyTop = tester.getTopLeft(sticky).dy;
    final stickyCenter = tester.getCenter(sticky).dy;
    final stackCenter = tester.getCenter(stack).dy;
    expect(stickyTop - stackTop, lessThan(24));
    expect(stickyCenter, lessThan(stackCenter - 80));
  });
}
