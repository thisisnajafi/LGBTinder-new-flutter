import 'package:flutter/material.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import '../../features/chat/utils/chat_screenshot_ui.dart';

/// Centered muted service row for screenshot / match / call notices.
class ChatSystemMessage extends StatelessWidget {
  static const Key barKey = ValueKey('chat-system-message');
  static const double iconSize = 14;
  static const String matchedCaption = 'You matched!';

  final String caption;
  final String iconPath;
  final Color? color;
  final VoidCallback? onTap;

  const ChatSystemMessage({
    super.key,
    required this.caption,
    required this.iconPath,
    this.color,
    this.onTap,
  });

  factory ChatSystemMessage.screenshot({
    Key? key,
    required bool isSent,
  }) {
    return ChatSystemMessage(
      key: key,
      caption: ChatScreenshotUi.threadCaption(isSent: isSent),
      iconPath: AppIcons.camera,
    );
  }

  factory ChatSystemMessage.match({
    Key? key,
    String caption = matchedCaption,
  }) {
    return ChatSystemMessage(
      key: key,
      caption: caption,
      iconPath: AppIcons.heartTick,
    );
  }

  static bool isMatchRow(Map<String, dynamic> message) {
    final type =
        message['type']?.toString() ?? message['message_type']?.toString();
    if (type == 'match') return true;
    if (type != ChatScreenshotUi.systemType) return false;
    final body =
        (message['text'] ?? message['message'] ?? '').toString().trim();
    if (body.isEmpty) return false;
    final lower = body.toLowerCase();
    return lower == 'you matched!' || lower == 'match';
  }

  static String matchCaption(Map<String, dynamic> message) {
    final body =
        (message['text'] ?? message['message'] ?? '').toString().trim();
    return body.isEmpty ? matchedCaption : body;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = color ??
        (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);

    final row = Padding(
      key: barKey,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacingLG,
        vertical: AppSpacing.spacingSM,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppSvgIcon(
            assetPath: iconPath,
            size: iconSize,
            color: muted,
          ),
          const SizedBox(width: AppSpacing.spacingXS),
          Flexible(
            child: AppText(
              caption,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return row;

    return Semantics(
      label: caption,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: row,
      ),
    );
  }
}
