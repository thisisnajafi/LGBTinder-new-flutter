// Repository: AuthRepository
import '../models/models.dart';
import '../models/send_otp_request.dart';
import '../models/verify_otp_request.dart';
import '../models/otp_response.dart';
import '../models/reset_password_request.dart';
import '../models/social_auth_request.dart';
import '../models/social_auth_response.dart';
import '../services/auth_service.dart';

/// Auth repository - wraps AuthService for use in use cases
class AuthRepository {
  final AuthService _authService;

  AuthRepository(this._authService);

  /// Register a new user
  Future<RegisterResponse> register(RegisterRequest request) async {
    return await _authService.register(request);
  }

  /// Login with email and password
  Future<LoginResponse> login(LoginRequest request) async {
    return await _authService.login(request);
  }

  /// Check user state
  Future<UserStateResponse> checkUserState(String email) async {
    return await _authService.checkUserState(email);
  }

  /// Verify email with code
  Future<VerifyEmailResponse> verifyEmail(VerifyEmailRequest request) async {
    return await _authService.verifyEmail(request);
  }

  /// Complete profile registration
  Future<CompleteRegistrationResponse> completeRegistration(
    CompleteRegistrationRequest request,
  ) async {
    return await _authService.completeRegistration(request);
  }

  /// Logout
  Future<void> logout() async {
    return await _authService.logout();
  }

  /// Send OTP for password reset
  Future<OtpResponse> sendOtp(SendOtpRequest request) async {
    return await _authService.sendOtp(request);
  }

  /// Verify OTP for password reset
  Future<OtpResponse> verifyOtp(VerifyOtpRequest request) async {
    return await _authService.verifyOtp(request);
  }

  /// Reset password with verified OTP
  Future<OtpResponse> resetPassword(ResetPasswordRequest request) async {
    return await _authService.resetPassword(request);
  }

  /// Handle social authentication callback
  Future<SocialAuthResponse> handleSocialCallback(SocialAuthRequest request) async {
    return await _authService.handleSocialCallback(request);
  }

  /// Check if authenticated
  Future<bool> isAuthenticated() async {
    return await _authService.isAuthenticated();
  }
}
