import 'package:flutter/material.dart';

import '../../core/constants/animation_constants.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/spacing_constants.dart';

/// Animated unread count pill on a conversation row (CHAT-MSG-002).
class ChatUnreadBadge extends StatelessWidget {
  final int count;

  const ChatUnreadBadge({
    super.key,
    required this.count,
  });

  static String labelFor(int count) => count > 99 ? '99+' : '$count';

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final duration = AppAnimations.chatUnreadBadgeDuration(context);
    final label = labelFor(count);

    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacingXS),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(100),
      ),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          if (duration == Duration.zero) return child;
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.45),
            end: Offset.zero,
          ).animate(animation);
          final scale = Tween<double>(
            begin: AppAnimations.chatUnreadBadgeScaleBegin,
            end: 1,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          );
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: scale,
              child: SlideTransition(position: slide, child: child),
            ),
          );
        },
        child: FittedBox(
          key: ValueKey(label),
          fit: BoxFit.scaleDown,
          child: AppText(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
            ),
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}
