import '../../data/repositories/auth_repository.dart';

/// Use Case: LogoutUseCase
/// Handles user logout by clearing tokens and session data
class LogoutUseCase {
  final AuthRepository _authRepository;

  LogoutUseCase(this._authRepository);

  /// Execute logout use case.
  /// Prefer [AuthProvider.logout] from UI — it is optimistic and single-pathed.
  /// This use case only performs the best-effort remote revoke.
  Future<void> execute({String? bearerToken, String? deviceToken}) async {
    try {
      await _authRepository.logout(
        bearerToken: bearerToken,
        deviceToken: deviceToken,
      );
    } catch (e) {
      // Background / non-UI callers: surface errors to the caller.
      rethrow;
    }
  }
}
