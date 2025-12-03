// Widget: PlanCard
// Subscription plan card
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/app_theme.dart';
import '../buttons/gradient_button.dart';

/// Plan card widget
/// Displays subscription plan with features and pricing
class PlanCard extends ConsumerWidget {
  final String planName;
  final String price;
  final String? period; // e.g., "per month", "per year"
  final List<String> features;
  final bool isPopular;
  final bool isSelected;
  final VoidCallback? onSelect;

  const PlanCard({
    Key? key,
    required this.planName,
    required this.price,
    this.period,
    this.features = const [],
    this.isPopular = false,
    this.isSelected = false,
    this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
          border: Border.all(
            color: isSelected
                ? AppColors.accentPurple
                : (isPopular ? AppColors.accentPurple.withOpacity(0.5) : borderColor),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accentPurple.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPopular)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacingMD,
                  vertical: AppSpacing.spacingXS,
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                ),
                child: Text(
                  'Most Popular',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (isPopular) SizedBox(height: AppSpacing.spacingMD),
            Text(
              planName,
              style: AppTypography.h2.copyWith(color: textColor),
            ),
            SizedBox(height: AppSpacing.spacingSM),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: AppTypography.h1.copyWith(
                    color: AppColors.accentPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (period != null) ...[
                  SizedBox(width: AppSpacing.spacingXS),
                  Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      period!,
                      style: AppTypography.body.copyWith(
                        color: secondaryTextColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (features.isNotEmpty) ...[
              SizedBox(height: AppSpacing.spacingLG),
              ...features.map((feature) {
                return Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.spacingSM),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 20,
                        color: AppColors.onlineGreen,
                      ),
                      SizedBox(width: AppSpacing.spacingSM),
                      Expanded(
                        child: Text(
                          feature,
                          style: AppTypography.body.copyWith(color: textColor),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
            SizedBox(height: AppSpacing.spacingLG),
            GradientButton(
              text: isSelected ? 'Selected' : 'Select Plan',
              onPressed: onSelect,
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}
