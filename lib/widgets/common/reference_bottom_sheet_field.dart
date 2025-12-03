// Widget: ReferenceBottomSheetField
// Field that opens a bottom sheet for selecting reference data
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../features/reference_data/data/models/reference_item.dart';
import '../../core/utils/app_icons.dart';
import 'selection_bottom_sheet.dart';

/// Field widget that opens a bottom sheet for selecting reference data
class ReferenceBottomSheetField extends StatelessWidget {
  final String label;
  final String? hint;
  final int? selectedId;
  final List<ReferenceItem> items;
  final Function(int?)? onChanged;
  final bool required;
  final bool enabled;
  final bool searchable;

  const ReferenceBottomSheetField({
    Key? key,
    required this.label,
    this.hint,
    this.selectedId,
    required this.items,
    this.onChanged,
    this.required = false,
    this.enabled = true,
    this.searchable = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    // Find selected item
    final selectedItem = items.firstWhere(
      (item) => item.id == selectedId,
      orElse: () => ReferenceItem(id: -1, title: ''),
    );

    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                label,
                style: AppTypography.h3.copyWith(color: textColor),
              ),
              if (required)
                Text(
                  ' *',
                  style: AppTypography.h3.copyWith(color: Colors.red),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.spacingMD),
          InkWell(
            onTap: enabled ? () async {
              // Dismiss keyboard and unfocus any text fields
              FocusScope.of(context).unfocus();
              
              final selected = await SelectionBottomSheet.showSingleSelect<ReferenceItem>(
                context: context,
                title: 'Select $label',
                items: items,
                getTitle: (item) => item.title,
                selectedItem: selectedItem.id != -1 ? selectedItem : null,
                searchable: searchable,
              );
              
              if (selected != null) {
                onChanged?.call(selected.id);
              }
            } : null,
            child: Container(
              padding: EdgeInsets.all(AppSpacing.spacingMD),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceElevatedDark
                    : AppColors.surfaceElevatedLight,
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedItem.id != -1
                          ? selectedItem.title
                          : (hint ?? 'Select $label'),
                      style: AppTypography.body.copyWith(
                        color: selectedItem.id != -1 ? textColor : secondaryTextColor,
                      ),
                    ),
                  ),
                  AppSvgIcon(
                    assetPath: AppIcons.arrowDown,
                    size: 20,
                    color: secondaryTextColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

