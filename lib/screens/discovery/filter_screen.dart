// Screen: FilterScreen
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
import '../../widgets/modals/bottom_sheet_custom.dart';

/// Filter screen - Discovery filters
class FilterScreen extends ConsumerStatefulWidget {
  const FilterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends ConsumerState<FilterScreen> {
  // Age range
  RangeValues _ageRange = const RangeValues(18, 35);
  
  // Distance
  double _maxDistance = 50.0;
  
  // Gender preferences
  List<String> _selectedGenders = ['All'];
  final List<String> _availableGenders = ['All', 'Male', 'Female', 'Non-binary', 'Other'];
  
  // Other filters
  bool _showVerifiedOnly = false;
  bool _showOnlineOnly = false;
  bool _showPremiumOnly = false;

  void _applyFilters() {
    // TODO: Apply filters and reload discovery cards
    Navigator.of(context).pop({
      'ageRange': _ageRange,
      'maxDistance': _maxDistance,
      'genders': _selectedGenders,
      'verifiedOnly': _showVerifiedOnly,
      'onlineOnly': _showOnlineOnly,
      'premiumOnly': _showPremiumOnly,
    });
  }

  void _resetFilters() {
    setState(() {
      _ageRange = const RangeValues(18, 35);
      _maxDistance = 50.0;
      _selectedGenders = ['All'];
      _showVerifiedOnly = false;
      _showOnlineOnly = false;
      _showPremiumOnly = false;
    });
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
        title: 'Filters',
        showBackButton: true,
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: Text(
              'Reset',
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
          // Age range
          SectionHeader(
            title: 'Age Range',
            icon: Icons.cake,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          RangeSlider(
            values: _ageRange,
            min: 18,
            max: 100,
            divisions: 82,
            labels: RangeLabels(
              _ageRange.start.round().toString(),
              _ageRange.end.round().toString(),
            ),
            activeColor: AppColors.accentPurple,
            onChanged: (RangeValues values) {
              setState(() {
                _ageRange = values;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_ageRange.start.round()}',
                style: AppTypography.body.copyWith(color: textColor),
              ),
              Text(
                '${_ageRange.end.round()}',
                style: AppTypography.body.copyWith(color: textColor),
              ),
            ],
          ),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Distance
          SectionHeader(
            title: 'Maximum Distance',
            icon: Icons.location_on,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Slider(
            value: _maxDistance,
            min: 1,
            max: 100,
            divisions: 99,
            label: '${_maxDistance.round()} km',
            activeColor: AppColors.accentPurple,
            onChanged: (double value) {
              setState(() {
                _maxDistance = value;
              });
            },
          ),
          Text(
            '${_maxDistance.round()} km',
            style: AppTypography.h3.copyWith(
              color: AppColors.accentPurple,
            ),
            textAlign: TextAlign.center,
          ),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Gender preferences
          SectionHeader(
            title: 'Show Me',
            icon: Icons.people,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Wrap(
            spacing: AppSpacing.spacingSM,
            runSpacing: AppSpacing.spacingSM,
            children: _availableGenders.map((gender) {
              final isSelected = _selectedGenders.contains(gender);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (gender == 'All') {
                      _selectedGenders = ['All'];
                    } else {
                      _selectedGenders.remove('All');
                      if (isSelected) {
                        _selectedGenders.remove(gender);
                      } else {
                        _selectedGenders.add(gender);
                      }
                      if (_selectedGenders.isEmpty) {
                        _selectedGenders = ['All'];
                      }
                    }
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacingMD,
                    vertical: AppSpacing.spacingSM,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentPurple.withOpacity(0.2)
                        : surfaceColor,
                    borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accentPurple
                          : borderColor,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    gender,
                    style: AppTypography.body.copyWith(
                      color: isSelected
                          ? AppColors.accentPurple
                          : textColor,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Additional filters
          SectionHeader(
            title: 'Additional Filters',
            icon: Icons.tune,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          SwitchListTile(
            title: Text(
              'Verified Only',
              style: AppTypography.body.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Show only verified profiles',
              style: AppTypography.caption.copyWith(color: secondaryTextColor),
            ),
            value: _showVerifiedOnly,
            onChanged: (value) {
              setState(() {
                _showVerifiedOnly = value;
              });
            },
            activeColor: AppColors.accentPurple,
          ),
          SwitchListTile(
            title: Text(
              'Online Only',
              style: AppTypography.body.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Show only online users',
              style: AppTypography.caption.copyWith(color: secondaryTextColor),
            ),
            value: _showOnlineOnly,
            onChanged: (value) {
              setState(() {
                _showOnlineOnly = value;
              });
            },
            activeColor: AppColors.accentPurple,
          ),
          SwitchListTile(
            title: Text(
              'Premium Only',
              style: AppTypography.body.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Show only premium members',
              style: AppTypography.caption.copyWith(color: secondaryTextColor),
            ),
            value: _showPremiumOnly,
            onChanged: (value) {
              setState(() {
                _showPremiumOnly = value;
              });
            },
            activeColor: AppColors.accentPurple,
          ),
          SizedBox(height: AppSpacing.spacingXXL),

          // Apply button
          GradientButton(
            text: 'Apply Filters',
            onPressed: _applyFilters,
            isFullWidth: true,
          ),
          SizedBox(height: AppSpacing.spacingXXL),
        ],
      ),
    );
  }
}
