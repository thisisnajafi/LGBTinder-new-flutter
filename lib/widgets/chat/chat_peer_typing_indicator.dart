import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/animation_constants.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/spacing_constants.dart';
import '../../features/chat/providers/chat_thread_providers.dart';
import '../../features/chat/providers/chat_typing_providers.dart';
import 'typing_indicator.dart';

/// Typing dots for one chat peer — isolated rebuild (PERF-PAGE-CHAT-005).
///
/// Start/stop slides the indicator only (CHAT-THREAD-003); message tiles are
/// not rebuilt.
class ChatPeerTypingIndicator extends ConsumerWidget {
  final int peerUserId;
  final String? displayName;
  final VoidCallback? onAppearedAtBottom;

  const ChatPeerTypingIndicator({
    super.key,
    required this.peerUserId,
    this.displayName,
    this.onAppearedAtBottom,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<bool>(isUserTypingProvider(peerUserId), (previous, next) {
      if (next != true || previous == true) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        if (!ref.read(isAtBottomProvider(peerUserId))) return;
        onAppearedAtBottom?.call();
      });
    });

    final isTyping = ref.watch(isUserTypingProvider(peerUserId));
    final reduced = !AppAnimations.animationsEnabled(context);
    final duration =
        reduced ? Duration.zero : AppAnimations.chatTypingExit;

    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: AppAnimations.curveDefault,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        if (reduced || duration == Duration.zero) return child;
        final slide = Tween<Offset>(
          begin: AppAnimations.chatMessageReceiveSlide,
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: AppAnimations.curveDefault,
          ),
        );
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: slide,
            child: child,
          ),
        );
      },
      child: isTyping
          ? Padding(
              key: const ValueKey('peer-typing'),
              padding: ResponsivePadding.page(context).copyWith(
                top: AppSpacing.spacingSM,
                bottom: AppSpacing.spacingSM,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TypingIndicator(displayName: displayName),
              ),
            )
          : const SizedBox.shrink(key: ValueKey('peer-typing-idle')),
    );
  }
}
