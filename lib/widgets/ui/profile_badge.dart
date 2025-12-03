// Widget: ProfileBadge
// Profile badge widget
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/app_theme.dart';
import '../badges/verification_badge.dart';
import '../badges/premium_badge.dart';

/// Profile badge widget
/// Displays profile badges (verified, premium, etc.)
class ProfileBadge extends ConsumerWidget {
  final bool isVerified;
  final bool isPremium;
  final String? customBadge;
  final IconData? customIcon;
  final Color? customColor;

  const ProfileBadge({
    Key? key,
    this.isVerified = false,
    this.isPremium = false,
    this.customBadge,
    this.customIcon,
    this.customColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    if (customBadge != null) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.spacingMD,
          vertical: AppSpacing.spacingXS,
        ),
        decoration: BoxDecoration(
          color: customColor?.withOpacity(0.2) ?? AppColors.accentPurple.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppRadius.radiusRound),
          border: Border.all(
            color: customColor ?? AppColors.accentPurple,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (customIcon != null) ...[
              Icon(
                customIcon,
                size: 14,
                color: customColor ?? AppColors.accentPurple,
              ),
              SizedBox(width: AppSpacing.spacingXS),
            ],
            Text(
              customBadge!,
              style: AppTypography.caption.copyWith(
                color: customColor ?? AppColors.accentPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isVerified)
          VerificationBadge(isVerified: true, size: 20),
        if (isVerified && isPremium)
          SizedBox(width: AppSpacing.spacingXS),
        if (isPremium)
          PremiumBadge(isPremium: true, fontSize: 10),
      ],
    );
  }
}
