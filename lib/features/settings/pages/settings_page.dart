import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/utils/app_icons.dart';
import '../../../core/widgets/app_grouped_list_card.dart';
import '../../../core/providers/theme_mode_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/settings/presentation/screens/account_details_screen.dart';
import '../../../features/settings/presentation/screens/appearance_settings_screen.dart';
import '../../../features/settings/presentation/screens/sound_preferences_screen.dart';
import '../../../routes/app_router.dart';
import '../../../screens/active_sessions_screen.dart';
import '../../../screens/blocked_users_screen.dart';
import '../../../screens/legal/privacy_policy_screen.dart';
import '../../../screens/legal/terms_of_service_screen.dart';
import '../../../screens/notification_settings_screen.dart';
import '../../../screens/two_factor_auth_screen.dart';
import '../../../screens/help_support_screen.dart';
import '../../../screens/privacy_settings_screen.dart';

/// App settings hub — account, app, legal, and danger zone (not profile content).
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  static const double _horizontalPad = 20;

  /// Space above a section title (after the previous card).
  static const EdgeInsets _sectionPadding = EdgeInsets.fromLTRB(
    _horizontalPad,
    AppSpacing.spacingXL,
    _horizontalPad,
    0,
  );

  static const EdgeInsets _firstSectionPadding = EdgeInsets.fromLTRB(
    _horizontalPad,
    0,
    _horizontalPad,
    0,
  );

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

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to use the app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
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

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your profile, matches, and messages. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.feedbackError),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    // TODO: wire delete-account flow via settings provider / account management
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account deletion is available under Account Management.'),
      ),
    );
  }

  void _push(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, AppSpacing.spacingSM, 20, 0),
              child: Text(
                'Settings',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.spacingXL),
            AppGroupedListSection(
              title: 'Account',
              padding: _firstSectionPadding,
              children: [
                _tile(
                  iconPath: AppIcons.user,
                  label: 'Account details',
                  subtitle: 'Phone, email, and password',
                  onTap: () => _push(const AccountDetailsScreen()),
                ),
                _tile(
                  iconPath: AppIcons.notification,
                  label: 'Notifications',
                  onTap: () => _push(const NotificationSettingsScreen()),
                ),
                _tile(
                  iconPath: AppIcons.shieldTick,
                  label: 'Privacy & safety',
                  onTap: () => _push(const PrivacySettingsScreen()),
                ),
                _tile(
                  iconPath: AppIcons.block,
                  label: 'Blocked users',
                  onTap: () => context.pushNamed('blocked-users'),
                ),
                _tile(
                  iconPath: AppIcons.getIconPath('monitor'),
                  label: 'Active sessions',
                  onTap: () => _push(const ActiveSessionsScreen()),
                ),
                _tile(
                  iconPath: AppIcons.lockOutline,
                  label: 'Two-factor authentication',
                  onTap: () => _push(const TwoFactorAuthScreen()),
                  showDivider: false,
                ),
              ],
            ),
            AppGroupedListSection(
              title: 'App',
              padding: _sectionPadding,
              children: [
                _tile(
                  iconPath: AppIcons.getIconPath('volume-high'),
                  label: 'Sounds & notifications',
                  onTap: () => _push(const SoundPreferencesScreen()),
                ),
                _tile(
                  iconPath: AppIcons.getIconPath('translate'),
                  label: 'Language / locale',
                  onTap: () {
                    // TODO: locale picker screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Language settings coming soon')),
                    );
                  },
                ),
                _tile(
                  iconPath: AppIcons.setting,
                  label: 'Appearance',
                  subtitle: themeModeLabel(themeMode),
                  onTap: () => _push(const AppearanceSettingsScreen()),
                  showDivider: false,
                ),
              ],
            ),
            AppGroupedListSection(
              title: 'Legal & support',
              padding: _sectionPadding,
              children: [
                _tile(
                  iconPath: AppIcons.help,
                  label: 'Help & support',
                  onTap: () => context.pushNamed('help-support'),
                ),
                _tile(
                  iconPath: AppIcons.shield,
                  label: 'Privacy policy',
                  onTap: () => context.pushNamed('privacy-policy'),
                ),
                _tile(
                  iconPath: AppIcons.document,
                  label: 'Terms of service',
                  onTap: () => context.pushNamed('terms-of-service'),
                ),
                _tile(
                  iconPath: AppIcons.info,
                  label: 'About',
                  subtitle: _appVersion != null ? 'Version $_appVersion' : 'Loading version…',
                  onTap: () {},
                  showDivider: false,
                  trailing: _appVersion != null
                      ? Text(
                          _appVersion!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                          ),
                        )
                      : null,
                ),
              ],
            ),
            AppGroupedListSection(
              title: 'Danger zone',
              padding: _sectionPadding,
              children: [
                _tile(
                  iconPath: AppIcons.logout,
                  label: 'Log out',
                  onTap: _confirmLogout,
                ),
                _tile(
                  iconPath: AppIcons.delete,
                  label: 'Delete account',
                  onTap: _confirmDeleteAccount,
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.spacingXXL),
          ],
        ),
      ),
    );
  }

  AppGroupedListTile _tile({
    required String iconPath,
    required String label,
    String? subtitle,
    required VoidCallback onTap,
    bool showDivider = true,
    Widget? trailing,
  }) {
    return AppGroupedListTile(
      iconPath: iconPath,
      label: label,
      subtitle: subtitle,
      onTap: onTap,
      showDivider: showDivider,
      trailing: trailing,
    );
  }
}
