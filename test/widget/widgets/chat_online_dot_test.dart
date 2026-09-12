import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/widgets/chat/chat_online_dot.dart';

void main() {
  testWidgets('online dot is 10px fill #22C55E with a 2px ring', (tester) async {
    const ring = Color(0xFF121212);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: ChatOnlineDot(ringColor: ring),
        ),
      ),
    );

    final box = tester.widget<Container>(find.byKey(ChatOnlineDot.dotKey));
    final decoration = box.decoration! as BoxDecoration;
    expect(decoration.color, ChatOnlineDot.fill);
    expect(ChatOnlineDot.fill, const Color(0xFF22C55E));
    expect(decoration.border?.top.width, ChatOnlineDot.ringWidth);
    expect(decoration.border?.top.color, ring);

    final size = tester.getSize(find.byKey(ChatOnlineDot.dotKey));
    expect(size.width, ChatOnlineDot.diameter + ChatOnlineDot.ringWidth * 2);
    expect(size.height, ChatOnlineDot.diameter + ChatOnlineDot.ringWidth * 2);
  });
}
