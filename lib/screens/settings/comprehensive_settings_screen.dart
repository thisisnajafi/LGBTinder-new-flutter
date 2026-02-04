// Screen: ComprehensiveSettingsScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../widgets/navbar/app_bar_custom.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/divider_custom.dart';
import '../../widgets/avatar/avatar_with_status.dart';
import '../../widgets/badges/premium_badge.dart';
import '../../widgets/badges/verification_badge.dart';
import '../notification_settings_screen.dart';
import '../privacy_settings_screen.dart';
import '../account_management_screen.dart';
import '../subscription_management_screen.dart';
import '../two_factor_auth_screen.dart';
import '../active_sessions_screen.dart';
import '../help_support_screen.dart';
import '../emergency_contacts_screen.dart';
import '../safety_settings_screen.dart';

/// Comprehensive settings screen - Main settings hub
class ComprehensiveSettingsScreen extends ConsumerStatefulWidget {
  const ComprehensiveSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ComprehensiveSettingsScreen> createState() => _ComprehensiveSettingsScreenState();
}

class _ComprehensiveSettingsScreenState extends ConsumerState<ComprehensiveSettingsScreen> {
  // User data (TODO: Get from provider)
  String _userName = 'User';
  String? _userAvatarUrl;
  bool _isPremium = false;
  bool _isVerified = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Settings',
        showBackButton: true,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingSM),
        children: [
          // Profile header
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(
                bottom: BorderSide(color: borderColor, width: 1),
              ),
            ),
            child: Row(
              children: [
                AvatarWithStatus(
                  imageUrl: _userAvatarUrl,
                  name: _userName,
                  isOnline: false,
                  size: 64.0,
                ),
                SizedBox(width: AppSpacing.spacingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _userName,
                            style: AppTypography.h2.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_isVerified) ...[
                            SizedBox(width: AppSpacing.spacingSM),
                            VerificationBadge(isVerified: true, size: 20),
                          ],
                          if (_isPremium) ...[
                            SizedBox(width: AppSpacing.spacingSM),
                            PremiumBadge(isPremium: true, fontSize: 10),
                          ],
                        ],
                      ),
                      SizedBox(height: AppSpacing.spacingXS),
                      Text(
                        'View and edit your profile',
                        style: AppTypography.caption.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: secondaryTextColor,
                ),
              ],
            ),
          ),

          // Account
          SectionHeader(
            title: 'Account',
            icon: Icons.person,
          ),
          _buildSettingsTile(
            icon: Icons.person_outline,
            title: 'Account Management',
            subtitle: 'Email, password, delete account',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AccountManagementScreen(),
                ),
              );
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          _buildSettingsTile(
            icon: Icons.security,
            title: 'Two-Factor Authentication',
            subtitle: 'Add an extra layer of security',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TwoFactorAuthScreen(),
                ),
              );
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          _buildSettingsTile(
            icon: Icons.devices,
            title: 'Active Sessions',
            subtitle: 'Manage your logged-in devices',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ActiveSessionsScreen(),
                ),
              );
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          DividerCustom(),

          // Privacy & Safety
          SectionHeader(
            title: 'Privacy & Safety',
            icon: Icons.lock,
          ),
          _buildSettingsTile(
            icon: Icons.privacy_tip,
            title: 'Privacy',
            subtitle: 'Control your privacy settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacySettingsScreen(),
                ),
              );
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          _buildSettingsTile(
            icon: Icons.shield,
            title: 'Safety',
            subtitle: 'Safety and security settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SafetySettingsScreen(),
                ),
              );
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          _buildSettingsTile(
            icon: Icons.emergency,
            title: 'Emergency Contacts',
            subtitle: 'Manage emergency contacts',
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
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          DividerCustom(),

          // Notifications
          SectionHeader(
            title: 'Notifications',
            icon: Icons.notifications,
          ),
          _buildSettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notification Settings',
            subtitle: 'Manage your notification preferences',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          DividerCustom(),

          // Premium & Payments
          SectionHeader(
            title: 'Premium & Payments',
            icon: Icons.star,
          ),
          _buildSettingsTile(
            icon: Icons.workspace_premium,
            title: 'Subscription',
            subtitle: 'Manage your premium subscription',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionManagementScreen(),
                ),
              );
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          DividerCustom(),

          // Support
          SectionHeader(
            title: 'Support',
            icon: Icons.help_outline,
          ),
          _buildSettingsTile(
            icon: Icons.support_agent,
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpSupportScreen(),
                ),
              );
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          DividerCustom(),

          // App info
          SectionHeader(
            title: 'About',
            icon: Icons.info,
          ),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'App Version',
            subtitle: '1.0.0',
            onTap: null,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingXXL),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accentPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppRadius.radiusSM),
              ),
              child: Icon(
                icon,
                color: AppColors.accentPurple,
                size: 20,
              ),
            ),
            SizedBox(width: AppSpacing.spacingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.body.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: AppSpacing.spacingXS),
                    Text(
                      subtitle,
                      style: AppTypography.caption.copyWith(
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: secondaryTextColor,
              ),
          ],
        ),
      ),
    );
  }
}
