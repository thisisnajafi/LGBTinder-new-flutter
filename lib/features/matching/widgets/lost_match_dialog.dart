import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../../core/theme/spacing_constants.dart';
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
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusLG),
        ),
        title: Text(
          'You lost a match',
          style: AppTypography.h3.copyWith(color: textColor),
        ),
        content: Text(
          'Passing on this profile removed your mutual match.',
          style: AppTypography.body.copyWith(color: secondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'OK',
              style: AppTypography.button.copyWith(
                color: AppColors.accentPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
