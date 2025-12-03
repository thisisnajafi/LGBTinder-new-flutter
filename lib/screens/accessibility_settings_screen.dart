// Screen: AccessibilitySettingsScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/divider_custom.dart';

/// Accessibility settings screen - Manage accessibility preferences
class AccessibilitySettingsScreen extends ConsumerStatefulWidget {
  const AccessibilitySettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AccessibilitySettingsScreen> createState() => _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState extends ConsumerState<AccessibilitySettingsScreen> {
  // Text & Display
  double _fontSizeScale = 1.0; // 0.8 to 2.0
  bool _boldText = false;
  bool _highContrast = false;
  String _colorBlindMode = 'none'; // 'none', 'protanopia', 'deuteranopia', 'tritanopia'

  // Motion
  bool _reduceMotion = false;
  bool _disableAnimations = false;

  // Screen Reader
  bool _screenReaderEnabled = false; // This should be detected from system
  bool _semanticLabels = true;

  // Touch & Interaction
  bool _largerTouchTargets = false;
  double _touchTargetSize = 44.0; // Minimum 44x44 points

  // Audio
  bool _audioDescriptions = false;
  bool _subtitlesEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // TODO: Load settings from API or local storage
    // Check system accessibility settings
    final mediaQuery = MediaQuery.of(context);
    _screenReaderEnabled = mediaQuery.accessibleNavigation;
    _reduceMotion = mediaQuery.disableAnimations;
  }

  Future<void> _saveSettings() async {
    try {
      // TODO: Save settings via API or local storage
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
        title: 'Accessibility',
        showBackButton: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        children: [
          // Text & Display
          SectionHeader(
            title: 'Text & Display',
            icon: Icons.text_fields,
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
                      'Font Size',
                      style: AppTypography.body.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(_fontSizeScale * 100).toInt()}%',
                      style: AppTypography.body.copyWith(
                        color: AppColors.accentPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.spacingMD),
                Slider(
                  value: _fontSizeScale,
                  min: 0.8,
                  max: 2.0,
                  divisions: 12,
                  label: '${(_fontSizeScale * 100).toInt()}%',
                  activeColor: AppColors.accentPurple,
                  onChanged: (value) {
                    setState(() {
                      _fontSizeScale = value;
                    });
                    _saveSettings();
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Small',
                      style: AppTypography.caption.copyWith(
                        color: secondaryTextColor,
                      ),
                    ),
                    Text(
                      'Large',
                      style: AppTypography.caption.copyWith(
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildSwitchTile(
            title: 'Bold Text',
            subtitle: 'Use bold font for better readability',
            value: _boldText,
            onChanged: (value) {
              setState(() {
                _boldText = value;
              });
              _saveSettings();
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildSwitchTile(
            title: 'High Contrast',
            subtitle: 'Increase contrast for better visibility',
            value: _highContrast,
            onChanged: (value) {
              setState(() {
                _highContrast = value;
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
            title: 'Color Blind Mode',
            subtitle: 'Adjust colors for color vision deficiencies',
            value: _colorBlindMode,
            options: [
              {'value': 'none', 'label': 'None'},
              {'value': 'protanopia', 'label': 'Protanopia (Red-Blind)'},
              {'value': 'deuteranopia', 'label': 'Deuteranopia (Green-Blind)'},
              {'value': 'tritanopia', 'label': 'Tritanopia (Blue-Blind)'},
            ],
            onChanged: (value) {
              setState(() {
                _colorBlindMode = value;
              });
              _saveSettings();
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Motion
          SectionHeader(
            title: 'Motion',
            icon: Icons.animation,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildSwitchTile(
            title: 'Reduce Motion',
            subtitle: 'Minimize animations and transitions',
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
          SizedBox(height: AppSpacing.spacingSM),
          _buildSwitchTile(
            title: 'Disable Animations',
            subtitle: 'Turn off all animations completely',
            value: _disableAnimations,
            onChanged: (value) {
              setState(() {
                _disableAnimations = value;
              });
              _saveSettings();
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Screen Reader
          SectionHeader(
            title: 'Screen Reader',
            icon: Icons.hearing,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Container(
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
                        'Screen Reader',
                        style: AppTypography.body.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppSpacing.spacingXS),
                      Text(
                        _screenReaderEnabled
                            ? 'Enabled (System Setting)'
                            : 'Disabled',
                        style: AppTypography.caption.copyWith(
                          color: _screenReaderEnabled
                              ? AppColors.onlineGreen
                              : secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _screenReaderEnabled ? Icons.check_circle : Icons.info_outline,
                  color: _screenReaderEnabled
                      ? AppColors.onlineGreen
                      : secondaryTextColor,
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildSwitchTile(
            title: 'Enhanced Semantic Labels',
            subtitle: 'Provide detailed labels for screen readers',
            value: _semanticLabels,
            onChanged: (value) {
              setState(() {
                _semanticLabels = value;
              });
              _saveSettings();
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Touch & Interaction
          SectionHeader(
            title: 'Touch & Interaction',
            icon: Icons.touch_app,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildSwitchTile(
            title: 'Larger Touch Targets',
            subtitle: 'Increase minimum touch target size to 48x48 points',
            value: _largerTouchTargets,
            onChanged: (value) {
              setState(() {
                _largerTouchTargets = value;
                _touchTargetSize = value ? 48.0 : 44.0;
              });
              _saveSettings();
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          if (_largerTouchTargets) ...[
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
                        'Touch Target Size',
                        style: AppTypography.body.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_touchTargetSize.toInt()}x${_touchTargetSize.toInt()}',
                        style: AppTypography.body.copyWith(
                          color: AppColors.accentPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  Slider(
                    value: _touchTargetSize,
                    min: 44.0,
                    max: 60.0,
                    divisions: 8,
                    label: '${_touchTargetSize.toInt()}',
                    activeColor: AppColors.accentPurple,
                    onChanged: (value) {
                      setState(() {
                        _touchTargetSize = value;
                      });
                      _saveSettings();
                    },
                  ),
                ],
              ),
            ),
          ],
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Audio
          SectionHeader(
            title: 'Audio',
            icon: Icons.volume_up,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildSwitchTile(
            title: 'Audio Descriptions',
            subtitle: 'Narrate visual content for audio-only users',
            value: _audioDescriptions,
            onChanged: (value) {
              setState(() {
                _audioDescriptions = value;
              });
              _saveSettings();
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildSwitchTile(
            title: 'Subtitles',
            subtitle: 'Show subtitles for audio content',
            value: _subtitlesEnabled,
            onChanged: (value) {
              setState(() {
                _subtitlesEnabled = value;
              });
              _saveSettings();
            },
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
    required Function(bool) onChanged,
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
