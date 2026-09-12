import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../widgets/buttons/gradient_button.dart';
import '../../../reference_data/data/models/reference_item.dart';
import '../../utils/onboarding_preferences_draft.dart';
import '../../widgets/onboarding_progress_indicator.dart';

/// Progress + intro copy (PERF-SCR-ONBPREF-001 section 0).
class OnboardingPreferencesHeader extends StatelessWidget {
  const OnboardingPreferencesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Column(
      children: [
        const OnboardingProgressIndicator(
          currentStep: 0,
          totalSteps: 1,
          stepLabel: 'Set your preferences',
        ),
        const SizedBox(height: AppSpacing.spacingLG),
        Text(
          'Help us find the perfect matches for you',
          style: AppTypography.body.copyWith(color: secondaryTextColor),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Title + optional caption + chip wrap bound to a [ValueNotifier].
class OnboardingChipSection extends StatelessWidget {
  const OnboardingChipSection({
    super.key,
    required this.title,
    required this.items,
    required this.selectedIds,
    this.caption,
  });

  final String title;
  final String? caption;
  final List<ReferenceItem> items;
  final ValueNotifier<List<int>> selectedIds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.h3.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.spacingMD),
        if (caption != null) ...[
          Text(
            caption!,
            style: AppTypography.caption.copyWith(color: secondaryTextColor),
          ),
          const SizedBox(height: AppSpacing.spacingSM),
        ],
        ValueListenableBuilder<List<int>>(
          valueListenable: selectedIds,
          builder: (context, selected, _) {
            return Wrap(
              spacing: AppSpacing.spacingSM,
              runSpacing: AppSpacing.spacingSM,
              children: [
                for (final item in items)
                  OnboardingPreferenceChip(
                    key: ValueKey('onboarding_pref_chip_${item.id}'),
                    label: item.title,
                    isSelected: selected.contains(item.id),
                    onTap: () {
                      AppHaptics.selection();
                      selectedIds.value =
                          togglePreferenceId(selectedIds.value, item.id);
                    },
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class OnboardingPreferenceChip extends StatelessWidget {
  const OnboardingPreferenceChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor =
        isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacingMD,
          vertical: AppSpacing.spacingSM,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentPurple : surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.radiusRound),
          border: Border.all(
            color: isSelected ? AppColors.accentPurple : borderColor,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.body.copyWith(
            color: isSelected ? theme.colorScheme.onPrimary : textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class OnboardingAgeRangeSection extends StatelessWidget {
  const OnboardingAgeRangeSection({
    super.key,
    required this.ageRange,
  });

  final ValueNotifier<RangeValues> ageRange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return ValueListenableBuilder<RangeValues>(
      valueListenable: ageRange,
      builder: (context, values, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Age Range',
              style: AppTypography.h3.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.spacingMD),
            RangeSlider(
              values: values,
              min: 18,
              max: 100,
              divisions: 82,
              labels: RangeLabels(
                values.start.round().toString(),
                values.end.round().toString(),
              ),
              activeColor: AppColors.accentPurple,
              onChanged: (next) => ageRange.value = next,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${values.start.round()}',
                  style: AppTypography.body.copyWith(color: textColor),
                ),
                Text(
                  '${values.end.round()}',
                  style: AppTypography.body.copyWith(color: textColor),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class OnboardingDistanceSection extends StatelessWidget {
  const OnboardingDistanceSection({
    super.key,
    required this.maxDistance,
  });

  final ValueNotifier<double> maxDistance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return ValueListenableBuilder<double>(
      valueListenable: maxDistance,
      builder: (context, distance, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Maximum Distance',
              style: AppTypography.h3.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.spacingMD),
            Slider(
              value: distance,
              min: 1,
              max: 100,
              divisions: 99,
              label: '${distance.round()} km',
              activeColor: AppColors.accentPurple,
              onChanged: (next) => maxDistance.value = next,
            ),
            Text(
              '${distance.round()} km',
              style: AppTypography.h3.copyWith(color: textColor),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }
}

class OnboardingPreferencesSaveRow extends StatelessWidget {
  const OnboardingPreferencesSaveRow({
    super.key,
    required this.saving,
    required this.onSave,
  });

  final ValueNotifier<bool> saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: saving,
      builder: (context, isSaving, _) {
        return GradientButton(
          text: isSaving ? 'Saving...' : 'Save Preferences',
          onPressed: isSaving ? null : onSave,
          isLoading: isSaving,
          isFullWidth: true,
          iconPath: AppIcons.getIconPath('tick-circle'),
        );
      },
    );
  }
}
