// Widget: MessageReplyWidget
// Message reply preview widget
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';

/// Message reply widget
/// Displays a preview of the message being replied to
class MessageReplyWidget extends ConsumerWidget {
  final String? repliedToName;
  final String? repliedToMessage;
  final String? repliedToMessageType;
  final VoidCallback? onCancel;

  const MessageReplyWidget({
    Key? key,
    this.repliedToName,
    this.repliedToMessage,
    this.repliedToMessageType,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = AppColors.accentPurple;

    if (repliedToName == null && repliedToMessage == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          left: BorderSide(color: borderColor, width: 3),
        ),
        borderRadius: BorderRadius.circular(AppRadius.radiusSM),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (repliedToName != null)
                  Text(
                    repliedToName!,
                    style: AppTypography.caption.copyWith(
                      color: borderColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                SizedBox(height: AppSpacing.spacingXS),
                if (repliedToMessage != null)
                  Text(
                    _getMessagePreview(repliedToMessage!, repliedToMessageType),
                    style: AppTypography.body.copyWith(
                      color: secondaryTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (onCancel != null)
            IconButton(
              icon: Icon(
                Icons.close,
                size: 18,
                color: secondaryTextColor,
              ),
              onPressed: onCancel,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  String _getMessagePreview(String message, String? type) {
    if (type == 'image') return '📷 Photo';
    if (type == 'video') return '🎥 Video';
    if (type == 'audio') return '🎤 Audio';
    if (type == 'file') return '📎 File';
    return message;
  }
}
