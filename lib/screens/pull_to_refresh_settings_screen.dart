// Screen: PullToRefreshSettingsScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/divider_custom.dart';

/// Pull to refresh settings screen - Manage pull to refresh preferences
class PullToRefreshSettingsScreen extends ConsumerStatefulWidget {
  const PullToRefreshSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PullToRefreshSettingsScreen> createState() => _PullToRefreshSettingsScreenState();
}

class _PullToRefreshSettingsScreenState extends ConsumerState<PullToRefreshSettingsScreen> {
  // General settings
  bool _pullToRefreshEnabled = true;
  String _refreshIndicatorStyle = 'material'; // 'material', 'cupertino', 'custom'
  double _refreshThreshold = 100.0; // Distance in pixels to trigger refresh

  // Visual settings
  bool _showRefreshIndicator = true;
  String _indicatorColor = 'accent'; // 'accent', 'primary', 'custom'
  Color _customIndicatorColor = AppColors.accentPurple;

  // Behavior settings
  bool _enableOnScroll = true;
  bool _enableOnSwipe = true;
  String _refreshTrigger = 'release'; // 'release', 'drag'

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
          const SnackBar(content: Text('Pull to refresh settings saved')),
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
        title: 'Pull to Refresh',
        showBackButton: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        children: [
          // General settings
          SectionHeader(
            title: 'General Settings',
            icon: Icons.refresh,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildSwitchTile(
            title: 'Enable Pull to Refresh',
            subtitle: 'Enable pull to refresh functionality',
            value: _pullToRefreshEnabled,
            onChanged: (value) {
              setState(() {
                _pullToRefreshEnabled = value;
              });
              _saveSettings();
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          if (_pullToRefreshEnabled) ...[
            SizedBox(height: AppSpacing.spacingMD),
            _buildSelectorTile(
              title: 'Refresh Indicator Style',
              subtitle: 'Choose the style of refresh indicator',
              value: _refreshIndicatorStyle,
              options: [
                {'value': 'material', 'label': 'Material Design'},
                {'value': 'cupertino', 'label': 'Cupertino (iOS)'},
                {'value': 'custom', 'label': 'Custom'},
              ],
              onChanged: (value) {
                setState(() {
                  _refreshIndicatorStyle = value;
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
                        'Refresh Threshold',
                        style: AppTypography.body.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_refreshThreshold.toInt()}px',
                        style: AppTypography.body.copyWith(
                          color: AppColors.accentPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  Slider(
                    value: _refreshThreshold,
                    min: 50.0,
                    max: 200.0,
                    divisions: 15,
                    label: '${_refreshThreshold.toInt()}px',
                    activeColor: AppColors.accentPurple,
                    onChanged: (value) {
                      setState(() {
                        _refreshThreshold = value;
                      });
                      _saveSettings();
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '50px',
                        style: AppTypography.caption.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                      Text(
                        '200px',
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
          if (_pullToRefreshEnabled) ...[
            SectionHeader(
              title: 'Visual Settings',
              icon: Icons.palette,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            _buildSwitchTile(
              title: 'Show Refresh Indicator',
              subtitle: 'Display the refresh indicator',
              value: _showRefreshIndicator,
              onChanged: (value) {
                setState(() {
                  _showRefreshIndicator = value;
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
              title: 'Indicator Color',
              subtitle: 'Choose the color of the refresh indicator',
              value: _indicatorColor,
              options: [
                {'value': 'accent', 'label': 'Accent Color'},
                {'value': 'primary', 'label': 'Primary Color'},
                {'value': 'custom', 'label': 'Custom Color'},
              ],
              onChanged: (value) {
                setState(() {
                  _indicatorColor = value;
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
          ],

          // Behavior settings
          if (_pullToRefreshEnabled) ...[
            SectionHeader(
              title: 'Behavior Settings',
              icon: Icons.tune,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            _buildSwitchTile(
              title: 'Enable on Scroll',
              subtitle: 'Allow pull to refresh when scrolling',
              value: _enableOnScroll,
              onChanged: (value) {
                setState(() {
                  _enableOnScroll = value;
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
              title: 'Enable on Swipe',
              subtitle: 'Allow pull to refresh when swiping',
              value: _enableOnSwipe,
              onChanged: (value) {
                setState(() {
                  _enableOnSwipe = value;
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
              title: 'Refresh Trigger',
              subtitle: 'When to trigger the refresh',
              value: _refreshTrigger,
              options: [
                {'value': 'release', 'label': 'On Release'},
                {'value': 'drag', 'label': 'On Drag'},
              ],
              onChanged: (value) {
                setState(() {
                  _refreshTrigger = value;
                });
                _saveSettings();
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
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
