import '../../data/repositories/profile_repository.dart';
import '../../data/models/user_profile.dart';

/// Use Case: GetProfileUseCase
/// Handles retrieving the current user's profile
class GetProfileUseCase {
  final ProfileRepository _profileRepository;

  GetProfileUseCase(this._profileRepository);

  /// Execute get profile use case
  /// Returns [UserProfile] with current user's profile data
  Future<UserProfile> execute() async {
    try {
      return await _profileRepository.getProfile();
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
