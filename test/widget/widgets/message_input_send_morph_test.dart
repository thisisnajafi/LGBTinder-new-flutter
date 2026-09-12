import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/widgets/chat/message_input.dart';

void main() {
  testWidgets('empty composer shows attach + mic; text shows send',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: MessageInput(
              onSend: _noopSend,
              onMediaTap: _noopTap,
              onVoiceRecordStart: _noopVoice,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('chat-attach-button')), findsOneWidget);
    expect(
      tester
          .widgetList<AppSvgIcon>(find.byType(AppSvgIcon))
          .map((icon) => icon.assetPath),
      containsAll([AppIcons.attach, AppIcons.microphone]),
    );

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('chat-attach-button')), findsNothing);
    expect(
      tester
          .widgetList<AppSvgIcon>(find.byType(AppSvgIcon))
          .map((icon) => icon.assetPath),
      contains(AppIcons.send),
    );
  });
}

void _noopSend(String _) {}
void _noopTap() {}
Future<bool> _noopVoice() async => true;
