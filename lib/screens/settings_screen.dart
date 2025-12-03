// Screen: SettingsScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../core/utils/app_icons.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/divider_custom.dart';
import '../widgets/avatar/avatar_with_status.dart';
import 'settings/account_management_screen.dart';
import 'privacy_settings_screen.dart';
import 'notification_settings_screen.dart';
import 'safety_settings_screen.dart';
import 'accessibility_settings_screen.dart';
import 'premium_features_screen.dart';
import 'payment_settings_screen.dart';
import 'legal/terms_of_service_screen.dart';
import 'legal/privacy_policy_screen.dart';
import '../features/payments/providers/payment_providers.dart';
import '../features/payments/data/models/subscription_plan.dart';
import '../features/payments/presentation/screens/subscription_management_screen.dart';
import '../features/payments/presentation/screens/google_play_billing_test_screen.dart';
import '../pages/onboarding_page.dart';

/// Settings screen - Main settings page
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        children: [
          // Profile section
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            child: Row(
              children: [
                AvatarWithStatus(
                  imageUrl: 'https://via.placeholder.com/100',
                  name: 'User',
                  isOnline: true,
                  size: 64.0,
                ),
                SizedBox(width: AppSpacing.spacingLG),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alex',
                        style: AppTypography.h2.copyWith(color: textColor),
                      ),
                      SizedBox(height: AppSpacing.spacingXS),
                      Text(
                        'alex@example.com',
                        style: AppTypography.body.copyWith(color: secondaryTextColor),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: AppSvgIcon(
                    assetPath: AppIcons.chevronRight,
                    color: secondaryTextColor,
                    size: 24,
                  ),
                  onPressed: () {
                    context.go('/profile');
                  },
                ),
              ],
            ),
          ),
          DividerCustom(),

          // Account section
          SectionHeader(
            title: 'Account',
            iconPath: AppIcons.userOutline,
          ),
          _buildSettingsItem(
            context: context,
            iconPath: AppIcons.userEdit,
            title: 'Account Management',
            subtitle: 'Edit profile, change password',
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
          ),
          _buildSettingsItem(
            context: context,
            iconPath: AppIcons.lockOutline,
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
          ),
          _buildSettingsItem(
            context: context,
            iconPath: AppIcons.card,
            title: 'Payment Settings',
            subtitle: 'Configure payment systems and features',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PaymentSettingsScreen(),
                ),
              );
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
          _buildSettingsItem(
            context: context,
            iconPath: AppIcons.discover,
            title: 'Complete Setup',
            subtitle: 'Finish setting up your preferences',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OnboardingPage(),
                ),
              );
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
          _buildSettingsItem(
            context: context,
            iconPath: AppIcons.notification,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
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
          ),
          DividerCustom(),

          // Safety section
          SectionHeader(
            title: 'Safety',
            iconPath: AppIcons.shield,
          ),
          _buildSettingsItem(
            context: context,
            iconPath: AppIcons.shieldTick,
            title: 'Safety Center',
            subtitle: 'Report, block, and safety tools',
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
          ),
          DividerCustom(),

          // Premium section
          SectionHeader(
            title: 'Premium',
            iconPath: AppIcons.star,
          ),
          _buildSettingsItem(
            context: context,
            iconPath: AppIcons.crown,
            title: 'Premium Features',
            subtitle: ref.watch(subscriptionStatusProvider).when(
                  data: (status) => status?.isActive == true
                      ? 'Active - ${status?.planName ?? "Premium"}'
                      : 'Unlock premium features',
                  loading: () => 'Loading...',
                  error: (_, __) => 'Unlock premium features',
                ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PremiumFeaturesScreen(),
                ),
              );
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            trailing: ref.watch(subscriptionStatusProvider).when(
                  data: (status) => status?.isActive == true
                      ? Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.spacingSM,
                            vertical: AppSpacing.spacingXS,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.onlineGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                            border: Border.all(color: AppColors.onlineGreen),
                          ),
                          child: Text(
                            'ACTIVE',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.onlineGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.spacingSM,
                            vertical: AppSpacing.spacingXS,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.accentPurple, AppColors.accentPink],
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                          ),
                          child: Text(
                            'UPGRADE',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
          ),
          // Subscription Management (only show if subscribed)
          if (ref.watch(subscriptionStatusProvider).maybeWhen(
                data: (status) => status?.isActive == true,
                orElse: () => false,
              ))
            _buildSettingsItem(
              context: context,
              iconPath: AppIcons.card,
              title: 'Subscription',
              subtitle: 'Manage your subscription',
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
            ),
          // Google Play Billing Test (development only)
          _buildSettingsItem(
            context: context,
            iconPath: AppIcons.settings,
            title: 'Google Play Billing Test',
            subtitle: 'Test Google Play Billing integration',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GooglePlayBillingTestScreen(),
                ),
              );
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
          DividerCustom(),

          // Accessibility section
          SectionHeader(
            title: 'Accessibility',
            iconPath: AppIcons.settings,
          ),
          _buildSettingsItem(
            context: context,
            iconPath: AppIcons.settings,
            title: 'Accessibility Settings',
            subtitle: 'Customize accessibility options',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccessibilitySettingsScreen(),
                ),
              );
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
          DividerCustom(),

          // About section
          SectionHeader(
            title: 'About',
            iconPath: AppIcons.info,
          ),
          _buildSettingsItem(
            context: context,
            iconPath: AppIcons.help,
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            onTap: () {
              context.go('/help');
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
          _buildSettingsItem(
            context: context,
            iconPath: AppIcons.document,
            title: 'Terms of Service',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsOfServiceScreen(),
                ),
              );
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
          _buildSettingsItem(
            context: context,
            iconPath: AppIcons.shield,
            title: 'Privacy Policy',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
          SizedBox(height: AppSpacing.spacingXXL),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required BuildContext context,
    IconData? icon,
    String? iconPath,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required Color textColor,
    required Color secondaryTextColor,
    Widget? trailing,
  }) {
    assert(icon != null || iconPath != null, 'Either icon or iconPath must be provided');
    return ListTile(
      leading: iconPath != null
          ? AppSvgIcon(
              assetPath: iconPath,
              color: AppColors.accentPurple,
              size: 24,
            )
          : Icon(icon, color: AppColors.accentPurple),
      title: Text(
        title,
        style: AppTypography.body.copyWith(color: textColor),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: AppTypography.caption.copyWith(color: secondaryTextColor),
            )
          : null,
      trailing: trailing ??
          AppSvgIcon(
            assetPath: AppIcons.chevronRight,
            color: secondaryTextColor,
            size: 20,
          ),
      onTap: onTap,
    );
  }
}
