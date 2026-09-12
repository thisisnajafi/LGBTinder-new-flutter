import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/widgets/chat/chat_deleted_tombstone.dart';

void main() {
  testWidgets('tombstone is italic muted copy with an SVG, no Material icon',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: ChatDeletedTombstone(isSent: true),
        ),
      ),
    );

    expect(find.text(ChatDeletedTombstone.caption), findsOneWidget);
    expect(find.byKey(ChatDeletedTombstone.barKey), findsOneWidget);
    expect(find.byType(AppSvgIcon), findsOneWidget);
    expect(find.byType(Icon), findsNothing);

    final text = tester.widget<Text>(find.text(ChatDeletedTombstone.caption));
    expect(text.style?.fontStyle, FontStyle.italic);
  });
}
