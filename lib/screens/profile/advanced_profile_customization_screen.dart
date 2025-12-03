// Screen: AdvancedProfileCustomizationScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../widgets/navbar/app_bar_custom.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/divider_custom.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/modals/alert_dialog_custom.dart';

/// Advanced profile customization screen - Advanced profile customization options
class AdvancedProfileCustomizationScreen extends ConsumerStatefulWidget {
  const AdvancedProfileCustomizationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdvancedProfileCustomizationScreen> createState() => _AdvancedProfileCustomizationScreenState();
}

class _AdvancedProfileCustomizationScreenState extends ConsumerState<AdvancedProfileCustomizationScreen> {
  bool _isSaving = false;

  // Customization options
  String _profileLayout = 'default';
  String _colorScheme = 'default';
  bool _showBadges = true;
  bool _showStats = true;
  bool _showInterests = true;
  bool _showEducation = true;
  bool _showWork = true;
  String _bioStyle = 'standard';
  bool _enableAnimations = true;
  double _profileOpacity = 1.0;

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
        title: 'Advanced Customization',
        showBackButton: true,
        actions: [
          if (_isSaving)
            Padding(
              padding: EdgeInsets.all(AppSpacing.spacingMD),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveSettings,
              child: Text(
                'Save',
                style: AppTypography.button.copyWith(
                  color: AppColors.accentPurple,
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        children: [
          SectionHeader(
            title: 'Layout Options',
            icon: Icons.view_quilt,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildLayoutOption(
            'Default',
            'default',
            Icons.grid_view,
            textColor,
            secondaryTextColor,
            surfaceColor,
            borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildLayoutOption(
            'Compact',
            'compact',
            Icons.view_compact,
            textColor,
            secondaryTextColor,
            surfaceColor,
            borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildLayoutOption(
            'Expanded',
            'expanded',
            Icons.view_agenda,
            textColor,
            secondaryTextColor,
            surfaceColor,
            borderColor,
          ),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          SectionHeader(
            title: 'Color Scheme',
            icon: Icons.palette,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildColorSchemeOption(
            'Default',
            'default',
            [AppColors.accentPurple],
            textColor,
            secondaryTextColor,
            surfaceColor,
            borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildColorSchemeOption(
            'Rainbow',
            'rainbow',
            [
              Colors.red,
              Colors.orange,
              Colors.yellow,
              Colors.green,
              Colors.blue,
              Colors.indigo,
              Colors.purple,
            ],
            textColor,
            secondaryTextColor,
            surfaceColor,
            borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildColorSchemeOption(
            'Monochrome',
            'monochrome',
            [Colors.grey],
            textColor,
            secondaryTextColor,
            surfaceColor,
            borderColor,
          ),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          SectionHeader(
            title: 'Display Options',
            icon: Icons.tune,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildSwitchOption(
            'Show Badges',
            'Display verification and premium badges',
            _showBadges,
            (value) => setState(() => _showBadges = value),
            textColor,
            secondaryTextColor,
            surfaceColor,
            borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildSwitchOption(
            'Show Stats',
            'Display profile statistics',
            _showStats,
            (value) => setState(() => _showStats = value),
            textColor,
            secondaryTextColor,
            surfaceColor,
            borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildSwitchOption(
            'Show Interests',
            'Display interests section',
            _showInterests,
            (value) => setState(() => _showInterests = value),
            textColor,
            secondaryTextColor,
            surfaceColor,
            borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildSwitchOption(
            'Show Education',
            'Display education section',
            _showEducation,
            (value) => setState(() => _showEducation = value),
            textColor,
            secondaryTextColor,
            surfaceColor,
            borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildSwitchOption(
            'Show Work',
            'Display work section',
            _showWork,
            (value) => setState(() => _showWork = value),
            textColor,
            secondaryTextColor,
            surfaceColor,
            borderColor,
          ),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          SectionHeader(
            title: 'Bio Style',
            icon: Icons.text_fields,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildBioStyleOption(
            'Standard',
            'standard',
            textColor,
            secondaryTextColor,
            surfaceColor,
            borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildBioStyleOption(
            'Minimal',
            'minimal',
            textColor,
            secondaryTextColor,
            surfaceColor,
            borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildBioStyleOption(
            'Detailed',
            'detailed',
            textColor,
            secondaryTextColor,
            surfaceColor,
            borderColor,
          ),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          SectionHeader(
            title: 'Advanced Options',
            icon: Icons.settings,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildSwitchOption(
            'Enable Animations',
            'Show profile animations',
            _enableAnimations,
            (value) => setState(() => _enableAnimations = value),
            textColor,
            secondaryTextColor,
            surfaceColor,
            borderColor,
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
                      'Profile Opacity',
                      style: AppTypography.body.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(_profileOpacity * 100).toInt()}%',
                      style: AppTypography.body.copyWith(
                        color: AppColors.accentPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.spacingMD),
                Slider(
                  value: _profileOpacity,
                  min: 0.5,
                  max: 1.0,
                  divisions: 10,
                  activeColor: AppColors.accentPurple,
                  onChanged: (value) {
                    setState(() {
                      _profileOpacity = value;
                    });
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.spacingXXL),
          GradientButton(
            text: 'Save Customization',
            onPressed: _isSaving ? null : _saveSettings,
            isLoading: _isSaving,
            isFullWidth: true,
            icon: Icons.save,
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutOption(
    String label,
    String value,
    IconData icon,
    Color textColor,
    Color secondaryTextColor,
    Color surfaceColor,
    Color borderColor,
  ) {
    final isSelected = _profileLayout == value;
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(
          color: isSelected
              ? AppColors.accentPurple
              : borderColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _profileLayout = value;
          });
        },
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.spacingMD),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppColors.accentPurple
                    : secondaryTextColor,
              ),
              SizedBox(width: AppSpacing.spacingMD),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body.copyWith(
                    color: textColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppColors.accentPurple,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorSchemeOption(
    String label,
    String value,
    List<Color> colors,
    Color textColor,
    Color secondaryTextColor,
    Color surfaceColor,
    Color borderColor,
  ) {
    final isSelected = _colorScheme == value;
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(
          color: isSelected
              ? AppColors.accentPurple
              : borderColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _colorScheme = value;
          });
        },
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.spacingMD),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: colors.length > 1
                      ? LinearGradient(colors: colors)
                      : null,
                  color: colors.length == 1 ? colors[0] : null,
                  borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                ),
              ),
              SizedBox(width: AppSpacing.spacingMD),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body.copyWith(
                    color: textColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppColors.accentPurple,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchOption(
    String title,
    String description,
    bool value,
    Function(bool) onChanged,
    Color textColor,
    Color secondaryTextColor,
    Color surfaceColor,
    Color borderColor,
  ) {
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
                SizedBox(height: AppSpacing.spacingXS),
                Text(
                  description,
                  style: AppTypography.caption.copyWith(
                    color: secondaryTextColor,
                  ),
                ),
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

  Widget _buildBioStyleOption(
    String label,
    String value,
    Color textColor,
    Color secondaryTextColor,
    Color surfaceColor,
    Color borderColor,
  ) {
    final isSelected = _bioStyle == value;
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(
          color: isSelected
              ? AppColors.accentPurple
              : borderColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _bioStyle = value;
          });
        },
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.spacingMD),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body.copyWith(
                    color: textColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppColors.accentPurple,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // TODO: Save settings via API
      // PUT /api/profile/customization
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        AlertDialogCustom.show(
          context,
          title: 'Settings Saved',
          message: 'Your customization settings have been saved!',
          icon: Icons.check_circle,
          iconColor: AppColors.onlineGreen,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
