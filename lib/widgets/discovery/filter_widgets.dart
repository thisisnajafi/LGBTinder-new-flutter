import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/app_icons.dart';

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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.accentPurple.withValues(alpha: isDark ? 0.22 : 0.12),
            borderRadius: BorderRadius.circular(AppRadius.radiusMD),
          ),
          alignment: Alignment.center,
          child: AppSvgIcon(
            assetPath: iconPath,
            size: 22,
            color: AppColors.accentPurple,
          ),
        ),
        SizedBox(width: AppSpacing.spacingMD),
        Expanded(
          child: Text(
            title,
            style: AppTypography.h4.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// Thin section separator.
class FilterSectionDivider extends StatelessWidget {
  const FilterSectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingLG),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDark ? AppColors.borderSubtleDark : AppColors.borderSubtleLight,
      ),
    );
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

    return Stack(
      children: [
        Opacity(opacity: 0.42, child: AbsorbPointer(child: child)),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onUpgrade,
              child: Center(
                child: Container(
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
          ),
        ),
      ],
    );
  }
}

/// Multi-select chips for reference-data filters.
class FilterMultiSelectSection extends StatelessWidget {
  final String title;
  final String iconPath;
  final List<({int id, String label})> options;
  final List<int> selectedIds;
  final ValueChanged<List<int>> onChanged;
  final bool enabled;

  const FilterMultiSelectSection({
    super.key,
    required this.title,
    required this.iconPath,
    required this.options,
    required this.selectedIds,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilterSectionHeader(iconPath: iconPath, title: title),
        SizedBox(height: AppSpacing.spacingMD),
        Wrap(
          spacing: AppSpacing.spacingSM,
          runSpacing: AppSpacing.spacingSM,
          children: options.map((option) {
            final isSelected = selectedIds.contains(option.id);
            return FilterGenderChip(
              label: option.label,
              isSelected: isSelected,
              onTap: enabled
                  ? () {
                      final next = List<int>.from(selectedIds);
                      if (isSelected) {
                        next.remove(option.id);
                      } else {
                        next.add(option.id);
                      }
                      onChanged(next);
                    }
                  : () {},
            );
          }).toList(),
        ),
      ],
    );
  }
}
