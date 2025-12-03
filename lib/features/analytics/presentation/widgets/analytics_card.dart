import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/border_radius_constants.dart';

/// Analytics card widget - displays analytics metrics
class AnalyticsCard extends ConsumerWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final String? subtitle;
  final VoidCallback? onTap;

  const AnalyticsCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.subtitle,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = backgroundColor ?? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subtitleColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final iconBgColor = iconColor?.withValues(alpha: 0.1) ?? AppColors.primaryLight.withValues(alpha: 0.1);

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
      ),
      color: cardColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and title row
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(AppSpacing.spacingXS),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor ?? AppColors.primaryLight,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: AppSpacing.spacingSM),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.labelLarge.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.spacingMD),

              // Value
              Text(
                value,
                style: AppTypography.headlineMedium.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Subtitle (if provided)
              if (subtitle != null) ...[
                SizedBox(height: AppSpacing.spacingXS),
                Text(
                  subtitle!,
                  style: AppTypography.bodySmall.copyWith(
                    color: subtitleColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
