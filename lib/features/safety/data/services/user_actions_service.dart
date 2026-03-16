import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../models/block.dart';
import '../models/report.dart';
import '../models/favorite.dart';
import '../models/emergency_contact.dart';

/// User actions service (block, unblock, report, mute, favorites)
class UserActionsService {
  final ApiService _apiService;

  UserActionsService(this._apiService);

  /// Block a user
  Future<BlockedUser> blockUser(BlockUserRequest request) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.blockUser,
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return BlockedUser.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Unblock a user.
  /// API: DELETE /block/user expects body { "user_id": int }.
  Future<void> unblockUser(int blockedUserId) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        ApiEndpoints.blockUser,
        data: {'user_id': blockedUserId},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Check if a user is blocked.
  /// API: GET /block/check?user_id= returns { data: { is_blocked: bool } }.
  Future<bool> checkIfBlocked(int userId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.blockCheck,
        queryParameters: {'user_id': userId},
        fromJson: (json) => json as Map<String, dynamic>,
      );
      if (!response.isSuccess || response.data == null) return false;
      final data = response.data!['data'] as Map<String, dynamic>?;
      return data?['is_blocked'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Get list of blocked users.
  /// API: GET /block/list returns { data: { blocked_users: [...], total_blocked } }.
  Future<List<BlockedUser>> getBlockedUsers() async {
    try {
      final response = await _apiService.get<dynamic>(
        ApiEndpoints.blockList,
      );

      if (response.data is! Map<String, dynamic>) return [];
      final data = response.data as Map<String, dynamic>;
      final inner = data['data'] as Map<String, dynamic>?;
      if (inner == null) return [];
      final blockedUsers = inner['blocked_users'] as List<dynamic>?;
      if (blockedUsers == null) return [];

      return blockedUsers.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        map['blocked_user_id'] ??= map['id'];
        map['user_id'] ??= map['id'];
        map['first_name'] ??= map['name']?.toString().split(' ').first ?? 'Blocked User';
        return BlockedUser.fromJson(map);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Report a user.
  /// API: POST /reports returns 201 with data: { report: {...}, reportable_type, message }.
  Future<Report> reportUser(ReportUserRequest request) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.reports,
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        final reportJson = data['report'] as Map<String, dynamic>? ?? data;
        return Report.fromJson(reportJson);
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

  /// Unmute a user (API: DELETE mutes/unmute). Body: user_id.
  Future<void> unmuteUser(int userId) async {
    final response = await _apiService.delete<Map<String, dynamic>>(
      ApiEndpoints.mutesUnmute,
      data: {'user_id': userId},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
  }

  /// Get muted users list (API: GET mutes/list). Returns paginated data; list in data.muted_users.data.
  Future<Map<String, dynamic>> getMutesList({int page = 1}) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.mutesList,
      queryParameters: {'page': page},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// Update mutes settings (API: PUT mutes/settings). Body: user_id, mute_type.
  Future<void> updateMutesSettings({required int userId, required String muteType}) async {
    final response = await _apiService.put<Map<String, dynamic>>(
      ApiEndpoints.mutesSettings,
      data: {'user_id': userId, 'mute_type': muteType},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
  }

  /// Check if a user is muted (API: GET mutes/check?user_id=).
  Future<bool> checkIfMuted(int userId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.mutesCheck,
        queryParameters: {'user_id': userId},
        fromJson: (json) => json as Map<String, dynamic>,
      );
      if (!response.isSuccess || response.data == null) return false;
      final data = response.data!['data'] as Map<String, dynamic>?;
      return data?['is_muted'] == true;
    } catch (e) {
      return false;
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

  /// Remove user from favorites
  Future<void> removeFromFavorites(int favoriteUserId) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        ApiEndpoints.favoritesRemove,
        data: {'favorite_user_id': favoriteUserId},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get favorites list
  Future<List<FavoriteUser>> getFavorites() async {
    try {
      final response = await _apiService.get<dynamic>(
        ApiEndpoints.favoritesList,
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
            .map((item) => FavoriteUser.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Check if user is in favorites (API: GET favorites/check?user_id=).
  Future<bool> checkFavorite(int userId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.favoritesCheck,
        queryParameters: {'user_id': userId},
        fromJson: (json) => json as Map<String, dynamic>,
      );
      if (!response.isSuccess || response.data == null) return false;
      final data = response.data!['data'] as Map<String, dynamic>?;
      return data?['is_favorite'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Update note for a favorite (API: PUT favorites/note). Body: user_id, note.
  Future<void> updateFavoriteNote(int userId, String note) async {
    final response = await _apiService.put<Map<String, dynamic>>(
      ApiEndpoints.favoritesNote,
      data: {'user_id': userId, 'note': note},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
  }

  /// Get reports list (API: GET reports). Returns list of reports (same or similar to history).
  Future<List<Report>> getReports({int? page}) async {
    try {
      final response = await _apiService.get<dynamic>(
        ApiEndpoints.reports,
        queryParameters: page != null ? {'page': page} : null,
      );
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final list = data['data'] as List<dynamic>? ?? data['reports'] as List<dynamic>?;
        if (list != null) {
          return list
              .where((e) => e is Map<String, dynamic>)
              .map((e) => Report.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      if (response.data is List) {
        return (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map(Report.fromJson)
            .toList();
      }
    } catch (e) {
      rethrow;
    }
    return [];
  }

  /// Get reports list (backend: GET /reports?page= — paginated; no /reports/history).
  Future<List<Report>> getReportsHistory({int page = 1, String? status}) async {
    try {
      final queryParams = <String, dynamic>{'page': page};
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      final response = await _apiService.get<dynamic>(
        ApiEndpoints.reportsList,
        queryParameters: queryParams,
      );

      List<dynamic>? dataList;
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final inner = data['data'] as Map<String, dynamic>?;
        if (inner != null && inner['reports'] != null) {
          final reports = inner['reports'];
          if (reports is List) {
            dataList = reports;
          } else if (reports is Map && reports['data'] is List) {
            dataList = reports['data'] as List;
          }
        }
        if (dataList == null && data['data'] is List) dataList = data['data'] as List;
      } else if (response.data is List) {
        dataList = response.data as List;
      }

      if (dataList != null) {
        return dataList
            .map((item) => Report.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Get a single report by id (backend: GET /reports/:id).
  Future<Report?> getReportById(int reportId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.reportById(reportId),
        fromJson: (json) => json as Map<String, dynamic>,
      );
      if (!response.isSuccess || response.data == null) return null;
      final data = response.data!;
      final reportMap = data['data'] as Map<String, dynamic>? ?? data['report'] as Map<String, dynamic>? ?? data;
      return Report.fromJson(Map<String, dynamic>.from(reportMap));
    } catch (e) {
      rethrow;
    }
  }

  /// Add emergency contact
  Future<EmergencyContact> addEmergencyContact(AddEmergencyContactRequest request) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.emergencyContactsAdd,
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return EmergencyContact.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update emergency contact
  Future<EmergencyContact> updateEmergencyContact(UpdateEmergencyContactRequest request) async {
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        ApiEndpoints.emergencyContactById(request.contactId),
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return EmergencyContact.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Remove emergency contact
  Future<void> removeEmergencyContact(int contactId) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        ApiEndpoints.emergencyContactById(contactId),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get emergency contacts (uses list endpoint)
  Future<List<EmergencyContact>> getEmergencyContacts() async {
    try {
      final response = await _apiService.get<dynamic>(
        ApiEndpoints.emergencyContactsList,
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
            .map((item) => EmergencyContact.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Get emergency contacts from base endpoint (API: GET /emergency-contacts). Returns { contacts, total }.
  Future<Map<String, dynamic>> getEmergencyContactsBase() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.emergencyContactsBase,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// Create emergency contact via base endpoint (API: POST /emergency-contacts). Body: name, phone, relationship.
  Future<Map<String, dynamic>> createEmergencyContactBase(Map<String, dynamic> body) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.emergencyContactsBase,
      data: body,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// Verify emergency contact (API: POST emergency-contacts/:id/verify).
  Future<Map<String, dynamic>> verifyEmergencyContact(int contactId) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.emergencyContactVerify(contactId),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// Confirm emergency contact (API: POST emergency-contacts/:id/confirm). Body: code.
  Future<Map<String, dynamic>> confirmEmergencyContact(int contactId, String code) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.emergencyContactConfirm(contactId),
      data: {'code': code},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// Send emergency alert
  Future<EmergencyAlert> sendEmergencyAlert(SendEmergencyAlertRequest request) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.emergencyAlert,
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return EmergencyAlert.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }
}

