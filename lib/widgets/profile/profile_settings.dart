// Widget: ProfileSettings
// Profile settings widget
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/utils/app_icons.dart';

/// Profile settings widget
/// Displays settings options for profile management
class ProfileSettings extends ConsumerWidget {
  final Function()? onEditProfile;
  final Function()? onPrivacySettings;
  final Function()? onBlockedUsers;
  final Function()? onDeleteAccount;
  final Function()? onLogout;

  const ProfileSettings({
    Key? key,
    this.onEditProfile,
    this.onPrivacySettings,
    this.onBlockedUsers,
    this.onDeleteAccount,
    this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Column(
      children: [
        _buildSettingItem(
          context: context,
          iconPath: AppIcons.edit,
          title: 'Edit Profile',
          subtitle: 'Update your profile information',
          onTap: onEditProfile,
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
        ),
        _buildSettingItem(
          context: context,
          iconPath: AppIcons.shield,
          title: 'Privacy Settings',
          subtitle: 'Manage your privacy preferences',
          onTap: onPrivacySettings,
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
        ),
        _buildSettingItem(
          context: context,
          iconPath: AppIcons.block,
          title: 'Blocked Users',
          subtitle: 'Manage blocked users',
          onTap: onBlockedUsers,
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
        ),
        Divider(
          color: borderColor,
          height: AppSpacing.spacingXL,
        ),
        _buildSettingItem(
          context: context,
          iconPath: AppIcons.delete,
          title: 'Delete Account',
          subtitle: 'Permanently delete your account',
          onTap: onDeleteAccount,
          textColor: AppColors.notificationRed,
          secondaryTextColor: secondaryTextColor,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          isDestructive: true,
        ),
        _buildSettingItem(
          context: context,
          iconPath: AppIcons.logout,
          title: 'Logout',
          subtitle: 'Sign out of your account',
          onTap: onLogout,
          textColor: AppColors.notificationRed,
          secondaryTextColor: secondaryTextColor,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required BuildContext context,
    IconData? icon, // Legacy support
    String? iconPath, // SVG icon path
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border(
            bottom: BorderSide(color: borderColor, width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.spacingMD),
              decoration: BoxDecoration(
                color: isDestructive
                    ? AppColors.notificationRed.withOpacity(0.1)
                    : AppColors.accentPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.radiusSM),
              ),
              child: iconPath != null
                  ? AppSvgIcon(
                      assetPath: iconPath!,
                      size: 24,
                      color: isDestructive ? AppColors.notificationRed : AppColors.accentPurple,
                    )
                  : Icon(
                      icon!,
                      color: isDestructive ? AppColors.notificationRed : AppColors.accentPurple,
                    ),
            ),
            SizedBox(width: AppSpacing.spacingLG),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.h3.copyWith(color: textColor),
                  ),
                  SizedBox(height: AppSpacing.spacingXS),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(color: secondaryTextColor),
                  ),
                ],
              ),
            ),
            AppSvgIcon(
              assetPath: AppIcons.chevronRight,
              size: 20,
              color: secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }
}
