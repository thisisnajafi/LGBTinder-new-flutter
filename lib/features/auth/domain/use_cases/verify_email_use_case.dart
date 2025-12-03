import '../../data/repositories/auth_repository.dart';
import '../../data/models/verify_email_request.dart';
import '../../data/models/verify_email_response.dart';

/// Use Case: VerifyEmailUseCase
/// Handles email verification with 6-digit code
class VerifyEmailUseCase {
  final AuthRepository _authRepository;

  VerifyEmailUseCase(this._authRepository);

  /// Execute verify email use case
  /// Returns [VerifyEmailResponse] with verification status and user details
  Future<VerifyEmailResponse> execute(VerifyEmailRequest request) async {
    try {
      return await _authRepository.verifyEmail(request);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
