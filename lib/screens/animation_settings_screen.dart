// Screen: AnimationSettingsScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/divider_custom.dart';

/// Animation settings screen - Manage animation preferences
class AnimationSettingsScreen extends ConsumerStatefulWidget {
  const AnimationSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AnimationSettingsScreen> createState() => _AnimationSettingsScreenState();
}

class _AnimationSettingsScreenState extends ConsumerState<AnimationSettingsScreen> {
  // General animation settings
  bool _animationsEnabled = true;
  bool _reduceMotion = false;
  String _animationSpeed = 'normal'; // 'slow', 'normal', 'fast'
  double _animationDuration = 1.0; // Multiplier: 0.5x to 2.0x

  // Specific animation types
  bool _pageTransitions = true;
  bool _buttonAnimations = true;
  bool _listAnimations = true;
  bool _cardAnimations = true;
  bool _loadingAnimations = true;
  bool _gestureAnimations = true;

  // Animation curves
  String _animationCurve = 'easeOut'; // 'linear', 'easeIn', 'easeOut', 'easeInOut', 'elastic', 'bounce'

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // TODO: Load settings from API or local storage
    final mediaQuery = MediaQuery.of(context);
    _reduceMotion = mediaQuery.disableAnimations;
  }

  Future<void> _saveSettings() async {
    try {
      // TODO: Save settings via API or local storage
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Animation Settings',
        showBackButton: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        children: [
          // General settings
          SectionHeader(
            title: 'General Animation Settings',
            icon: Icons.animation,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildSwitchTile(
            title: 'Enable Animations',
            subtitle: 'Turn animations on or off',
            value: _animationsEnabled,
            onChanged: (value) {
              setState(() {
                _animationsEnabled = value;
              });
              _saveSettings();
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          if (_animationsEnabled) ...[
            SizedBox(height: AppSpacing.spacingSM),
            _buildSwitchTile(
              title: 'Reduce Motion',
              subtitle: 'Minimize animations for better performance',
              value: _reduceMotion,
              onChanged: (value) {
                setState(() {
                  _reduceMotion = value;
                });
                _saveSettings();
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            _buildSelectorTile(
              title: 'Animation Speed',
              subtitle: 'Control the speed of animations',
              value: _animationSpeed,
              options: [
                {'value': 'slow', 'label': 'Slow (0.5x)'},
                {'value': 'normal', 'label': 'Normal (1.0x)'},
                {'value': 'fast', 'label': 'Fast (1.5x)'},
              ],
              onChanged: (value) {
                setState(() {
                  _animationSpeed = value;
                  switch (value) {
                    case 'slow':
                      _animationDuration = 0.5;
                      break;
                    case 'normal':
                      _animationDuration = 1.0;
                      break;
                    case 'fast':
                      _animationDuration = 1.5;
                      break;
                  }
                });
                _saveSettings();
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            Container(
              padding: EdgeInsets.all(AppSpacing.spacingMD),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Animation Duration',
                        style: AppTypography.body.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_animationDuration.toStringAsFixed(1)}x',
                        style: AppTypography.body.copyWith(
                          color: AppColors.accentPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  Slider(
                    value: _animationDuration,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    label: '${_animationDuration.toStringAsFixed(1)}x',
                    activeColor: AppColors.accentPurple,
                    onChanged: (value) {
                      setState(() {
                        _animationDuration = value;
                        if (value < 0.75) {
                          _animationSpeed = 'slow';
                        } else if (value > 1.25) {
                          _animationSpeed = 'fast';
                        } else {
                          _animationSpeed = 'normal';
                        }
                      });
                      _saveSettings();
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '0.5x',
                        style: AppTypography.caption.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                      Text(
                        '2.0x',
                        style: AppTypography.caption.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.spacingMD),
            _buildSelectorTile(
              title: 'Animation Curve',
              subtitle: 'Choose the animation style',
              value: _animationCurve,
              options: [
                {'value': 'linear', 'label': 'Linear'},
                {'value': 'easeIn', 'label': 'Ease In'},
                {'value': 'easeOut', 'label': 'Ease Out'},
                {'value': 'easeInOut', 'label': 'Ease In Out'},
                {'value': 'elastic', 'label': 'Elastic'},
                {'value': 'bounce', 'label': 'Bounce'},
              ],
              onChanged: (value) {
                setState(() {
                  _animationCurve = value;
                });
                _saveSettings();
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
          ],
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Specific animation types
          SectionHeader(
            title: 'Animation Types',
            icon: Icons.tune,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildSwitchTile(
            title: 'Page Transitions',
            subtitle: 'Animate screen transitions',
            value: _pageTransitions,
            onChanged: _animationsEnabled
                ? (value) {
                    setState(() {
                      _pageTransitions = value;
                    });
                    _saveSettings();
                  }
                : null,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildSwitchTile(
            title: 'Button Animations',
            subtitle: 'Animate button presses and interactions',
            value: _buttonAnimations,
            onChanged: _animationsEnabled
                ? (value) {
                    setState(() {
                      _buttonAnimations = value;
                    });
                    _saveSettings();
                  }
                : null,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildSwitchTile(
            title: 'List Animations',
            subtitle: 'Animate list items and scrolling',
            value: _listAnimations,
            onChanged: _animationsEnabled
                ? (value) {
                    setState(() {
                      _listAnimations = value;
                    });
                    _saveSettings();
                  }
                : null,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildSwitchTile(
            title: 'Card Animations',
            subtitle: 'Animate card swipes and interactions',
            value: _cardAnimations,
            onChanged: _animationsEnabled
                ? (value) {
                    setState(() {
                      _cardAnimations = value;
                    });
                    _saveSettings();
                  }
                : null,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildSwitchTile(
            title: 'Loading Animations',
            subtitle: 'Animate loading indicators and skeletons',
            value: _loadingAnimations,
            onChanged: _animationsEnabled
                ? (value) {
                    setState(() {
                      _loadingAnimations = value;
                    });
                    _saveSettings();
                  }
                : null,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildSwitchTile(
            title: 'Gesture Animations',
            subtitle: 'Animate swipe and drag gestures',
            value: _gestureAnimations,
            onChanged: _animationsEnabled
                ? (value) {
                    setState(() {
                      _gestureAnimations = value;
                    });
                    _saveSettings();
                  }
                : null,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingXXL),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required bool value,
    required Function(bool)? onChanged,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body.copyWith(
                    color: onChanged == null
                        ? secondaryTextColor
                        : textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: AppSpacing.spacingXS),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.accentPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorTile({
    required String title,
    String? subtitle,
    required String value,
    required List<Map<String, String>> options,
    required Function(String) onChanged,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.body.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: AppSpacing.spacingXS),
            Text(
              subtitle,
              style: AppTypography.caption.copyWith(
                color: secondaryTextColor,
              ),
            ),
          ],
          SizedBox(height: AppSpacing.spacingMD),
          ...options.map((option) {
            final isSelected = value == option['value'];
            return Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.spacingSM),
              child: GestureDetector(
                onTap: () => onChanged(option['value']!),
                child: Container(
                  padding: EdgeInsets.all(AppSpacing.spacingMD),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentPurple.withOpacity(0.2)
                        : backgroundColor,
                    borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accentPurple
                          : borderColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option['label']!,
                          style: AppTypography.body.copyWith(
                            color: textColor,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: AppColors.accentPurple,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
