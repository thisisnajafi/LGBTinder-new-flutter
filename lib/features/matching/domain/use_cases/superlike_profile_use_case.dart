import '../../data/repositories/matching_repository.dart';
import '../../data/models/superlike.dart';

/// Use Case: SuperlikeProfileUseCase
/// Handles superliking a user profile (premium feature)
class SuperlikeProfileUseCase {
  final MatchingRepository _matchingRepository;

  SuperlikeProfileUseCase(this._matchingRepository);

  /// Execute superlike profile use case
  /// Returns [SuperlikeResponse] indicating if it's a match and remaining superlikes
  Future<SuperlikeResponse> execute(int profileId) async {
    try {
      return await _matchingRepository.superlikeProfile(profileId);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
