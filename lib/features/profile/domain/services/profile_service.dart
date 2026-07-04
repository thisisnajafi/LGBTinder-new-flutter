import 'dart:convert';
import 'dart:io';

import 'package:lgbtindernew/core/constants/api_endpoints.dart';
import 'package:lgbtindernew/shared/services/api_service.dart';
import 'package:lgbtindernew/shared/services/token_storage_service.dart';
import 'package:lgbtindernew/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  /// Upload profile image (uses profile-pictures API so discover/matching checks pass).
  Future<UserImage> uploadImage(String imagePath) async {
    try {
      final response = await _apiService.uploadFile<Map<String, dynamic>>(
        ApiEndpoints.profilePicturesUpload,
        File(imagePath),
        fieldName: 'image',
        fields: {'is_primary': '1'},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final imageData = response.data!['image'] as Map<String, dynamic>;
        final sizes = imageData['sizes'] as Map<String, dynamic>?;
        final imageUrl = sizes?['full'] ?? sizes?['250x250'] ?? '';
        return UserImage(
          id: imageData['id'] as int,
          userId: 0,
          path: imageUrl is String ? imageUrl : '',
          type: 'profile',
          order: 0,
          isPrimary: true,
          sizes: sizes,
        );
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
        ApiEndpoints.profilePicturesSetPrimary(imageId),
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

  Future<ProfileVerification> _refreshVerificationStatusAfterAction() async {
    return getVerificationStatus();
  }

  Future<ProfileVerification> _submitVerificationFile({
    required String endpoint,
    required String fieldName,
    required String filePath,
    void Function(double progress)? onUploadProgress,
  }) async {
    final response = await _apiService.uploadFile<Map<String, dynamic>>(
      endpoint,
      File(filePath),
      fieldName: fieldName,
      onSendProgress: onUploadProgress == null
          ? null
          : (sent, total) {
              if (total > 0) {
                onUploadProgress(sent / total);
              }
            },
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (!response.isSuccess) {
      throw Exception(response.message);
    }

    VerificationSubmitResult.fromJson(
      response.data ?? <String, dynamic>{},
    );

    return _refreshVerificationStatusAfterAction();
  }

  /// Submit photo verification
  Future<ProfileVerification> submitPhotoVerification(
    String photoPath, {
    void Function(double progress)? onUploadProgress,
  }) async {
    try {
      return await _submitVerificationFile(
        endpoint: ApiEndpoints.profileVerificationPhoto,
        fieldName: 'photo',
        filePath: photoPath,
        onUploadProgress: onUploadProgress,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Submit ID verification
  Future<ProfileVerification> submitIdVerification(
    String idPath, {
    void Function(double progress)? onUploadProgress,
  }) async {
    try {
      return await _submitVerificationFile(
        endpoint: ApiEndpoints.profileVerificationId,
        fieldName: 'id_document',
        filePath: idPath,
        onUploadProgress: onUploadProgress,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Submit video verification
  Future<ProfileVerification> submitVideoVerification(
    String videoPath, {
    void Function(double progress)? onUploadProgress,
  }) async {
    try {
      return await _submitVerificationFile(
        endpoint: ApiEndpoints.profileVerificationVideo,
        fieldName: 'video',
        filePath: videoPath,
        onUploadProgress: onUploadProgress,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get verification history
  Future<List<VerificationHistoryItem>> getVerificationHistory() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.profileVerificationHistory,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final verifications =
            response.data!['verifications'] as List<dynamic>? ?? [];
        return verifications
            .whereType<Map>()
            .map((item) => VerificationHistoryItem.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList();
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel verification
  Future<ProfileVerification> cancelVerification(int verificationId) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        ApiEndpoints.profileVerificationCancel(verificationId),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }

      return _refreshVerificationStatusAfterAction();
    } catch (e) {
      rethrow;
    }
  }

  static const _guidelinesCacheKey = 'verification:guidelines';
  static const _guidelinesSavedAtKey = 'verification:guidelines:savedAt';
  static const _guidelinesTtl = Duration(hours: 24);

  /// Get verification guidelines (cached 24h in shared_preferences)
  Future<VerificationGuidelines> getVerificationGuidelines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAtMs = prefs.getInt(_guidelinesSavedAtKey);
      final cachedJson = prefs.getString(_guidelinesCacheKey);

      if (savedAtMs != null && cachedJson != null) {
        final age = DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(savedAtMs),
        );
        if (age < _guidelinesTtl) {
          final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
          return VerificationGuidelines.fromJson(decoded);
        }
      }

      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.profileVerificationGuidelines,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final envelope = <String, dynamic>{'data': response.data};
        await prefs.setString(_guidelinesCacheKey, jsonEncode(envelope));
        await prefs.setInt(
          _guidelinesSavedAtKey,
          DateTime.now().millisecondsSinceEpoch,
        );
        return VerificationGuidelines.fromJson(envelope);
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
