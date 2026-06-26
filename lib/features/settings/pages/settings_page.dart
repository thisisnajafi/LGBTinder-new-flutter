import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/providers/theme_mode_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/utils/app_icons.dart';
import '../../../core/widgets/premium/premium_design_system.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/settings/presentation/screens/account_details_screen.dart';
import '../../../features/settings/presentation/screens/appearance_settings_screen.dart';
import '../../../features/settings/presentation/screens/matching_preferences_screen.dart';
import '../../../features/settings/presentation/screens/sound_preferences_screen.dart';
import '../../../routes/app_router.dart';
import '../../../routes/home_tab_routes.dart';
import '../../../screens/active_sessions_screen.dart';
import '../../../screens/blocked_users_screen.dart';
import '../../../screens/help_support_screen.dart';
import '../../../screens/legal/privacy_policy_screen.dart';
import '../../../screens/legal/terms_of_service_screen.dart';
import '../../../screens/notification_settings_screen.dart';
import '../../../screens/privacy_settings_screen.dart';
import '../../../screens/two_factor_auth_screen.dart';

/// Premium account dashboard — aligned with own-profile design language.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  static const double _sectionGap = AppSpacing.spacingXL;
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _appVersion = '${info.version} (${info.buildNumber})');
      }
    } catch (_) {
      if (mounted) setState(() => _appVersion = '1.0.0');
    }
  }

  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to use the app.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.feedbackError),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go(AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return PremiumTabPageLayout(
      title: 'Settings',
      subtitle: 'Your account, privacy, and preferences',
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.spacingXXL),
        children: [
          PremiumHubGridSection(
            title: 'Quick access',
            subtitle: 'Essential account tools',
            actions: [
              PremiumHubActionData(
                iconPath: AppIcons.userEdit,
                title: 'Profile',
                subtitle: 'Edit your dating profile',
                onTap: () => context.go(HomeTabRoutes.locationForTab(3)),
              ),
              PremiumHubActionData(
                iconPath: AppIcons.crown,
                title: 'Membership',
                subtitle: 'Plans & benefits',
                onTap: () => context.pushNamed('subscription-management'),
              ),
              PremiumHubActionData(
                iconPath: AppIcons.shieldTick,
                title: 'Security',
                subtitle: 'Sessions & 2FA',
                onTap: () => _push(const ActiveSessionsScreen()),
              ),
              PremiumHubActionData(
                iconPath: AppIcons.shield,
                title: 'Privacy',
                subtitle: 'Visibility & data',
                onTap: () => _push(const PrivacySettingsScreen()),
              ),
              PremiumHubActionData(
                iconPath: AppIcons.notification,
                title: 'Alerts',
                subtitle: 'Push & email prefs',
                onTap: () => _push(const NotificationSettingsScreen()),
              ),
              PremiumHubActionData(
                iconPath: AppIcons.discover,
                title: 'Discovery',
                subtitle: 'Who you want to meet',
                onTap: () => _push(const MatchingPreferencesScreen()),
              ),
            ],
          ),
          const SizedBox(height: _sectionGap),
          PremiumSettingsGroup(
            title: 'Account',
            subtitle: 'Identity, safety, and access',
            children: [
              PremiumSettingsTile(
                iconPath: AppIcons.user,
                title: 'Account details',
                subtitle: 'Phone, email, and password',
                onTap: () => _push(const AccountDetailsScreen()),
              ),
              PremiumSettingsTile(
                iconPath: AppIcons.block,
                title: 'Blocked users',
                subtitle: 'Manage blocked profiles',
                accent: AppColors.feedbackWarning,
                onTap: () => context.pushNamed('blocked-users'),
              ),
              PremiumSettingsTile(
                iconPath: AppIcons.lockOutline,
                title: 'Two-factor authentication',
                subtitle: 'Extra sign-in protection',
                onTap: () => _push(const TwoFactorAuthScreen()),
              ),
            ],
          ),
          const SizedBox(height: _sectionGap),
          PremiumSettingsGroup(
            title: 'App experience',
            subtitle: 'Sounds, language, and appearance',
            children: [
              PremiumSettingsTile(
                iconPath: AppIcons.getIconPath('volume-high'),
                title: 'Sounds & haptics',
                subtitle: 'Notification sounds',
                onTap: () => _push(const SoundPreferencesScreen()),
              ),
              PremiumSettingsTile(
                iconPath: AppIcons.setting,
                title: 'Appearance',
                subtitle: themeModeLabel(themeMode),
                onTap: () => _push(const AppearanceSettingsScreen()),
              ),
            ],
          ),
          const SizedBox(height: _sectionGap),
          PremiumSettingsGroup(
            title: 'Support & legal',
            children: [
              PremiumSettingsTile(
                iconPath: AppIcons.help,
                title: 'Help & support',
                subtitle: 'FAQs and contact us',
                onTap: () => context.pushNamed('help-support'),
              ),
              PremiumSettingsTile(
                iconPath: AppIcons.shield,
                title: 'Privacy policy',
                onTap: () => context.pushNamed('privacy-policy'),
              ),
              PremiumSettingsTile(
                iconPath: AppIcons.document,
                title: 'Terms of service',
                onTap: () => context.pushNamed('terms-of-service'),
              ),
              PremiumSettingsTile(
                iconPath: AppIcons.info,
                title: 'About',
                subtitle: _appVersion != null ? 'Version $_appVersion' : 'Loading…',
                onTap: () {},
                trailing: _appVersion != null
                    ? Text(
                        _appVersion!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.45),
                            ),
                      )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: _sectionGap),
          PremiumSettingsGroup(
            title: 'Account actions',
            children: [
              PremiumSettingsTile(
                iconPath: AppIcons.logout,
                title: 'Log out',
                onTap: _confirmLogout,
                destructive: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
