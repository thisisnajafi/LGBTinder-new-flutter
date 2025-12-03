import '../../data/repositories/auth_repository.dart';
import '../../data/models/verify_otp_request.dart';
import '../../data/models/otp_response.dart';

/// Use Case: VerifyOtpUseCase
/// Handles OTP verification for password reset
class VerifyOtpUseCase {
  final AuthRepository _authRepository;

  VerifyOtpUseCase(this._authRepository);

  /// Execute verify OTP use case
  /// Returns [OtpResponse] with verification status
  Future<OtpResponse> execute(VerifyOtpRequest request) async {
    try {
      return await _authRepository.verifyOtp(request);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
