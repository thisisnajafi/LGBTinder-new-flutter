import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_motion_prefs_provider.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/app_settings_detail.dart';
import '../../../../core/widgets/premium/premium_design_system.dart';
import '../../data/models/sound_preferences.dart';
import '../../providers/sound_preferences_provider.dart';

/// Settings screen for message, call, and notification sounds.
class SoundPreferencesScreen extends ConsumerWidget {
  const SoundPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(soundPreferencesProvider);
    final catalogAsync = ref.watch(soundCatalogProvider);

    return AppSettingsDetailScaffold(
      title: 'Sounds & notifications',
      subtitle: 'Choose tones for messages, calls, and alerts',
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Padding(
          padding: ResponsivePadding.page(context),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText(
                  'Failed to load sounds',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.spacingMD),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(soundPreferencesProvider.notifier).refresh(),
                  child: const AppText(
                    'Retry',
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (prefs) {
          return catalogAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _SoundPreferencesEditor(
              initialPrefs: prefs,
              catalog: const SoundCatalog(),
            ),
            data: (catalog) => _SoundPreferencesEditor(
              initialPrefs: prefs,
              catalog: catalog,
            ),
          );
        },
      ),
    );
  }
}

/// Owns selection notifiers so preview/select rebuilds one group, not the list
/// (PERF-FEAT-SET-002).
class _SoundPreferencesEditor extends ConsumerStatefulWidget {
  const _SoundPreferencesEditor({
    required this.initialPrefs,
    required this.catalog,
  });

  final SoundPreferences initialPrefs;
  final SoundCatalog catalog;

  @override
  ConsumerState<_SoundPreferencesEditor> createState() =>
      _SoundPreferencesEditorState();
}

class _SoundPreferencesEditorState
    extends ConsumerState<_SoundPreferencesEditor> {
  late final ValueNotifier<String> _messageSound;
  late final ValueNotifier<String> _callRingtone;
  late final ValueNotifier<String> _notificationSound;
  late final ValueNotifier<bool> _vibrationEnabled;
  late final ValueNotifier<bool> _saving;

  @override
  void initState() {
    super.initState();
    final prefs = widget.initialPrefs;
    _messageSound = ValueNotifier(prefs.messageSound);
    _callRingtone = ValueNotifier(prefs.callRingtone);
    _notificationSound = ValueNotifier(prefs.notificationSound);
    _vibrationEnabled = ValueNotifier(prefs.vibrationEnabled);
    _saving = ValueNotifier(false);
  }

  @override
  void dispose() {
    _messageSound.dispose();
    _callRingtone.dispose();
    _notificationSound.dispose();
    _vibrationEnabled.dispose();
    _saving.dispose();
    super.dispose();
  }

  SoundPreferences _currentPrefs() {
    return SoundPreferences(
      messageSound: _messageSound.value,
      callRingtone: _callRingtone.value,
      notificationSound: _notificationSound.value,
      vibrationEnabled: _vibrationEnabled.value,
    );
  }

  Future<void> _save(SoundPreferences prefs) async {
    if (_saving.value) return;
    _saving.value = true;
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
      if (mounted) _saving.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSettingsDetailList(
      children: [
        _SoundOptionsGroup(
          title: 'Message sounds',
          options: widget.catalog.messageSounds,
          selectedId: _messageSound,
          category: SoundCategory.message,
          saving: _saving,
          onCommit: (id) => _save(_currentPrefs().copyWith(messageSound: id)),
        ),
        const SizedBox(height: AppSpacing.spacingXL),
        _SoundOptionsGroup(
          title: 'Call ringtones',
          options: widget.catalog.callRingtones,
          selectedId: _callRingtone,
          category: SoundCategory.call,
          saving: _saving,
          onCommit: (id) => _save(_currentPrefs().copyWith(callRingtone: id)),
        ),
        const SizedBox(height: AppSpacing.spacingXL),
        _SoundOptionsGroup(
          title: 'Notification sounds',
          options: widget.catalog.notificationSounds,
          selectedId: _notificationSound,
          category: SoundCategory.notification,
          saving: _saving,
          onCommit: (id) =>
              _save(_currentPrefs().copyWith(notificationSound: id)),
        ),
        const SizedBox(height: AppSpacing.spacingXL),
        PremiumSettingsGroup(
          title: 'Haptics',
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: _saving,
              builder: (context, saving, _) {
                return ValueListenableBuilder<bool>(
                  valueListenable: _vibrationEnabled,
                  builder: (context, vibration, _) {
                    return PremiumToggleRow(
                      title: 'Vibration',
                      subtitle: 'Vibrate when playing message sounds',
                      value: vibration,
                      onChanged: saving
                          ? (_) {}
                          : (value) {
                              _vibrationEnabled.value = value;
                              _save(_currentPrefs().copyWith(
                                vibrationEnabled: value,
                              ));
                            },
                      iconPath: AppIcons.getIconPath('mobile'),
                      enabled: !saving,
                    );
                  },
                );
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _saving,
              builder: (context, saving, _) => _AppHapticsToggle(saving: saving),
            ),
          ],
        ),
      ],
    );
  }
}

class _SoundOptionsGroup extends StatelessWidget {
  const _SoundOptionsGroup({
    required this.title,
    required this.options,
    required this.selectedId,
    required this.category,
    required this.saving,
    required this.onCommit,
  });

  final String title;
  final List<SoundOption> options;
  final ValueNotifier<String> selectedId;
  final SoundCategory category;
  final ValueNotifier<bool> saving;
  final ValueChanged<String> onCommit;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return PremiumSettingsGroup(
        title: title,
        children: [
          AppText(
            'No sounds available',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                ),
            maxLines: 2,
          ),
        ],
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: saving,
      builder: (context, isSaving, _) {
        return ValueListenableBuilder<String>(
          valueListenable: selectedId,
          builder: (context, selected, _) {
            return PremiumSettingsGroup(
              title: title,
              children: [
                for (final option in options)
                  PremiumSoundOptionTile(
                    label: option.name,
                    isSelected: option.id == selected,
                    onSelect: isSaving
                        ? null
                        : () {
                            if (option.id == selected) return;
                            selectedId.value = option.id;
                            onCommit(option.id);
                          },
                    onPreview: () => SoundService.instance.previewSound(
                      option.id,
                      category,
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _AppHapticsToggle extends ConsumerWidget {
  const _AppHapticsToggle({required this.saving});

  final bool saving;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(
      appMotionPrefsProvider.select((s) => s.hapticsEnabled),
    );
    return PremiumToggleRow(
      title: 'Haptic feedback',
      subtitle: 'Taps, refresh, and UI confirmation',
      value: enabled,
      iconPath: AppIcons.getIconPath('mobile'),
      enabled: !saving,
      onChanged: saving
          ? (_) {}
          : (value) =>
              ref.read(appMotionPrefsProvider.notifier).setHapticsEnabled(value),
    );
  }
}
