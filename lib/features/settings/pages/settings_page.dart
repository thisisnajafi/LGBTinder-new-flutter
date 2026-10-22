import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/cache/cache_manager.dart' show appCacheManagerProvider;
import '../../../core/providers/theme_mode_provider.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/utils/app_icons.dart';
import '../../../core/widgets/app_list_view.dart';
import '../../../core/widgets/premium/premium_design_system.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/settings/presentation/screens/account_details_screen.dart';
import '../../../features/settings/presentation/screens/appearance_settings_screen.dart';
import '../../../features/settings/presentation/screens/delete_account_screen.dart';
import '../../../features/settings/presentation/screens/matching_preferences_screen.dart';
import '../../../features/settings/presentation/screens/sound_preferences_screen.dart';
import '../../../core/localization/widgets/language_selector.dart';
import '../../../routes/app_router.dart';
import 'about_screen.dart';
import '../../../routes/home_tab_routes.dart';
import '../../../screens/active_sessions_screen.dart';
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
      builder: (ctx) => ResponsiveGrid.constrainedTo(
        ctx,
        AlertDialog(
          title: const AppText(
            'Log out?',
            maxLines: 2,
          ),
          content: const AppText(
            'You will need to sign in again to use the app.',
            maxLines: 3,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.feedbackError),
              child: const Text('Log out'),
            ),
          ],
        ),
        tablet: 400,
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go(AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final sections = <Widget>[
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
                subtitle: 'Active sessions',
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
              PremiumHubActionData(
                iconPath: AppIcons.heart,
                title: 'Likes you',
                subtitle: 'People who liked your profile',
                onTap: () => context.pushNamed('likes-received'),
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
                iconPath: AppIcons.shieldTick,
                title: 'Safety center',
                subtitle: 'Reports, alerts, and emergency contacts',
                onTap: () => context.pushNamed('safety-center'),
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
              PremiumSettingsTile(
                iconPath: AppIcons.discover,
                title: 'Language',
                subtitle: 'English, Persian, Arabic, and more',
                onTap: () => _push(
                  const PremiumDetailScaffold(
                    title: 'Language',
                    subtitle: 'App language and layout direction',
                    body: SingleChildScrollView(
                      child: LanguageSelector(),
                    ),
                  ),
                ),
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
                onTap: () => _push(const AboutScreen()),
                trailing: _appVersion != null
                    ? AppText(
                        _appVersion!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.45),
                            ),
                        maxLines: 1,
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
              PremiumSettingsTile(
                iconPath: AppIcons.delete,
                title: 'Delete account',
                subtitle: 'Permanently erase your account and data',
                onTap: () => _push(const DeleteAccountScreen()),
                destructive: true,
              ),
            ],
          ),
    ];

    return PremiumTabPageLayout(
      title: 'Settings',
      subtitle: 'Your account, privacy, and preferences',
      wideContentMaxWidth: 720,
      onRefresh: () async {
        await ref.read(appCacheManagerProvider).revalidateAll();
        await _loadVersion();
      },
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 720;
          if (!wide) {
            return AppListView.builder(
              physics: AppScroll.bouncing,
              padding: const EdgeInsets.only(bottom: AppSpacing.spacingXXXL),
              itemCount: sections.length,
              itemBuilder: (context, index) => sections[index],
            );
          }
          final mid = (sections.length / 2).ceil();
          Widget column(int start, int end) {
            final slice = sections.sublist(start, end);
            return AppListView.builder(
              physics: AppScroll.bouncing,
              padding: const EdgeInsets.only(
                bottom: AppSpacing.spacingXXXL,
                right: AppSpacing.spacingSM,
              ),
              itemCount: slice.length,
              itemBuilder: (context, index) => slice[index],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: column(0, mid)),
              Expanded(child: column(mid, sections.length)),
            ],
          );
        },
      ),
    );
  }
}
