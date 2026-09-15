import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/widgets/buttons/gradient_button.dart';
import 'package:lgbtindernew/widgets/buttons/scale_tap_feedback.dart';

void main() {
  testWidgets('ScaleTapFeedback skips scale when Reduce Motion is on', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: ScaleTapFeedback(
            onTap: () => taps++,
            child: const Text('Tap'),
          ),
        ),
      ),
    );

    expect(find.byType(ScaleTransition), findsNothing);
    await tester.tap(find.text('Tap'));
    expect(taps, 1);
  });

  testWidgets('disabled GradientButton skips ScaleTransition', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: GradientButton(text: 'Save', onPressed: null)),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(GradientButton),
        matching: find.byType(ScaleTransition),
      ),
      findsNothing,
    );
    expect(find.text('Save'), findsOneWidget);
  });
}
