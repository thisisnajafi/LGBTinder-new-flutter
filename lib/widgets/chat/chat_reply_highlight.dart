import 'package:flutter/material.dart';

import '../../core/constants/animation_constants.dart';

/// Full-width wash behind a jumped-to original (CHAT-THREAD-006).
class ChatReplyHighlight extends StatelessWidget {
  final bool highlighted;
  final Widget child;

  const ChatReplyHighlight({
    super.key,
    required this.highlighted,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final wash = Theme.of(context).colorScheme.primary.withValues(
          alpha: highlighted ? 0.16 : 0,
        );
    return AnimatedContainer(
      key: const ValueKey('chat-reply-highlight'),
      duration: AppAnimations.chatReplyHighlightFadeDuration(context),
      curve: AppAnimations.curveDefault,
      color: wash,
      child: child,
    );
  }
}
