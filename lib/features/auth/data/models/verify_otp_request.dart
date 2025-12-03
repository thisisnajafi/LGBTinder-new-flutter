/// Verify OTP request model
class VerifyOtpRequest {
  final String email;
  final String code;

  VerifyOtpRequest({
    required this.email,
    required this.code,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'code': code,
    };
  }
}
