import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/call.dart';
import '../data/models/call_action_request.dart';
import '../data/models/call_statistics.dart';
import '../domain/use_cases/initiate_call_use_case.dart';
import '../domain/use_cases/get_call_history_use_case.dart';
import '../domain/use_cases/get_call_use_case.dart';
import '../domain/use_cases/accept_call_use_case.dart';
import '../domain/use_cases/end_call_use_case.dart';

/// Call provider - manages call functionality and state
final callProvider = StateNotifierProvider<CallNotifier, CallState>((ref) {
  final initiateCallUseCase = ref.watch(initiateCallUseCaseProvider);
  final getCallHistoryUseCase = ref.watch(getCallHistoryUseCaseProvider);
  final getCallUseCase = ref.watch(getCallUseCaseProvider);
  final acceptCallUseCase = ref.watch(acceptCallUseCaseProvider);
  final endCallUseCase = ref.watch(endCallUseCaseProvider);

  return CallNotifier(
    initiateCallUseCase: initiateCallUseCase,
    getCallHistoryUseCase: getCallHistoryUseCase,
    getCallUseCase: getCallUseCase,
    acceptCallUseCase: acceptCallUseCase,
    endCallUseCase: endCallUseCase,
  );
});

/// Call state
class CallState {
  final Call? activeCall;
  final List<Call> callHistory;
  final CallSettings callSettings;
  final CallStatistics? statistics;
  final bool isLoading;
  final bool isInitiatingCall;
  final bool isAcceptingCall;
  final bool isEndingCall;
  final bool isLoadingHistory;
  final String? error;
  final String? incomingCallId;
  final Duration callDuration;

  CallState({
    this.activeCall,
    this.callHistory = const [],
    CallSettings? callSettings,
    this.statistics,
    this.isLoading = false,
    this.isInitiatingCall = false,
    this.isAcceptingCall = false,
    this.isEndingCall = false,
    this.isLoadingHistory = false,
    this.error,
    this.incomingCallId,
    this.callDuration = Duration.zero,
  }) : callSettings = callSettings ?? CallSettings();

  CallState copyWith({
    Call? activeCall,
    List<Call>? callHistory,
    CallSettings? callSettings,
    CallStatistics? statistics,
    bool? isLoading,
    bool? isInitiatingCall,
    bool? isAcceptingCall,
    bool? isEndingCall,
    bool? isLoadingHistory,
    String? error,
    String? incomingCallId,
    Duration? callDuration,
  }) {
    return CallState(
      activeCall: activeCall ?? this.activeCall,
      callHistory: callHistory ?? this.callHistory,
      callSettings: callSettings ?? this.callSettings,
      statistics: statistics ?? this.statistics,
      isLoading: isLoading ?? this.isLoading,
      isInitiatingCall: isInitiatingCall ?? this.isInitiatingCall,
      isAcceptingCall: isAcceptingCall ?? this.isAcceptingCall,
      isEndingCall: isEndingCall ?? this.isEndingCall,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      error: error ?? this.error,
      incomingCallId: incomingCallId ?? this.incomingCallId,
      callDuration: callDuration ?? this.callDuration,
    );
  }
}

/// Call notifier
class CallNotifier extends StateNotifier<CallState> {
  final InitiateCallUseCase _initiateCallUseCase;
  final GetCallHistoryUseCase _getCallHistoryUseCase;
  final GetCallUseCase _getCallUseCase;
  final AcceptCallUseCase _acceptCallUseCase;
  final EndCallUseCase _endCallUseCase;

  CallNotifier({
    required InitiateCallUseCase initiateCallUseCase,
    required GetCallHistoryUseCase getCallHistoryUseCase,
    required GetCallUseCase getCallUseCase,
    required AcceptCallUseCase acceptCallUseCase,
    required EndCallUseCase endCallUseCase,
  }) : _initiateCallUseCase = initiateCallUseCase,
       _getCallHistoryUseCase = getCallHistoryUseCase,
       _getCallUseCase = getCallUseCase,
       _acceptCallUseCase = acceptCallUseCase,
       _endCallUseCase = endCallUseCase,
       super(CallState());

