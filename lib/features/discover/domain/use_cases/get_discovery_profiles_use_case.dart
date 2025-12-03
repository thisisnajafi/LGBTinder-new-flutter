import '../../data/repositories/discovery_repository.dart';
import '../../data/models/discovery_profile.dart';
import '../../data/models/discovery_filters.dart';

/// Use Case: GetDiscoveryProfilesUseCase
/// Handles retrieving profiles for discovery/swipe functionality
class GetDiscoveryProfilesUseCase {
  final DiscoveryRepository _discoveryRepository;

  GetDiscoveryProfilesUseCase(this._discoveryRepository);

  /// Execute get discovery profiles use case
  /// Returns [List<DiscoveryProfile>] with profiles for swiping
  Future<List<DiscoveryProfile>> execute({
    int limit = 20,
    DiscoveryFilters? filters,
  }) async {
    try {
      return await _discoveryRepository.getDiscoveryProfiles(
        limit: limit,
        filters: filters,
      );
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
