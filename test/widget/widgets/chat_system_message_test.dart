import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/features/chat/utils/chat_screenshot_ui.dart';
import 'package:lgbtindernew/widgets/chat/chat_system_message.dart';

void main() {
  testWidgets('screenshot system row is centered muted copy with SVG camera',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: ChatSystemMessage.screenshot(isSent: false),
        ),
      ),
    );

    expect(find.text(ChatScreenshotUi.theyTook), findsOneWidget);
    expect(find.byKey(ChatSystemMessage.barKey), findsOneWidget);
    expect(find.byType(AppSvgIcon), findsOneWidget);
    expect(find.byType(Icon), findsNothing);

    final icon = tester.widget<AppSvgIcon>(find.byType(AppSvgIcon));
    expect(icon.assetPath, AppIcons.camera);
    expect(icon.size, 14);
  });

  testWidgets('match system row uses heart SVG and no bubble chrome',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: ChatSystemMessage.match(),
        ),
      ),
    );

    expect(find.text(ChatSystemMessage.matchedCaption), findsOneWidget);
    expect(find.byType(InkWell), findsNothing);
    expect(find.byType(Card), findsNothing);
    final icon = tester.widget<AppSvgIcon>(find.byType(AppSvgIcon));
    expect(icon.assetPath, AppIcons.heartTick);
    expect(icon.size, ChatSystemMessage.iconSize);
    expect(find.byType(Icon), findsNothing);
  });
}
