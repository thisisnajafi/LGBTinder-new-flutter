import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/features/chat/utils/voice_waveform_layout.dart';
import 'package:lgbtindernew/widgets/chat/voice_waveform_bars.dart';

void main() {
  test('default bar count is 22', () {
    expect(VoiceWaveformLayout.barCount, 22);
    expect(AppAnimations.chatVoiceWaveformBars, 22);
    expect(AppAnimations.chatVoiceWaveformTick, const Duration(milliseconds: 100));
  });

  test('playhead fraction matches audio progress', () {
    expect(
      VoiceWaveformLayout.playedFraction(
        index: 0,
        barCount: 10,
        progress: 0.5,
      ),
      1,
    );
    expect(
      VoiceWaveformLayout.playedFraction(
        index: 4,
        barCount: 10,
        progress: 0.5,
      ),
      1,
    );
    expect(
      VoiceWaveformLayout.playedFraction(
        index: 5,
        barCount: 10,
        progress: 0.5,
      ),
      0,
    );
    expect(
      VoiceWaveformLayout.playedFraction(
        index: 4,
        barCount: 10,
        progress: 0.45,
      ),
      closeTo(0.5, 0.001),
    );
  });

  test('idle heights are deterministic per index', () {
    expect(
      VoiceWaveformLayout.idleHeightFactor(3, 22),
      VoiceWaveformLayout.idleHeightFactor(3, 22),
    );
    expect(
      VoiceWaveformLayout.idleHeightFactor(3, 22),
      isNot(VoiceWaveformLayout.idleHeightFactor(8, 22)),
    );
  });

  test('Reduce Motion / paused uses idle heights, not the ticker', () {
    expect(
      VoiceWaveformLayout.heightFactor(
        index: 2,
        barCount: 22,
        t: 0.8,
        active: true,
        animate: false,
      ),
      VoiceWaveformLayout.idleHeightFactor(2, 22),
    );
  });

  test('position gate drops updates inside 100ms', () {
    final gate = ChatVoicePositionGate();
    final t0 = DateTime(2026, 1, 1);
    expect(gate.allow(t0), isTrue);
    expect(gate.allow(t0.add(const Duration(milliseconds: 99))), isFalse);
    expect(gate.allow(t0.add(const Duration(milliseconds: 100))), isTrue);
    gate.reset();
    expect(gate.allow(t0.add(const Duration(milliseconds: 101))), isTrue);
  });

  test('painter shouldRepaint when progress or motion changes', () {
    const a = VoiceWaveformPainter(
      barCount: 22,
      progress: 0.2,
      t: 0,
      active: true,
      animate: true,
      color: Color(0xFF000000),
    );
    const b = VoiceWaveformPainter(
      barCount: 22,
      progress: 0.4,
      t: 0,
      active: true,
      animate: true,
      color: Color(0xFF000000),
    );
    const c = VoiceWaveformPainter(
      barCount: 22,
      progress: 0.2,
      t: 0.5,
      active: true,
      animate: true,
      color: Color(0xFF000000),
    );
    expect(a.shouldRepaint(b), isTrue);
    expect(a.shouldRepaint(c), isTrue);
    expect(a.shouldRepaint(a), isFalse);
  });
}
