import '../../data/repositories/profile_repository.dart';
import '../../data/models/update_profile_request.dart';
import '../../data/models/user_profile.dart';

/// Use Case: UpdateProfileUseCase
/// Handles updating user profile information
class UpdateProfileUseCase {
  final ProfileRepository _profileRepository;

  UpdateProfileUseCase(this._profileRepository);

  /// Execute update profile use case
  /// Returns [UserProfile] with updated profile data
  Future<UserProfile> execute(UpdateProfileRequest request) async {
    try {
      return await _profileRepository.updateProfile(request);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
