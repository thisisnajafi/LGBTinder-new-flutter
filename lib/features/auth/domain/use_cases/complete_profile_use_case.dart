import '../../data/repositories/auth_repository.dart';
import '../../data/models/complete_registration_request.dart';
import '../../data/models/complete_registration_response.dart';

/// Use Case: CompleteProfileUseCase
/// Handles profile completion during registration
class CompleteProfileUseCase {
  final AuthRepository _authRepository;

  CompleteProfileUseCase(this._authRepository);

  /// Execute complete profile use case
  /// Returns [CompleteRegistrationResponse] with completed user profile
  Future<CompleteRegistrationResponse> execute(CompleteRegistrationRequest request) async {
    try {
      return await _authRepository.completeRegistration(request);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
