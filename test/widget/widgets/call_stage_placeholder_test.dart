import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/calls/presentation/widgets/call_stage_placeholder.dart';

void main() {
  testWidgets('CallStagePlaceholder shows camera-off copy', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CallStagePlaceholder(
              userId: 12,
              caption: 'Camera is off',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Camera is off'), findsOneWidget);
  });

  testWidgets('compact CallStagePlaceholder still shows caption', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 112,
              height: 148,
              child: CallStagePlaceholder(
                userId: 12,
                caption: 'Camera is off',
                compact: true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Camera is off'), findsOneWidget);
  });
}
