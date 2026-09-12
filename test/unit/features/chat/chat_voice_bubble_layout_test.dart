import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/utils/chat_voice_bubble_layout.dart';

void main() {
  test('voice bubble width is at least 120 and grows with duration', () {
    expect(ChatVoiceBubbleLayout.minWidth, 120);
    expect(
      ChatVoiceBubbleLayout.width(durationSeconds: 1, maxWidth: 280),
      120,
    );
    expect(
      ChatVoiceBubbleLayout.width(durationSeconds: 0, maxWidth: 280),
      120,
    );
    final mid = ChatVoiceBubbleLayout.width(
      durationSeconds: 30,
      maxWidth: 280,
    );
    expect(mid, greaterThan(120));
    expect(mid, lessThan(280));
    expect(
      ChatVoiceBubbleLayout.width(durationSeconds: 60, maxWidth: 280),
      280,
    );
    expect(
      ChatVoiceBubbleLayout.width(durationSeconds: 90, maxWidth: 280),
      280,
    );
    expect(
      ChatVoiceBubbleLayout.width(durationSeconds: 90, maxWidth: 400),
      ChatVoiceBubbleLayout.maxWidthCap,
    );
  });

  test('playback speed cycles 1 / 1.5 / 2', () {
    expect(ChatVoiceBubbleLayout.speeds, [1.0, 1.5, 2.0]);
    expect(ChatVoiceBubbleLayout.nextSpeed(1.0), 1.5);
    expect(ChatVoiceBubbleLayout.nextSpeed(1.5), 2.0);
    expect(ChatVoiceBubbleLayout.nextSpeed(2.0), 1.0);
    expect(ChatVoiceBubbleLayout.speedLabel(1.0), '1x');
    expect(ChatVoiceBubbleLayout.speedLabel(1.5), '1.5x');
    expect(ChatVoiceBubbleLayout.speedLabel(2.0), '2x');
  });
}
