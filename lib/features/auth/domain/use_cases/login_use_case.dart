import '../../data/repositories/auth_repository.dart';
import '../../data/models/login_request.dart';
import '../../data/models/login_response.dart';
import '../../data/models/email_verification_required_exception.dart';

/// Use Case: LoginUseCase
/// Handles user login with email and password
class LoginUseCase {
  final AuthRepository _authRepository;

  LoginUseCase(this._authRepository);

  /// Execute login use case
  /// Throws [EmailVerificationRequiredException] if email verification is needed
  /// Returns [LoginResponse] on successful login or profile completion required
  Future<LoginResponse> execute(LoginRequest request) async {
    try {
      return await _authRepository.login(request);
    } catch (e) {
      // Re-throw EmailVerificationRequiredException to let UI handle it
      if (e is EmailVerificationRequiredException) {
        rethrow;
      }
      // Re-throw other exceptions as well
      rethrow;
    }
  }
}
