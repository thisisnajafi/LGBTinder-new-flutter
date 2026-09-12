import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/widgets/chat/chat_reply_quote.dart';
import 'package:lgbtindernew/widgets/chat/message_bubble.dart';

void main() {
  testWidgets('quote shows name, one-line preview, 3px bar, 44px height',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: ChatReplyQuote(
            name: 'Sam',
            preview: 'hello there this is a long preview that should clip',
            onTap: () => taps++,
          ),
        ),
      ),
    );

    expect(find.text('Sam'), findsOneWidget);
    expect(
      find.text('hello there this is a long preview that should clip'),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('chat-reply-quote'))).height,
      AppAnimations.chatReplyQuoteHeight,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('chat-reply-quote-bar'))).width,
      AppAnimations.chatReplyQuoteBarWidth,
    );

    await tester.tap(find.byKey(const ValueKey('chat-reply-quote')));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('quote on a sent bubble still exposes the jump target',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: ChatReplyQuote(
            name: 'You',
            preview: 'Photo',
            isSent: true,
          ),
        ),
      ),
    );

    expect(find.text('You'), findsOneWidget);
    expect(find.text('Photo'), findsOneWidget);
  });

  testWidgets('MessageBubble quote is a tappable header above the text',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: MessageBubble(
                message: 'later',
                isSent: false,
                replyToName: 'Sam',
                replyToPreview: 'earlier',
                onReplyQuoteTap: () => taps++,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(ChatReplyQuote), findsOneWidget);
    expect(find.text('earlier'), findsOneWidget);
    expect(find.text('later'), findsOneWidget);

    await tester.tap(find.text('earlier'));
    await tester.pump();
    expect(taps, 1);
  });
}
