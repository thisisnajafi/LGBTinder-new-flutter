import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../reference_data/data/models/reference_item.dart';
import '../../reference_data/providers/reference_data_providers.dart';
import 'profile_wizard_provider.dart';

/// Snapshot of wizard reference lists (PERF-PAGE-WIZARD-004).
///
/// Steps consume this instead of re-watching each [FutureProvider].
class WizardReferenceCache {
  const WizardReferenceCache({
    required this.countries,
    required this.genders,
    required this.educationLevels,
    required this.jobs,
    required this.languages,
    required this.preferredGenders,
    required this.relationGoals,
    required this.interests,
    required this.musicGenres,
  });

  final AsyncValue<List<ReferenceItem>> countries;
  final AsyncValue<List<ReferenceItem>> genders;
  final AsyncValue<List<ReferenceItem>> educationLevels;
  final AsyncValue<List<ReferenceItem>> jobs;
  final AsyncValue<List<ReferenceItem>> languages;
  final AsyncValue<List<ReferenceItem>> preferredGenders;
  final AsyncValue<List<ReferenceItem>> relationGoals;
  final AsyncValue<List<ReferenceItem>> interests;
  final AsyncValue<List<ReferenceItem>> musicGenres;
}

final wizardReferenceCacheProvider = Provider<WizardReferenceCache>((ref) {
  return WizardReferenceCache(
    countries: ref.watch(countriesProvider),
    genders: ref.watch(gendersProvider),
    educationLevels: ref.watch(educationLevelsProvider),
    jobs: ref.watch(jobsProvider),
    languages: ref.watch(languagesProvider),
    preferredGenders: ref.watch(preferredGendersProvider),
    relationGoals: ref.watch(relationshipGoalsProvider),
    interests: ref.watch(interestsProvider),
    musicGenres: ref.watch(musicGenresProvider),
  );
});

final wizardCitiesProvider = Provider<AsyncValue<List<ReferenceItem>>>((ref) {
  final countryId =
      ref.watch(profileWizardProvider.select((s) => s.countryId));
  if (countryId == null) {
    return const AsyncValue<List<ReferenceItem>>.data([]);
  }
  return ref.watch(citiesProvider(countryId));
});
