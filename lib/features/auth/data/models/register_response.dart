/// Register response model
class RegisterResponse {
  final int userId;
  final String email;
  final String? onesignalPlayerId;
  final bool emailSent;
  final String? resendAvailableAt;
  final int? hourlyAttemptsRemaining;

  RegisterResponse({
    required this.userId,
    required this.email,
    this.onesignalPlayerId,
    required this.emailSent,
    this.resendAvailableAt,
    this.hourlyAttemptsRemaining,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    if (json['user_id'] == null) {
      throw FormatException('RegisterResponse.fromJson: user_id is required but was null');
    }
    if (json['email'] == null) {
      throw FormatException('RegisterResponse.fromJson: email is required but was null');
    }
    
    return RegisterResponse(
      userId: (json['user_id'] is int) ? json['user_id'] as int : int.parse(json['user_id'].toString()),
      email: json['email'].toString(),
      onesignalPlayerId: json['onesignal_player_id']?.toString(),
      emailSent: json['email_sent'] == true || json['email_sent'] == 1,
      resendAvailableAt: json['resend_available_at']?.toString(),
      hourlyAttemptsRemaining: json['hourly_attempts_remaining'] != null ? ((json['hourly_attempts_remaining'] is int) ? json['hourly_attempts_remaining'] as int : int.tryParse(json['hourly_attempts_remaining'].toString())) : null,
    );
  }
}

