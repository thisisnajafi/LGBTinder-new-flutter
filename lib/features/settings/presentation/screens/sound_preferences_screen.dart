import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/app_settings_detail.dart';
import '../../../../core/widgets/premium/premium_design_system.dart';
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

  Widget _soundGroup({
    required String title,
    required List<SoundOption> options,
    required String selectedId,
    required SoundCategory category,
    required ValueChanged<String> onSelect,
  }) {
    if (options.isEmpty) {
      return PremiumSettingsGroup(
        title: title,
        children: [
          Text(
            'No sounds available',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                ),
          ),
        ],
      );
    }

    return PremiumSettingsGroup(
      title: title,
      children: [
        for (final option in options)
          PremiumSoundOptionTile(
            label: option.name,
            isSelected: option.id == selectedId,
            onSelect: _isSaving ? null : () => onSelect(option.id),
            onPreview: () => _preview(option.id, category),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(soundPreferencesProvider);
    final catalogAsync = ref.watch(soundCatalogProvider);

    return AppSettingsDetailScaffold(
      title: 'Sounds & notifications',
      subtitle: 'Choose tones for messages, calls, and alerts',
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
        _soundGroup(
          title: 'Message sounds',
          options: catalog.messageSounds,
          selectedId: prefs.messageSound,
          category: SoundCategory.message,
          onSelect: (id) => _save(prefs.copyWith(messageSound: id)),
        ),
        const SizedBox(height: AppSpacing.spacingXL),
        _soundGroup(
          title: 'Call ringtones',
          options: catalog.callRingtones,
          selectedId: prefs.callRingtone,
          category: SoundCategory.call,
          onSelect: (id) => _save(prefs.copyWith(callRingtone: id)),
        ),
        const SizedBox(height: AppSpacing.spacingXL),
        _soundGroup(
          title: 'Notification sounds',
          options: catalog.notificationSounds,
          selectedId: prefs.notificationSound,
          category: SoundCategory.notification,
          onSelect: (id) => _save(prefs.copyWith(notificationSound: id)),
        ),
        const SizedBox(height: AppSpacing.spacingXL),
        PremiumSettingsGroup(
          title: 'Haptics',
          children: [
            PremiumToggleRow(
              title: 'Vibration',
              subtitle: 'Vibrate when playing message sounds',
              value: prefs.vibrationEnabled,
              onChanged: _isSaving
                  ? (_) {}
                  : (value) => _save(prefs.copyWith(vibrationEnabled: value)),
              iconPath: AppIcons.getIconPath('mobile'),
              enabled: !_isSaving,
            ),
          ],
        ),
      ],
    );
  }
}
