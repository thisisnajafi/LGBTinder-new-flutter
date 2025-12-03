import '../../data/repositories/profile_repository.dart';
import '../../data/models/user_image.dart';

/// Use Case: UploadImageUseCase
/// Handles uploading profile images
class UploadImageUseCase {
  final ProfileRepository _profileRepository;

  UploadImageUseCase(this._profileRepository);

  /// Execute upload image use case
  /// Returns [UserImage] with uploaded image data
  Future<UserImage> execute(String imagePath) async {
    try {
      return await _profileRepository.uploadImage(imagePath);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
