import '../../data/repositories/discovery_repository.dart';
import '../../data/models/discovery_profile.dart';
import '../../data/models/discovery_filters.dart';

/// Use Case: ApplyFiltersUseCase
/// Handles applying filters to discovery results
class ApplyFiltersUseCase {
  final DiscoveryRepository _discoveryRepository;

  ApplyFiltersUseCase(this._discoveryRepository);

  /// Execute apply filters use case
  /// Returns [List<DiscoveryProfile>] filtered by the provided filters
  Future<List<DiscoveryProfile>> execute(DiscoveryFilters filters) async {
    try {
      return await _discoveryRepository.applyFilters(filters);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
