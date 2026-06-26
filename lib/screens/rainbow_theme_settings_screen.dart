// Screen: RainbowThemeSettingsScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/app_settings_detail.dart';
import '../core/widgets/premium/premium_design_system.dart';

/// Rainbow theme settings screen - Customize rainbow theme
class RainbowThemeSettingsScreen extends ConsumerStatefulWidget {
  const RainbowThemeSettingsScreen({super.key});

  @override
  ConsumerState<RainbowThemeSettingsScreen> createState() =>
      _RainbowThemeSettingsScreenState();
}

class _RainbowThemeSettingsScreenState
    extends ConsumerState<RainbowThemeSettingsScreen> {
  bool _rainbowThemeEnabled = false;
  String _rainbowStyle = 'gradient';
  double _rainbowIntensity = 0.5;
  double _animationSpeed = 1.0;

  final List<bool> _enabledColors = [true, true, true, true, true, true];
  static const _colorNames = [
    'Red',
    'Orange',
    'Yellow',
    'Green',
    'Blue',
    'Purple',
  ];

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
          const SnackBar(content: Text('Rainbow theme settings saved')),
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

  void _setStyle(String value) {
    setState(() => _rainbowStyle = value);
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final surfaceColor = isDark
        ? AppColors.cardBackgroundDark
        : AppColors.cardBackgroundLight;
    final borderColor =
        AppColors.accentViolet.withValues(alpha: isDark ? 0.12 : 0.1);

    return AppSettingsDetailScaffold(
      title: 'Rainbow theme',
      subtitle: 'Pride colors, style, and intensity',
      body: AppSettingsDetailList(
        children: [
          PremiumSettingsGroup(
            title: 'Theme',
            children: [
              PremiumToggleRow(
                title: 'Enable rainbow theme',
                subtitle: 'Apply pride colors throughout the app',
                value: _rainbowThemeEnabled,
                iconPath: AppIcons.magicStar,
                onChanged: (value) {
                  setState(() => _rainbowThemeEnabled = value);
                  _saveSettings();
                },
              ),
              if (_rainbowThemeEnabled) ...[
                _SettingOption(
                  label: 'Gradient',
                  isSelected: _rainbowStyle == 'gradient',
                  onSelect: () => _setStyle('gradient'),
                ),
                _SettingOption(
                  label: 'Solid colors',
                  isSelected: _rainbowStyle == 'solid',
                  onSelect: () => _setStyle('solid'),
                ),
                _SettingOption(
                  label: 'Animated',
                  isSelected: _rainbowStyle == 'animated',
                  onSelect: () => _setStyle('animated'),
                ),
                _SliderCard(
                  title: 'Rainbow intensity',
                  valueLabel: '${(_rainbowIntensity * 100).toInt()}%',
                  minLabel: 'Subtle',
                  maxLabel: 'Vibrant',
                  slider: Slider(
                    value: _rainbowIntensity,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    label: '${(_rainbowIntensity * 100).toInt()}%',
                    activeColor: AppColors.accentViolet,
                    onChanged: (value) {
                      setState(() => _rainbowIntensity = value);
                      _saveSettings();
                    },
                  ),
                ),
                if (_rainbowStyle == 'animated')
                  _SliderCard(
                    title: 'Animation speed',
                    valueLabel: '${_animationSpeed.toStringAsFixed(1)}x',
                    minLabel: 'Slow',
                    maxLabel: 'Fast',
                    slider: Slider(
                      value: _animationSpeed,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      label: '${_animationSpeed.toStringAsFixed(1)}x',
                      activeColor: AppColors.accentViolet,
                      onChanged: (value) {
                        setState(() => _animationSpeed = value);
                        _saveSettings();
                      },
                    ),
                  ),
              ],
            ],
          ),
          if (_rainbowThemeEnabled) ...[
            const SizedBox(height: AppSpacing.spacingXL),
            PremiumSettingsGroup(
              title: 'Rainbow colors',
              subtitle: 'Tap to include or exclude each stripe',
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.spacingMD),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(AppRadius.radiusLG),
                    border: Border.all(color: borderColor),
                  ),
                  child: Wrap(
                    spacing: AppSpacing.spacingSM,
                    runSpacing: AppSpacing.spacingSM,
                    children: List.generate(_colorNames.length, (index) {
                      final isEnabled = _enabledColors[index];
                      final color = AppColors.lgbtGradient[index];
                      return PremiumTapScale(
                        onTap: () {
                          setState(() => _enabledColors[index] = !isEnabled);
                          _saveSettings();
                        },
                        semanticLabel: '${_colorNames[index]} color',
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: isEnabled ? 1 : 0.35),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isEnabled
                                  ? Colors.white
                                  : borderColor,
                              width: isEnabled ? 2.5 : 1,
                            ),
                          ),
                          child: isEnabled
                              ? Center(
                                  child: AppSvgIcon(
                                    assetPath: AppIcons.tickCircle,
                                    size: 22,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ],
          if (!_rainbowThemeEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSettingsLayout.horizontalPadding,
                AppSpacing.spacingMD,
                AppSettingsLayout.horizontalPadding,
                0,
              ),
              child: Text(
                'Enable rainbow theme above to customize style and colors.',
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

class _SliderCard extends StatelessWidget {
  const _SliderCard({
    required this.title,
    required this.valueLabel,
    required this.minLabel,
    required this.maxLabel,
    required this.slider,
  });

  final String title;
  final String valueLabel;
  final String minLabel;
  final String maxLabel;
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(minLabel, style: theme.textTheme.bodySmall),
              Text(maxLabel, style: theme.textTheme.bodySmall),
            ],
          ),
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
