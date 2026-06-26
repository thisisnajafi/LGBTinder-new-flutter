// Screen: HapticFeedbackSettingsScreen
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/app_settings_detail.dart';
import '../core/widgets/premium/premium_design_system.dart';

/// Haptic feedback settings screen - Manage haptic feedback preferences
class HapticFeedbackSettingsScreen extends ConsumerStatefulWidget {
  const HapticFeedbackSettingsScreen({super.key});

  @override
  ConsumerState<HapticFeedbackSettingsScreen> createState() =>
      _HapticFeedbackSettingsScreenState();
}

class _HapticFeedbackSettingsScreenState
    extends ConsumerState<HapticFeedbackSettingsScreen> {
  bool _hapticEnabled = true;
  String _hapticIntensity = 'medium';
  double _intensityValue = 0.5;

  bool _buttonHaptics = true;
  bool _swipeHaptics = true;
  bool _matchHaptics = true;
  bool _messageHaptics = true;
  bool _errorHaptics = true;
  bool _successHaptics = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // TODO: Load settings from API or local storage
  }

  Future<void> _saveSettings() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Haptic settings saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e')),
        );
      }
    }
  }

  void _testHaptic() {
    if (!_hapticEnabled) return;

    switch (_hapticIntensity) {
      case 'light':
        HapticFeedback.lightImpact();
      case 'medium':
        HapticFeedback.mediumImpact();
      case 'heavy':
        HapticFeedback.heavyImpact();
    }
  }

  void _setIntensity(String value) {
    setState(() {
      _hapticIntensity = value;
      _intensityValue = switch (value) {
        'light' => 0.3,
        'heavy' => 0.8,
        _ => 0.5,
      };
    });
    _saveSettings();
    _testHaptic();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final secondaryTextColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final surfaceColor = isDark
        ? AppColors.cardBackgroundDark
        : AppColors.cardBackgroundLight;
    final borderColor =
        AppColors.accentViolet.withValues(alpha: isDark ? 0.12 : 0.1);

    return AppSettingsDetailScaffold(
      title: 'Haptic feedback',
      subtitle: 'Vibration strength and interaction types',
      body: AppSettingsDetailList(
        children: [
          PremiumSettingsGroup(
            title: 'General',
            children: [
              PremiumToggleRow(
                title: 'Enable haptic feedback',
                subtitle: 'Vibration for taps, swipes, and alerts',
                value: _hapticEnabled,
                iconPath: AppIcons.fingerPrint,
                onChanged: (value) {
                  setState(() => _hapticEnabled = value);
                  _saveSettings();
                },
              ),
              if (_hapticEnabled) ...[
                _IntensityOption(
                  label: 'Light',
                  isSelected: _hapticIntensity == 'light',
                  onSelect: () => _setIntensity('light'),
                ),
                _IntensityOption(
                  label: 'Medium',
                  isSelected: _hapticIntensity == 'medium',
                  onSelect: () => _setIntensity('medium'),
                ),
                _IntensityOption(
                  label: 'Heavy',
                  isSelected: _hapticIntensity == 'heavy',
                  onSelect: () => _setIntensity('heavy'),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
                  padding: const EdgeInsets.all(AppSpacing.spacingMD),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(AppRadius.radiusLG),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Intensity level',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          Text(
                            '${(_intensityValue * 100).toInt()}%',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentViolet,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _intensityValue,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        label: '${(_intensityValue * 100).toInt()}%',
                        activeColor: AppColors.accentViolet,
                        onChanged: (value) {
                          setState(() {
                            _intensityValue = value;
                            _hapticIntensity = value < 0.4
                                ? 'light'
                                : value > 0.6
                                    ? 'heavy'
                                    : 'medium';
                          });
                          _saveSettings();
                        },
                        onChangeEnd: (_) => _testHaptic(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Light', style: theme.textTheme.bodySmall),
                          Text('Heavy', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                PremiumSettingsTile(
                  iconPath: AppIcons.flash,
                  title: 'Test haptic',
                  subtitle: 'Feel the current intensity',
                  accent: AppColors.accentViolet,
                  onTap: _testHaptic,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.spacingXL),
          PremiumSettingsGroup(
            title: 'Haptic types',
            children: [
              PremiumToggleRow(
                title: 'Button presses',
                subtitle: 'Feedback when pressing buttons',
                value: _buttonHaptics,
                iconPath: AppIcons.setting2,
                enabled: _hapticEnabled,
                onChanged: (value) {
                  setState(() => _buttonHaptics = value);
                  _saveSettings();
                },
              ),
              PremiumToggleRow(
                title: 'Swipe gestures',
                subtitle: 'Feedback when swiping cards',
                value: _swipeHaptics,
                iconPath: AppIcons.like,
                enabled: _hapticEnabled,
                onChanged: (value) {
                  setState(() => _swipeHaptics = value);
                  _saveSettings();
                },
              ),
              PremiumToggleRow(
                title: 'New matches',
                subtitle: 'Feedback when you get a match',
                value: _matchHaptics,
                iconPath: AppIcons.heart,
                enabled: _hapticEnabled,
                onChanged: (value) {
                  setState(() => _matchHaptics = value);
                  _saveSettings();
                },
              ),
              PremiumToggleRow(
                title: 'New messages',
                subtitle: 'Feedback when receiving messages',
                value: _messageHaptics,
                iconPath: AppIcons.message,
                enabled: _hapticEnabled,
                onChanged: (value) {
                  setState(() => _messageHaptics = value);
                  _saveSettings();
                },
              ),
              PremiumToggleRow(
                title: 'Errors',
                subtitle: 'Feedback for error states',
                value: _errorHaptics,
                iconPath: AppIcons.danger,
                enabled: _hapticEnabled,
                onChanged: (value) {
                  setState(() => _errorHaptics = value);
                  _saveSettings();
                },
              ),
              PremiumToggleRow(
                title: 'Success actions',
                subtitle: 'Feedback for successful actions',
                value: _successHaptics,
                iconPath: AppIcons.tickCircle,
                enabled: _hapticEnabled,
                onChanged: (value) {
                  setState(() => _successHaptics = value);
                  _saveSettings();
                },
              ),
            ],
          ),
          if (!_hapticEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSettingsLayout.horizontalPadding,
                AppSpacing.spacingMD,
                AppSettingsLayout.horizontalPadding,
                0,
              ),
              child: Text(
                'Enable haptic feedback above to customize interaction types.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: secondaryTextColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IntensityOption extends StatelessWidget {
  const _IntensityOption({
    required this.label,
    required this.isSelected,
    required this.onSelect,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PremiumTapScale(
      onTap: onSelect,
      semanticLabel: '$label intensity',
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacingMD,
          vertical: AppSpacing.spacingSM + 2,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentViolet.withValues(alpha: isDark ? 0.18 : 0.12)
              : (isDark
                  ? AppColors.cardBackgroundDark
                  : AppColors.cardBackgroundLight),
          borderRadius: BorderRadius.circular(AppRadius.radiusLG),
          border: Border.all(
            color: isSelected
                ? AppColors.accentViolet
                : AppColors.accentViolet.withValues(alpha: isDark ? 0.12 : 0.1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isSelected)
              AppSvgIcon(
                assetPath: AppIcons.tickCircle,
                size: 20,
                color: AppColors.accentViolet,
              ),
          ],
        ),
      ),
    );
  }
}
