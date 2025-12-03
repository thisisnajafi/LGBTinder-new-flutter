import '../../data/repositories/matching_repository.dart';

/// Use case for getting pending likes (received likes)
class GetPendingLikesUseCase {
  final MatchingRepository _repository;

  GetPendingLikesUseCase(this._repository);

  /// Execute get pending likes use case
  Future<List<Like>> execute() async {
    try {
      return await _repository.getPendingLikes();
    } catch (e) {
      rethrow;
    }
  }
}
