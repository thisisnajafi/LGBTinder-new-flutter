/// Send OTP request model
class SendOtpRequest {
  final String email;

  SendOtpRequest({
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }
}
