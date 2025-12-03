import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../models/block.dart';
import '../models/report.dart';
import '../models/favorite.dart';

/// User actions service (block, unblock, report, mute, favorites)
class UserActionsService {
  final ApiService _apiService;

  UserActionsService(this._apiService);

  /// Block a user
  Future<void> blockUser(BlockUserRequest request) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.blockUser,
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Unblock a user
  Future<void> unblockUser(int blockedUserId) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        ApiEndpoints.blockUser,
        data: {'blocked_user_id': blockedUserId},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get list of blocked users
  Future<List<BlockedUser>> getBlockedUsers() async {
    try {
      final response = await _apiService.get<dynamic>(
        ApiEndpoints.blockList,
      );

      List<dynamic>? dataList;
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['data'] != null && data['data'] is List) {
          dataList = data['data'] as List;
        }
      } else if (response.data is List) {
        dataList = response.data as List;
      }

      if (dataList != null) {
        return dataList
            .map((item) => BlockedUser.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Report a user
  Future<Report> reportUser(ReportUserRequest request) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.reports,
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return Report.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Mute a user
  Future<void> muteUser(int mutedUserId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.mutesMute,
        data: {'muted_user_id': mutedUserId},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Add user to favorites
  Future<FavoriteUser> addToFavorites(AddFavoriteRequest request) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.favoritesAdd,
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return FavoriteUser.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }
}

