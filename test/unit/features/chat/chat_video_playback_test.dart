import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/data/models/message_delivery_status.dart';
import 'package:lgbtindernew/features/chat/utils/chat_video_playback.dart';

void main() {
  test('Remote uploaded videos can open the player', () {
    expect(
      ChatVideoPlayback.canOpen(
        mediaUrl: 'https://cdn.example/clip.mp4',
      ),
      isTrue,
    );
  });

  test('Empty, local, sending, and failed videos cannot open', () {
    expect(ChatVideoPlayback.canOpen(mediaUrl: null), isFalse);
    expect(ChatVideoPlayback.canOpen(mediaUrl: '  '), isFalse);
    expect(
      ChatVideoPlayback.canOpen(mediaUrl: '/tmp/pending.mp4'),
      isFalse,
    );
    expect(
      ChatVideoPlayback.canOpen(
        mediaUrl: 'https://cdn.example/clip.mp4',
        deliveryStatus: MessageDeliveryStatus.sending,
      ),
      isFalse,
    );
    expect(
      ChatVideoPlayback.canOpen(
        mediaUrl: 'https://cdn.example/clip.mp4',
        deliveryStatus: MessageDeliveryStatus.failed,
      ),
      isFalse,
    );
  });
}
