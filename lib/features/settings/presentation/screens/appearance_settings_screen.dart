import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/theme_mode_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/app_settings_detail.dart';
import '../../../../core/widgets/premium/premium_design_system.dart';

/// Choose light, dark, or system (device) appearance.
class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(themeModeProvider);

    return AppSettingsDetailScaffold(
      title: 'Appearance',
      subtitle: 'Match your vibe — light, dark, or automatic',
      body: AppSettingsDetailList(
        children: [
          PremiumSettingsGroup(
            title: 'Theme',
            subtitle: 'Applies across profile, chat, and settings',
            children: [
              PremiumSettingsTile(
                iconPath: AppIcons.getIconPath('sun'),
                title: 'Light',
                subtitle: 'Always use light mode',
                accent: AppColors.warningYellow,
                onTap: () =>
                    ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light),
                trailing: selected == ThemeMode.light
                    ? AppSvgIcon(
                        assetPath: AppIcons.checkCircle,
                        size: 20,
                        color: AppColors.accentPink,
                      )
                    : null,
              ),
              PremiumSettingsTile(
                iconPath: AppIcons.getIconPath('moon'),
                title: 'Dark',
                subtitle: 'Always use dark mode',
                accent: AppColors.accentViolet,
                onTap: () =>
                    ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark),
                trailing: selected == ThemeMode.dark
                    ? AppSvgIcon(
                        assetPath: AppIcons.checkCircle,
                        size: 20,
                        color: AppColors.accentPink,
                      )
                    : null,
              ),
              PremiumSettingsTile(
                iconPath: AppIcons.setting,
                title: 'System',
                subtitle: 'Follow device settings',
                onTap: () => ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.system),
                trailing: selected == ThemeMode.system
                    ? AppSvgIcon(
                        assetPath: AppIcons.checkCircle,
                        size: 20,
                        color: AppColors.accentPink,
                      )
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
