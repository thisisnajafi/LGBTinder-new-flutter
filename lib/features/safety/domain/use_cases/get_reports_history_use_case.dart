import '../../data/repositories/safety_repository.dart';

/// Use case for getting reports history
class GetReportsHistoryUseCase {
  final SafetyRepository _repository;

  GetReportsHistoryUseCase(this._repository);

  /// Execute get reports history use case
  Future<List<Report>> execute() async {
    try {
      return await _repository.getReportsHistory();
    } catch (e) {
      rethrow;
    }
  }
}
