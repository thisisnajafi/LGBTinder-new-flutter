import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/utils/chat_voice_record_gesture.dart';

void main() {
  test('slide left past 72px cancels', () {
    expect(
      ChatVoiceRecordGesture.resolve(dx: -72, dy: 0),
      ChatVoiceRecordAction.cancel,
    );
    expect(
      ChatVoiceRecordGesture.resolve(dx: -40, dy: 8),
      ChatVoiceRecordAction.none,
    );
  });

  test('slide up past 72px locks', () {
    expect(
      ChatVoiceRecordGesture.resolve(dx: 0, dy: -72),
      ChatVoiceRecordAction.lock,
    );
    expect(
      ChatVoiceRecordGesture.resolve(dx: 12, dy: -80),
      ChatVoiceRecordAction.lock,
    );
  });

  test('diagonal prefers the larger axis', () {
    expect(
      ChatVoiceRecordGesture.resolve(dx: -90, dy: -80),
      ChatVoiceRecordAction.cancel,
    );
    expect(
      ChatVoiceRecordGesture.resolve(dx: -80, dy: -90),
      ChatVoiceRecordAction.lock,
    );
  });
}
