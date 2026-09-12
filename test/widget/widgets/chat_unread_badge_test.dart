import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/widgets/chat/chat_unread_badge.dart';

void main() {
  test('unread labels cap at 99+', () {
    expect(ChatUnreadBadge.labelFor(1), '1');
    expect(ChatUnreadBadge.labelFor(99), '99');
    expect(ChatUnreadBadge.labelFor(100), '99+');
    expect(ChatUnreadBadge.labelFor(250), '99+');
  });

  testWidgets('count change keeps the 99+ cap and animates 250ms',
      (tester) async {
    var count = 3;
    late void Function(void Function()) setCount;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              setCount = setState;
              return ChatUnreadBadge(count: count);
            },
          ),
        ),
      ),
    );
    expect(find.text('3'), findsOneWidget);

    setCount(() => count = 100);
    await tester.pump();
    expect(find.text('99+'), findsOneWidget);
    expect(
      tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration,
      AppAnimations.chatUnreadBadge,
    );
  });

  testWidgets('Reduce Motion uses Duration.zero', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          );
        },
        home: const Scaffold(
          body: ChatUnreadBadge(count: 2),
        ),
      ),
    );
    expect(
      tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration,
      Duration.zero,
    );
  });
}
