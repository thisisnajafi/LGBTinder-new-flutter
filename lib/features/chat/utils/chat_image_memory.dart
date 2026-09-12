import 'package:flutter/painting.dart';

import 'chat_image_placeholder.dart';

/// Decode-size caps for chat photos (CHAT-PERF-003).
class ChatImageMemory {
  ChatImageMemory._();

  static const int bubbleMaxDecode = ChatImagePlaceholder.memCacheSize;
  /// Full-screen viewer can decode larger than the 800px bubble cap.
  static const int viewerMaxDecode = 1920;

  static int bubbleDecodePx({
    required double logicalWidth,
    required double logicalHeight,
    required double devicePixelRatio,
  }) {
    final longest =
        logicalWidth > logicalHeight ? logicalWidth : logicalHeight;
    return _clampPx(
      (longest * devicePixelRatio).round(),
      max: bubbleMaxDecode,
    );
  }

  static int viewerDecodePx({
    required Size screen,
    required double devicePixelRatio,
  }) {
    return _clampPx(
      (screen.longestSide * devicePixelRatio).round(),
      max: viewerMaxDecode,
    );
  }

  static int _clampPx(int px, {required int max}) {
    if (px < 1) return 1;
    if (px > max) return max;
    return px;
  }
}
