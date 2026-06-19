import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/widgets/app_settings_detail.dart';
import '../../core/widgets/premium/premium_design_system.dart';
import '../../features/reference_data/data/models/reference_item.dart';
import '../../widgets/common/selection_bottom_sheet.dart';
import '../../core/utils/app_icons.dart';

/// Shared layout helpers — profile wizard steps use the same grouped UI as
/// settings detail pages and [ProfileEditPage].
class ProfileWizardLayout {
  ProfileWizardLayout._();

  static Widget stepList({required List<Widget> children}) {
    return AppSettingsDetailList(children: children);
  }

  static Widget section(
    String title,
    List<Widget> children, {
    bool first = false,
    bool? showTitle,
    String? subtitle,
  }) {
    if (showTitle == false) {
      return Padding(
        padding: EdgeInsets.only(top: first ? 0 : AppSpacing.spacingXL),
        child: Column(children: children),
      );
    }
    return Padding(
      padding: EdgeInsets.only(top: first ? 0 : AppSpacing.spacingXL),
      child: PremiumSettingsGroup(
        title: title,
        subtitle: subtitle,
        children: children,
      ),
    );
  }

  static Widget inset({required Widget child}) => AppSettingsInset(child: child);

  static Widget footnote({required String text}) =>
      AppSettingsSectionFootnote(text: text);

  /// Picker row matching [AppGroupedListTile] (settings / profile edit style).
  static Widget pickerTile({
    required BuildContext context,
    required String label,
    required String? value,
    required String hint,
    required VoidCallback onTap,
    bool showDivider = true,
    bool required = false,
  }) {
    final theme = Theme.of(context);
    final display = (value != null && value.isNotEmpty) ? value : hint;
    final isPlaceholder = value == null || value.isEmpty;

    return PremiumTapScale(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
        onTap();
      },
      semanticLabel: label,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacingMD,
          vertical: AppSpacing.spacingMD,
        ),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? AppColors.cardBackgroundDark
              : AppColors.cardBackgroundLight,
          borderRadius: BorderRadius.circular(AppRadius.radiusLG),
          border: Border.all(
            color: AppColors.accentViolet.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    required ? '$label *' : label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    display,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: isPlaceholder ? 0.45 : 0.72,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppSvgIcon(
              assetPath: AppIcons.chevronRight,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> pickReferenceItem({
    required BuildContext context,
    required String title,
    required List<ReferenceItem> items,
    required ReferenceItem? selected,
    required ValueChanged<ReferenceItem> onSelected,
    bool searchable = true,
  }) async {
    FocusScope.of(context).unfocus();
    final picked = await SelectionBottomSheet.showSingleSelect<ReferenceItem>(
      context: context,
      title: title,
      items: items,
      getTitle: (item) => item.title,
      selectedItem: selected,
      searchable: searchable,
    );
    if (picked != null) onSelected(picked);
  }
}
