import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/widgets/app_grouped_list_card.dart';
import '../../../../core/widgets/app_settings_detail.dart';
import '../../data/models/sound_preferences.dart';
import '../../providers/sound_preferences_provider.dart';

/// Settings screen for message, call, and notification sounds.
class SoundPreferencesScreen extends ConsumerStatefulWidget {
  const SoundPreferencesScreen({super.key});

  @override
  ConsumerState<SoundPreferencesScreen> createState() =>
      _SoundPreferencesScreenState();
}

class _SoundPreferencesScreenState extends ConsumerState<SoundPreferencesScreen> {
  bool _isSaving = false;

  Future<void> _save(SoundPreferences prefs) async {
    setState(() => _isSaving = true);
    try {
      await ref.read(soundPreferencesProvider.notifier).updatePreferences(prefs);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sound preferences saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _preview(String soundId, SoundCategory category) async {
    await SoundService.instance.previewSound(soundId, category);
  }

  List<Widget> _soundSection({
    required String title,
    required EdgeInsetsGeometry padding,
    required List<SoundOption> options,
    required String selectedId,
    required SoundCategory category,
    required ValueChanged<String> onSelect,
  }) {
    if (options.isEmpty) {
      return [
        AppGroupedListSection(
          title: title,
          padding: padding,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.spacingMD),
              child: Text(
                'No sounds available',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                    ),
              ),
            ),
          ],
        ),
      ];
    }

    return [
      AppGroupedListSection(
        title: title,
        padding: padding,
        children: [
          for (var i = 0; i < options.length; i++)
            AppGroupedSoundOptionTile(
              label: options[i].name,
              isSelected: options[i].id == selectedId,
              onSelect: _isSaving ? null : () => onSelect(options[i].id),
              onPreview: () => _preview(options[i].id, category),
              showDivider: i < options.length - 1,
            ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(soundPreferencesProvider);
    final catalogAsync = ref.watch(soundCatalogProvider);

    return AppSettingsDetailScaffold(
      title: 'Sounds & notifications',
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to load sounds'),
              const SizedBox(height: AppSpacing.spacingMD),
              ElevatedButton(
                onPressed: () =>
                    ref.read(soundPreferencesProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (prefs) {
          return catalogAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _buildContent(prefs, const SoundCatalog()),
            data: (catalog) => _buildContent(prefs, catalog),
          );
        },
      ),
    );
  }

  Widget _buildContent(SoundPreferences prefs, SoundCatalog catalog) {
    return AppSettingsDetailList(
      children: [
        ..._soundSection(
          title: 'Message sounds',
          padding: AppSettingsLayout.firstSectionPadding,
          options: catalog.messageSounds,
          selectedId: prefs.messageSound,
          category: SoundCategory.message,
          onSelect: (id) => _save(prefs.copyWith(messageSound: id)),
        ),
        ..._soundSection(
          title: 'Call ringtones',
          padding: AppSettingsLayout.sectionPadding,
          options: catalog.callRingtones,
          selectedId: prefs.callRingtone,
          category: SoundCategory.call,
          onSelect: (id) => _save(prefs.copyWith(callRingtone: id)),
        ),
        ..._soundSection(
          title: 'Notification sounds',
          padding: AppSettingsLayout.sectionPadding,
          options: catalog.notificationSounds,
          selectedId: prefs.notificationSound,
          category: SoundCategory.notification,
          onSelect: (id) => _save(prefs.copyWith(notificationSound: id)),
        ),
        AppGroupedListSection(
          title: 'Haptics',
          padding: AppSettingsLayout.sectionPadding,
          children: [
            AppGroupedSwitchTile(
              label: 'Vibration',
              subtitle: 'Vibrate when playing message sounds',
              value: prefs.vibrationEnabled,
              onChanged: _isSaving
                  ? null
                  : (value) => _save(prefs.copyWith(vibrationEnabled: value)),
              showDivider: false,
            ),
          ],
        ),
      ],
    );
  }
}
