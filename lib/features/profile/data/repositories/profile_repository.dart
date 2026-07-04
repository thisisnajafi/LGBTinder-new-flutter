import '../../domain/services/profile_service.dart';
import '../models/user_profile.dart';
import '../models/update_profile_request.dart';
import '../models/user_image.dart';
import '../models/profile_verification.dart';
import '../models/profile_completion.dart';

/// Profile repository - wraps ProfileService for use in use cases
class ProfileRepository {
  final ProfileService _profileService;

  ProfileRepository(this._profileService);

  /// Get current user profile
  Future<UserProfile> getProfile() async {
    return await _profileService.getProfile();
  }

  /// Get user profile by ID
  Future<UserProfile> getUserProfile(int userId) async {
    return await _profileService.getUserProfile(userId);
  }

  /// Update user profile
  Future<UserProfile> updateProfile(UpdateProfileRequest request) async {
    return await _profileService.updateProfile(request);
  }

  /// Upload profile image
  Future<UserImage> uploadImage(String imagePath) async {
    return await _profileService.uploadImage(imagePath);
  }

  /// Delete profile image
  Future<void> deleteImage(int imageId) async {
    return await _profileService.deleteImage(imageId);
  }

  /// Set primary profile image
  Future<void> setPrimaryImage(int imageId) async {
    return await _profileService.setPrimaryImage(imageId);
  }

  /// Get profile images
  Future<List<UserImage>> getProfileImages() async {
    return await _profileService.getProfileImages();
  }

  /// Get profile verification status
  Future<ProfileVerification> getVerificationStatus() async {
    return await _profileService.getVerificationStatus();
  }

  Future<ProfileVerification> submitPhotoVerification(
    String photoPath, {
    void Function(double progress)? onUploadProgress,
  }) async {
    return _profileService.submitPhotoVerification(
      photoPath,
      onUploadProgress: onUploadProgress,
    );
  }

  Future<ProfileVerification> submitIdVerification(
    String idPath, {
    void Function(double progress)? onUploadProgress,
  }) async {
    return _profileService.submitIdVerification(
      idPath,
      onUploadProgress: onUploadProgress,
    );
  }

  Future<ProfileVerification> submitVideoVerification(
    String videoPath, {
    void Function(double progress)? onUploadProgress,
  }) async {
    return _profileService.submitVideoVerification(
      videoPath,
      onUploadProgress: onUploadProgress,
    );
  }

  Future<List<VerificationHistoryItem>> getVerificationHistory() async {
    return _profileService.getVerificationHistory();
  }

  Future<ProfileVerification> cancelVerification(int verificationId) async {
    return _profileService.cancelVerification(verificationId);
  }

  Future<VerificationGuidelines> getVerificationGuidelines() async {
    return _profileService.getVerificationGuidelines();
  }

  /// Get profile completion status
  Future<ProfileCompletion> getProfileCompletionStatus() async {
    return await _profileService.getProfileCompletionStatus();
  }
}
