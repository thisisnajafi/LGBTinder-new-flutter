import '../../data/repositories/matching_repository.dart';
import '../../data/models/compatibility_score.dart';

/// Use Case: GetCompatibilityScoreUseCase
/// Handles retrieving compatibility score between users
class GetCompatibilityScoreUseCase {
  final MatchingRepository _matchingRepository;

  GetCompatibilityScoreUseCase(this._matchingRepository);

  /// Execute get compatibility score use case
  /// Returns [CompatibilityScore] with detailed compatibility information
  Future<CompatibilityScore> execute(int targetUserId) async {
    try {
      return await _matchingRepository.getCompatibilityScore(targetUserId);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
