// Widget: RetentionOfferDialog
// Retention offer dialog
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/app_theme.dart';
import '../buttons/gradient_button.dart';
import '../badges/premium_badge.dart';

/// Retention offer dialog widget
/// Dialog offering discount to retain subscription
class RetentionOfferDialog extends ConsumerWidget {
  final String discountPercent;
  final String originalPrice;
  final String discountedPrice;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const RetentionOfferDialog({
    Key? key,
    required this.discountPercent,
    required this.originalPrice,
    required this.discountedPrice,
    this.onAccept,
    this.onDecline,
  }) : super(key: key);

  static Future<bool?> show(
    BuildContext context, {
    required String discountPercent,
    required String originalPrice,
    required String discountedPrice,
    VoidCallback? onAccept,
    VoidCallback? onDecline,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RetentionOfferDialog(
        discountPercent: discountPercent,
        originalPrice: originalPrice,
        discountedPrice: discountedPrice,
        onAccept: () {
          Navigator.of(context).pop(true);
          onAccept?.call();
        },
        onDecline: () {
          Navigator.of(context).pop(false);
          onDecline?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.spacingXL),
        decoration: BoxDecoration(
          gradient: AppTheme.accentGradient,
          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PremiumBadge(isPremium: true, fontSize: 14),
            SizedBox(height: AppSpacing.spacingLG),
            Text(
              'Wait! Special Offer',
              style: AppTypography.h1.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            Container(
              padding: EdgeInsets.all(AppSpacing.spacingMD),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              ),
              child: Column(
                children: [
                  Text(
                    '$discountPercent% OFF',
                    style: AppTypography.h1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: AppSpacing.spacingSM),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        originalPrice,
                        style: AppTypography.body.copyWith(
                          color: Colors.white70,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      SizedBox(width: AppSpacing.spacingSM),
                      Text(
                        discountedPrice,
                        style: AppTypography.h2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.spacingLG),
            Text(
              'Stay with us and save!',
              style: AppTypography.body.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.spacingXXL),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white),
                      padding: EdgeInsets.symmetric(
                        vertical: AppSpacing.spacingMD,
                      ),
                    ),
                    child: Text(
                      'No Thanks',
                      style: AppTypography.button.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.spacingMD),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: AppSpacing.spacingMD,
                      ),
                    ),
                    child: Text(
                      'Keep Premium',
                      style: AppTypography.button.copyWith(
                        color: AppColors.accentPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
