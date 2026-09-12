import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/features/calls/presentation/widgets/call_live_chrome.dart';

void main() {
  testWidgets('CallHideButton exposes hide semantics and chat icon', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Center(
            child: CallHideButton(onTap: () => taps++),
          ),
        ),
      ),
    );

    expect(find.text('Chat'), findsOneWidget);
    expect(
      tester.widget<AppSvgIcon>(find.byType(AppSvgIcon)).assetPath,
      AppIcons.message,
    );

    await tester.tap(find.byType(CallHideButton));
    expect(taps, 1);
  });
}
