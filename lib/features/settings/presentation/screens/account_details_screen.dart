import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/app_grouped_list_card.dart';
import '../../../../core/widgets/app_settings_detail.dart';
import '../../../../screens/settings/account_management_screen.dart';
import '../../../../core/utils/country_phone_utils.dart';
import '../../../profile/providers/profile_page_cache_provider.dart';

/// Read-only account contact and security details with links to change flows.
class AccountDetailsScreen extends ConsumerStatefulWidget {
  const AccountDetailsScreen({super.key});

  @override
  ConsumerState<AccountDetailsScreen> createState() =>
      _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends ConsumerState<AccountDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cache = ref.read(profilePageCacheProvider);
      if (cache.valueOrNull?.profile == null) {
        ref.read(profilePageCacheProvider.notifier).refresh();
      }
    });
  }

  void _openAccountManagement() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const AccountManagementScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profilePageCacheProvider);
    final profile = profileState.valueOrNull?.profile;

    final email = profile?.email;
    final phone = profile?.phoneNumber ??
        profile?.additionalData?['phone_number']?.toString();
    final emailDisplay =
        (email != null && email.isNotEmpty && email != 'user@unknown.com')
            ? email
            : 'Not set';
    final phoneDisplay = (phone != null && phone.isNotEmpty)
        ? CountryPhoneUtils.formatInternationalDisplay(phone)
        : 'Not set';

    return AppSettingsDetailScaffold(
      title: 'Account details',
      body: profileState.isLoading && profile == null
          ? const Center(child: CircularProgressIndicator())
          : AppSettingsDetailList(
              children: [
                AppGroupedListSection(
                  title: 'Contact',
                  padding: AppSettingsLayout.firstSectionPadding,
                  children: [
                    AppGroupedInfoTile(
                      label: 'Phone number',
                      value: phoneDisplay,
                      badge: profile?.isPhoneVerified == true
                          ? 'Verified'
                          : null,
                    ),
                    AppGroupedInfoTile(
                      label: 'Email',
                      value: emailDisplay,
                      badge: profile?.isEmailVerified == true
                          ? 'Verified'
                          : null,
                      showDivider: false,
                    ),
                  ],
                ),
                AppGroupedListSection(
                  title: 'Security',
                  padding: AppSettingsLayout.sectionPadding,
                  children: [
                    AppGroupedListTile(
                      iconPath: AppIcons.lockOutline,
                      label: 'Password',
                      subtitle: 'Change your sign-in password',
                      onTap: _openAccountManagement,
                      showDivider: false,
                      trailing: Text(
                        '••••••••',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.45),
                              letterSpacing: 1.2,
                            ),
                      ),
                    ),
                  ],
                ),
                const AppSettingsSectionFootnote(
                  text:
                      'To update your email or password, open account management.',
                ),
                AppGroupedListSection(
                  title: 'Management',
                  padding: AppSettingsLayout.sectionPadding,
                  children: [
                    AppGroupedListTile(
                      iconPath: AppIcons.setting,
                      label: 'Account management',
                      subtitle: 'Change email, password, or delete account',
                      onTap: _openAccountManagement,
                      showDivider: false,
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
