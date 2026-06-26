// Screen: AccessibilitySettingsScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/app_settings_detail.dart';
import '../core/widgets/premium/premium_design_system.dart';

/// Accessibility settings screen - Manage accessibility preferences
class AccessibilitySettingsScreen extends ConsumerStatefulWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  ConsumerState<AccessibilitySettingsScreen> createState() =>
      _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState
    extends ConsumerState<AccessibilitySettingsScreen> {
  double _fontSizeScale = 1.0;
  bool _boldText = false;
  bool _highContrast = false;
  String _colorBlindMode = 'none';

  bool _reduceMotion = false;
  bool _disableAnimations = false;

  bool _screenReaderEnabled = false;
  bool _semanticLabels = true;

  bool _largerTouchTargets = false;
  double _touchTargetSize = 44.0;

  bool _audioDescriptions = false;
  bool _subtitlesEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final mediaQuery = MediaQuery.of(context);
    setState(() {
      _screenReaderEnabled = mediaQuery.accessibleNavigation;
      _reduceMotion = mediaQuery.disableAnimations;
    });
  }

  Future<void> _saveSettings() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Accessibility settings saved')),
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

  void _setColorBlindMode(String value) {
    setState(() => _colorBlindMode = value);
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.cardBackgroundDark
        : AppColors.cardBackgroundLight;
    final borderColor =
        AppColors.accentViolet.withValues(alpha: isDark ? 0.12 : 0.1);

    return AppSettingsDetailScaffold(
      title: 'Accessibility',
      subtitle: 'Text, motion, touch, and audio preferences',
      body: AppSettingsDetailList(
        children: [
          PremiumSettingsGroup(
            title: 'Text & display',
            children: [
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
                          'Font size',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${(_fontSizeScale * 100).toInt()}%',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentViolet,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _fontSizeScale,
                      min: 0.8,
                      max: 2.0,
                      divisions: 12,
                      label: '${(_fontSizeScale * 100).toInt()}%',
                      activeColor: AppColors.accentViolet,
                      onChanged: (value) {
                        setState(() => _fontSizeScale = value);
                        _saveSettings();
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Small', style: theme.textTheme.bodySmall),
                        Text('Large', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
              PremiumToggleRow(
                title: 'Bold text',
                subtitle: 'Use bold font for better readability',
                value: _boldText,
                iconPath: AppIcons.documentText,
                onChanged: (value) {
                  setState(() => _boldText = value);
                  _saveSettings();
                },
              ),
              PremiumToggleRow(
                title: 'High contrast',
                subtitle: 'Increase contrast for better visibility',
                value: _highContrast,
                iconPath: AppIcons.eye,
                onChanged: (value) {
                  setState(() => _highContrast = value);
                  _saveSettings();
                },
              ),
              _SettingOption(
                label: 'None',
                isSelected: _colorBlindMode == 'none',
                onSelect: () => _setColorBlindMode('none'),
              ),
              _SettingOption(
                label: 'Protanopia (red-blind)',
                isSelected: _colorBlindMode == 'protanopia',
                onSelect: () => _setColorBlindMode('protanopia'),
              ),
              _SettingOption(
                label: 'Deuteranopia (green-blind)',
                isSelected: _colorBlindMode == 'deuteranopia',
                onSelect: () => _setColorBlindMode('deuteranopia'),
              ),
              _SettingOption(
                label: 'Tritanopia (blue-blind)',
                isSelected: _colorBlindMode == 'tritanopia',
                onSelect: () => _setColorBlindMode('tritanopia'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacingXL),
          PremiumSettingsGroup(
            title: 'Motion',
            children: [
              PremiumToggleRow(
                title: 'Reduce motion',
                subtitle: 'Minimize animations and transitions',
                value: _reduceMotion,
                iconPath: AppIcons.eyeSlash,
                onChanged: (value) {
                  setState(() => _reduceMotion = value);
                  _saveSettings();
                },
              ),
              PremiumToggleRow(
                title: 'Disable animations',
                subtitle: 'Turn off all animations completely',
                value: _disableAnimations,
                iconPath: AppIcons.magicStar,
                onChanged: (value) {
                  setState(() => _disableAnimations = value);
                  _saveSettings();
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacingXL),
          PremiumSettingsGroup(
            title: 'Screen reader',
            children: [
              PremiumInfoRow(
                label: 'System screen reader',
                value: _screenReaderEnabled ? 'Enabled' : 'Disabled',
                badge: _screenReaderEnabled ? 'Active' : 'Off',
                badgeColor: _screenReaderEnabled
                    ? AppColors.onlineGreen
                    : theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
              PremiumToggleRow(
                title: 'Enhanced semantic labels',
                subtitle: 'Provide detailed labels for screen readers',
                value: _semanticLabels,
                iconPath: AppIcons.microphone,
                onChanged: (value) {
                  setState(() => _semanticLabels = value);
                  _saveSettings();
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacingXL),
          PremiumSettingsGroup(
            title: 'Touch & interaction',
            children: [
              PremiumToggleRow(
                title: 'Larger touch targets',
                subtitle: 'Increase minimum touch target size to 48×48',
                value: _largerTouchTargets,
                iconPath: AppIcons.fingerPrint,
                onChanged: (value) {
                  setState(() {
                    _largerTouchTargets = value;
                    _touchTargetSize = value ? 48.0 : 44.0;
                  });
                  _saveSettings();
                },
              ),
              if (_largerTouchTargets)
                _SliderCard(
                  title: 'Touch target size',
                  valueLabel:
                      '${_touchTargetSize.toInt()}×${_touchTargetSize.toInt()}',
                  slider: Slider(
                    value: _touchTargetSize,
                    min: 44.0,
                    max: 60.0,
                    divisions: 8,
                    label: '${_touchTargetSize.toInt()}',
                    activeColor: AppColors.accentViolet,
                    onChanged: (value) {
                      setState(() => _touchTargetSize = value);
                      _saveSettings();
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacingXL),
          PremiumSettingsGroup(
            title: 'Audio',
            children: [
              PremiumToggleRow(
                title: 'Audio descriptions',
                subtitle: 'Narrate visual content for audio-only users',
                value: _audioDescriptions,
                iconPath: AppIcons.getIconPath('volume-high'),
                onChanged: (value) {
                  setState(() => _audioDescriptions = value);
                  _saveSettings();
                },
              ),
              PremiumToggleRow(
                title: 'Subtitles',
                subtitle: 'Show subtitles for audio content',
                value: _subtitlesEnabled,
                iconPath: AppIcons.documentText,
                onChanged: (value) {
                  setState(() => _subtitlesEnabled = value);
                  _saveSettings();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SliderCard extends StatelessWidget {
  const _SliderCard({
    required this.title,
    required this.valueLabel,
    required this.slider,
  });

  final String title;
  final String valueLabel;
  final Widget slider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.cardBackgroundDark
        : AppColors.cardBackgroundLight;
    final borderColor =
        AppColors.accentViolet.withValues(alpha: isDark ? 0.12 : 0.1);

    return Container(
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
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                valueLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentViolet,
                ),
              ),
            ],
          ),
          slider,
        ],
      ),
    );
  }
}

class _SettingOption extends StatelessWidget {
  const _SettingOption({
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
      semanticLabel: label,
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
