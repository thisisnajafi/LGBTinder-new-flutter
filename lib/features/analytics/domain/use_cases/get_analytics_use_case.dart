import '../../data/repositories/analytics_repository.dart';
import '../../data/models/user_analytics.dart';

/// Use case for getting user analytics
class GetAnalyticsUseCase {
  final AnalyticsRepository _repository;

  GetAnalyticsUseCase(this._repository);

  /// Execute get analytics use case
  Future<UserAnalytics> execute({int days = 30}) async {
    try {
      return await _repository.getUserAnalytics(days: days);
    } catch (e) {
      rethrow;
    }
  }
}
