import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/data/models/passport_location.dart';
import '../../../core/location/passport_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/app_icons.dart';

/// Shown on discover when a premium passport search location is active.
class DiscoverPassportBanner extends ConsumerWidget {
  const DiscoverPassportBanner({
    super.key,
    required this.passport,
    required this.onReturnHome,
    this.isClearing = false,
  });

  final PassportLocation passport;
  final VoidCallback onReturnHome;
  final bool isClearing;

  @override
  Widget build(BuildContext context) {
    if (!passport.active) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final label = passport.displayLabel;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.contentPadding,
        0,
        AppSpacing.contentPadding,
        AppSpacing.spacingSM,
      ),
      child: Material(
        color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
          onTap: isClearing ? null : onReturnHome,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacingMD,
              vertical: AppSpacing.spacingSM,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                AppSvgIcon(
                  assetPath: AppIcons.map,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.spacingSM),
                Expanded(
                  child: Text(
                    'Passport active — exploring $label',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isClearing)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Text(
                    'Return home',
                    style: AppTypography.labelSmall.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
