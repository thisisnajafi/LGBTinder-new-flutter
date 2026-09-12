import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/onboarding/widgets/onboarding_intro_hero.dart';
import 'package:lgbtindernew/pages/onboarding_page.dart';

void main() {
  testWidgets('builds only the current slide and its neighbors', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: OnboardingPage()),
      ),
    );
    await tester.pump();

    Finder slide(int index) =>
        find.byKey(ValueKey('onboarding_slide_$index'), skipOffstage: false);

    expect(slide(0), findsOneWidget);
    expect(slide(1), findsOneWidget);
    expect(slide(2), findsNothing);
    expect(slide(3), findsNothing);
    expect(find.byType(OnboardingIntroHero), findsWidgets);
    expect(find.byType(ConfettiWidget), findsNothing);

    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(slide(0), findsOneWidget);
    expect(slide(1), findsOneWidget);
    expect(slide(2), findsOneWidget);
    expect(slide(3), findsNothing);
  });

  testWidgets('reduce motion skips confetti and still shows the first hero',
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
          home: const OnboardingPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Welcome to LGBTFinder'), findsOneWidget);
    expect(find.byType(ConfettiWidget), findsNothing);
    expect(find.byType(OnboardingIntroHero), findsWidgets);
  });
}
