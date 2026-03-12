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

  /// Get profile badge info (API: GET profile/badge/info). Returns data or throws on error.
  Future<Map<String, dynamic>> getProfileBadgeInfo() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.profileBadgeInfo,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// Get match status with a user (API: GET profile/:id/match-status). Returns { is_matched, target_user_id }.
  Future<Map<String, dynamic>> getProfileMatchStatus(int userId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.profileMatchStatus(userId),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// Get profiles by filter (by-job, by-language, etc.). Returns list of UserProfile.
  Future<List<UserProfile>> _getProfilesByEndpoint(String path) async {
    final response = await _apiService.get<dynamic>(path);
    List<dynamic>? list;
    if (response.data is List) {
      list = response.data as List;
    } else if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      list = data['data'] as List<dynamic>? ?? data['profiles'] as List<dynamic>?;
    }
    if (list == null) return [];
    return list
        .where((e) => e is Map<String, dynamic>)
        .map((e) => UserProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserProfile>> getProfilesByJob(int jobId) async =>
      _getProfilesByEndpoint(ApiEndpoints.profileByJob(jobId));
  Future<List<UserProfile>> getProfilesByLanguage(int id) async =>
      _getProfilesByEndpoint(ApiEndpoints.profileByLanguage(id));
  Future<List<UserProfile>> getProfilesByRelationGoal(int id) async =>
      _getProfilesByEndpoint(ApiEndpoints.profileByRelationGoal(id));
  Future<List<UserProfile>> getProfilesByInterest(int id) async =>
      _getProfilesByEndpoint(ApiEndpoints.profileByInterest(id));
  Future<List<UserProfile>> getProfilesByMusicGenre(int id) async =>
      _getProfilesByEndpoint(ApiEndpoints.profileByMusicGenre(id));
  Future<List<UserProfile>> getProfilesByEducation(int id) async =>
      _getProfilesByEndpoint(ApiEndpoints.profileByEducation(id));
  Future<List<UserProfile>> getProfilesByPreferredGender(int id) async =>
      _getProfilesByEndpoint(ApiEndpoints.profileByPreferredGender(id));
  Future<List<UserProfile>> getProfilesByGender(int id) async =>
      _getProfilesByEndpoint(ApiEndpoints.profileByGender(id));

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
        return images
            .where((image) => image != null)
            .map((image) {
              try {
                return UserImage.fromJson(image is Map<String, dynamic> ? image : Map<String, dynamic>.from(image as Map));
              } catch (e) {
                return null;
              }
            })
            .whereType<UserImage>()
            .toList();
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
