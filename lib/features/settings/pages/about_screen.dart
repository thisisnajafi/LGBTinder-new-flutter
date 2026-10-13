import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/theme/spacing_constants.dart';
import '../../../core/utils/app_icons.dart';
import '../../../core/widgets/premium/premium_design_system.dart';

/// Version, legal links, and a short product blurb.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '…';

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
      if (mounted) setState(() => _version = '1.0.0');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PremiumDetailScaffold(
      title: 'About',
      subtitle: 'LGBTFinder',
      body: ListView(
        physics: AppScroll.bouncing,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.spacingLG,
          AppSpacing.spacingSM,
          AppSpacing.spacingLG,
          AppSpacing.spacingXXL,
        ),
        children: [
          PremiumSettingsGroup(
            title: 'App',
            children: [
              PremiumSettingsTile(
                iconPath: AppIcons.info,
                title: 'Version',
                subtitle: _version,
                onTap: () {},
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
            ],
          ),
          const SizedBox(height: AppSpacing.spacingXL),
          Text(
            'LGBTFinder is a dating app for the LGBTQ+ community. '
            'This build talks to the development API.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
