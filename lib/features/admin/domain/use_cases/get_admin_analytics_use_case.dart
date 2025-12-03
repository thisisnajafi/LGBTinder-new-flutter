import '../../data/repositories/admin_repository.dart';
import '../../data/models/admin_analytics.dart';

/// Use Case: GetAdminAnalyticsUseCase
/// Handles retrieving admin analytics data
class GetAdminAnalyticsUseCase {
  final AdminRepository _adminRepository;

  GetAdminAnalyticsUseCase(this._adminRepository);

  /// Execute get admin analytics use case
  /// Returns [AdminAnalytics] with dashboard statistics
  Future<AdminAnalytics> execute({
    AnalyticsFilter? filter,
  }) async {
    try {
      return await _adminRepository.getAdminAnalytics(filter: filter);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
