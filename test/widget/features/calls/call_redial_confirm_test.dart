import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/features/calls/utils/call_redial_confirm.dart';

void main() {
  Future<ValueNotifier<bool?>> pumpSheet(
    WidgetTester tester, {
    required String peerName,
    required bool isVideo,
  }) async {
    final result = ValueNotifier<bool?>(null);
    addTearDown(result.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  result.value = await showCallRedialConfirmSheet(
                    context: context,
                    peerName: peerName,
                    isVideo: isVideo,
                  );
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
    return result;
  }

  testWidgets('voice redial sheet confirms the same call type', (tester) async {
    final result = await pumpSheet(
      tester,
      peerName: 'Alex',
      isVideo: false,
    );

    expect(find.text('Call Alex?'), findsOneWidget);
    expect(find.text('Voice call'), findsOneWidget);
    expect(find.text('Video call'), findsNothing);

    await tester.tap(find.text('Voice call'));
    await tester.pumpAndSettle();
    expect(result.value, isTrue);
  });

  testWidgets('video redial sheet confirms video only', (tester) async {
    final result = await pumpSheet(
      tester,
      peerName: 'Sam',
      isVideo: true,
    );

    expect(find.text('Call Sam?'), findsOneWidget);
    expect(find.text('Video call'), findsOneWidget);
    expect(find.text('Voice call'), findsNothing);

    await tester.tap(find.text('Video call'));
    await tester.pumpAndSettle();
    expect(result.value, isTrue);
  });

  testWidgets('cancel does not start a redial', (tester) async {
    final result = await pumpSheet(
      tester,
      peerName: 'Alex',
      isVideo: false,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result.value, isFalse);
  });
}
