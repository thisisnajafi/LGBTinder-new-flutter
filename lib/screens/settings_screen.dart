// Screen: SettingsScreen (Task 5 — summary overview with GET /api/settings)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/widgets/app_grouped_list_card.dart';
import '../core/widgets/app_page_header.dart';
import '../core/utils/app_icons.dart';
import '../widgets/avatar/avatar_with_status.dart';
import 'settings/account_management_screen.dart';
import '../features/settings/presentation/screens/matching_preferences_screen.dart';
import '../features/settings/providers/settings_provider.dart';
import 'privacy_settings_screen.dart';
import 'notification_settings_screen.dart';
import 'safety_settings_screen.dart';
import 'accessibility_settings_screen.dart';
import 'premium_features_screen.dart';
import 'payment_settings_screen.dart';
import '../features/marketing/presentation/screens/referral_screen.dart';
import '../features/payments/providers/payment_providers.dart';
import '../features/payments/presentation/screens/google_play_billing_test_screen.dart';
import '../screens/onboarding/onboarding_preferences_screen.dart';
import '../routes/app_router.dart';

/// Settings screen - Main settings overview (Task 5: summary from GET /api/settings)
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(settingsSummaryProvider);
    final subscriptionStatus = ref.watch(subscriptionStatusProvider);
    final isSubscribed = subscriptionStatus.maybeWhen(
      data: (status) => status?.isActive == true,
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(settingsSummaryProvider);
            await ref.read(settingsSummaryProvider.future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const AppPageHeader(title: 'Settings'),
              const SizedBox(height: AppSpacing.spacingLG),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppPageHeader.horizontalPadding,
                ),
                child: Row(
                  children: [
                    AvatarWithStatus(
                      imageUrl: 'https://via.placeholder.com/100',
                      name: summaryAsync.valueOrNull?.profile.displayName ?? 'User',
                      isOnline: true,
                      size: 64.0,
                    ),
                    const SizedBox(width: AppSpacing.spacingLG),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            summaryAsync.valueOrNull?.profile.displayName ?? 'Profile',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.spacingXS),
                          Text(
                            summaryAsync.valueOrNull?.account.email ?? '—',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: AppSvgIcon(
                        assetPath: AppIcons.chevronRight,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                        size: 24,
                      ),
                      onPressed: () {
                        context.go('${AppRoutes.home}?tab=3');
                      },
                    ),
                  ],
                ),
              ),
              AppGroupedListSection(
                title: 'Account',
                children: [
                  _tile(
                    iconPath: AppIcons.userEdit,
                    label: 'Account Management',
                    subtitle: summaryAsync.valueOrNull?.account.email != null
                        ? '${summaryAsync.valueOrNull!.account.email} · Edit profile, password'
                        : 'Edit profile, change password',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AccountManagementScreen(),
                      ),
                    ),
                  ),
                  _tile(
                    iconPath: AppIcons.discover,
                    label: 'Discovery preferences',
                    subtitle: summaryAsync.valueOrNull?.discoverySubtitle ??
                        'Age range, distance, who can see you',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MatchingPreferencesScreen(),
                      ),
                    ),
                  ),
                  _tile(
                    iconPath: AppIcons.share,
                    label: 'Invite Friends',
                    subtitle: 'Share your referral code, earn rewards',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReferralScreen(),
                      ),
                    ),
                  ),
                  _tile(
                    iconPath: AppIcons.lockOutline,
                    label: 'Privacy',
                    subtitle: 'Control your privacy settings',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacySettingsScreen(),
                      ),
                    ),
                  ),
                  _tile(
                    iconPath: AppIcons.card,
                    label: 'Payment Settings',
                    subtitle: 'Configure payment systems and features',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PaymentSettingsScreen(),
                      ),
                    ),
                  ),
                  _tile(
                    iconPath: AppIcons.discover,
                    label: 'Complete Setup',
                    subtitle: 'Finish setting up your preferences',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OnboardingPreferencesScreen(),
                      ),
                    ),
                  ),
                  _tile(
                    iconPath: AppIcons.notification,
                    label: 'Notifications',
                    subtitle: summaryAsync.valueOrNull != null
                        ? '${summaryAsync.valueOrNull!.notifications.subtitle} · Manage preferences'
                        : 'Manage notification preferences',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationSettingsScreen(),
                      ),
                    ),
                    showDivider: false,
                  ),
                ],
              ),
              AppGroupedListSection(
                title: 'Safety',
                children: [
                  _tile(
                    iconPath: AppIcons.shieldTick,
                    label: 'Safety Center',
                    subtitle: 'Report, block, and safety tools',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SafetySettingsScreen(),
                      ),
                    ),
                    showDivider: false,
                  ),
                ],
              ),
              AppGroupedListSection(
                title: 'Premium',
                children: [
                  _tile(
                    iconPath: AppIcons.star,
                    label: 'Compare tiers',
                    subtitle: 'Basid vs Silder vs Golden — see what you get',
                    onTap: () => context.push(AppRoutes.tierComparison),
                  ),
                  _tile(
                    iconPath: AppIcons.crown,
                    label: 'Premium Features',
                    subtitle: subscriptionStatus.when(
                      data: (status) => status?.isActive == true
                          ? 'Active - ${status?.planName ?? "Premium"}'
                          : 'Unlock premium features',
                      loading: () => 'Loading...',
                      error: (_, __) => 'Unlock premium features',
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PremiumFeaturesScreen(),
                      ),
                    ),
                    trailing: subscriptionStatus.when(
                      data: (status) => status?.isActive == true
                          ? _premiumBadge(
                              label: 'ACTIVE',
                              background: AppColors.onlineGreen.withValues(alpha: 0.2),
                              borderColor: AppColors.onlineGreen,
                              textColor: AppColors.onlineGreen,
                            )
                          : _premiumBadge(
                              label: 'UPGRADE',
                              gradient: const LinearGradient(
                                colors: [AppColors.accentPurple, AppColors.accentPink],
                              ),
                              textColor: Colors.white,
                            ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                  _tile(
                    iconPath: AppIcons.card,
                    label: 'Subscription status',
                    subtitle: 'View your current plan and expiry',
                    onTap: () => context.push(AppRoutes.subscriptionStatus),
                  ),
                  if (isSubscribed)
                    _tile(
                      iconPath: AppIcons.card,
                      label: 'Subscription',
                      subtitle: 'Manage your subscription',
                      onTap: () => context.push(AppRoutes.subscriptionManagement),
                    ),
                  _tile(
                    iconPath: AppIcons.settings,
                    label: 'Google Play Billing Test',
                    subtitle: 'Test Google Play Billing integration',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GooglePlayBillingTestScreen(),
                      ),
                    ),
                    showDivider: false,
                  ),
                ],
              ),
              AppGroupedListSection(
                title: 'Accessibility',
                children: [
                  _tile(
                    iconPath: AppIcons.settings,
                    label: 'Accessibility Settings',
                    subtitle: 'Customize accessibility options',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AccessibilitySettingsScreen(),
                      ),
                    ),
                    showDivider: false,
                  ),
                ],
              ),
              AppGroupedListSection(
                title: 'About',
                children: [
                  _tile(
                    iconPath: AppIcons.help,
                    label: 'Help & Support',
                    subtitle: 'Get help and contact support',
                    onTap: () => context.push(AppRoutes.helpSupport),
                  ),
                  _tile(
                    iconPath: AppIcons.document,
                    label: 'Terms of Service',
                    onTap: () => context.push(AppRoutes.termsOfService),
                  ),
                  _tile(
                    iconPath: AppIcons.shield,
                    label: 'Privacy Policy',
                    onTap: () => context.push(AppRoutes.privacyPolicy),
                    showDivider: false,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.spacingXXL),
            ],
          ),
        ),
      ),
    );
  }

  AppGroupedListTile _tile({
    required String iconPath,
    required String label,
    String? subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    bool showDivider = true,
  }) {
    return AppGroupedListTile(
      iconPath: iconPath,
      label: label,
      subtitle: subtitle,
      onTap: onTap,
      trailing: trailing,
      showDivider: showDivider,
    );
  }

  Widget _premiumBadge({
    required String label,
    Color? background,
    Color? borderColor,
    Color? textColor,
    Gradient? gradient,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacingSM,
        vertical: AppSpacing.spacingXS,
      ),
      decoration: BoxDecoration(
        color: background,
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.radiusSM),
        border: borderColor != null ? Border.all(color: borderColor) : null,
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
