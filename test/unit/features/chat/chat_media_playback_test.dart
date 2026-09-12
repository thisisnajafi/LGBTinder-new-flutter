import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/utils/chat_media_playback.dart';

void main() {
  tearDown(() {
    ChatMediaPlayback.interruptToken.value = 0;
  });

  test('interrupt bumps the shared token so other players can pause', () {
    final before = ChatMediaPlayback.interruptToken.value;
    ChatMediaPlayback.interrupt();
    expect(ChatMediaPlayback.interruptToken.value, before + 1);
  });
}
