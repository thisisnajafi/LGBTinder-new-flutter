import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/api_providers.dart';
import '../../../../shared/services/api_service.dart';
import '../models/call.dart';
import '../models/call_settings.dart' as call_settings;
import '../models/initiate_call_request.dart';
import '../models/initiate_call_response.dart';
import '../models/call_action_request.dart';
import '../models/call_history_response.dart';
import '../models/call_settings_request.dart';
import '../models/call_quota.dart';

/// Calls service for handling video/voice call functionality
class CallsService {
  final ApiService _apiService;

  CallsService(this._apiService);

  /// Initiate a call (video or voice)
  Future<InitiateCallResponse> initiateCall(InitiateCallRequest request) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.callsInitiate,
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return InitiateCallResponse.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Accept an incoming call
  Future<void> acceptCall(int callId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.callsAccept,
        data: CallActionRequest.accept(callId).toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Reject an incoming call
  Future<void> rejectCall(int callId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.callsReject,
        data: CallActionRequest.reject(callId).toJson(),
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
  Future<void> endCall(int callId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.callsEnd,
        data: CallActionRequest.end(callId).toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get call history
  Future<CallHistoryResponse> getCallHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      final response = await _apiService.get<dynamic>(
        ApiEndpoints.callsHistory,
        queryParameters: queryParams,
      );

      List<dynamic>? dataList;
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['data'] != null && data['data'] is List) {
          dataList = data['data'] as List;
        }
      } else if (response.data is List) {
        dataList = response.data;
      }

      final calls = dataList?.map((item) => Call.fromJson(item as Map<String, dynamic>)).toList() ?? [];

      return CallHistoryResponse(
        calls: calls,
        total: calls.length,
        page: page,
        perPage: limit,
        hasMore: calls.length >= limit,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get active call status
  Future<Call?> getActiveCall() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.callsActive,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        if (data['call'] != null) {
          return Call.fromJson(data['call'] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Get call settings
  Future<call_settings.CallSettings> getCallSettings() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.callsSettings,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return call_settings.CallSettings.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update call settings
  Future<void> updateCallSettings(CallSettingsRequest request) async {
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        ApiEndpoints.callsSettingsUpdate,
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

  /// Get call quota/limits
  Future<CallQuota> getCallQuota() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.callsQuota,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return CallQuota.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }
}

/// Riverpod provider for CallsService
final callsServiceProvider = Provider<CallsService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return CallsService(apiService);
});
