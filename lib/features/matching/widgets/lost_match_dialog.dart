import 'package:flutter/material.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../../core/theme/typography.dart';

/// Shown when a dislike removes an existing mutual match.
class LostMatchDialog {
  LostMatchDialog._();

  static Future<void> show(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ResponsiveGrid.constrainedTo(
        ctx,
        AlertDialog(
          backgroundColor:
              isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.radiusLG),
          ),
          title: AppText(
            'You lost a match',
            style: AppTypography.h3.copyWith(color: textColor),
            maxLines: 2,
          ),
          content: AppText(
            'Passing on this profile removed your mutual match.',
            style: AppTypography.body.copyWith(color: secondaryColor),
            maxLines: 4,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: AppText(
                'OK',
                style: AppTypography.button.copyWith(
                  color: AppColors.accentPurple,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
        tablet: 400,
      ),
    );
  }
}
