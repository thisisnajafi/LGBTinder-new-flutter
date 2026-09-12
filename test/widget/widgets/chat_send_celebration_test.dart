import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/theme/app_colors.dart';
import 'package:lgbtindernew/features/chat/presentation/widgets/chat_send_celebration_burst.dart';
import 'package:lgbtindernew/features/chat/utils/chat_send_celebration.dart';

void main() {
  test('painter emits 4 fading particles', () {
    final particles = ChatSendCelebrationPainter.compute(
      center: Offset.zero,
      t: 0.5,
      palette: AppColors.lgbtGradient,
    );
    expect(particles, hasLength(4));
    expect(particles.first.opacity, closeTo(0.5, 0.01));
    expect(particles.first.position.distance, greaterThan(0));
  });

  testWidgets('burst uses a RepaintBoundary and disposes after 600ms',
      (tester) async {
    var done = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            ChatSendCelebrationBurst(
              globalCenter: const Offset(80, 80),
              colors: AppColors.lgbtGradient,
              onDone: () => done++,
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(ChatSendCelebrationBurst),
        matching: find.byType(RepaintBoundary),
      ),
      findsOneWidget,
    );

    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    expect(done, 1);
  });

  testWidgets('Reduce Motion skips the overlay', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () {
                    ChatSendCelebration.tryPlay(
                      context: context,
                      text: '😂',
                    );
                  },
                  child: const Text('send'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('send'));
    await tester.pump();
    expect(find.byType(ChatSendCelebrationBurst), findsNothing);
  });
}
