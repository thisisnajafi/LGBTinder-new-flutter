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
    return RegisterResponse(
      userId: json['user_id'] as int,
      email: json['email'] as String,
      onesignalPlayerId: json['onesignal_player_id'] as String?,
      emailSent: json['email_sent'] as bool? ?? false,
      resendAvailableAt: json['resend_available_at'] as String?,
      hourlyAttemptsRemaining: json['hourly_attempts_remaining'] as int?,
    );
  }
}

