// Widget: ReferenceDropdown
// Dropdown widget for selecting reference data items
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../features/reference_data/data/models/reference_item.dart';
import '../../core/utils/app_icons.dart';

/// Dropdown widget for selecting reference data items
class ReferenceDropdown extends ConsumerWidget {
  final String label;
  final String? hint;
  final int? selectedId;
  final List<ReferenceItem> items;
  final Function(int?)? onChanged;
  final bool required;
  final bool enabled;

  const ReferenceDropdown({
    Key? key,
    required this.label,
    this.hint,
    this.selectedId,
    required this.items,
    this.onChanged,
    this.required = false,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
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
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceElevatedDark
                  : AppColors.surfaceElevatedLight,
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              border: Border.all(color: borderColor),
            ),
            child: DropdownButtonFormField<int>(
              value: selectedId,
              decoration: InputDecoration(
                hintText: hint ?? 'Select $label',
                hintStyle: AppTypography.body.copyWith(color: secondaryTextColor),
                contentPadding: EdgeInsets.all(AppSpacing.spacingMD),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                  borderSide: BorderSide(color: AppColors.accentPurple, width: 2),
                ),
              ),
              style: AppTypography.body.copyWith(color: textColor),
              dropdownColor: surfaceColor,
              icon: AppSvgIcon(
                assetPath: AppIcons.arrowDown,
                size: 24,
                color: textColor,
              ),
              items: items.map((item) {
                return DropdownMenuItem<int>(
                  value: item.id,
                  child: Text(
                    item.title,
                    style: AppTypography.body.copyWith(color: textColor),
                  ),
                );
              }).toList(),
              onChanged: enabled ? (value) {
                onChanged?.call(value);
              } : null,
              isExpanded: true,
            ),
          ),
        ],
      ),
    );
  }
}

