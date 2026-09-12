import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_grouped_list_card.dart';
import '../../../core/widgets/metric_slider_tile.dart';
import '../../../features/profile/providers/profile_wizard_provider.dart';
import '../../../features/profile/providers/wizard_reference_cache_provider.dart';
import '../../../widgets/common/reference_bottom_sheet_field.dart';
import '../profile_wizard_layout.dart';
import 'wizard_step_support.dart';

/// Step 3 — bio, height/weight, education, job, languages.
class WizardStepAbout extends ConsumerStatefulWidget {
  const WizardStepAbout({super.key, required this.bioController});

  static const pageKey = ValueKey<String>('wizard-step-about');

  final TextEditingController bioController;

  @override
  ConsumerState<WizardStepAbout> createState() => _WizardStepAboutState();
}

class _WizardStepAboutState extends ConsumerState<WizardStepAbout> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    final refs = ref.watch(wizardReferenceCacheProvider);
    final height = ref.watch(profileWizardProvider.select((s) => s.height));
    final weight = ref.watch(profileWizardProvider.select((s) => s.weight));
    final educations = ref.watch(
      profileWizardProvider.select((s) => s.educations),
    );
    final jobs = ref.watch(profileWizardProvider.select((s) => s.jobs));
    final languages = ref.watch(
      profileWizardProvider.select((s) => s.languages),
    );

    return ProfileWizardLayout.stepList(
      children: [
        ProfileWizardLayout.section('About Me', [
          ProfileWizardLayout.inset(
            child: TextFormField(
              controller: widget.bioController,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Tell us about yourself...',
                alignLabelWithHint: true,
              ),
              onChanged: (value) =>
                  ref.read(profileWizardProvider.notifier).setBio(value),
              validator: (value) {
                if (value != null && value.length > 500) {
                  return 'Bio must be 500 characters or less';
                }
                return null;
              },
            ),
          ),
        ], first: true),
        ProfileWizardLayout.section('Personal Details', [
          ProfileWizardLayout.inset(
            child: HeightSliderTile(
              value: height,
              onChanged: (value) =>
                  ref.read(profileWizardProvider.notifier).setHeight(value),
            ),
          ),
          const AppGroupedRowSeparator(),
          ProfileWizardLayout.inset(
            child: WeightSliderTile(
              value: weight,
              onChanged: (value) =>
                  ref.read(profileWizardProvider.notifier).setWeight(value),
            ),
          ),
        ]),
        ProfileWizardLayout.section('Background', [
          refs.educationLevels.when(
            data: (items) => ReferenceBottomSheetField(
              label: 'Education',
              hint: 'Select your education level',
              selectedId: educations.isNotEmpty ? educations.first : null,
              items: items,
              groupedStyle: true,
              onChanged: (value) {
                ref
                    .read(profileWizardProvider.notifier)
                    .setEducations(value != null ? [value] : const []);
              },
              required: true,
              searchable: true,
            ),
            loading: () => WizardStepSupport.loadingField(
              label: 'Education',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              isDark: isDark,
            ),
            error: (error, _) => WizardStepSupport.errorField(
              label: 'Education',
              error: error,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              isDark: isDark,
            ),
          ),
          refs.jobs.when(
            data: (items) => ReferenceBottomSheetField(
              label: 'Job',
              hint: 'Select your job',
              selectedId: jobs.isNotEmpty ? jobs.first : null,
              items: items,
              groupedStyle: true,
              onChanged: (value) {
                ref
                    .read(profileWizardProvider.notifier)
                    .setJobs(value != null ? [value] : const []);
              },
              required: true,
              searchable: true,
            ),
            loading: () => WizardStepSupport.loadingField(
              label: 'Job',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              isDark: isDark,
            ),
            error: (error, _) => WizardStepSupport.errorField(
              label: 'Job',
              error: error,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              isDark: isDark,
            ),
          ),
          refs.languages.when(
            data: (items) {
              return WizardStepSupport.groupedMultiSelectPicker(
                context: context,
                label: 'Languages',
                hint: 'Select languages',
                selectedTitles: WizardStepSupport.titleListFor(
                  items,
                  languages,
                ),
                onTap: () => WizardStepSupport.showMultiSelect(
                  context: context,
                  title: 'Select Languages',
                  items: items,
                  selectedIds: languages,
                  onSelected: (ids) => ref
                      .read(profileWizardProvider.notifier)
                      .setLanguages(ids),
                ),
                required: true,
                showDivider: false,
              );
            },
            loading: () => WizardStepSupport.loadingField(
              label: 'Languages',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              isDark: isDark,
            ),
            error: (error, _) => WizardStepSupport.errorField(
              label: 'Languages',
              error: error,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              isDark: isDark,
            ),
          ),
        ]),
      ],
    );
  }
}
