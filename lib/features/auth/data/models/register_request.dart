/// Register request model
class RegisterRequest {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String passwordConfirmation;

  RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
  });

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    };
  }
}
