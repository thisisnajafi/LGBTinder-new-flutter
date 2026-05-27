import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/app_icons.dart';
import '../../data/models/sub_plan_bundle_pricing.dart';
import '../../data/models/subscription_plan.dart';

/// Duration pricing rows for a single plan tier (1 month → yearly).
class PlanDurationOptions extends StatelessWidget {
  final List<SubPlan> options;
  final SubPlan? selectedOption;
  final Color accent;
  final bool isDark;
  final void Function(SubPlan option) onOptionSelected;

  const PlanDurationOptions({
    super.key,
    required this.options,
    required this.selectedOption,
    required this.accent,
    required this.isDark,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final borderColor =
        isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    final sorted = List<SubPlan>.from(options)
      ..sort((a, b) => (a.durationDays ?? 0).compareTo(b.durationDays ?? 0));

    final bestValue = sorted.length > 1 ? sorted.last : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose billing period',
          style: AppTypography.labelMedium.copyWith(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: AppSpacing.spacingSM),
        ...sorted.map((option) {
          final isSelected = selectedOption?.id == option.id;
          final isBestValue = bestValue?.id == option.id && sorted.length > 1;
          final pricing = SubPlanBundlePricing.forOption(option, sorted);

          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.spacingSM),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onOptionSelected(option),
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacingMD,
                    vertical: AppSpacing.spacingMD,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accent.withValues(alpha: isDark ? 0.18 : 0.1)
                        : surfaceColor,
                    borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                    border: Border.all(
                      color: isSelected ? accent : borderColor,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SelectionDot(
                        selected: isSelected,
                        accent: accent,
                        borderColor: borderColor,
                      ),
                      SizedBox(width: AppSpacing.spacingMD),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  option.durationLabel,
                                  style: AppTypography.body.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (isBestValue) ...[
                                  SizedBox(width: AppSpacing.spacingSM),
                                  _Badge(
                                    label: 'Best value',
                                    background: accent,
                                  ),
                                ],
                                if (pricing.hasBundleDiscount &&
                                    pricing.discountPercent != null) ...[
                                  SizedBox(width: AppSpacing.spacingSM),
                                  _Badge(
                                    label: '${pricing.discountPercent}% OFF',
                                    background: AppColors.feedbackSuccess,
                                  ),
                                ],
                              ],
                            ),
                            if (option.monthsCount > 1) ...[
                              SizedBox(height: AppSpacing.spacingXS),
                              Text(
                                '${_formatPrice(option.perMonthPrice, option.currency)}/month',
                                style: AppTypography.caption.copyWith(
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                            if (pricing.hasBundleDiscount) ...[
                              SizedBox(height: AppSpacing.spacingXS),
                              Text(
                                'Save ${_formatPrice(pricing.savingsAmount, option.currency)}',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.feedbackSuccess,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatPrice(
                              pricing.sellingPrice,
                              option.currency,
                            ),
                            style: AppTypography.h3.copyWith(
                              color: isSelected ? accent : textColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (pricing.hasBundleDiscount &&
                              pricing.originalPrice != null) ...[
                            SizedBox(height: AppSpacing.spacingXS),
                            Text(
                              'Was ${_formatPrice(pricing.originalPrice!, option.currency)}',
                              style: AppTypography.caption.copyWith(
                                color: secondaryTextColor,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  String _formatPrice(double price, String currency) {
    final symbol =
        currency.toUpperCase() == 'USD' ? '\$' : currency.toUpperCase();
    final decimals = price % 1 == 0 ? 0 : 2;
    return '$symbol${price.toStringAsFixed(decimals)}';
  }
}

class _SelectionDot extends StatelessWidget {
  final bool selected;
  final Color accent;
  final Color borderColor;

  const _SelectionDot({
    required this.selected,
    required this.accent,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? accent : borderColor,
          width: 2,
        ),
        color: selected ? accent.withValues(alpha: 0.15) : Colors.transparent,
      ),
      child: selected
          ? Center(
              child: AppSvgIcon(
                assetPath: AppIcons.check,
                size: 12,
                color: accent,
              ),
            )
          : null,
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color background;

  const _Badge({
    required this.label,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.spacingSM,
        vertical: AppSpacing.spacingXS,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.radiusSM),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}
