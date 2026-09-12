import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/widgets/chat/chat_swipe_to_reply.dart';

void main() {
  testWidgets('swipe past 60px toward center starts a reply', (tester) async {
    var replies = 0;
    await _host(tester, isSent: true, onReply: () => replies++);

    await tester.drag(find.text('bubble'), const Offset(-100, 0));
    await tester.pumpAndSettle();

    expect(replies, 1);
  });

  testWidgets('sub-threshold swipe snaps back without replying',
      (tester) async {
    var replies = 0;
    await _host(tester, isSent: true, onReply: () => replies++);

    await tester.drag(find.text('bubble'), const Offset(-30, 0));
    await tester.pumpAndSettle();

    expect(replies, 0);
  });

  testWidgets('sent bubbles ignore a swipe away from center', (tester) async {
    var replies = 0;
    await _host(tester, isSent: true, onReply: () => replies++);

    await tester.drag(find.text('bubble'), const Offset(100, 0));
    await tester.pumpAndSettle();

    expect(replies, 0);
  });

  testWidgets('received bubbles reply when swiped right', (tester) async {
    var replies = 0;
    await _host(tester, isSent: false, onReply: () => replies++);

    await tester.drag(find.text('bubble'), const Offset(100, 0));
    await tester.pumpAndSettle();

    expect(replies, 1);
  });

  testWidgets('Reduce Motion still replies and uses the reply SVG',
      (tester) async {
    var replies = 0;
    await _host(
      tester,
      isSent: true,
      reduceMotion: true,
      onReply: () => replies++,
    );

    expect(
      tester.widget<AppSvgIcon>(find.byType(AppSvgIcon)).assetPath,
      AppIcons.reply,
    );
    expect(find.byType(Icon), findsNothing);

    await tester.drag(find.text('bubble'), const Offset(-100, 0));
    await tester.pumpAndSettle();
    expect(replies, 1);
  });
}

Future<void> _host(
  WidgetTester tester, {
  required bool isSent,
  required VoidCallback onReply,
  bool reduceMotion = false,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      builder: reduceMotion
          ? (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              );
            }
          : null,
      home: Scaffold(
        body: Center(
          child: ChatSwipeToReply(
            isSent: isSent,
            onReply: onReply,
            child: const SizedBox(
              width: 220,
              height: 72,
              child: Center(child: Text('bubble')),
            ),
          ),
        ),
      ),
    ),
  );
}
