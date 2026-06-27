// Screen: ComprehensiveSettingsScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/premium/premium_design_system.dart';
import '../../features/settings/presentation/screens/sound_preferences_screen.dart';
import '../../routes/app_router.dart';
import '../../widgets/avatar/avatar_with_status.dart';
import '../../widgets/badges/premium_badge.dart';
import '../../widgets/badges/verification_badge.dart';
import '../active_sessions_screen.dart';
import '../emergency_contacts_screen.dart';
import '../notification_settings_screen.dart';
import '../privacy_settings_screen.dart';
import '../safety_settings_screen.dart';
import '../two_factor_auth_screen.dart';
import 'account_management_screen.dart';

/// Comprehensive settings screen — premium settings hub (legacy entry).
class ComprehensiveSettingsScreen extends ConsumerStatefulWidget {
  const ComprehensiveSettingsScreen({super.key});

  @override
  ConsumerState<ComprehensiveSettingsScreen> createState() =>
      _ComprehensiveSettingsScreenState();
}

class _ComprehensiveSettingsScreenState
    extends ConsumerState<ComprehensiveSettingsScreen> {
  String _userName = 'User';
  String? _userAvatarUrl;
  bool _isPremium = false;
  bool _isVerified = false;

  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return PremiumDetailScaffold(
      title: 'Settings',
      subtitle: 'Account, privacy, and preferences',
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.spacingXXL),
        children: [
          PremiumShell(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
            child: PremiumTapScale(
              onTap: () {},
              semanticLabel: 'View profile',
              child: Row(
                children: [
                  AvatarWithStatus(
                    imageUrl: _userAvatarUrl,
                    name: _userName,
                    isOnline: false,
                    size: 64,
                  ),
                  const SizedBox(width: AppSpacing.spacingMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _userName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_isVerified) ...[
                              const SizedBox(width: AppSpacing.spacingSM),
                              const VerificationBadge(isVerified: true, size: 20),
                            ],
                            if (_isPremium) ...[
                              const SizedBox(width: AppSpacing.spacingSM),
                              const PremiumBadge(isPremium: true, fontSize: 10),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.spacingXS),
                        Text(
                          'View and edit your profile',
                          style: theme.textTheme.bodySmall?.copyWith(color: muted),
                        ),
                      ],
                    ),
                  ),
                  AppSvgIcon(
                    assetPath: AppIcons.chevronRight,
                    size: 18,
                    color: muted,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.spacingXL),
          PremiumSettingsGroup(
            title: 'Account',
            children: [
              PremiumSettingsTile(
                iconPath: AppIcons.user,
                title: 'Account Management',
                subtitle: 'Email and password',
                onTap: () => _push(const AccountManagementScreen()),
              ),
              PremiumSettingsTile(
                iconPath: AppIcons.key,
                title: 'Two-Factor Authentication',
                subtitle: 'Add an extra layer of security',
                onTap: () => _push(const TwoFactorAuthScreen()),
              ),
              PremiumSettingsTile(
                iconPath: AppIcons.getIconPath('mobile'),
                title: 'Active Sessions',
                subtitle: 'Manage your logged-in devices',
                onTap: () => _push(const ActiveSessionsScreen()),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacingXL),
          PremiumSettingsGroup(
            title: 'Privacy & Safety',
            children: [
              PremiumSettingsTile(
                iconPath: AppIcons.lock,
                title: 'Privacy',
                subtitle: 'Control your privacy settings',
                onTap: () => _push(const PrivacySettingsScreen()),
              ),
              PremiumSettingsTile(
                iconPath: AppIcons.shield,
                title: 'Safety',
                subtitle: 'Safety and security settings',
                onTap: () => _push(const SafetySettingsScreen()),
              ),
              PremiumSettingsTile(
                iconPath: AppIcons.danger,
                title: 'Emergency Contacts',
                subtitle: 'Manage emergency contacts',
                onTap: () => _push(const EmergencyContactsScreen()),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacingXL),
          PremiumSettingsGroup(
            title: 'Notifications',
            children: [
              PremiumSettingsTile(
                iconPath: AppIcons.notification,
                title: 'Notification Settings',
                subtitle: 'Manage your notification preferences',
                onTap: () => _push(const NotificationSettingsScreen()),
              ),
              PremiumSettingsTile(
                iconPath: AppIcons.getIconPath('volume-high'),
                title: 'Sounds',
                subtitle: 'Message, call, and notification sounds',
                onTap: () => _push(const SoundPreferencesScreen()),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacingXL),
          PremiumSettingsGroup(
            title: 'Premium & Payments',
            children: [
              PremiumSettingsTile(
                iconPath: AppIcons.crown,
                title: 'Subscription',
                subtitle: 'Manage your premium subscription',
                accent: AppColors.accentRose,
                onTap: () => context.push(AppRoutes.subscriptionManagement),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacingXL),
          PremiumSettingsGroup(
            title: 'Support',
            children: [
              PremiumSettingsTile(
                iconPath: AppIcons.support,
                title: 'Help & Support',
                subtitle: 'Get help and contact support',
                onTap: () => context.push(AppRoutes.helpSupport),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacingXL),
          PremiumSettingsGroup(
            title: 'About',
            children: [
              PremiumInfoRow(
                label: 'App version',
                value: '1.0.0',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
