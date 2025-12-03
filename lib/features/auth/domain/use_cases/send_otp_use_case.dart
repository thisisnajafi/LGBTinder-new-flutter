import '../../data/repositories/auth_repository.dart';
import '../../data/models/send_otp_request.dart';
import '../../data/models/otp_response.dart';

/// Use Case: SendOtpUseCase
/// Handles sending OTP for password reset
class SendOtpUseCase {
  final AuthRepository _authRepository;

  SendOtpUseCase(this._authRepository);

  /// Execute send OTP use case
  /// Returns [OtpResponse] with success status and message
  Future<OtpResponse> execute(SendOtpRequest request) async {
    try {
      return await _authRepository.sendOtp(request);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