  /// Initiate a new call
  Future<Call?> initiateCall(InitiateCallRequest request) async {
    state = state.copyWith(isInitiatingCall: true, error: null);

    try {
      final call = await _initiateCallUseCase.execute(request);
      state = state.copyWith(
        activeCall: call,
        isInitiatingCall: false,
      );
      return call;
    } catch (e) {
      state = state.copyWith(
        isInitiatingCall: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Accept an incoming call
  Future<bool> acceptCall(CallActionRequest request) async {
    state = state.copyWith(isAcceptingCall: true, error: null);

    try {
      final call = await _acceptCallUseCase.execute(request);
      state = state.copyWith(
        activeCall: call,
        incomingCallId: null,
        isAcceptingCall: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isAcceptingCall: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Decline an incoming call
  Future<bool> declineCall(CallActionRequest request) async {
    try {
      await _acceptCallUseCase.execute(request); // This will decline the call
      state = state.copyWith(incomingCallId: null);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// End an active call
  Future<bool> endCall(CallActionRequest request) async {
    state = state.copyWith(isEndingCall: true, error: null);

    try {
      final call = await _endCallUseCase.execute(request);
      state = state.copyWith(
        activeCall: null,
        callDuration: Duration.zero,
        isEndingCall: false,
      );

      // Add to call history
      final updatedHistory = [call, ...state.callHistory];
      state = state.copyWith(callHistory: updatedHistory);

      return true;
    } catch (e) {
      state = state.copyWith(
        isEndingCall: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Load call history
  Future<void> loadCallHistory({
    int? page,
    int? limit,
    String? status,
    String? callType,
  }) async {
    state = state.copyWith(isLoadingHistory: true, error: null);

    try {
      final history = await _getCallHistoryUseCase.execute(
        page: page,
        limit: limit,
        status: status,
        callType: callType,
      );

      state = state.copyWith(
        callHistory: history,
        isLoadingHistory: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingHistory: false,
        error: e.toString(),
      );
    }
  }

  /// Load recent calls
  Future<void> loadRecentCalls({int limit = 10}) async {
    try {
      final recentCalls = await _getCallHistoryUseCase.getRecentCalls(limit: limit);
      state = state.copyWith(callHistory: recentCalls);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Load missed calls
  Future<void> loadMissedCalls({int limit = 20}) async {
    try {
      final missedCalls = await _getCallHistoryUseCase.getMissedCalls(limit: limit);
      state = state.copyWith(callHistory: missedCalls);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Get call by ID
  Future<Call> getCall(String callId) async {
    return await _getCallUseCase.execute(callId);
  }

  /// Set incoming call
  void setIncomingCall(String callId) {
    state = state.copyWith(incomingCallId: callId);
  }

  /// Clear incoming call
  void clearIncomingCall() {
    state = state.copyWith(incomingCallId: null);
  }

  /// Update call duration
  void updateCallDuration(Duration duration) {
    state = state.copyWith(callDuration: duration);
  }

  /// Start call timer
  void startCallTimer() {
    // This would typically be handled by a timer in the UI
    // For now, just reset duration
    state = state.copyWith(callDuration: Duration.zero);
  }


  /// Check if there's an active call
  bool get hasActiveCall => state.activeCall != null;

  /// Check if there's an incoming call
  bool get hasIncomingCall => state.incomingCallId != null;

  /// Get formatted call duration
  String get formattedCallDuration {
    final duration = state.callDuration;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get missed calls count
  int get missedCallsCount {
    return state.callHistory.where((call) => call.isMissed).length;
  }

  /// Get recent calls count
  int get recentCallsCount {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return state.callHistory
        .where((call) => call.startedAt.isAfter(sevenDaysAgo))
        .length;
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset call state
  void reset() {
    state = CallState();
  }
}

// Use case providers
final initiateCallUseCaseProvider = Provider<InitiateCallUseCase>((ref) {
  throw UnimplementedError('InitiateCallUseCase must be overridden in the provider scope');
});

final getCallHistoryUseCaseProvider = Provider<GetCallHistoryUseCase>((ref) {
  throw UnimplementedError('GetCallHistoryUseCase must be overridden in the provider scope');
});

final getCallUseCaseProvider = Provider<GetCallUseCase>((ref) {
  throw UnimplementedError('GetCallUseCase must be overridden in the provider scope');
});

final acceptCallUseCaseProvider = Provider<AcceptCallUseCase>((ref) {
  throw UnimplementedError('AcceptCallUseCase must be overridden in the provider scope');
});

final endCallUseCaseProvider = Provider<EndCallUseCase>((ref) {
  throw UnimplementedError('EndCallUseCase must be overridden in the provider scope');
});