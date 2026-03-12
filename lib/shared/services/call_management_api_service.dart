import '../../core/constants/api_endpoints.dart';
import 'api_service.dart';

/// Call management API (initiate, accept, reject, end, history, statistics).
class CallManagementApiService {
  final ApiService _apiService;

  CallManagementApiService(this._apiService);

  /// POST call-management/initiate. Body: receiver_id.
  Future<Map<String, dynamic>> initiate(int receiverId) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.callManagementInitiate,
      data: {'receiver_id': receiverId},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST call-management/:id/accept
  Future<Map<String, dynamic>> accept(int callId) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.callManagementAccept(callId),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST call-management/:id/reject
  Future<Map<String, dynamic>> reject(int callId) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.callManagementReject(callId),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST call-management/:id/end
  Future<Map<String, dynamic>> end(int callId) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.callManagementEnd(callId),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET call-management/history. Returns { data: { calls: [], pagination: {} } }. Optional [page] for pagination.
  Future<Map<String, dynamic>> getHistory({int? page}) async {
    final path = page != null
        ? '${ApiEndpoints.callManagementHistory}?page=$page'
        : ApiEndpoints.callManagementHistory;
    final response = await _apiService.get<Map<String, dynamic>>(
      path,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// DELETE call-management/history/:id
  Future<void> deleteHistoryEntry(int id) async {
    final response = await _apiService.delete<Map<String, dynamic>>(
      ApiEndpoints.callManagementHistoryDelete(id),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
  }

  /// GET call-management/statistics. Returns total_calls, total_duration, missed_calls, etc.
  Future<Map<String, dynamic>> getStatistics() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.callManagementStatistics,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }
}
