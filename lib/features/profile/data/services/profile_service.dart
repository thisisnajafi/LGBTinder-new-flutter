import 'dart:io';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../shared/models/api_error.dart';
import '../../../../shared/services/api_service.dart';
import '../models/user_image.dart';
import '../models/user_profile.dart';
import '../models/update_profile_request.dart';

/// Profile management service
class ProfileService {
  final ApiService _apiService;

  ProfileService(this._apiService);

  /// Get my profile
  Future<UserProfile> getMyProfile() async {
    profileLog('getMyProfile: ${ApiEndpoints.profile}');
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.profile,
        fromJson: (json) => json as Map<String, dynamic>,
        useCache: false,
      );

      profileLog(
        'getMyProfile: status=${response.status} success=${response.isSuccess} '
        'message=${response.message} dataNull=${response.data == null}',
      );

      if (response.isSuccess && response.data != null) {
        try {
          final profile = UserProfile.fromJson(response.data!);
          profileLog('getMyProfile: parsed id=${profile.id}');
          return profile;
        } catch (e, st) {
          profileLog('getMyProfile: UserProfile.fromJson failed');
          profileLog('getMyProfile: raw keys=${response.data!.keys.toList()}');
          profileLogError('getMyProfile parse', e, st);
          rethrow;
        }
      } else {
        profileLog('getMyProfile: API returned failure — ${response.message}');
        throw Exception(
          response.message.isNotEmpty
              ? response.message
              : 'Failed to load profile',
        );
      }
    } on ApiError catch (e) {
      profileLogError('getMyProfile', e);
      rethrow;
    } catch (e, st) {
      profileLogError('getMyProfile', e, st);
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

  /// Update profile
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

  /// Get profile badge info (API: GET profile/badge/info). Returns data or throws on error.
  Future<Map<String, dynamic>> getProfileBadgeInfo() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.profileBadgeInfo,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
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

  /// Gallery and profile photos when GET /profile omits them.
  Future<List<UserImage>> getProfileImages() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.imagesList,
      fromJson: (json) {
        if (json is List) return <String, dynamic>{'images': json};
        if (json is Map<String, dynamic>) return json;
        if (json is Map) return Map<String, dynamic>.from(json);
        return <String, dynamic>{};
      },
    );
    if (!response.isSuccess || response.data == null) {
      throw Exception(response.message);
    }
    final raw = response.data!['images'] ?? response.data!['data'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((image) {
      return UserImage.fromJson(Map<String, dynamic>.from(image));
    }).toList();
  }
}

