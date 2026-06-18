import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_icons.dart';
import '../../../core/widgets/app_action_bottom_sheet.dart';

/// Settings-style bottom sheet for profile actions (block, report, favorites).
class ProfileMoreOptionsSheet extends StatelessWidget {
  final VoidCallback onBlock;
  final VoidCallback onReport;
  final VoidCallback onAddFavorite;
  final String? userName;

  const ProfileMoreOptionsSheet({
    super.key,
    required this.onBlock,
    required this.onReport,
    required this.onAddFavorite,
    this.userName,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onBlock,
    required VoidCallback onReport,
    required VoidCallback onAddFavorite,
    String? userName,
  }) {
    return AppActionBottomSheet.show(
      context: context,
      title: userName?.trim().isNotEmpty == true ? userName!.trim() : null,
      actions: _items(context, onBlock: onBlock, onReport: onReport, onAddFavorite: onAddFavorite),
    );
  }

  static List<AppActionSheetItem> _items(
    BuildContext context, {
    required VoidCallback onBlock,
    required VoidCallback onReport,
    required VoidCallback onAddFavorite,
  }) {
    final theme = Theme.of(context);
    return [
      AppActionSheetItem(
        iconPath: AppIcons.block,
        label: 'Block user',
        iconColor: AppColors.feedbackError,
        onTap: () {
          Navigator.pop(context);
          onBlock();
        },
      ),
      AppActionSheetItem(
        iconPath: AppIcons.flag,
        label: 'Report user',
        iconColor: AppColors.feedbackWarning,
        onTap: () {
          Navigator.pop(context);
          onReport();
        },
      ),
      AppActionSheetItem(
        iconPath: AppIcons.favoriteBorder,
        label: 'Add to favorites',
        iconColor: theme.colorScheme.primary,
        onTap: () {
          Navigator.pop(context);
          onAddFavorite();
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetShell(
      title: userName?.trim().isNotEmpty == true ? userName!.trim() : null,
      actions: _items(
        context,
        onBlock: onBlock,
        onReport: onReport,
        onAddFavorite: onAddFavorite,
      ),
    );
  }
}
