import '../../data/repositories/safety_repository.dart';
import '../../data/models/report.dart';

/// Use Case: ReportUserUseCase
/// Handles reporting users for inappropriate behavior
class ReportUserUseCase {
  final SafetyRepository _safetyRepository;

  ReportUserUseCase(this._safetyRepository);

  /// Execute report user use case
  /// Returns [Report] with report details
  Future<Report> execute(ReportUserRequest request) async {
    try {
      return await _safetyRepository.reportUser(request);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
