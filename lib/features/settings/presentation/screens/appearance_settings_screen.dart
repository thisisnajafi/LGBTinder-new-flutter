import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_motion_prefs_provider.dart';
import '../../../../core/providers/theme_mode_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/app_settings_detail.dart';
import '../../../../core/widgets/premium/premium_design_system.dart';

/// Choose light, dark, or system (device) appearance.
class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(themeModeProvider);
    final reduceMotion = ref.watch(
      appMotionPrefsProvider.select((s) => s.reduceMotion),
    );

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
                selected: selected == ThemeMode.light,
                onTap: () => ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.light),
              ),
              PremiumSettingsTile(
                iconPath: AppIcons.getIconPath('moon'),
                title: 'Dark',
                subtitle: 'Always use dark mode',
                accent: AppColors.accentViolet,
                selected: selected == ThemeMode.dark,
                onTap: () => ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.dark),
              ),
              PremiumSettingsTile(
                iconPath: AppIcons.setting,
                title: 'System',
                subtitle: 'Follow device settings',
                selected: selected == ThemeMode.system,
                onTap: () => ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.system),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacingXL),
          PremiumSettingsGroup(
            title: 'Motion',
            subtitle: 'Also respects your system Reduce Motion setting',
            children: [
              PremiumToggleRow(
                title: 'Reduce motion',
                subtitle: 'Skip stagger, Lottie, and shimmer animations',
                value: reduceMotion,
                iconPath: AppIcons.setting,
                onChanged: (value) => ref
                    .read(appMotionPrefsProvider.notifier)
                    .setReduceMotion(value),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
