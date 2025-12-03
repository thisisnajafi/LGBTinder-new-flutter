// Screen: HapticFeedbackSettingsScreen
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/divider_custom.dart';

/// Haptic feedback settings screen - Manage haptic feedback preferences
class HapticFeedbackSettingsScreen extends ConsumerStatefulWidget {
  const HapticFeedbackSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HapticFeedbackSettingsScreen> createState() => _HapticFeedbackSettingsScreenState();
}

class _HapticFeedbackSettingsScreenState extends ConsumerState<HapticFeedbackSettingsScreen> {
  // General haptic settings
  bool _hapticEnabled = true;
  String _hapticIntensity = 'medium'; // 'light', 'medium', 'heavy'
  double _intensityValue = 0.5; // 0.0 to 1.0

  // Specific haptic types
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
      // TODO: Save settings via API or local storage
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
        break;
      case 'medium':
        HapticFeedback.mediumImpact();
        break;
      case 'heavy':
        HapticFeedback.heavyImpact();
        break;
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
        title: 'Haptic Feedback',
        showBackButton: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        children: [
          // General settings
          SectionHeader(
            title: 'General Settings',
            icon: Icons.vibration,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildSwitchTile(
            title: 'Enable Haptic Feedback',
            subtitle: 'Enable haptic feedback for interactions',
            value: _hapticEnabled,
            onChanged: (value) {
              setState(() {
                _hapticEnabled = value;
              });
              _saveSettings();
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          if (_hapticEnabled) ...[
            SizedBox(height: AppSpacing.spacingMD),
            _buildSelectorTile(
              title: 'Haptic Intensity',
              subtitle: 'Choose the strength of haptic feedback',
              value: _hapticIntensity,
              options: [
                {'value': 'light', 'label': 'Light'},
                {'value': 'medium', 'label': 'Medium'},
                {'value': 'heavy', 'label': 'Heavy'},
              ],
              onChanged: (value) {
                setState(() {
                  _hapticIntensity = value;
                  switch (value) {
                    case 'light':
                      _intensityValue = 0.3;
                      break;
                    case 'medium':
                      _intensityValue = 0.5;
                      break;
                    case 'heavy':
                      _intensityValue = 0.8;
                      break;
                  }
                });
                _saveSettings();
                _testHaptic();
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
                        'Intensity Level',
                        style: AppTypography.body.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(_intensityValue * 100).toInt()}%',
                        style: AppTypography.body.copyWith(
                          color: AppColors.accentPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  Slider(
                    value: _intensityValue,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    label: '${(_intensityValue * 100).toInt()}%',
                    activeColor: AppColors.accentPurple,
                    onChanged: (value) {
                      setState(() {
                        _intensityValue = value;
                        if (value < 0.4) {
                          _hapticIntensity = 'light';
                        } else if (value > 0.6) {
                          _hapticIntensity = 'heavy';
                        } else {
                          _hapticIntensity = 'medium';
                        }
                      });
                      _saveSettings();
                    },
                    onChangeEnd: (value) {
                      _testHaptic();
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Light',
                        style: AppTypography.caption.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                      Text(
                        'Heavy',
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
            Container(
              padding: EdgeInsets.all(AppSpacing.spacingMD),
              decoration: BoxDecoration(
                color: AppColors.accentPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                border: Border.all(color: AppColors.accentPurple),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Haptic',
                        style: AppTypography.body.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppSpacing.spacingXS),
                      Text(
                        'Tap to feel the current intensity',
                        style: AppTypography.caption.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.vibration,
                      color: AppColors.accentPurple,
                    ),
                    onPressed: _testHaptic,
                  ),
                ],
              ),
            ),
          ],
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Specific haptic types
          SectionHeader(
            title: 'Haptic Types',
            icon: Icons.tune,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildSwitchTile(
            title: 'Button Presses',
            subtitle: 'Haptic feedback when pressing buttons',
            value: _buttonHaptics,
            onChanged: _hapticEnabled
                ? (value) {
                    setState(() {
                      _buttonHaptics = value;
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
            title: 'Swipe Gestures',
            subtitle: 'Haptic feedback when swiping cards',
            value: _swipeHaptics,
            onChanged: _hapticEnabled
                ? (value) {
                    setState(() {
                      _swipeHaptics = value;
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
            title: 'New Matches',
            subtitle: 'Haptic feedback when you get a match',
            value: _matchHaptics,
            onChanged: _hapticEnabled
                ? (value) {
                    setState(() {
                      _matchHaptics = value;
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
            title: 'New Messages',
            subtitle: 'Haptic feedback when receiving messages',
            value: _messageHaptics,
            onChanged: _hapticEnabled
                ? (value) {
                    setState(() {
                      _messageHaptics = value;
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
            title: 'Errors',
            subtitle: 'Haptic feedback for error states',
            value: _errorHaptics,
            onChanged: _hapticEnabled
                ? (value) {
                    setState(() {
                      _errorHaptics = value;
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
            title: 'Success Actions',
            subtitle: 'Haptic feedback for successful actions',
            value: _successHaptics,
            onChanged: _hapticEnabled
                ? (value) {
                    setState(() {
                      _successHaptics = value;
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
