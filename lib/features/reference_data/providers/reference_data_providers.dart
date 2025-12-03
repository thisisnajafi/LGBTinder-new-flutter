import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_providers.dart';
import '../data/services/reference_data_service.dart';
import '../data/models/reference_item.dart';

/// Reference Data Service Provider
final referenceDataServiceProvider = Provider<ReferenceDataService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ReferenceDataService(apiService);
});

/// Countries Provider (FutureProvider for async data)
final countriesProvider = FutureProvider<List<ReferenceItem>>((ref) async {
  final service = ref.watch(referenceDataServiceProvider);
  return await service.getCountries();
});

/// Cities Provider (FutureProvider with countryId parameter)
final citiesProvider = FutureProvider.family<List<ReferenceItem>, int>((ref, countryId) async {
  final service = ref.watch(referenceDataServiceProvider);
  return await service.getCitiesByCountry(countryId);
});

/// Genders Provider
final gendersProvider = FutureProvider<List<ReferenceItem>>((ref) async {
  final service = ref.watch(referenceDataServiceProvider);
  return await service.getGenders();
});

/// Jobs Provider
final jobsProvider = FutureProvider<List<ReferenceItem>>((ref) async {
  final service = ref.watch(referenceDataServiceProvider);
  return await service.getJobs();
});

/// Education Levels Provider
final educationLevelsProvider = FutureProvider<List<ReferenceItem>>((ref) async {
  final service = ref.watch(referenceDataServiceProvider);
  return await service.getEducationLevels();
});

/// Interests Provider
final interestsProvider = FutureProvider<List<ReferenceItem>>((ref) async {
  final service = ref.watch(referenceDataServiceProvider);
  return await service.getInterests();
});

/// Languages Provider
final languagesProvider = FutureProvider<List<ReferenceItem>>((ref) async {
  final service = ref.watch(referenceDataServiceProvider);
  return await service.getLanguages();
});

/// Music Genres Provider
final musicGenresProvider = FutureProvider<List<ReferenceItem>>((ref) async {
  final service = ref.watch(referenceDataServiceProvider);
  return await service.getMusicGenres();
});

/// Relationship Goals Provider
final relationshipGoalsProvider = FutureProvider<List<ReferenceItem>>((ref) async {
  final service = ref.watch(referenceDataServiceProvider);
  return await service.getRelationshipGoals();
});

/// Preferred Genders Provider
final preferredGendersProvider = FutureProvider<List<ReferenceItem>>((ref) async {
  final service = ref.watch(referenceDataServiceProvider);
  return await service.getPreferredGenders();
});
