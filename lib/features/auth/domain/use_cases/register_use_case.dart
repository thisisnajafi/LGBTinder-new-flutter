import '../../data/repositories/auth_repository.dart';
import '../../data/models/register_request.dart';
import '../../data/models/register_response.dart';

/// Use Case: RegisterUseCase
/// Handles user registration with email verification
class RegisterUseCase {
  final AuthRepository _authRepository;

  RegisterUseCase(this._authRepository);

  /// Execute register use case
  /// Returns [RegisterResponse] with user details and verification status
  Future<RegisterResponse> execute(RegisterRequest request) async {
    try {
      return await _authRepository.register(request);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
