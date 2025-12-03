// Widget: ProfileBio
// Profile bio section
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/utils/app_icons.dart';

/// Profile bio widget
/// Displays user's profile bio/description
/// Data from API: user.profile_bio
class ProfileBio extends ConsumerWidget {
  final String? bio;
  final VoidCallback? onEdit;
  final bool isEditable;

  const ProfileBio({
    Key? key,
    this.bio,
    this.onEdit,
    this.isEditable = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    if (bio == null || bio!.isEmpty) {
      if (!isEditable) {
        return const SizedBox.shrink();
      }
      return Container(
        margin: EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Add a bio to tell others about yourself',
                style: AppTypography.body.copyWith(color: secondaryTextColor),
              ),
            ),
            if (onEdit != null)
              IconButton(
                icon: Icon(
                  Icons.add,
                  color: AppColors.accentPurple,
                ),
                onPressed: onEdit,
              ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'About',
                style: AppTypography.h3.copyWith(color: textColor),
              ),
              if (isEditable && onEdit != null)
                IconButton(
                  icon: AppSvgIcon(
                    assetPath: AppIcons.edit,
                    size: 20,
                    color: AppColors.accentPurple,
                  ),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Text(
            bio!,
            style: AppTypography.body.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
}
