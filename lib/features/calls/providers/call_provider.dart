// Provider: Call Provider
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/calls_service.dart';
import '../data/models/initiate_call_request.dart';
import '../data/models/initiate_call_response.dart';
import '../data/models/call_history_response.dart';
import '../data/models/call_settings.dart';
import '../data/models/call_quota.dart';
import '../data/models/call_action_request.dart';
import '../data/models/call_settings_request.dart';

/// Call Provider - Manages call-related API operations
class CallProvider {
  final CallsService _callsService;

  CallProvider(this._callsService);

  /// Initiate a new call
  Future<InitiateCallResponse> initiateCall(InitiateCallRequest request) async {
    return await _callsService.initiateCall(request);
  }

  /// Accept an incoming call
  Future<void> acceptCall(int callId) async {
    await _callsService.acceptCall(callId);
  }

  /// Reject an incoming call
  Future<void> rejectCall(int callId) async {
    await _callsService.rejectCall(callId);
  }

  /// End an ongoing call
  Future<void> endCall(int callId) async {
    await _callsService.endCall(callId);
  }

  /// Get call history
  Future<CallHistoryResponse> getCallHistory() async {
    return await _callsService.getCallHistory();
  }

  /// Get call settings
  Future<CallSettings> getCallSettings() async {
    return await _callsService.getCallSettings();
  }

  /// Update call settings
  Future<void> updateCallSettings(CallSettings settings) async {
    await _callsService.updateCallSettings(CallSettingsRequest.fromSettings(settings));
  }

  /// Get call quota
  Future<CallQuota> getCallQuota() async {
    return await _callsService.getCallQuota();
  }
}

/// Riverpod provider for CallProvider
final callProvider = Provider<CallProvider>((ref) {
  final callsService = ref.watch(callsServiceProvider);
  return CallProvider(callsService);
});
