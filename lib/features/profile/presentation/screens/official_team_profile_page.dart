import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/premium/premium_design_system.dart';
import '../../../../routes/app_router.dart';
import '../../../../widgets/buttons/gradient_button.dart';
import '../../../../widgets/chat/chat_peer_avatar.dart';
import '../../../../widgets/chat/official_account_badge.dart';

/// Dedicated page for the LGBTFinder Team system account.
///
/// Dating chrome (match, compatibility, presence, tier, like/pass, report)
/// does not belong on this account.
class OfficialTeamProfilePage extends StatefulWidget {
  final int userId;

  /// True when this page was opened on top of the Team chat.
  final bool openedFromChat;

  const OfficialTeamProfilePage({
    super.key,
    required this.userId,
    this.openedFromChat = false,
  });

  static Future<void> open(
    BuildContext context, {
    required int userId,
    bool openedFromChat = false,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => OfficialTeamProfilePage(
          userId: userId,
          openedFromChat: openedFromChat,
        ),
      ),
    );
  }

  @override
  State<OfficialTeamProfilePage> createState() => _OfficialTeamProfilePageState();
}

class _OfficialTeamProfilePageState extends State<OfficialTeamProfilePage> {
  String? _version;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _version = '${info.version} (${info.buildNumber})');
    } catch (_) {
      if (mounted) setState(() => _version = null);
    }
  }

  void _openAnnouncements() {
    if (widget.openedFromChat && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    final target = Uri(
      path: AppRoutes.chat,
      queryParameters: {
        'userId': widget.userId.toString(),
        'userName': 'LGBTFinder Team',
        'official': '1',
        'systemOfficial': '1',
      },
    ).toString();
    context.push(target);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.62);

    return PremiumDetailScaffold(
      title: 'LGBTFinder Team',
      body: ListView(
        physics: AppScroll.bouncing,
        padding: const EdgeInsets.only(bottom: AppSpacing.spacingXXL),
        children: [
          const SizedBox(height: AppSpacing.spacingLG),
          Center(
            child: ClipOval(
              child: OfficialTeamLogo(size: 112),
            ),
          ),
          const SizedBox(height: AppSpacing.spacingMD),
          const Center(child: _VerifiedOfficialBadge()),
          const SizedBox(height: AppSpacing.spacingSM),
          Text(
            'LGBTFinder Team',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.spacingXS),
          Text(
            'News, safety, and updates from LGBTFinder',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
          const SizedBox(height: AppSpacing.spacingXL),
          PremiumSettingsGroup(
            title: 'About',
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.spacingMD,
                  AppSpacing.spacingSM,
                  AppSpacing.spacingMD,
                  AppSpacing.spacingMD,
                ),
                child: Text(
                  'LGBTFinder is a community for LGBTQ+ people to meet, match, and talk. '
                  'This account shares product news and safety updates from the team. '
                  'Be kind, look out for each other, and use the tools below if something does not feel right.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacingLG),
          PremiumSettingsGroup(
            title: 'Quick links',
            children: [
              PremiumSettingsTile(
                iconPath: AppIcons.help,
                title: 'Help & support',
                onTap: () => context.push(AppRoutes.helpSupport),
              ),
              PremiumSettingsTile(
                iconPath: AppIcons.shield,
                title: 'Safety tips',
                onTap: () => context.push(AppRoutes.safetyCenter),
              ),
              PremiumSettingsTile(
                iconPath: AppIcons.document,
                title: 'Privacy policy',
                onTap: () => context.push(AppRoutes.privacyPolicy),
              ),
              PremiumSettingsTile(
                iconPath: AppIcons.document,
                title: 'Terms of service',
                onTap: () => context.push(AppRoutes.termsOfService),
              ),
            ],
          ),
          if (_version != null) ...[
            const SizedBox(height: AppSpacing.spacingLG),
            Text(
              'App version $_version',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(color: muted),
            ),
          ],
          const SizedBox(height: AppSpacing.spacingXL),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacingLG,
            ),
            child: GradientButton(
              text: 'View announcements',
              iconPath: AppIcons.message,
              onPressed: _openAnnouncements,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifiedOfficialBadge extends StatelessWidget {
  const _VerifiedOfficialBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSvgIcon(
          assetPath: AppIcons.verify,
          size: 18,
          color: AppColors.accentViolet,
        ),
        const SizedBox(width: 6),
        const OfficialAccountBadge(),
      ],
    );
  }
}
