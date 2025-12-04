import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../models/call.dart';
import '../models/call_statistics.dart';

/// Call service for managing voice and video calls
class CallService {
  final ApiService _apiService;

  CallService(this._apiService);

  /// Initiate a new call
  Future<Call> initiateCall(InitiateCallRequest request) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.callsInitiate,
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return Call.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Accept an incoming call
  Future<Call> acceptCall(CallActionRequest request) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.callsAccept(request.callId),
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return Call.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Decline an incoming call
  Future<void> declineCall(CallActionRequest request) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.callsDecline(request.callId),
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

  /// End an active call
  Future<Call> endCall(CallActionRequest request) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.callsEnd(request.callId),
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return Call.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get a specific call by ID
  Future<Call> getCall(String callId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '${ApiEndpoints.calls}/${callId}',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return Call.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get call history
  Future<List<Call>> getCallHistory({
    int? page,
    int? limit,
    String? status,
    String? callType,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (status != null) queryParams['status'] = status;
      if (callType != null) queryParams['call_type'] = callType;

      final response = await _apiService.get<dynamic>(
        ApiEndpoints.callsHistory,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
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
            .map((item) => Call.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Get active call for user
  Future<Call?> getActiveCall() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.callsActive,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return Call.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get call by ID
  Future<Call> getCall(String callId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.callsById(callId),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return Call.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update call settings
  Future<CallSettings> updateCallSettings(UpdateCallSettingsRequest request) async {
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        ApiEndpoints.callsSettings,
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return CallSettings.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get call settings
  Future<CallSettings> getCallSettings() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.callsSettings,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return CallSettings.fromJson(response.data!);
      } else {
        // Return default settings if none exist
        return CallSettings();
      }
    } catch (e) {
      // Return default settings on error
      return CallSettings();
    }
  }

  /// Get call statistics
  Future<CallStatistics> getCallStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.callsStatistics,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return CallStatistics.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Check if user can call another user
  Future<CallEligibility> checkCallEligibility(int targetUserId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.callsEligibility(targetUserId),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return CallEligibility.fromJson(response.data!);
      } else {
        // Default to not eligible if check fails
        return CallEligibility(canCall: false, reason: 'Unable to verify eligibility');
      }
    } catch (e) {
      return CallEligibility(canCall: false, reason: 'Network error');
    }
  }

  /// Report call issue
  Future<void> reportCallIssue(CallIssueReport report) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.callsReportIssue,
        data: report.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get call participants info
  Future<List<CallParticipant>> getCallParticipants(List<int> userIds) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.callsParticipants,
        data: {'user_ids': userIds},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!['participants'] as List?;
        if (data != null) {
          return data
              .map((item) => CallParticipant.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}
