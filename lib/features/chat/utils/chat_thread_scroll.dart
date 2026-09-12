/// Scroll math for a Telegram-style `ListView(reverse: true)` (CHAT-PERF-001).
///
/// Pixel 0 is the latest row (visual bottom). [maxScrollExtent] is the oldest
/// end (visual top).
class ChatThreadScroll {
  ChatThreadScroll._();

  static const bool reversed = true;
  static const double latestPixels = 0;
  static const double loadOlderThreshold = 120;

  /// Maps a reverse-list builder index to chronological storage (oldest = 0).
  static int chronologicalIndex(int itemCount, int visualIndex) {
    if (itemCount <= 0) return 0;
    return itemCount - 1 - visualIndex;
  }

  static bool isNearLatest({
    required double pixels,
    double threshold = 200,
  }) {
    return pixels <= threshold;
  }

  static bool isNearOldest({
    required double pixels,
    required double maxScrollExtent,
    double threshold = loadOlderThreshold,
  }) {
    return pixels >= maxScrollExtent - threshold;
  }

  /// Jump target for the latest row, or null if already there.
  static double? pinnedLatestPixels({
    required double pixels,
    double epsilon = 1,
  }) {
    if (pixels.abs() < epsilon) return null;
    return latestPixels;
  }
}
