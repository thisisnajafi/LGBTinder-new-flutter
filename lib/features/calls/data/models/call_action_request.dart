/// Call action request model (accept, reject, end)
class CallActionRequest {
  final String callId;
  final String action; // 'accept', 'reject', 'end'
  final String? reason;

  CallActionRequest({
    required this.callId,
    required this.action,
    this.reason,
  });

  factory CallActionRequest.accept(String callId) {
    return CallActionRequest(callId: callId, action: 'accept');
  }

  factory CallActionRequest.reject(String callId, {String? reason}) {
    return CallActionRequest(callId: callId, action: 'reject', reason: reason);
  }

  factory CallActionRequest.end(String callId, {String? reason}) {
    return CallActionRequest(callId: callId, action: 'end', reason: reason);
  }

  Map<String, dynamic> toJson() {
    return {
      'call_id': callId,
      'action': action,
      if (reason != null && reason!.isNotEmpty) 'reason': reason,
    };
  }
}
