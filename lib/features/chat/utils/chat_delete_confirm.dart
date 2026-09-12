import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_icons.dart';
import '../../../core/widgets/app_action_bottom_sheet.dart';

enum ChatDeleteChoice { forMe, forEveryone }

/// Confirm delete-for-me vs delete-for-everyone (CHAT-FEAT-001).
Future<ChatDeleteChoice?> showChatDeleteConfirmSheet({
  required BuildContext context,
  required bool canDeleteForEveryone,
}) {
  return AppActionBottomSheet.show<ChatDeleteChoice>(
    context: context,
    title: 'Delete message?',
    actions: [
      AppActionSheetItem(
        iconPath: AppIcons.delete,
        label: 'Delete for me',
        onTap: () => Navigator.pop(context, ChatDeleteChoice.forMe),
      ),
      if (canDeleteForEveryone)
        AppActionSheetItem(
          iconPath: AppIcons.delete,
          label: 'Delete for everyone',
          iconColor: AppColors.feedbackError,
          onTap: () => Navigator.pop(context, ChatDeleteChoice.forEveryone),
        ),
    ],
  );
}
