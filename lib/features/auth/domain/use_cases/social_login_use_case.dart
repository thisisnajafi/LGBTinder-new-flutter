import '../../data/repositories/auth_repository.dart';
import '../../data/models/social_auth_request.dart';
import '../../data/models/social_auth_response.dart';

/// Use Case: SocialLoginUseCase
/// Handles social authentication (Google OAuth)
class SocialLoginUseCase {
  final AuthRepository _authRepository;

  SocialLoginUseCase(this._authRepository);

  /// Execute social login use case
  /// Returns [SocialAuthResponse] with authentication status
  Future<SocialAuthResponse> execute(SocialAuthRequest request) async {
    try {
      return await _authRepository.handleSocialCallback(request);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
