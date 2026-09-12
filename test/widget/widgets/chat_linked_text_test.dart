import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/widgets/chat/chat_linked_text.dart';

void main() {
  testWidgets('tapping a URL opens it externally', (tester) async {
    Uri? opened;
    ChatLinkOpener.launch = (uri) async {
      opened = uri;
      return true;
    };
    addTearDown(ChatLinkOpener.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: ChatLinkedText(
            text: 'https://example.com/chat',
            style: TextStyle(fontSize: 14),
            linkColor: Color(0xFF7C3AED),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ChatLinkedText));
    await tester.pump();
    expect(opened, Uri.parse('https://example.com/chat'));
  });

  testWidgets('plain text is not a link', (tester) async {
    var launches = 0;
    ChatLinkOpener.launch = (uri) async {
      launches++;
      return true;
    };
    addTearDown(ChatLinkOpener.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: ChatLinkedText(
            text: 'hello there',
            style: TextStyle(fontSize: 14),
            linkColor: Color(0xFF7C3AED),
          ),
        ),
      ),
    );

    await tester.tap(find.text('hello there'));
    await tester.pump();
    expect(launches, 0);
  });
}
