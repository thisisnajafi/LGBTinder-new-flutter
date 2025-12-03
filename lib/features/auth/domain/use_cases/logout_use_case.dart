import '../../data/repositories/auth_repository.dart';

/// Use Case: LogoutUseCase
/// Handles user logout by clearing tokens and session data
class LogoutUseCase {
  final AuthRepository _authRepository;

  LogoutUseCase(this._authRepository);

  /// Execute logout use case
  /// Clears all stored tokens and session data
  Future<void> execute() async {
    try {
      await _authRepository.logout();
    } catch (e) {
      // Re-throw exceptions to let UI handle logout failures
      rethrow;
    }
  }
}
