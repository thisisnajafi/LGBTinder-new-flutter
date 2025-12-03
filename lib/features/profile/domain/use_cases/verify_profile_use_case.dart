import '../../data/repositories/profile_repository.dart';
import '../../data/models/profile_verification.dart';

/// Use Case: VerifyProfileUseCase
/// Handles profile verification operations
class VerifyProfileUseCase {
  final ProfileRepository _profileRepository;

  VerifyProfileUseCase(this._profileRepository);

  /// Get verification status
  Future<ProfileVerification> getVerificationStatus() async {
    try {
      return await _profileRepository.getVerificationStatus();
    } catch (e) {
      rethrow;
    }
  }

  /// Submit photo verification
  Future<ProfileVerification> submitPhotoVerification(String photoPath) async {
    try {
      return await _profileRepository.submitPhotoVerification(photoPath);
    } catch (e) {
      rethrow;
    }
  }

  /// Submit ID verification
  Future<ProfileVerification> submitIdVerification(String idPath) async {
    try {
      return await _profileRepository.submitIdVerification(idPath);
    } catch (e) {
      rethrow;
    }
  }

  /// Submit video verification
  Future<ProfileVerification> submitVideoVerification(String videoPath) async {
    try {
      return await _profileRepository.submitVideoVerification(videoPath);
    } catch (e) {
      rethrow;
    }
  }

  /// Get verification history
  Future<List<ProfileVerification>> getVerificationHistory() async {
    try {
      return await _profileRepository.getVerificationHistory();
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel verification
  Future<void> cancelVerification(int verificationId) async {
    try {
      return await _profileRepository.cancelVerification(verificationId);
    } catch (e) {
      rethrow;
    }
  }

  /// Get verification guidelines
  Future<Map<String, dynamic>> getVerificationGuidelines() async {
    try {
      return await _profileRepository.getVerificationGuidelines();
    } catch (e) {
      rethrow;
    }
  }
}
