import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

import 'package:lgbtindernew/widgets/animations/lottie_animations.dart';

void main() {
  const heart = 'assets/lottie/chat_heart.json';

  setUp(LottiePlaybackLimiter.debugReset);
  tearDown(LottiePlaybackLimiter.debugReset);

  testWidgets('does not mount Lottie until after the first frame',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ThemeAwareLottie(assetPath: heart, width: 48, height: 48),
      ),
    );

    expect(find.byType(LottieBuilder), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump();
    expect(find.byType(LottieBuilder), findsOneWidget);
  });

  testWidgets('Reduce Motion keeps the static fallback', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          );
        },
        home: const ThemeAwareLottie(assetPath: heart, width: 48, height: 48),
      ),
    );
    await tester.pump();

    expect(find.byType(LottieBuilder), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(LottiePlaybackLimiter.debugActiveCount, 0);
  });

  testWidgets('second Lottie stays on fallback while the first holds the slot',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            ThemeAwareLottie(assetPath: heart, width: 48, height: 48),
            ThemeAwareLottie(assetPath: heart, width: 48, height: 48),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(LottieBuilder), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(LottiePlaybackLimiter.debugActiveCount, 1);
  });
}
