import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/widgets/chat/voice_waveform_bars.dart';

void main() {
  testWidgets('waveform is one CustomPainter inside a RepaintBoundary',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: SizedBox(
            width: 200,
            child: VoiceWaveformBars(
              active: true,
              color: Color(0xFF7C3AED),
              progress: 0.4,
            ),
          ),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(VoiceWaveformBars),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(VoiceWaveformBars),
        matching: find.byType(RepaintBoundary),
      ),
      findsOneWidget,
    );
    expect(find.byType(AnimatedContainer), findsNothing);
  });

  testWidgets('Reduce Motion keeps a static painter (no AnimatedContainers)',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          );
        },
        home: const Scaffold(
          body: SizedBox(
            width: 200,
            child: VoiceWaveformBars(
              active: true,
              color: Color(0xFF7C3AED),
              progress: 0.25,
            ),
          ),
        ),
      ),
    );

    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(VoiceWaveformBars),
        matching: find.byType(CustomPaint),
      ),
    );
    final painter = paint.painter! as VoiceWaveformPainter;
    expect(painter.animate, isFalse);
    expect(painter.t, 0);
    expect(painter.progress, 0.25);
    expect(find.byType(AnimatedContainer), findsNothing);
  });
}
