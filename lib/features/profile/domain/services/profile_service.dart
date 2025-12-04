import 'package:lgbtindernew/core/constants/api_endpoints.dart';
import 'package:lgbtindernew/shared/services/api_service.dart';
import 'package:lgbtindernew/shared/services/token_storage_service.dart';
import 'package:lgbtindernew/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/update_profile_request.dart';
import '../../data/models/user_image.dart';
import '../../data/models/profile_verification.dart';
import '../../data/models/profile_completion.dart';

/// Profile service for handling all profile-related API calls
class ProfileService {
  final ApiService _apiService;
  final TokenStorageService _tokenStorage;
  final DioClient _dioClient;

  ProfileService(
    this._apiService,
    this._tokenStorage,
    this._dioClient,
  );

  /// Get current user profile
  Future<UserProfile> getProfile() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.profile,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return UserProfile.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get user profile by ID
  Future<UserProfile> getUserProfile(int userId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.profileById(userId),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return UserProfile.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update user profile
  Future<UserProfile> updateProfile(UpdateProfileRequest request) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.profileUpdate,
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return UserProfile.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Upload profile image
  Future<UserImage> uploadImage(String imagePath) async {
    try {
      // Create multipart form data
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imagePath,
          filename: imagePath.split('/').last,
        ),
      });

      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.imagesUpload,
        data: formData,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return UserImage.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete profile image
  Future<void> deleteImage(int imageId) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        ApiEndpoints.imagesById(imageId),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Set primary profile image
  Future<void> setPrimaryImage(int imageId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.imagesSetPrimary(imageId),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get profile images
  Future<List<UserImage>> getProfileImages() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.imagesList,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final images = response.data!['images'] as List<dynamic>? ?? [];
        return images.map((image) => UserImage.fromJson(image as Map<String, dynamic>)).toList();
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get profile verification status
  Future<ProfileVerification> getVerificationStatus() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.profileVerificationStatus,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return ProfileVerification.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Submit photo verification
  Future<ProfileVerification> submitPhotoVerification(String photoPath) async {
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          photoPath,
          filename: photoPath.split('/').last,
        ),
      });

      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.profileVerificationPhoto,
        data: formData,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return ProfileVerification.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Submit ID verification
  Future<ProfileVerification> submitIdVerification(String idPath) async {
    try {
      final formData = FormData.fromMap({
        'id_document': await MultipartFile.fromFile(
          idPath,
          filename: idPath.split('/').last,
        ),
      });

      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.profileVerificationId,
        data: formData,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return ProfileVerification.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Submit video verification
  Future<ProfileVerification> submitVideoVerification(String videoPath) async {
    try {
      final formData = FormData.fromMap({
        'video': await MultipartFile.fromFile(
          videoPath,
          filename: videoPath.split('/').last,
        ),
      });

      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.profileVerificationVideo,
        data: formData,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return ProfileVerification.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get verification history
  Future<List<ProfileVerification>> getVerificationHistory() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.profileVerificationHistory,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final history = response.data!['history'] as List<dynamic>? ?? [];
        return history.map((item) => ProfileVerification.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel verification
  Future<void> cancelVerification(int verificationId) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        ApiEndpoints.profileVerificationCancel(verificationId),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get verification guidelines
  Future<Map<String, dynamic>> getVerificationGuidelines() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.profileVerificationGuidelines,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get profile completion status
  Future<ProfileCompletion> getProfileCompletionStatus() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.profileCompletionStatus,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return ProfileCompletion.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Change user email address
  Future<void> changeEmail(String newEmail) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.changeEmail,
        data: {'new_email': newEmail},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Verify email change with verification code
  Future<void> verifyEmailChange(String verificationCode) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.verifyEmailChange,
        data: {'verification_code': verificationCode},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }
}
