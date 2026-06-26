import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/app_icons.dart';
import '../../features/reference_data/data/models/reference_item.dart';
import '../common/selection_bottom_sheet.dart';

/// Compact subsection label inside a [PremiumFilterSection].
class FilterSubsectionTitle extends StatelessWidget {
  final String title;

  const FilterSubsectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Purple icon badge + section title (Filters screen).
class FilterSectionHeader extends StatelessWidget {
  final String iconPath;
  final String title;

  const FilterSectionHeader({
    super.key,
    required this.iconPath,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Row(
      children: [
        Container(
          width: 4,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            gradient: AppColors.brandGradient,
          ),
        ),
        SizedBox(width: AppSpacing.spacingSM),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.accentViolet.withValues(alpha: isDark ? 0.2 : 0.12),
            borderRadius: BorderRadius.circular(AppRadius.radiusMD),
          ),
          alignment: Alignment.center,
          child: AppSvgIcon(
            assetPath: iconPath,
            size: 20,
            color: AppColors.accentViolet,
          ),
        ),
        SizedBox(width: AppSpacing.spacingSM),
        Expanded(
          child: Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color: textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

/// Thin section separator — hidden when inside premium shells.
class FilterSectionDivider extends StatelessWidget {
  const FilterSectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: AppSpacing.spacingMD);
  }
}

/// Themed sliders for filter screen.
class FilterSliderTheme extends StatelessWidget {
  final Widget child;

  const FilterSliderTheme({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactive = AppColors.accentPurple.withValues(alpha: isDark ? 0.2 : 0.14);

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: AppColors.accentPurple,
        inactiveTrackColor: inactive,
        thumbColor: Colors.white,
        overlayColor: AppColors.accentPurple.withValues(alpha: 0.16),
        trackHeight: 5,
        rangeThumbShape: const RoundRangeSliderThumbShape(
          enabledThumbRadius: 11,
          elevation: 2,
        ),
        rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 11,
          elevation: 2,
        ),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
      ),
      child: child,
    );
  }
}

/// Gender / preference chip.
class FilterGenderChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterGenderChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.spacingMD,
            vertical: AppSpacing.spacingSM + 2,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accentPurple.withValues(alpha: isDark ? 0.28 : 0.12)
                : (isDark ? AppColors.surfaceDark : Colors.white),
            borderRadius: BorderRadius.circular(AppRadius.radiusRound),
            border: Border.all(
              color: isSelected ? AppColors.accentPurple : borderColor,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.body.copyWith(
              color: isSelected ? AppColors.accentPurple : textColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Toggle row with icon, title, subtitle, and switch.
class FilterToggleRow extends StatelessWidget {
  final String iconPath;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? trailing;

  const FilterToggleRow({
    super.key,
    required this.iconPath,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingSM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accentPurple.withValues(alpha: isDark ? 0.18 : 0.08),
              borderRadius: BorderRadius.circular(AppRadius.radiusXS),
            ),
            alignment: Alignment.center,
            child: AppSvgIcon(
              assetPath: iconPath,
              size: 18,
              color: AppColors.accentPurple,
            ),
          ),
          SizedBox(width: AppSpacing.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.body.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
                SizedBox(height: AppSpacing.spacingXS),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(color: secondaryColor),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.spacingSM),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.accentPurple.withValues(alpha: 0.45),
            activeThumbColor: Colors.white,
            inactiveThumbColor: isDark ? AppColors.surfaceElevatedDark : Colors.white,
            inactiveTrackColor: isDark ? AppColors.borderMediumDark : AppColors.borderSubtleLight,
          ),
        ],
      ),
    );
  }
}

/// Distance value pill under slider.
class FilterValuePill extends StatelessWidget {
  final String label;

