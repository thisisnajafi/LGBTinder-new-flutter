import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/features/chat/utils/chat_swipe_to_reply.dart';

void main() {
  test('sent bubbles only move left; received only move right', () {
    expect(
      ChatSwipeToReplyPhysics.clampDx(40, isSent: true),
      0,
    );
    expect(
      ChatSwipeToReplyPhysics.clampDx(-40, isSent: true),
      -40,
    );
    expect(
      ChatSwipeToReplyPhysics.clampDx(-40, isSent: false),
      0,
    );
    expect(
      ChatSwipeToReplyPhysics.clampDx(40, isSent: false),
      40,
    );
  });

  test('drag is capped at the max stretch', () {
    expect(
      ChatSwipeToReplyPhysics.clampDx(-200, isSent: true),
      -AppAnimations.chatSwipeReplyMax,
    );
    expect(
      ChatSwipeToReplyPhysics.clampDx(200, isSent: false),
      AppAnimations.chatSwipeReplyMax,
    );
  });

  test('threshold is 60px and sub-threshold does not reply', () {
    expect(AppAnimations.chatSwipeReplyThreshold, 60);
    expect(ChatSwipeToReplyPhysics.crossed(-59), isFalse);
    expect(ChatSwipeToReplyPhysics.crossed(-60), isTrue);
    expect(
      ChatSwipeToReplyPhysics.shouldReply(-59, isSent: true),
      isFalse,
    );
    expect(
      ChatSwipeToReplyPhysics.shouldReply(-60, isSent: true),
      isTrue,
    );
    expect(
      ChatSwipeToReplyPhysics.shouldReply(60, isSent: true),
      isFalse,
    );
    expect(
      ChatSwipeToReplyPhysics.shouldReply(60, isSent: false),
      isTrue,
    );
  });

  test('reply icon tracks a fraction of the bubble offset', () {
    expect(
      ChatSwipeToReplyPhysics.iconFollowDx(-40),
      -40 * AppAnimations.chatSwipeReplyIconFollow,
    );
  });
}
