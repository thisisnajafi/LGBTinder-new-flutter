import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/theme_mode_provider.dart';
import '../../../../core/widgets/app_grouped_list_card.dart';
import '../../../../core/widgets/app_settings_detail.dart';

/// Choose light, dark, or system (device) appearance.
class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(themeModeProvider);

    return AppSettingsDetailScaffold(
      title: 'Appearance',
      body: AppSettingsDetailList(
        children: [
          AppGroupedListSection(
            title: 'Theme',
            padding: AppSettingsLayout.firstSectionPadding,
            children: [
              AppGroupedOptionTile(
                label: 'Light',
                subtitle: 'Always use light mode',
                isSelected: selected == ThemeMode.light,
                onTap: () => ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.light),
              ),
              AppGroupedOptionTile(
                label: 'Dark',
                subtitle: 'Always use dark mode',
                isSelected: selected == ThemeMode.dark,
                onTap: () => ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.dark),
              ),
              AppGroupedOptionTile(
                label: 'System',
                subtitle: 'Match your device settings',
                isSelected: selected == ThemeMode.system,
                onTap: () => ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.system),
                showDivider: false,
              ),
            ],
          ),
          const AppSettingsSectionFootnote(
            text:
                'Light and dark stay fixed regardless of your device. '
                'System updates when your phone or tablet theme changes.',
          ),
        ],
      ),
    );
  }
}
