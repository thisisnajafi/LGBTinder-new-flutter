import '../../data/repositories/analytics_repository.dart';

/// Use case for tracking user activity
class TrackActivityUseCase {
  final AnalyticsRepository _repository;

  TrackActivityUseCase(this._repository);

  /// Execute track activity use case
  Future<void> execute({
    required String action,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      await _repository.trackActivity(
        action: action,
        metadata: metadata,
      );
    } catch (e) {
      rethrow;
    }
  }
}
