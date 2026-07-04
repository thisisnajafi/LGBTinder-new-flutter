import '../../data/repositories/profile_repository.dart';
import '../../data/models/profile_verification.dart';

/// Use Case: VerifyProfileUseCase
/// Handles profile verification operations
class VerifyProfileUseCase {
  final ProfileRepository _profileRepository;

  VerifyProfileUseCase(this._profileRepository);

  Future<ProfileVerification> getVerificationStatus() async {
    return _profileRepository.getVerificationStatus();
  }

  Future<ProfileVerification> submitPhotoVerification(
    String photoPath, {
    void Function(double progress)? onUploadProgress,
  }) async {
    return _profileRepository.submitPhotoVerification(
      photoPath,
      onUploadProgress: onUploadProgress,
    );
  }

  Future<ProfileVerification> submitIdVerification(
    String idPath, {
    void Function(double progress)? onUploadProgress,
  }) async {
    return _profileRepository.submitIdVerification(
      idPath,
      onUploadProgress: onUploadProgress,
    );
  }

  Future<ProfileVerification> submitVideoVerification(
    String videoPath, {
    void Function(double progress)? onUploadProgress,
  }) async {
    return _profileRepository.submitVideoVerification(
      videoPath,
      onUploadProgress: onUploadProgress,
    );
  }

  Future<List<VerificationHistoryItem>> getVerificationHistory() async {
    return _profileRepository.getVerificationHistory();
  }

  Future<ProfileVerification> cancelVerification(int verificationId) async {
    return _profileRepository.cancelVerification(verificationId);
  }

  Future<VerificationGuidelines> getVerificationGuidelines() async {
    return _profileRepository.getVerificationGuidelines();
  }
}
