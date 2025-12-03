/// Initiate call request model
class InitiateCallRequest {
  final int receiverId;
  final String callType; // 'video' or 'voice'

  InitiateCallRequest({
    required this.receiverId,
    required this.callType,
  });

  Map<String, dynamic> toJson() {
    return {
      'receiver_id': receiverId,
      'call_type': callType,
    };
  }
}
