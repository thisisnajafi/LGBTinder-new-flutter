import '../../data/repositories/admin_repository.dart';
import '../../data/models/admin_analytics.dart';

/// Use case for exporting analytics data
class ExportAnalyticsUseCase {
  final AdminRepository _repository;

  ExportAnalyticsUseCase(this._repository);

  /// Execute export analytics use case
  Future<String> execute(ExportAnalyticsRequest request) async {
    try {
      return await _repository.exportAnalytics(request);
    } catch (e) {
      rethrow;
    }
  }
}
