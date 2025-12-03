// Screen: SafetySettingsScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/divider_custom.dart';
import '../widgets/modals/confirmation_dialog.dart';
import 'blocked_users_screen.dart';
import 'report_history_screen.dart';
import 'emergency_contacts_screen.dart';

/// Safety settings screen - Manage safety and privacy settings
class SafetySettingsScreen extends ConsumerStatefulWidget {
  const SafetySettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SafetySettingsScreen> createState() => _SafetySettingsScreenState();
}

class _SafetySettingsScreenState extends ConsumerState<SafetySettingsScreen> {
  bool _shareLocation = false;
  bool _showDistance = true;
  bool _allowMessages = true;
  bool _readReceipts = true;
  bool _safetyAlerts = true;
  bool _blockUnknownUsers = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Safety Settings',
        showBackButton: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        children: [
          // Privacy settings
          SectionHeader(
            title: 'Privacy',
            icon: Icons.lock,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildSwitchTile(
            title: 'Share Location',
            subtitle: 'Allow others to see your approximate location',
            value: _shareLocation,
            onChanged: (value) {
              setState(() {
                _shareLocation = value;
              });
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
          _buildSwitchTile(
            title: 'Show Distance',
            subtitle: 'Display distance to other users',
            value: _showDistance,
            onChanged: (value) {
              setState(() {
                _showDistance = value;
              });
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
          _buildSwitchTile(
            title: 'Allow Messages',
            subtitle: 'Let others message you',
            value: _allowMessages,
            onChanged: (value) {
              setState(() {
                _allowMessages = value;
              });
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
          _buildSwitchTile(
            title: 'Read Receipts',
            subtitle: 'Show when messages are read',
            value: _readReceipts,
            onChanged: (value) {
              setState(() {
                _readReceipts = value;
              });
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Safety features
          SectionHeader(
            title: 'Safety Features',
            icon: Icons.shield,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildSwitchTile(
            title: 'Safety Alerts',
            subtitle: 'Get notified about potential safety concerns',
            value: _safetyAlerts,
            onChanged: (value) {
              setState(() {
                _safetyAlerts = value;
              });
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
          _buildSwitchTile(
            title: 'Block Unknown Users',
            subtitle: 'Only allow messages from matched users',
            value: _blockUnknownUsers,
            onChanged: (value) {
              setState(() {
                _blockUnknownUsers = value;
              });
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Safety actions
          SectionHeader(
            title: 'Safety Actions',
            icon: Icons.security,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildActionTile(
            icon: Icons.block,
            title: 'Blocked Users',
            subtitle: 'Manage blocked users',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BlockedUsersScreen(),
                ),
              );
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
          _buildActionTile(
            icon: Icons.report,
            title: 'Report History',
            subtitle: 'View your reports',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReportHistoryScreen(),
                ),
              );
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
          _buildActionTile(
            icon: Icons.emergency,
            title: 'Emergency Contacts',
            subtitle: 'Set up emergency contacts',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmergencyContactsScreen(),
                ),
              );
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Danger zone
          SectionHeader(
            title: 'Account Actions',
            icon: Icons.warning,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildDangerTile(
            icon: Icons.delete_forever,
            title: 'Delete Account',
            subtitle: 'Permanently delete your account and all data',
            onTap: () async {
              final confirmed = await ConfirmationDialog.show(
                context,
                title: 'Delete Account',
                message: 'Are you sure you want to delete your account? This action cannot be undone.',
                confirmText: 'Delete',
                cancelText: 'Cancel',
                isDestructive: true,
              );
              if (confirmed == true) {
                // TODO: Delete account via API
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account deletion requested')),
                );
              }
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
          SizedBox(height: AppSpacing.spacingXXL),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: AppTypography.body.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.caption.copyWith(color: secondaryTextColor),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.accentPurple,
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.accentPurple),
      title: Text(
        title,
        style: AppTypography.body.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.caption.copyWith(color: secondaryTextColor),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: secondaryTextColor,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDangerTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.notificationRed),
      title: Text(
        title,
        style: AppTypography.body.copyWith(
          color: AppColors.notificationRed,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.caption.copyWith(color: secondaryTextColor),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: secondaryTextColor,
      ),
      onTap: onTap,
    );
  }
}
