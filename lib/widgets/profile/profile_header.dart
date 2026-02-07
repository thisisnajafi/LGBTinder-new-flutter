// Widget: ProfileHeader
// Profile header with avatar and name
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../avatar/avatar_with_status.dart';
import '../badges/verification_badge.dart';
import '../badges/premium_badge.dart';
import '../../core/utils/app_icons.dart';

/// Profile header widget
/// Displays user avatar, name, age, location, and badges
/// Data structure based on API: /api/user and /api/profile/{id}
class ProfileHeader extends ConsumerWidget {
  final String name;
  final int? age;
  final String? location; // city, country
  final String? avatarUrl;
  final bool isVerified;
  final bool isPremium;
  final bool isOnline;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onEdit;
  /// When true (e.g. own profile), show a thin pride gradient ring around the avatar.
  final bool showPrideAccent;

  const ProfileHeader({
    Key? key,
    required this.name,
    this.age,
    this.location,
    this.avatarUrl,
    this.isVerified = false,
    this.isPremium = false,
    this.isOnline = false,
    this.onAvatarTap,
    this.onEdit,
    this.showPrideAccent = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      child: Column(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: onAvatarTap,
                child: showPrideAccent
                    ? Container(
                        width: 124,
                        height: 124,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.prideGradient,
                        ),
                        padding: const EdgeInsets.all(2),
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.scaffoldBackgroundColor,
                          ),
                          child: AvatarWithStatus(
                            imageUrl: avatarUrl,
                            name: name,
                            isOnline: isOnline,
                            size: 120.0,
                            showRing: false,
                          ),
                        ),
                      )
                    : AvatarWithStatus(
                        imageUrl: avatarUrl,
                        name: name,
                        isOnline: isOnline,
                        size: 120.0,
                        showRing: true,
                      ),
              ),
              if (onEdit != null)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.accentPurple,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                        width: 3,
                      ),
                    ),
                    child: IconButton(
                      icon: AppSvgIcon(
                        assetPath: AppIcons.edit,
                        size: 20,
                        color: Colors.white,
                      ),
                      onPressed: onEdit,
                      padding: EdgeInsets.all(AppSpacing.spacingSM),
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.spacingLG),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                name,
                style: AppTypography.h1.copyWith(color: textColor),
              ),
              if (isVerified) ...[
                SizedBox(width: AppSpacing.spacingSM),
                VerificationBadge(isVerified: isVerified, size: 24),
              ],
            ],
          ),
          if (age != null || location != null) ...[
            SizedBox(height: AppSpacing.spacingXS),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (age != null)
                  Text(
                    '$age',
                    style: AppTypography.body.copyWith(color: secondaryTextColor),
                  ),
                if (age != null && location != null)
                  Text(
                    ' • ',
                    style: AppTypography.body.copyWith(color: secondaryTextColor),
                  ),
                if (location != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: secondaryTextColor,
                      ),
                      SizedBox(width: AppSpacing.spacingXS),
                      Text(
                        location!,
                        style: AppTypography.body.copyWith(color: secondaryTextColor),
                      ),
                    ],
                  ),
              ],
            ),
          ],
          if (isPremium) ...[
            SizedBox(height: AppSpacing.spacingMD),
            PremiumBadge(isPremium: isPremium),
          ],
        ],
      ),
    );
  }
}
