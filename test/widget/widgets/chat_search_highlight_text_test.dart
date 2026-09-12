import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/widgets/chat/chat_search_highlight_text.dart';

void main() {
  testWidgets('matching substring uses ColorScheme.primary', (tester) async {
    const primary = Color(0xFFEC4899);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: const ColorScheme.light(primary: primary),
        ),
        home: const Scaffold(
          body: ChatSearchHighlightText(
            text: 'Alexandra',
            query: 'alex',
            style: TextStyle(color: Color(0xFF111827)),
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.byType(Text));
    final children = (text.textSpan! as TextSpan).children!.cast<TextSpan>();
    expect(children.first.text, 'Alex');
    expect(children.first.style?.color, primary);
    expect(children.last.text, 'andra');
  });
}