  const FilterValuePill({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.only(top: AppSpacing.spacingSM),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.spacingMD,
          vertical: AppSpacing.spacingXS,
        ),
        decoration: BoxDecoration(
          color: AppColors.accentPurple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.radiusRound),
        ),
        child: Text(
          label,
          style: AppTypography.h4.copyWith(
            color: AppColors.accentPurple,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Small PRO badge for premium-only filter rows.
class FilterProBadge extends StatelessWidget {
  const FilterProBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.spacingSM,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(AppRadius.radiusXS),
      ),
      child: Text(
        'PRO',
        style: AppTypography.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

/// Wraps premium-only sections with lock overlay for free users.
class FilterPremiumGate extends StatelessWidget {
  final bool isPremium;
  final VoidCallback onUpgrade;
  final Widget child;

  const FilterPremiumGate({
    super.key,
    required this.isPremium,
    required this.onUpgrade,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (isPremium) return child;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onUpgrade,
            borderRadius: BorderRadius.circular(AppRadius.radiusRound),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.spacingMD,
                vertical: AppSpacing.spacingSM,
              ),
              decoration: BoxDecoration(
                color: AppColors.accentPurple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                border: Border.all(color: AppColors.accentPurple),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppSvgIcon(
                    assetPath: AppIcons.crown,
                    size: 18,
                    color: AppColors.accentPurple,
                  ),
                  SizedBox(width: AppSpacing.spacingSM),
                  Text(
                    'Upgrade to unlock',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.accentPurple,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.spacingMD),
        Opacity(opacity: 0.42, child: AbsorbPointer(child: child)),
      ],
    );
  }
}

/// Multi-select filter field that opens a searchable bottom sheet dropdown.
class FilterMultiSelectDropdown extends StatelessWidget {
  final String title;
  final String iconPath;
  final List<ReferenceItem> options;
  final List<int> selectedIds;
  final ValueChanged<List<int>> onChanged;
  final bool enabled;

  const FilterMultiSelectDropdown({
    super.key,
    required this.title,
    required this.iconPath,
    required this.options,
    required this.selectedIds,
    required this.onChanged,
    this.enabled = true,
  });

  String _summaryText() {
    if (selectedIds.isEmpty) return 'Any';
    final labels = options
        .where((option) => selectedIds.contains(option.id))
        .map((option) => option.title)
        .toList();
    if (labels.isEmpty) return 'Any';
    if (labels.length <= 2) return labels.join(', ');
    return '${labels.length} selected';
  }

  Future<void> _openPicker(BuildContext context) async {
    if (!enabled || options.isEmpty) return;

    final selectedItems = options
        .where((option) => selectedIds.contains(option.id))
        .toList();

    final result = await SelectionBottomSheet.showMultiSelect<ReferenceItem>(
      context: context,
      title: title,
      items: options,
      getTitle: (item) => item.title,
      selectedItems: selectedItems,
      searchable: options.length > 8,
      compareItems: (a, b) => a.id.compareTo(b.id),
    );

    if (result != null) {
      onChanged(result.map((item) => item.id).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor =
        isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final summary = _summaryText();
    final hasSelection = selectedIds.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilterSectionHeader(iconPath: iconPath, title: title),
        SizedBox(height: AppSpacing.spacingMD),
        Material(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
          child: InkWell(
            onTap: enabled ? () => _openPicker(context) : null,
            borderRadius: BorderRadius.circular(AppRadius.radiusMD),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.spacingMD,
                vertical: AppSpacing.spacingMD,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                border: Border.all(
                  color: hasSelection ? AppColors.accentPurple : borderColor,
                  width: hasSelection ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      summary,
                      style: AppTypography.body.copyWith(
                        color: hasSelection ? textColor : secondaryColor,
                        fontWeight:
                            hasSelection ? FontWeight.w600 : FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: AppSpacing.spacingSM),
                  AppSvgIcon(
                    assetPath: AppIcons.arrowDown,
                    size: 18,
                    color: enabled ? AppColors.accentPurple : secondaryColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
