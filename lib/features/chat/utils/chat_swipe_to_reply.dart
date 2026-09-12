import '../../../core/constants/animation_constants.dart';

/// Horizontal swipe math for reply-on-bubble (CHAT-ANIM-010).
class ChatSwipeToReplyPhysics {
  ChatSwipeToReplyPhysics._();

  static double clampDx(double dx, {required bool isSent}) {
    if (isSent) {
      return dx.clamp(-AppAnimations.chatSwipeReplyMax, 0);
    }
    return dx.clamp(0, AppAnimations.chatSwipeReplyMax);
  }

  static double progress(double dx) =>
      (dx.abs() / AppAnimations.chatSwipeReplyThreshold).clamp(0.0, 1.0);

  static bool crossed(double dx) =>
      dx.abs() >= AppAnimations.chatSwipeReplyThreshold;

  /// Sent bubbles only count a left swipe; received only a right swipe.
  static bool shouldReply(double dx, {required bool isSent}) {
    if (!crossed(dx)) return false;
    return isSent ? dx < 0 : dx > 0;
  }

  static double iconFollowDx(double dx) =>
      dx * AppAnimations.chatSwipeReplyIconFollow;
}
