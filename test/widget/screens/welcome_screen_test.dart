import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/onboarding/widgets/welcome_value_props.dart';
import 'package:lgbtindernew/screens/auth/welcome_screen.dart';

void main() {
  testWidgets('first paint skips mosaic and wraps the logo hero', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: WelcomeScreen()),
      ),
    );

    expect(find.byKey(const ValueKey('welcome_hero')), findsOneWidget);
    expect(find.byType(WelcomeValueProps), findsNothing);
    expect(find.text('Create Account'), findsOneWidget);

    await tester.pump();

    expect(find.byType(WelcomeValueProps), findsOneWidget);
    expect(find.byKey(const ValueKey('welcome_hero')), findsOneWidget);
  });

  testWidgets('reduce motion still shows branding without mosaic on first frame',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            );
          },
          home: const WelcomeScreen(),
        ),
      ),
    );

    expect(find.byType(WelcomeValueProps), findsNothing);
    expect(find.text('LGBTFinder'), findsOneWidget);

    await tester.pump();

    expect(find.byType(WelcomeValueProps), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
