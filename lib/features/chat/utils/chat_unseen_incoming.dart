import 'chat_thread_scroll.dart';

/// Unseen-incoming rules for the chat thread jump FAB
/// (CHAT-RT-002 / CHAT-ANIM-009 / CHAT-THREAD-004).
/// Distances assume a reverse thread ([ChatThreadScroll]).
class ChatUnseenIncoming {
  ChatUnseenIncoming._();

  /// Show the jump FAB when farther from the latest row than this.
  static const double fabThreshold = 200;

  /// Auto-scroll when the user is this close to the latest message.
  /// Same cutoff as [fabThreshold] so 180–200px is not a dead zone.
  static const double autoScrollThreshold = fabThreshold;

  static bool isNearBottom({
    required double pixels,
    double threshold = autoScrollThreshold,
  }) {
    return ChatThreadScroll.isNearLatest(
      pixels: pixels,
      threshold: threshold,
    );
  }

  static bool shouldShowFab({
    required double pixels,
  }) {
    return !isNearBottom(
      pixels: pixels,
      threshold: fabThreshold,
    );
  }

  static bool shouldIncrementBadge({
    required bool insertedNewRow,
    required bool fromPeer,
    required bool nearBottom,
  }) {
    return insertedNewRow && fromPeer && !nearBottom;
  }
}
