import '../../data/repositories/matching_repository.dart';
import '../../data/models/like.dart';

/// Use Case: LikeProfileUseCase
/// Handles liking a user profile
class LikeProfileUseCase {
  final MatchingRepository _matchingRepository;

  LikeProfileUseCase(this._matchingRepository);

  /// Execute like profile use case
  /// Returns [LikeResponse] indicating if it's a match
  Future<LikeResponse> execute(int profileId) async {
    try {
      return await _matchingRepository.likeProfile(profileId);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
