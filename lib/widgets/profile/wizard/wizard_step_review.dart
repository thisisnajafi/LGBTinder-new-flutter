import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/utils/app_icons.dart';
import '../../../core/widgets/app_grouped_list_card.dart';
import '../../../features/profile/providers/profile_wizard_provider.dart';
import '../../../features/profile/providers/wizard_reference_cache_provider.dart';
import '../../../features/reference_data/data/models/reference_item.dart';
import '../profile_wizard_layout.dart';
import 'wizard_step_support.dart';

/// Step 7 — review summary. Uses [wizardReferenceCacheProvider] instead of
/// re-watching each reference list.
class WizardStepReview extends ConsumerWidget {
  const WizardStepReview({super.key});

  static const pageKey = ValueKey<String>('wizard-step-review');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final draft = ref.watch(profileWizardProvider);
    final refs = ref.watch(wizardReferenceCacheProvider);
    final cities = ref.watch(wizardCitiesProvider);

    String nameOf(AsyncValue<List<ReferenceItem>> async, int? id) {
      return async.maybeWhen(
        data: (items) {
          final match = items.firstWhere(
            (item) => item.id == id,
            orElse: () => ReferenceItem(id: -1, title: ''),
          );
          return match.id != -1 ? match.title : '';
        },
        orElse: () => '',
      );
    }

    final countryName = nameOf(refs.countries, draft.countryId);
    final cityName = nameOf(cities, draft.cityId);
    final genderName = nameOf(refs.genders, draft.genderId);
    final educationSummary =
        refs.educationLevels.maybeWhen(
              data: (items) =>
                  WizardStepSupport.titlesFor(items, draft.educations),
              orElse: () => '',
            );
    final jobsSummary = refs.jobs.maybeWhen(
      data: (items) => WizardStepSupport.titlesFor(items, draft.jobs),
      orElse: () => '',
    );
    final languagesSummary = refs.languages.maybeWhen(
      data: (items) => WizardStepSupport.titlesFor(items, draft.languages),
      orElse: () => '',
    );
    final preferredGendersSummary = refs.preferredGenders.maybeWhen(
      data: (items) =>
          WizardStepSupport.titlesFor(items, draft.preferredGenders),
      orElse: () => '',
    );
    final relationGoalsSummary = refs.relationGoals.maybeWhen(
      data: (items) =>
          WizardStepSupport.titlesFor(items, draft.relationGoals),
      orElse: () => '',
    );
    final interestsSummary = refs.interests.maybeWhen(
      data: (items) =>
          WizardStepSupport.titlesFor(items, draft.interestsIds),
      orElse: () => '',
    );
    final musicGenresSummary = refs.musicGenres.maybeWhen(
      data: (items) => WizardStepSupport.titlesFor(items, draft.musicGenres),
      orElse: () => '',
    );

    final birthDateStr = draft.birthDate == null
        ? ''
        : '${draft.birthDate!.day}/${draft.birthDate!.month}/${draft.birthDate!.year}';

    return ProfileWizardLayout.stepList(children: [
      ProfileWizardLayout.inset(
        child: Column(
          children: [
            AppSvgIcon(
              assetPath: AppIcons.checkCircle,
              size: 72,
              color: AppColors.onlineGreen,
            ),
            const SizedBox(height: AppSpacing.spacingLG),
            Text(
              'You\'re All Set!',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.spacingSM),
            Text(
              'Review your profile before continuing.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
      ProfileWizardLayout.section(
        'Profile Photo',
        [
          AppGroupedInfoTile(
            label: 'Profile Photo',
            value: draft.hasProfilePhoto ? 'Uploaded' : 'Not set',
            badge: draft.hasProfilePhoto ? 'Ready' : null,
          ),
          AppGroupedInfoTile(
            label: 'Additional Photos',
            value: draft.additionalImageFiles.isEmpty
                ? 'None added'
                : '${draft.additionalImageFiles.length} photos',
            showDivider: false,
          ),
        ],
        first: true,
        showTitle: true,
      ),
      ProfileWizardLayout.section(
        'Basic Information & Contact',
        [
          AppGroupedInfoTile(
            label: 'Name',
            value: draft.name.isNotEmpty ? draft.name : 'Not set',
          ),
          AppGroupedInfoTile(
            label: 'Phone',
            value:
                draft.phoneNumber.isNotEmpty ? draft.phoneNumber : 'Not set',
          ),
          AppGroupedInfoTile(
            label: 'Country',
            value: countryName.isNotEmpty ? countryName : 'Not set',
          ),
          AppGroupedInfoTile(
            label: 'City',
            value: cityName.isNotEmpty ? cityName : 'Not set',
          ),
          AppGroupedInfoTile(
            label: 'Gender',
            value: genderName.isNotEmpty ? genderName : 'Not set',
          ),
          AppGroupedInfoTile(
            label: 'Birth Date',
            value: birthDateStr.isNotEmpty ? birthDateStr : 'Not set',
          ),
          AppGroupedInfoTile(
            label: 'Age',
            value: draft.age != null ? '${draft.age} years' : 'Not set',
            showDivider: false,
          ),
        ],
      ),
      ProfileWizardLayout.section(
        'About You',
        [
          AppGroupedInfoTile(
            label: 'Bio',
            value: draft.bio.isNotEmpty ? draft.bio : 'Not set',
          ),
          AppGroupedInfoTile(
            label: 'Height',
            value: '${draft.height} cm',
          ),
          AppGroupedInfoTile(
            label: 'Weight',
            value: '${draft.weight} kg',
          ),
          AppGroupedInfoTile(
            label: 'Education',
            value: educationSummary.isEmpty ? 'Not set' : educationSummary,
          ),
          AppGroupedInfoTile(
            label: 'Job',
            value: jobsSummary.isEmpty ? 'Not set' : jobsSummary,
          ),
          AppGroupedInfoTile(
            label: 'Languages',
            value: languagesSummary.isEmpty ? 'Not set' : languagesSummary,
            showDivider: false,
          ),
        ],
      ),
      ProfileWizardLayout.section(
        'Preferences & Lifestyle',
        [
          AppGroupedInfoTile(
            label: 'Age Preference',
            value: '${draft.minAgePreference}-${draft.maxAgePreference} years',
          ),
          AppGroupedInfoTile(
            label: 'Preferred Genders',
            value: preferredGendersSummary.isEmpty
                ? 'Not set'
                : preferredGendersSummary,
          ),
          AppGroupedInfoTile(
            label: 'Relationship Goals',
            value: relationGoalsSummary.isEmpty
                ? 'Not set'
                : relationGoalsSummary,
          ),
          AppGroupedInfoTile(
            label: 'Smoking',
            value: draft.smoke ? 'Yes' : 'No',
          ),
          AppGroupedInfoTile(
            label: 'Drinking',
            value: draft.drink ? 'Yes' : 'No',
          ),
          AppGroupedInfoTile(
            label: 'Gym',
            value: draft.gym ? 'Yes' : 'No',
            showDivider: false,
          ),
        ],
      ),
      ProfileWizardLayout.section(
        'Interests & Music',
        [
          AppGroupedInfoTile(
            label: 'Music Genres',
            value:
                musicGenresSummary.isEmpty ? 'Not set' : musicGenresSummary,
          ),
          AppGroupedInfoTile(
            label: 'Interests',
            value: interestsSummary.isEmpty ? 'Not set' : interestsSummary,
            showDivider: false,
          ),
        ],
      ),
      ProfileWizardLayout.footnote(
        text: 'You can update any of these details later in profile settings.',
      ),
    ]);
  }
}
