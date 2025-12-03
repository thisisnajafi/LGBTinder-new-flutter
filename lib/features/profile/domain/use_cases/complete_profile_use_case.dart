import '../../data/repositories/profile_repository.dart';
import '../../data/models/profile_completion.dart';

/// Use Case: CompleteProfileUseCase
/// Handles profile completion status checking
class CompleteProfileUseCase {
  final ProfileRepository _profileRepository;

  CompleteProfileUseCase(this._profileRepository);

  /// Get profile completion status
  Future<ProfileCompletion> execute() async {
    try {
      return await _profileRepository.getProfileCompletionStatus();
    } catch (e) {
      rethrow;
    }
  }
}
