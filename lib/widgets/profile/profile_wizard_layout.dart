import 'package:flutter/material.dart';

import '../../core/theme/spacing_constants.dart';
import '../../core/widgets/app_grouped_list_card.dart';
import '../../core/widgets/app_settings_detail.dart';
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
  }) {
    return AppGroupedListSection(
      title: title,
      padding: first
          ? AppSettingsLayout.firstSectionPadding
          : AppSettingsLayout.sectionPadding,
      children: children,
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              onTap();
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacingMD,
                  vertical: AppSpacing.spacingMD,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            required ? '$label *' : label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
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
            ),
          ),
        ),
        if (showDivider) const AppGroupedRowSeparator(),
      ],
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
