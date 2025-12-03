/// Call action request model (accept, reject, end)
class CallActionRequest {
  final int callId;
  final String action; // 'accept', 'reject', 'end'

  CallActionRequest({
    required this.callId,
    required this.action,
  });

  factory CallActionRequest.accept(int callId) {
    return CallActionRequest(callId: callId, action: 'accept');
  }

  factory CallActionRequest.reject(int callId) {
    return CallActionRequest(callId: callId, action: 'reject');
  }

  factory CallActionRequest.end(int callId) {
    return CallActionRequest(callId: callId, action: 'end');
  }

  Map<String, dynamic> toJson() {
    return {
      'call_id': callId,
      'action': action,
    };
  }
}
