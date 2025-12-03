import '../../data/repositories/discovery_repository.dart';
import '../../data/models/discovery_profile.dart';
import '../../data/models/discovery_filters.dart';

/// Use Case: GetNearbySuggestionsUseCase
/// Handles retrieving nearby user suggestions
class GetNearbySuggestionsUseCase {
  final DiscoveryRepository _discoveryRepository;

  GetNearbySuggestionsUseCase(this._discoveryRepository);

  /// Execute get nearby suggestions use case
  /// Returns [List<DiscoveryProfile>] with nearby user suggestions
  Future<List<DiscoveryProfile>> execute({
    int limit = 20,
    DiscoveryFilters? filters,
  }) async {
    try {
      return await _discoveryRepository.getNearbySuggestions(
        limit: limit,
        filters: filters,
      );
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
