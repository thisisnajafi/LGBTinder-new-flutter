/// Exception thrown when email verification is required
class EmailVerificationRequiredException implements Exception {
  final String email;
  final String message;

  EmailVerificationRequiredException({
    required this.email,
    this.message = 'Email verification required',
  });

  @override
  String toString() => message;
}

