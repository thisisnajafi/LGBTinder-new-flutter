import 'package:flutter/material.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import 'message_bubble.dart';

/// Italic muted stand-in for a message deleted for everyone (CHAT-BUBBLE-008).
class ChatDeletedTombstone extends StatelessWidget {
  static const Key barKey = ValueKey('chat-deleted-tombstone');
  static const String caption = 'This message was deleted';

  final bool isSent;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const ChatDeletedTombstone({
    super.key,
    required this.isSent,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        key: barKey,
        padding: MessageBubbleChrome.margin(
          isSent: isSent,
          isFirstInGroup: isFirstInGroup,
          isLastInGroup: isLastInGroup,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSvgIcon(
              assetPath: AppIcons.block,
              size: 16,
              color: muted,
            ),
            const SizedBox(width: AppSpacing.spacingXS),
            AppText(
              caption,
              maxLines: 1,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
