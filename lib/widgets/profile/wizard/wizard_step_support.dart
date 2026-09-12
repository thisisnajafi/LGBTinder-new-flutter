import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/theme/typography.dart';
import '../../../features/reference_data/data/models/reference_item.dart';
import '../../common/selection_bottom_sheet.dart';
import '../profile_wizard_layout.dart';

/// Shared loading / error / picker rows for profile-wizard steps.
class WizardStepSupport {
  WizardStepSupport._();

  static String titlesFor(List<ReferenceItem> items, List<int> ids) {
    return items
        .where((item) => ids.contains(item.id))
        .map((item) => item.title)
        .join(', ');
  }

  static List<String> titleListFor(List<ReferenceItem> items, List<int> ids) {
    return items
        .where((item) => ids.contains(item.id))
        .map((item) => item.title)
        .toList();
  }

  static Future<void> showMultiSelect({
    required BuildContext context,
    required String title,
    required List<ReferenceItem> items,
    required List<int> selectedIds,
    required ValueChanged<List<int>> onSelected,
  }) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final selected = await SelectionBottomSheet.showMultiSelect<ReferenceItem>(
      context: context,
      title: title,
      items: items,
      getTitle: (item) => item.title,
      selectedItems:
          items.where((item) => selectedIds.contains(item.id)).toList(),
      searchable: true,
    );
    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });
    if (selected != null) {
      onSelected(selected.map((item) => item.id).toList());
    }
  }

  static Widget groupedMultiSelectPicker({
    required BuildContext context,
    required String label,
    required String hint,
    required List<String> selectedTitles,
    required VoidCallback onTap,
    bool required = false,
    bool showDivider = true,
  }) {
    final value = selectedTitles.isEmpty ? null : selectedTitles.join(', ');
    return ProfileWizardLayout.pickerTile(
      context: context,
      label: label,
      value: value,
      hint: hint,
      onTap: onTap,
      required: required,
      showDivider: showDivider,
    );
  }

  static Widget loadingField({
    required String label,
    required Color textColor,
    required Color secondaryTextColor,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label *',
            style: AppTypography.h3.copyWith(color: textColor),
          ),
          const SizedBox(height: AppSpacing.spacingMD),
          Container(
            padding: const EdgeInsets.all(AppSpacing.spacingMD),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceElevatedDark
                  : AppColors.surfaceElevatedLight,
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              border: Border.all(
                color: isDark
                    ? AppColors.borderMediumDark
                    : AppColors.borderMediumLight,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.accentPurple,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.spacingMD),
                Text(
                  'Loading...',
                  style: AppTypography.body.copyWith(color: secondaryTextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget errorField({
    required String label,
    required Object error,
    required Color textColor,
    required Color secondaryTextColor,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label *',
            style: AppTypography.h3.copyWith(color: textColor),
          ),
          const SizedBox(height: AppSpacing.spacingMD),
          Container(
            padding: const EdgeInsets.all(AppSpacing.spacingMD),
            decoration: BoxDecoration(
              color: AppColors.feedbackError.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              border: Border.all(color: AppColors.feedbackError),
            ),
            child: Text(
              'Failed to load $label: $error',
              style: AppTypography.body.copyWith(color: AppColors.feedbackError),
            ),
          ),
        ],
      ),
    );
  }
}
