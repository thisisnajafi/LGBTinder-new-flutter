import '../services/discovery_service.dart';
import '../models/discovery_profile.dart';
import '../models/discovery_filters.dart';

/// Discovery repository - wraps DiscoveryService for use in use cases
class DiscoveryRepository {
  final DiscoveryService _discoveryService;

  DiscoveryRepository(this._discoveryService);

  /// Get discovery profiles (nearby suggestions)
  Future<List<DiscoveryProfile>> getDiscoveryProfiles({
    int limit = 20,
    DiscoveryFilters? filters,
  }) async {
    return await _discoveryService.getDiscoveryProfiles(
      limit: limit,
      filters: filters,
    );
  }

  /// Get nearby suggestions
  Future<List<DiscoveryProfile>> getNearbySuggestions({
    int limit = 20,
    Map<String, dynamic>? filters,
  }) async {
    return await _discoveryService.getNearbySuggestions(
      limit: limit,
      filters: filters,
    );
  }

  /// Apply filters to discovery
  Future<List<DiscoveryProfile>> applyFilters(DiscoveryFilters filters) async {
    return await _discoveryService.applyFilters(filters);
  }

  /// Like a profile
  Future<void> likeProfile(int profileId) async {
    return await _discoveryService.likeProfile(profileId);
  }

  /// Dislike a profile
  Future<void> dislikeProfile(int profileId) async {
    return await _discoveryService.dislikeProfile(profileId);
  }

  /// Superlike a profile
  Future<void> superlikeProfile(int profileId) async {
    return await _discoveryService.superlikeProfile(profileId);
  }

  /// Get user profile details for discovery
  Future<DiscoveryProfile> getUserProfile(int userId) async {
    return await _discoveryService.getUserProfile(userId);
  }
}
