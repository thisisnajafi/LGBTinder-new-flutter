import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/widgets/chat/message_reply_widget.dart';

void main() {
  Widget host({
    String? name,
    String? message,
    VoidCallback? onCancel,
    bool reduceMotion = false,
  }) {
    return MaterialApp(
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
        body: MessageReplyWidget(
          repliedToName: name,
          repliedToMessage: message,
          onCancel: onCancel ?? () {},
        ),
      ),
    );
  }

  Size previewSize(WidgetTester tester) {
    return tester.getSize(find.byKey(const ValueKey('chat-reply-preview')));
  }

  testWidgets('slides in from height 0 to 56', (tester) async {
    await tester.pumpWidget(host());
    expect(previewSize(tester).height, 0);

    await tester.pumpWidget(host(name: 'Alex', message: 'Hello'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final mid = previewSize(tester).height;
    expect(mid, greaterThan(0));
    expect(mid, lessThan(AppAnimations.chatReplyPreviewHeight));

    await tester.pumpAndSettle();
    expect(previewSize(tester).height, AppAnimations.chatReplyPreviewHeight);
    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('slides out when preview is cleared', (tester) async {
    await tester.pumpWidget(host(name: 'You', message: 'Hi'));
    await tester.pumpAndSettle();
    expect(previewSize(tester).height, AppAnimations.chatReplyPreviewHeight);

    await tester.pumpWidget(host());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(previewSize(tester).height, greaterThan(0));
    expect(find.text('You'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(previewSize(tester).height, 0);
  });

  testWidgets('Reduce Motion snaps height with no Icons.close', (tester) async {
    await tester.pumpWidget(
      host(name: 'Sam', message: 'Photo', reduceMotion: true),
    );
    await tester.pump();

    expect(previewSize(tester).height, AppAnimations.chatReplyPreviewHeight);
    expect(find.byIcon(Icons.close), findsNothing);
    expect(
      tester.widget<AppSvgIcon>(find.byType(AppSvgIcon)).assetPath,
      AppIcons.close,
    );

    final bar = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('chat-reply-preview')),
    );
    expect(bar.duration, Duration.zero);
  });

  testWidgets('close button clears via onCancel', (tester) async {
    var cancelled = 0;
    await tester.pumpWidget(
      host(
        name: 'Alex',
        message: 'Hello',
        onCancel: () => cancelled++,
      ),
    );
    await tester.pumpAndSettle();
    final cancel = find.byKey(const ValueKey('chat-reply-cancel'));
    expect(cancel, findsOneWidget);
    expect(tester.getSize(cancel).width, greaterThanOrEqualTo(44));
    expect(tester.getSize(cancel).height, greaterThanOrEqualTo(44));
    expect(find.byIcon(Icons.close), findsNothing);
    await tester.tap(cancel);
    await tester.pump();
    expect(cancelled, 1);
  });
}
