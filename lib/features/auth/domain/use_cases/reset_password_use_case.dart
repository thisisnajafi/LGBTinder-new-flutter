import '../../data/repositories/auth_repository.dart';
import '../../data/models/reset_password_request.dart';
import '../../data/models/otp_response.dart';

/// Use Case: ResetPasswordUseCase
/// Handles password reset with verified OTP
class ResetPasswordUseCase {
  final AuthRepository _authRepository;

  ResetPasswordUseCase(this._authRepository);

  /// Execute reset password use case
  /// Returns [OtpResponse] with reset status
  Future<OtpResponse> execute(ResetPasswordRequest request) async {
    try {
      return await _authRepository.resetPassword(request);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
