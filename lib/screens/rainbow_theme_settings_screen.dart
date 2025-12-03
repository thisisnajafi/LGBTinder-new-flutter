// Screen: RainbowThemeSettingsScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/divider_custom.dart';

/// Rainbow theme settings screen - Customize rainbow theme
class RainbowThemeSettingsScreen extends ConsumerStatefulWidget {
  const RainbowThemeSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RainbowThemeSettingsScreen> createState() => _RainbowThemeSettingsScreenState();
}

class _RainbowThemeSettingsScreenState extends ConsumerState<RainbowThemeSettingsScreen> {
  // Theme settings
  bool _rainbowThemeEnabled = false;
  String _rainbowStyle = 'gradient'; // 'gradient', 'solid', 'animated'
  double _rainbowIntensity = 0.5; // 0.0 to 1.0
  double _animationSpeed = 1.0; // 0.5 to 2.0

  // Color settings
  List<bool> _enabledColors = [true, true, true, true, true, true]; // Red, Orange, Yellow, Green, Blue, Purple
  final List<Map<String, dynamic>> _rainbowColors = [
    {'name': 'Red', 'color': Colors.red, 'index': 0},
    {'name': 'Orange', 'color': Colors.orange, 'index': 1},
    {'name': 'Yellow', 'color': Colors.yellow, 'index': 2},
    {'name': 'Green', 'color': Colors.green, 'index': 3},
    {'name': 'Blue', 'color': Colors.blue, 'index': 4},
    {'name': 'Purple', 'color': Colors.purple, 'index': 5},
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
      // TODO: Save settings via API or local storage
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
        title: 'Rainbow Theme',
        showBackButton: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        children: [
          // Enable/disable
          SectionHeader(
            title: 'Theme Settings',
            icon: Icons.palette,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildSwitchTile(
            title: 'Enable Rainbow Theme',
            subtitle: 'Apply rainbow colors throughout the app',
            value: _rainbowThemeEnabled,
            onChanged: (value) {
              setState(() {
                _rainbowThemeEnabled = value;
              });
              _saveSettings();
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          if (_rainbowThemeEnabled) ...[
            SizedBox(height: AppSpacing.spacingMD),
            _buildSelectorTile(
              title: 'Rainbow Style',
              subtitle: 'Choose how rainbow colors are applied',
              value: _rainbowStyle,
              options: [
                {'value': 'gradient', 'label': 'Gradient'},
                {'value': 'solid', 'label': 'Solid Colors'},
                {'value': 'animated', 'label': 'Animated'},
              ],
              onChanged: (value) {
                setState(() {
                  _rainbowStyle = value;
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
                        'Rainbow Intensity',
                        style: AppTypography.body.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(_rainbowIntensity * 100).toInt()}%',
                        style: AppTypography.body.copyWith(
                          color: AppColors.accentPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  Slider(
                    value: _rainbowIntensity,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    label: '${(_rainbowIntensity * 100).toInt()}%',
                    activeColor: AppColors.accentPurple,
                    onChanged: (value) {
                      setState(() {
                        _rainbowIntensity = value;
                      });
                      _saveSettings();
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtle',
                        style: AppTypography.caption.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                      Text(
                        'Vibrant',
                        style: AppTypography.caption.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_rainbowStyle == 'animated') ...[
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
                          'Animation Speed',
                          style: AppTypography.body.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${_animationSpeed.toStringAsFixed(1)}x',
                          style: AppTypography.body.copyWith(
                            color: AppColors.accentPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.spacingMD),
                    Slider(
                      value: _animationSpeed,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      label: '${_animationSpeed.toStringAsFixed(1)}x',
                      activeColor: AppColors.accentPurple,
                      onChanged: (value) {
                        setState(() {
                          _animationSpeed = value;
                        });
                        _saveSettings();
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Slow',
                          style: AppTypography.caption.copyWith(
                            color: secondaryTextColor,
                          ),
                        ),
                        Text(
                          'Fast',
                          style: AppTypography.caption.copyWith(
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Color selection
          if (_rainbowThemeEnabled) ...[
            SectionHeader(
              title: 'Rainbow Colors',
              icon: Icons.color_lens,
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
                  Text(
                    'Select Colors',
                    style: AppTypography.body.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  Wrap(
                    spacing: AppSpacing.spacingSM,
                    runSpacing: AppSpacing.spacingSM,
                    children: _rainbowColors.map((colorData) {
                      final index = colorData['index'] as int;
                      final isEnabled = _enabledColors[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _enabledColors[index] = !_enabledColors[index];
                          });
                          _saveSettings();
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: (colorData['color'] as Color).withOpacity(
                              isEnabled ? 1.0 : 0.3,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isEnabled
                                  ? Colors.white
                                  : borderColor,
                              width: isEnabled ? 3 : 1,
                            ),
                          ),
                          child: isEnabled
                              ? Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 24,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
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
