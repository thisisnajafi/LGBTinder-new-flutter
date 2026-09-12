import 'package:flutter/material.dart';

import '../../core/constants/animation_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';

/// Circular jump-to-latest control with an unseen-incoming badge
/// (CHAT-ANIM-009 / CHAT-THREAD-004).
class ChatJumpToBottomFab extends StatelessWidget {
  static const double size = 52;

  final bool visible;
  final int unseenCount;
  final VoidCallback onPressed;

  const ChatJumpToBottomFab({
    super.key,
    required this.visible,
    required this.unseenCount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final reduceMotion = !AppAnimations.animationsEnabled(context);
    final duration = reduceMotion
        ? Duration.zero
        : (visible
            ? AppAnimations.chatJumpToBottomIn
            : AppAnimations.chatJumpToBottomOut);
    final badgeLabel = unseenCount > 99 ? '99+' : '$unseenCount';

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedScale(
        key: const ValueKey('chat-jump-to-bottom-scale'),
        scale: visible ? 1 : 0,
        duration: duration,
        curve: Curves.easeOutCubic,
        child: Semantics(
          button: true,
          label: unseenCount > 0
              ? 'Jump to $unseenCount new messages'
              : 'Jump to latest messages',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: size,
                height: size,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? AppColors.surfaceElevatedDark
                            : AppColors.surfaceElevatedLight,
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadow.withValues(alpha: 0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: AppSvgIcon(
                        assetPath: AppIcons.arrowDown,
                        size: 22,
                        color: colors.primary,
                      ),
                    ),
                    if (unseenCount > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 18),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.spacingXS,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: colors.error,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(999),
                            ),
                          ),
                          child: Text(
                            badgeLabel,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onError,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
