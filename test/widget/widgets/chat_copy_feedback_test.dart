import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/features/chat/utils/chat_copy_feedback.dart';

void main() {
  test('Copied snackbar holds 2 seconds', () {
    expect(AppAnimations.chatCopySnackbarHold, const Duration(seconds: 2));
    expect(ChatCopyFeedback.label, 'Copied');
  });

  testWidgets('Copied snackbar appears then dismisses after 2s', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    ChatCopyFeedback.snackBar(context),
                  );
                },
                child: const Text('copy'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('copy'));
    await tester.pumpAndSettle();
    expect(find.text(ChatCopyFeedback.label), findsOneWidget);

    await tester.pump(AppAnimations.chatCopySnackbarHold);
    await tester.pumpAndSettle();
    expect(find.text(ChatCopyFeedback.label), findsNothing);
  });
}
