import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/features/chat/utils/chat_delete_confirm.dart';

void main() {
  Future<void> openSheet(
    WidgetTester tester, {
    required bool canDeleteForEveryone,
    ValueChanged<ChatDeleteChoice?>? onChoice,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  final choice = await showChatDeleteConfirmSheet(
                    context: context,
                    canDeleteForEveryone: canDeleteForEveryone,
                  );
                  onChoice?.call(choice);
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows Delete for everyone only inside the window', (tester) async {
    await openSheet(tester, canDeleteForEveryone: true);
    expect(find.text('Delete for me'), findsOneWidget);
    expect(find.text('Delete for everyone'), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
    expect(find.byType(AppSvgIcon), findsWidgets);
  });

  testWidgets('hides Delete for everyone after 24 hours', (tester) async {
    await openSheet(tester, canDeleteForEveryone: false);
    expect(find.text('Delete for me'), findsOneWidget);
    expect(find.text('Delete for everyone'), findsNothing);
  });

  testWidgets('Delete for me pops forMe', (tester) async {
    ChatDeleteChoice? choice;
    await openSheet(
      tester,
      canDeleteForEveryone: true,
      onChoice: (value) => choice = value,
    );
    await tester.tap(find.text('Delete for me'));
    await tester.pumpAndSettle();
    expect(choice, ChatDeleteChoice.forMe);
  });
}
