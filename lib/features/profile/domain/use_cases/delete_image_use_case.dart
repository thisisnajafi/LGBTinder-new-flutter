import '../../data/repositories/profile_repository.dart';

/// Use Case: DeleteImageUseCase
/// Handles deleting profile images
class DeleteImageUseCase {
  final ProfileRepository _profileRepository;

  DeleteImageUseCase(this._profileRepository);

  /// Execute delete image use case
  /// Returns void on successful deletion
  Future<void> execute(int imageId) async {
    try {
      return await _profileRepository.deleteImage(imageId);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
