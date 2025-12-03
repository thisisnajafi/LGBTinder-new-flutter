/// Initiate call response model
class InitiateCallResponse {
  final int callId;
  final String status;
  final String? token;
  final String? channelName;
  final Map<String, dynamic>? metadata;

  InitiateCallResponse({
    required this.callId,
    required this.status,
    this.token,
    this.channelName,
    this.metadata,
  });

  factory InitiateCallResponse.fromJson(Map<String, dynamic> json) {
    return InitiateCallResponse(
      callId: json['call_id'] as int,
      status: json['status'] as String,
      token: json['token'] as String?,
      channelName: json['channel_name'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}
