import '../services/call_service.dart';
import '../models/call.dart';
import '../models/call_action_request.dart';
import '../models/call_statistics.dart';

/// Call repository - wraps CallService for use in use cases
class CallRepository {
  final CallService _callService;

  CallRepository(this._callService);

  /// Initiate a new call
  Future<Call> initiateCall(InitiateCallRequest request) async {
    return await _callService.initiateCall(request);
  }

  /// Accept an incoming call
  Future<Call> acceptCall(CallActionRequest request) async {
    return await _callService.acceptCall(request);
  }

  /// Decline an incoming call
  Future<void> declineCall(CallActionRequest request) async {
    return await _callService.declineCall(request);
  }

  /// End an active call
  Future<Call> endCall(CallActionRequest request) async {
    return await _callService.endCall(request);
  }

  /// Get a specific call by ID
  Future<Call> getCall(String callId) async {
    return await _callService.getCall(callId);
  }

  /// Get call history
  Future<List<Call>> getCallHistory({
    int? page,
    int? limit,
    String? status,
    String? callType,
  }) async {
    return await _callService.getCallHistory(
      page: page,
      limit: limit,
      status: status,
      callType: callType,
    );
  }

  /// Get active call for user
  Future<Call?> getActiveCall() async {
    return await _callService.getActiveCall();
  }

  /// Update call settings
  Future<CallSettings> updateCallSettings(UpdateCallSettingsRequest request) async {
    return await _callService.updateCallSettings(request);
  }

  /// Get call settings
  Future<CallSettings> getCallSettings() async {
    return await _callService.getCallSettings();
  }

  /// Get call statistics
  Future<CallStatistics> getCallStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _callService.getCallStatistics(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Check if user can call another user
  Future<CallEligibility> checkCallEligibility(int targetUserId) async {
    return await _callService.checkCallEligibility(targetUserId);
  }

  /// Report call issue
  Future<void> reportCallIssue(CallIssueReport report) async {
    return await _callService.reportCallIssue(report);
  }

  /// Get call participants info
  Future<List<CallParticipant>> getCallParticipants(List<int> userIds) async {
    return await _callService.getCallParticipants(userIds);
  }
}