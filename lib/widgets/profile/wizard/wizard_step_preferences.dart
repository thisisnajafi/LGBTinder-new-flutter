import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/widgets/app_grouped_list_card.dart';
import '../../../core/widgets/metric_slider_tile.dart';
import '../../../features/profile/providers/profile_wizard_provider.dart';
import '../../../features/profile/providers/wizard_reference_cache_provider.dart';
import '../profile_wizard_layout.dart';
import 'wizard_step_support.dart';

/// Step 4 — age range, preferred genders, goals, lifestyle.
class WizardStepPreferences extends ConsumerWidget {
  const WizardStepPreferences({super.key});

  static const pageKey = ValueKey<String>('wizard-step-preferences');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final refs = ref.watch(wizardReferenceCacheProvider);
    final minAge =
        ref.watch(profileWizardProvider.select((s) => s.minAgePreference));
    final maxAge =
        ref.watch(profileWizardProvider.select((s) => s.maxAgePreference));
    final preferredGenders =
        ref.watch(profileWizardProvider.select((s) => s.preferredGenders));
    final relationGoals =
        ref.watch(profileWizardProvider.select((s) => s.relationGoals));
    final smoke = ref.watch(profileWizardProvider.select((s) => s.smoke));
    final drink = ref.watch(profileWizardProvider.select((s) => s.drink));
    final gym = ref.watch(profileWizardProvider.select((s) => s.gym));

    return ProfileWizardLayout.stepList(children: [
      ProfileWizardLayout.section(
        'Preferences & Lifestyle',
        [
          ProfileWizardLayout.inset(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Age Preference',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      ' *',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.spacingMD),
                AgeRangeSliderTile(
                  minAge: minAge,
                  maxAge: maxAge,
                  onChanged: (values) {
                    ref.read(profileWizardProvider.notifier).setAgePreference(
                          min: values.start.round().clamp(18, maxAge - 1),
                          max: values.end.round().clamp(minAge + 1, 100),
                        );
                  },
                ),
              ],
            ),
          ),
          const AppGroupedRowSeparator(),
          refs.preferredGenders.when(
            data: (genders) {
              return WizardStepSupport.groupedMultiSelectPicker(
                context: context,
                label: 'Preferred Genders',
                hint: 'Select preferred genders',
                selectedTitles:
                    WizardStepSupport.titleListFor(genders, preferredGenders),
                onTap: () => WizardStepSupport.showMultiSelect(
                  context: context,
                  title: 'Select Preferred Genders',
                  items: genders,
                  selectedIds: preferredGenders,
                  onSelected: (ids) => ref
                      .read(profileWizardProvider.notifier)
                      .setPreferredGenders(ids),
                ),
                required: true,
              );
            },
            loading: () => WizardStepSupport.loadingField(
              label: 'Preferred Genders',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              isDark: isDark,
            ),
            error: (error, _) => WizardStepSupport.errorField(
              label: 'Preferred Genders',
              error: error,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              isDark: isDark,
            ),
          ),
          refs.relationGoals.when(
            data: (goals) {
              return WizardStepSupport.groupedMultiSelectPicker(
                context: context,
                label: 'Relationship Goals',
                hint: 'Select relationship goals',
                selectedTitles:
                    WizardStepSupport.titleListFor(goals, relationGoals),
                onTap: () => WizardStepSupport.showMultiSelect(
                  context: context,
                  title: 'Select Relationship Goals',
                  items: goals,
                  selectedIds: relationGoals,
                  onSelected: (ids) => ref
                      .read(profileWizardProvider.notifier)
                      .setRelationGoals(ids),
                ),
                required: true,
              );
            },
            loading: () => WizardStepSupport.loadingField(
              label: 'Relationship Goals',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              isDark: isDark,
            ),
            error: (error, _) => WizardStepSupport.errorField(
              label: 'Relationship Goals',
              error: error,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              isDark: isDark,
            ),
          ),
          AppGroupedSwitchTile(
            label: 'Smoking',
            subtitle: 'Do you smoke?',
            value: smoke,
            onChanged: (value) =>
                ref.read(profileWizardProvider.notifier).setSmoke(value),
          ),
          AppGroupedSwitchTile(
            label: 'Drinking',
            subtitle: 'Do you drink alcohol?',
            value: drink,
            onChanged: (value) =>
                ref.read(profileWizardProvider.notifier).setDrink(value),
          ),
          AppGroupedSwitchTile(
            label: 'Gym',
            subtitle: 'Do you work out regularly?',
            value: gym,
            onChanged: (value) =>
                ref.read(profileWizardProvider.notifier).setGym(value),
            showDivider: false,
          ),
        ],
        first: true,
      ),
    ]);
  }
}
