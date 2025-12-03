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

  /// Submit photo verification
  Future<ProfileVerification> submitPhotoVerification(String photoPath) async {
    return await _profileService.submitPhotoVerification(photoPath);
  }

  /// Submit ID verification
  Future<ProfileVerification> submitIdVerification(String idPath) async {
    return await _profileService.submitIdVerification(idPath);
  }

  /// Submit video verification
  Future<ProfileVerification> submitVideoVerification(String videoPath) async {
    return await _profileService.submitVideoVerification(videoPath);
  }

  /// Get verification history
  Future<List<ProfileVerification>> getVerificationHistory() async {
    return await _profileService.getVerificationHistory();
  }

  /// Cancel verification
  Future<void> cancelVerification(int verificationId) async {
    return await _profileService.cancelVerification(verificationId);
  }

  /// Get verification guidelines
  Future<Map<String, dynamic>> getVerificationGuidelines() async {
    return await _profileService.getVerificationGuidelines();
  }

  /// Get profile completion status
  Future<ProfileCompletion> getProfileCompletionStatus() async {
    return await _profileService.getProfileCompletionStatus();
  }
}
