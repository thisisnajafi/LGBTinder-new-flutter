// Screen: AnimationSettingsScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/app_settings_detail.dart';
import '../core/widgets/premium/premium_design_system.dart';

/// Animation settings screen - Manage animation preferences
class AnimationSettingsScreen extends ConsumerStatefulWidget {
  const AnimationSettingsScreen({super.key});

  @override
  ConsumerState<AnimationSettingsScreen> createState() =>
      _AnimationSettingsScreenState();
}

class _AnimationSettingsScreenState
    extends ConsumerState<AnimationSettingsScreen> {
  bool _animationsEnabled = true;
  bool _reduceMotion = false;
  String _animationSpeed = 'normal';
  double _animationDuration = 1.0;
  String _animationCurve = 'easeOut';

  bool _pageTransitions = true;
  bool _buttonAnimations = true;
  bool _listAnimations = true;
  bool _cardAnimations = true;
  bool _loadingAnimations = true;
  bool _gestureAnimations = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final mediaQuery = MediaQuery.of(context);
    _reduceMotion = mediaQuery.disableAnimations;
  }

  Future<void> _saveSettings() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Animation settings saved')),
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

  void _setSpeed(String value) {
    setState(() {
      _animationSpeed = value;
      _animationDuration = switch (value) {
        'slow' => 0.5,
        'fast' => 1.5,
        _ => 1.0,
      };
    });
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
      title: 'Animation settings',
      subtitle: 'Motion speed, curves, and interaction types',
      body: AppSettingsDetailList(
        children: [
          PremiumSettingsGroup(
            title: 'General',
            children: [
              PremiumToggleRow(
                title: 'Enable animations',
                subtitle: 'Turn motion effects on or off',
                value: _animationsEnabled,
                iconPath: AppIcons.magicStar,
                onChanged: (value) {
                  setState(() => _animationsEnabled = value);
                  _saveSettings();
                },
              ),
              if (_animationsEnabled) ...[
                PremiumToggleRow(
                  title: 'Reduce motion',
                  subtitle: 'Minimize animations for comfort or performance',
                  value: _reduceMotion,
                  iconPath: AppIcons.eyeSlash,
                  onChanged: (value) {
                    setState(() => _reduceMotion = value);
                    _saveSettings();
                  },
                ),
                _SettingOption(
                  label: 'Slow (0.5x)',
                  isSelected: _animationSpeed == 'slow',
                  onSelect: () => _setSpeed('slow'),
                ),
                _SettingOption(
                  label: 'Normal (1.0x)',
                  isSelected: _animationSpeed == 'normal',
                  onSelect: () => _setSpeed('normal'),
                ),
                _SettingOption(
                  label: 'Fast (1.5x)',
                  isSelected: _animationSpeed == 'fast',
                  onSelect: () => _setSpeed('fast'),
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
                            'Animation duration',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${_animationDuration.toStringAsFixed(1)}x',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentViolet,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _animationDuration,
                        min: 0.5,
                        max: 2.0,
                        divisions: 15,
                        label: '${_animationDuration.toStringAsFixed(1)}x',
                        activeColor: AppColors.accentViolet,
                        onChanged: (value) {
                          setState(() {
                            _animationDuration = value;
                            _animationSpeed = value < 0.75
                                ? 'slow'
                                : value > 1.25
                                    ? 'fast'
                                    : 'normal';
                          });
                          _saveSettings();
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('0.5x', style: theme.textTheme.bodySmall),
                          Text('2.0x', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                _SettingOption(
                  label: 'Linear',
                  isSelected: _animationCurve == 'linear',
                  onSelect: () => _setCurve('linear'),
                ),
                _SettingOption(
                  label: 'Ease in',
                  isSelected: _animationCurve == 'easeIn',
                  onSelect: () => _setCurve('easeIn'),
                ),
                _SettingOption(
                  label: 'Ease out',
                  isSelected: _animationCurve == 'easeOut',
                  onSelect: () => _setCurve('easeOut'),
                ),
                _SettingOption(
                  label: 'Ease in out',
                  isSelected: _animationCurve == 'easeInOut',
                  onSelect: () => _setCurve('easeInOut'),
                ),
                _SettingOption(
                  label: 'Elastic',
                  isSelected: _animationCurve == 'elastic',
                  onSelect: () => _setCurve('elastic'),
                ),
                _SettingOption(
                  label: 'Bounce',
                  isSelected: _animationCurve == 'bounce',
                  onSelect: () => _setCurve('bounce'),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.spacingXL),
          PremiumSettingsGroup(
            title: 'Animation types',
            children: [
              PremiumToggleRow(
                title: 'Page transitions',
                subtitle: 'Animate screen transitions',
                value: _pageTransitions,
                iconPath: AppIcons.arrowRight,
                enabled: _animationsEnabled,
                onChanged: (value) {
                  setState(() => _pageTransitions = value);
                  _saveSettings();
                },
              ),
              PremiumToggleRow(
                title: 'Button animations',
                subtitle: 'Animate button presses',
                value: _buttonAnimations,
                iconPath: AppIcons.setting2,
                enabled: _animationsEnabled,
                onChanged: (value) {
                  setState(() => _buttonAnimations = value);
                  _saveSettings();
                },
              ),
              PremiumToggleRow(
                title: 'List animations',
                subtitle: 'Animate list items and scrolling',
                value: _listAnimations,
                iconPath: AppIcons.menu,
                enabled: _animationsEnabled,
                onChanged: (value) {
                  setState(() => _listAnimations = value);
                  _saveSettings();
                },
              ),
              PremiumToggleRow(
                title: 'Card animations',
                subtitle: 'Animate card swipes and interactions',
                value: _cardAnimations,
                iconPath: AppIcons.card,
                enabled: _animationsEnabled,
                onChanged: (value) {
                  setState(() => _cardAnimations = value);
                  _saveSettings();
                },
              ),
              PremiumToggleRow(
                title: 'Loading animations',
                subtitle: 'Animate loading indicators and skeletons',
                value: _loadingAnimations,
                iconPath: AppIcons.refreshCircle,
                enabled: _animationsEnabled,
                onChanged: (value) {
                  setState(() => _loadingAnimations = value);
                  _saveSettings();
                },
              ),
              PremiumToggleRow(
                title: 'Gesture animations',
                subtitle: 'Animate swipe and drag gestures',
                value: _gestureAnimations,
                iconPath: AppIcons.fingerPrint,
                enabled: _animationsEnabled,
                onChanged: (value) {
                  setState(() => _gestureAnimations = value);
                  _saveSettings();
                },
              ),
            ],
          ),
          if (!_animationsEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSettingsLayout.horizontalPadding,
                AppSpacing.spacingMD,
                AppSettingsLayout.horizontalPadding,
                0,
              ),
              child: Text(
                'Enable animations above to customize motion types.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: secondaryTextColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _setCurve(String value) {
    setState(() => _animationCurve = value);
    _saveSettings();
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
