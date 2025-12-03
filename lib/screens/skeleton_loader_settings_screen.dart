// Screen: SkeletonLoaderSettingsScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/divider_custom.dart';

/// Skeleton loader settings screen - Manage skeleton loader preferences
class SkeletonLoaderSettingsScreen extends ConsumerStatefulWidget {
  const SkeletonLoaderSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SkeletonLoaderSettingsScreen> createState() => _SkeletonLoaderSettingsScreenState();
}

class _SkeletonLoaderSettingsScreenState extends ConsumerState<SkeletonLoaderSettingsScreen> {
  // General settings
  bool _skeletonLoadersEnabled = true;
  String _skeletonStyle = 'shimmer'; // 'shimmer', 'pulse', 'wave'
  double _animationSpeed = 1.0; // 0.5 to 2.0

  // Visual settings
  String _baseColor = 'surface'; // 'surface', 'gray', 'custom'
  Color _customBaseColor = AppColors.surfaceDark;
  String _highlightColor = 'elevated'; // 'elevated', 'accent', 'custom'
  Color _customHighlightColor = AppColors.surfaceElevatedDark;
  double _opacity = 0.7; // 0.0 to 1.0

  // Behavior settings
  bool _showOnInitialLoad = true;
  bool _showOnRefresh = true;
  int _minDisplayDuration = 500; // milliseconds

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
          const SnackBar(content: Text('Skeleton loader settings saved')),
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
        title: 'Skeleton Loaders',
        showBackButton: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        children: [
          // General settings
          SectionHeader(
            title: 'General Settings',
            icon: Icons.auto_awesome,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildSwitchTile(
            title: 'Enable Skeleton Loaders',
            subtitle: 'Show skeleton loaders while content loads',
            value: _skeletonLoadersEnabled,
            onChanged: (value) {
              setState(() {
                _skeletonLoadersEnabled = value;
              });
              _saveSettings();
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          if (_skeletonLoadersEnabled) ...[
            SizedBox(height: AppSpacing.spacingMD),
            _buildSelectorTile(
              title: 'Skeleton Style',
              subtitle: 'Choose the animation style',
              value: _skeletonStyle,
              options: [
                {'value': 'shimmer', 'label': 'Shimmer'},
                {'value': 'pulse', 'label': 'Pulse'},
                {'value': 'wave', 'label': 'Wave'},
              ],
              onChanged: (value) {
                setState(() {
                  _skeletonStyle = value;
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
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Visual settings
          if (_skeletonLoadersEnabled) ...[
            SectionHeader(
              title: 'Visual Settings',
              icon: Icons.palette,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            _buildSelectorTile(
              title: 'Base Color',
              subtitle: 'Color of the skeleton base',
              value: _baseColor,
              options: [
                {'value': 'surface', 'label': 'Surface Color'},
                {'value': 'gray', 'label': 'Gray'},
                {'value': 'custom', 'label': 'Custom'},
              ],
              onChanged: (value) {
                setState(() {
                  _baseColor = value;
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
              title: 'Highlight Color',
              subtitle: 'Color of the skeleton highlight',
              value: _highlightColor,
              options: [
                {'value': 'elevated', 'label': 'Elevated Surface'},
                {'value': 'accent', 'label': 'Accent Color'},
                {'value': 'custom', 'label': 'Custom'},
              ],
              onChanged: (value) {
                setState(() {
                  _highlightColor = value;
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
                        'Opacity',
                        style: AppTypography.body.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(_opacity * 100).toInt()}%',
                        style: AppTypography.body.copyWith(
                          color: AppColors.accentPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  Slider(
                    value: _opacity,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    label: '${(_opacity * 100).toInt()}%',
                    activeColor: AppColors.accentPurple,
                    onChanged: (value) {
                      setState(() {
                        _opacity = value;
                      });
                      _saveSettings();
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transparent',
                        style: AppTypography.caption.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                      Text(
                        'Opaque',
                        style: AppTypography.caption.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            DividerCustom(),
            SizedBox(height: AppSpacing.spacingLG),
          ],

          // Behavior settings
          if (_skeletonLoadersEnabled) ...[
            SectionHeader(
              title: 'Behavior Settings',
              icon: Icons.tune,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            _buildSwitchTile(
              title: 'Show on Initial Load',
              subtitle: 'Show skeleton loaders on first load',
              value: _showOnInitialLoad,
              onChanged: (value) {
                setState(() {
                  _showOnInitialLoad = value;
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
              title: 'Show on Refresh',
              subtitle: 'Show skeleton loaders when refreshing',
              value: _showOnRefresh,
              onChanged: (value) {
                setState(() {
                  _showOnRefresh = value;
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
                        'Min Display Duration',
                        style: AppTypography.body.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_minDisplayDuration}ms',
                        style: AppTypography.body.copyWith(
                          color: AppColors.accentPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  Slider(
                    value: _minDisplayDuration.toDouble(),
                    min: 0,
                    max: 2000,
                    divisions: 20,
                    label: '${_minDisplayDuration}ms',
                    activeColor: AppColors.accentPurple,
                    onChanged: (value) {
                      setState(() {
                        _minDisplayDuration = value.toInt();
                      });
                      _saveSettings();
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '0ms',
                        style: AppTypography.caption.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                      Text(
                        '2000ms',
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
