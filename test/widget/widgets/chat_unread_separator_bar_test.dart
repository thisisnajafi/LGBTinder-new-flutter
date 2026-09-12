import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/features/chat/utils/chat_thread_scroll.dart';
import 'package:lgbtindernew/features/chat/utils/chat_unread_separator.dart';
import 'package:lgbtindernew/widgets/chat/chat_thread_list_view.dart';
import 'package:lgbtindernew/widgets/chat/chat_unread_separator_bar.dart';

void main() {
  testWidgets('unread bar uses muted labelSmall copy', (tester) async {
    final theme = AppTheme.lightTheme;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: ChatUnreadSeparatorBar(count: 3),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('— 3 new messages —'));
    expect(text.style?.fontSize, theme.textTheme.labelSmall?.fontSize);
    expect(text.style?.color, theme.colorScheme.onSurfaceVariant);
    expect(find.byType(Divider), findsNWidgets(2));
    expect(find.byIcon(Icons.mark_email_unread), findsNothing);
  });

  testWidgets('singular copy for one unread', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: ChatUnreadSeparatorBar(count: 1),
        ),
      ),
    );

    expect(find.text('— 1 new message —'), findsOneWidget);
  });

  testWidgets('reveal scrolls a reverse thread onto the unread bar',
      (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final separatorKey = GlobalKey();
    final items = <Map<String, dynamic>>[
      for (var i = 0; i < 20; i++)
        {'text': 'sent-$i', 'is_sent': true},
      for (var i = 0; i < 8; i++)
        {'text': 'in-$i', 'is_sent': false},
    ];
    final timeline = ChatUnreadSeparator.insert(
      items: items,
      unreadCount: 8,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SizedBox(
            height: 360,
            child: ChatThreadListView(
              controller: controller,
              itemCount: timeline.length,
              itemBuilder: (context, visualIndex) {
                final item = timeline[
                    ChatThreadScroll.chronologicalIndex(
                  timeline.length,
                  visualIndex,
                )];
                if (item['kind'] == ChatUnreadSeparator.kind) {
                  return ChatUnreadSeparatorBar(
                    key: separatorKey,
                    count: item['count'] as int,
                  );
                }
                return SizedBox(
                  height: 72,
                  child: Text(item['text'] as String),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(controller.position.pixels, ChatThreadScroll.latestPixels);

    final reveal = ChatUnreadSeparatorScroll.reveal(
      separatorKey: separatorKey,
      controller: controller,
      duration: Duration.zero,
    );
    for (var i = 0; i < 24; i++) {
      await tester.pump();
    }
    expect(await reveal, isTrue);
    expect(find.byKey(separatorKey), findsOneWidget);
    final bar = tester.getRect(find.byKey(separatorKey));
    final viewport = tester.getRect(find.byType(ChatThreadListView));
    expect(bar.overlaps(viewport), isTrue);
    expect(controller.position.pixels, greaterThan(0));
  });
}
