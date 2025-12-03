// Screen: OnboardingPreferencesScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../widgets/navbar/app_bar_custom.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../features/profile/providers/profile_providers.dart';
import '../../features/profile/data/models/update_profile_request.dart';
import '../../features/reference_data/providers/reference_data_providers.dart';
import '../../features/reference_data/data/models/reference_item.dart';
import '../../shared/models/api_error.dart';
import '../../pages/home_page.dart';

/// Onboarding preferences screen - Preference selection during onboarding
class OnboardingPreferencesScreen extends ConsumerStatefulWidget {
  const OnboardingPreferencesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OnboardingPreferencesScreen> createState() => _OnboardingPreferencesScreenState();
}

class _OnboardingPreferencesScreenState extends ConsumerState<OnboardingPreferencesScreen> {
  bool _isSaving = false;
  bool _isLoading = true;

  // Reference data
  List<ReferenceItem> _genders = [];
  List<ReferenceItem> _preferredGenders = [];
  List<ReferenceItem> _relationGoals = [];
  List<ReferenceItem> _interests = [];

  // Gender preferences (using IDs)
  int? _selectedGenderId;
  List<int> _selectedPreferredGenderIds = [];

  // Age preferences
  RangeValues _ageRange = const RangeValues(18, 100);

  // Distance
  double _maxDistance = 50.0;

  // Relationship goals (using IDs)
  List<int> _selectedRelationGoalIds = [];

  // Interests (using IDs)
  List<int> _selectedInterestIds = [];

  @override
  void initState() {
    super.initState();
    _loadReferenceData();
  }

  Future<void> _loadReferenceData() async {
    try {
      final results = await Future.wait([
        ref.read(gendersProvider.future),
        ref.read(preferredGendersProvider.future),
        ref.read(relationshipGoalsProvider.future),
        ref.read(interestsProvider.future),
      ]);

      if (mounted) {
        setState(() {
          _genders = results[0];
          _preferredGenders = results[1];
          _relationGoals = results[2];
          _interests = results[3];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load preferences: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _savePreferences() async {
    // Validate minimum requirements
    if (_selectedInterestIds.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 3 interests'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final profileService = ref.read(profileServiceProvider);
      
      final request = UpdateProfileRequest(
        preferredGenders: _selectedPreferredGenderIds.isNotEmpty
            ? _selectedPreferredGenderIds
            : null,
        minAgePreference: _ageRange.start.round(),
        maxAgePreference: _ageRange.end.round(),
        relationGoals: _selectedRelationGoalIds.isNotEmpty
            ? _selectedRelationGoalIds
            : null,
        interests: _selectedInterestIds.isNotEmpty
            ? _selectedInterestIds
            : null,
      );

      await profileService.updateProfile(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved successfully!'),
            backgroundColor: AppColors.onlineGreen,
          ),
        );
        // Navigate to HomePage after saving preferences
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomePage(),
          ),
        );
      }
    } on ApiError catch (e) {
      if (mounted) {
        final errorMessage = e.errors != null && e.errors!.isNotEmpty
            ? e.getAllErrors()
            : e.message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preferences: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preferences: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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
        title: 'Set Your Preferences',
        showBackButton: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
              ),
            )
          : ListView(
              padding: EdgeInsets.all(AppSpacing.spacingLG),
              children: [
                Text(
                  'Help us find the perfect matches for you',
                  style: AppTypography.body.copyWith(
                    color: secondaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.spacingXXL),
                // Preferred genders
                Text(
                  'Looking For',
                  style: AppTypography.h3.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.spacingMD),
                Wrap(
                  spacing: AppSpacing.spacingSM,
                  runSpacing: AppSpacing.spacingSM,
                  children: _preferredGenders.map((gender) {
                    final isSelected = _selectedPreferredGenderIds.contains(gender.id);
                    return _buildChip(
                      label: gender.title,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedPreferredGenderIds.remove(gender.id);
                          } else {
                            _selectedPreferredGenderIds.add(gender.id);
                          }
                        });
                      },
                      textColor: textColor,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                    );
                  }).toList(),
                ),
                SizedBox(height: AppSpacing.spacingXL),
                // Age range
                Text(
                  'Age Range',
                  style: AppTypography.h3.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
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
                SizedBox(height: AppSpacing.spacingXL),
                // Distance
                Text(
                  'Maximum Distance',
                  style: AppTypography.h3.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
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
                  style: AppTypography.h3.copyWith(color: textColor),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.spacingXL),
                // Relationship goals
                Text(
                  'Relationship Goals',
                  style: AppTypography.h3.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.spacingMD),
                Wrap(
                  spacing: AppSpacing.spacingSM,
                  runSpacing: AppSpacing.spacingSM,
                  children: _relationGoals.map((goal) {
                    final isSelected = _selectedRelationGoalIds.contains(goal.id);
                    return _buildChip(
                      label: goal.title,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedRelationGoalIds.remove(goal.id);
                          } else {
                            _selectedRelationGoalIds.add(goal.id);
                          }
                        });
                      },
                      textColor: textColor,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                    );
                  }).toList(),
                ),
                SizedBox(height: AppSpacing.spacingXL),
                // Interests
                Text(
                  'Interests',
                  style: AppTypography.h3.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.spacingMD),
                Text(
                  'Select at least 3 interests',
                  style: AppTypography.caption.copyWith(
                    color: secondaryTextColor,
                  ),
                ),
                SizedBox(height: AppSpacing.spacingSM),
                Wrap(
                  spacing: AppSpacing.spacingSM,
                  runSpacing: AppSpacing.spacingSM,
                  children: _interests.map((interest) {
                    final isSelected = _selectedInterestIds.contains(interest.id);
                    return _buildChip(
                      label: interest.title,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedInterestIds.remove(interest.id);
                          } else {
                            _selectedInterestIds.add(interest.id);
                          }
                        });
                      },
                      textColor: textColor,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                    );
                  }).toList(),
                ),
                SizedBox(height: AppSpacing.spacingXXL),
                GradientButton(
                  text: _isSaving ? 'Saving...' : 'Save Preferences',
                  onPressed: _isSaving ? null : _savePreferences,
                  isLoading: _isSaving,
                  isFullWidth: true,
                  icon: Icons.save,
                ),
                SizedBox(height: AppSpacing.spacingXXL),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color textColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.spacingMD,
          vertical: AppSpacing.spacingSM,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentPurple
              : surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.radiusRound),
          border: Border.all(
            color: isSelected
                ? AppColors.accentPurple
                : borderColor,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.body.copyWith(
            color: isSelected ? Colors.white : textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
