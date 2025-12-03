// Widget: PremiumFeatureCard
// Premium feature card
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/app_theme.dart';
import '../badges/premium_badge.dart';

/// Premium feature card widget
/// Displays a premium feature with icon, title, description, and badge
class PremiumFeatureCard extends ConsumerWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;
  final VoidCallback? onTap;

  const PremiumFeatureCard({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    this.isUnlocked = false,
    this.onTap,
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
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
          border: Border.all(
            color: isUnlocked ? AppColors.accentPurple : borderColor,
            width: isUnlocked ? 2 : 1,
          ),
          gradient: isUnlocked ? null : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              surfaceColor,
              surfaceColor.withOpacity(0.8),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.spacingMD),
              decoration: BoxDecoration(
                gradient: isUnlocked
                    ? AppTheme.accentGradient
                    : LinearGradient(
                        colors: [
                          secondaryTextColor.withOpacity(0.2),
                          secondaryTextColor.withOpacity(0.1),
                        ],
                      ),
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              ),
              child: Icon(
                icon,
                color: isUnlocked
                    ? Colors.white
                    : secondaryTextColor,
                size: 32,
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
                          style: AppTypography.h3.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!isUnlocked)
                        PremiumBadge(isPremium: false, fontSize: 10),
                    ],
                  ),
                  SizedBox(height: AppSpacing.spacingXS),
                  Text(
                    description,
                    style: AppTypography.body.copyWith(
                      color: secondaryTextColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!isUnlocked)
              Icon(
                Icons.lock_outline,
                color: secondaryTextColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
