import '../../data/repositories/matching_repository.dart';

/// Use case for checking if current user is matched with another user
class CheckMatchStatusUseCase {
  final MatchingRepository _matchingRepository;

  CheckMatchStatusUseCase(this._matchingRepository);

  /// Execute check match status use case
  /// Returns true if users are matched, false otherwise
  Future<bool> execute(int targetUserId) async {
    try {
      return await _matchingRepository.checkMatchStatus(targetUserId);
    } catch (e) {
      // If we can't check match status, assume not matched
      return false;
    }
  }
}
