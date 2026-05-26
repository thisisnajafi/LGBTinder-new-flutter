import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/animation_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../widgets/buttons/gradient_button.dart';

/// Bottom sheet confirmation before skipping onboarding.
Future<bool?> showOnboardingSkipSheet(BuildContext context) {
  HapticFeedback.lightImpact();
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final textTheme = Theme.of(context).textTheme;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

      return Padding(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppRadius.radiusLG),
          ),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.spacingXL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Skip for now?',
                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: AppSpacing.spacingMD),
                Text(
                  'You can always finish setup later in Settings. Ready to jump in?',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.spacingXL),
                GradientButton(
                  text: 'Keep Going',
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                SizedBox(height: AppSpacing.spacingSM),
                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop(true);
                  },
                  child: Text(
                    'Skip',
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.accentRose,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
