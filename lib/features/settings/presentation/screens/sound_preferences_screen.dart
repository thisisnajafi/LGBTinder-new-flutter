import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/typography.dart';
import '../../../../widgets/common/section_header.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../data/models/sound_preferences.dart';
import '../../providers/sound_preferences_provider.dart';

/// Settings screen for message, call, and notification sounds.
class SoundPreferencesScreen extends ConsumerStatefulWidget {
  const SoundPreferencesScreen({super.key});

  @override
  ConsumerState<SoundPreferencesScreen> createState() =>
      _SoundPreferencesScreenState();
}

class _SoundPreferencesScreenState
    extends ConsumerState<SoundPreferencesScreen> {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor =
        isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    final prefsAsync = ref.watch(soundPreferencesProvider);
    final catalogAsync = ref.watch(soundCatalogProvider);

    return AppPageScaffold(
      title: 'Sounds',
      showBackButton: true,
      backgroundColor: backgroundColor,
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Failed to load sounds', style: TextStyle(color: textColor)),
              SizedBox(height: AppSpacing.spacingMD),
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
            error: (_, __) => _buildContent(
              prefs: prefs,
              catalog: const SoundCatalog(),
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            data: (catalog) => _buildContent(
              prefs: prefs,
              catalog: catalog,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent({
    required SoundPreferences prefs,
    required SoundCatalog catalog,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return ListView(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      children: [
        SectionHeader(title: 'Message Sounds', icon: Icons.chat_bubble_outline),
        SizedBox(height: AppSpacing.spacingMD),
        ..._buildSoundOptions(
          options: catalog.messageSounds,
          selectedId: prefs.messageSound,
          category: SoundCategory.message,
          onSelect: (id) => _save(prefs.copyWith(messageSound: id)),
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
        ),
        SizedBox(height: AppSpacing.spacingLG),
        SectionHeader(title: 'Call Ringtones', icon: Icons.phone_in_talk_outlined),
        SizedBox(height: AppSpacing.spacingMD),
        ..._buildSoundOptions(
          options: catalog.callRingtones,
          selectedId: prefs.callRingtone,
          category: SoundCategory.call,
          onSelect: (id) => _save(prefs.copyWith(callRingtone: id)),
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
        ),
        SizedBox(height: AppSpacing.spacingLG),
        SectionHeader(title: 'Notification Sounds', icon: Icons.notifications_outlined),
        SizedBox(height: AppSpacing.spacingMD),
        ..._buildSoundOptions(
          options: catalog.notificationSounds,
          selectedId: prefs.notificationSound,
          category: SoundCategory.notification,
          onSelect: (id) => _save(prefs.copyWith(notificationSound: id)),
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
        ),
        SizedBox(height: AppSpacing.spacingLG),
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(AppRadius.radiusMD),
            border: Border.all(color: borderColor),
          ),
          child: SwitchListTile(
            title: Text(
              'Vibration',
              style: AppTypography.body.copyWith(color: textColor),
            ),
            subtitle: Text(
              'Vibrate when playing message sounds',
              style: AppTypography.caption.copyWith(color: secondaryTextColor),
            ),
            value: prefs.vibrationEnabled,
            onChanged: _isSaving
                ? null
                : (value) => _save(prefs.copyWith(vibrationEnabled: value)),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSoundOptions({
    required List<SoundOption> options,
    required String selectedId,
    required SoundCategory category,
    required ValueChanged<String> onSelect,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    if (options.isEmpty) {
      return [
        Text(
          'No sounds available',
          style: AppTypography.caption.copyWith(color: secondaryTextColor),
        ),
      ];
    }

    return options.map((option) {
      final isSelected = option.id == selectedId;
      return Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.spacingSM),
        child: Material(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.radiusMD),
            onTap: _isSaving ? null : () => onSelect(option.id),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryLight
                      : borderColor,
                  width: isSelected ? 2 : 1,
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.spacingMD,
                vertical: AppSpacing.spacingSM,
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected
                        ? AppColors.primaryLight
                        : secondaryTextColor,
                  ),
                  SizedBox(width: AppSpacing.spacingMD),
                  Expanded(
                    child: Text(
                      option.name,
                      style: AppTypography.body.copyWith(
                        color: textColor,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Preview',
                    onPressed: () => _preview(option.id, category),
                    icon: Icon(Icons.volume_up, color: secondaryTextColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}
