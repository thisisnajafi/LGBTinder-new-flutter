import 'package:flutter/material.dart';

import '../../core/constants/animation_constants.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';

/// Telegram-style quoted header inside a bubble (CHAT-BUBBLE-005).
class ChatReplyQuote extends StatelessWidget {
  static const double height = AppAnimations.chatReplyQuoteHeight;
  static const double barWidth = AppAnimations.chatReplyQuoteBarWidth;

  final String? name;
  final String preview;
  final bool isSent;
  final VoidCallback? onTap;

  const ChatReplyQuote({
    super.key,
    required this.preview,
    this.name,
    this.isSent = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barColor = isSent
        ? theme.colorScheme.onPrimary
        : AppColors.accentPurple;
    final fillColor = isSent
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.16)
        : theme.colorScheme.onSurface.withValues(alpha: 0.08);
    final nameColor = barColor;
    final previewColor = isSent
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.85)
        : theme.colorScheme.onSurfaceVariant;
    final label = name != null && name!.trim().isNotEmpty
        ? name!.trim()
        : null;

    return Semantics(
      button: onTap != null,
      label: 'Jump to replied message',
      child: Material(
        color: fillColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusXS),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            key: const ValueKey('chat-reply-quote'),
            height: height,
            width: double.infinity,
            child: Row(
              children: [
                SizedBox(
                  key: const ValueKey('chat-reply-quote-bar'),
                  width: barWidth,
                  height: height,
                  child: ColoredBox(color: barColor),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacingSM,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (label != null)
                          AppText(
                            label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: nameColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        AppText(
                          preview,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: previewColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
