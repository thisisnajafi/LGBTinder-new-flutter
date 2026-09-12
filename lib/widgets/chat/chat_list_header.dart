// Widget: ChatListHeader
// Header for chat list with search
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/debounced_search_field.dart';

/// Chat list header widget
/// Header with search bar and filter options
class ChatListHeader extends StatelessWidget {
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onFilterTap;
  final String? searchHint;

  const ChatListHeader({
    super.key,
    this.onSearchChanged,
    this.onFilterTap,
    this.searchHint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final borderColor = isDark
        ? AppColors.borderMediumDark
        : AppColors.borderMediumLight;
    final fillColor = isDark
        ? AppColors.surfaceElevatedDark
        : AppColors.surfaceElevatedLight;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: DebouncedSearchField(
              hintText: searchHint ?? 'Search conversations...',
              onChanged: onSearchChanged ?? (_) {},
              decoration: InputDecoration(
                filled: true,
                fillColor: fillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                  borderSide: BorderSide(
                    color: AppColors.accentViolet.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacingMD,
                  vertical: AppSpacing.spacingMD,
                ),
              ),
            ),
          ),
          if (onFilterTap != null) ...[
            const SizedBox(width: AppSpacing.spacingMD),
            IconButton(
              tooltip: 'Filter conversations',
              onPressed: onFilterTap,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              icon: AppSvgIcon(
                assetPath: AppIcons.filter,
                size: 22,
                color: textColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
