import '../../data/repositories/matching_repository.dart';

/// Use case for getting superlike history
class GetSuperlikeHistoryUseCase {
  final MatchingRepository _repository;

  GetSuperlikeHistoryUseCase(this._repository);

  /// Execute get superlike history use case
  Future<List<Superlike>> execute() async {
    try {
      return await _repository.getSuperlikeHistory();
    } catch (e) {
      rethrow;
    }
  }
}
