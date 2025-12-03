import '../../data/repositories/safety_repository.dart';

/// Use Case: UnblockUserUseCase
/// Handles unblocking previously blocked users
class UnblockUserUseCase {
  final SafetyRepository _safetyRepository;

  UnblockUserUseCase(this._safetyRepository);

  /// Execute unblock user use case
  /// Returns void on successful unblock
  Future<void> execute(int blockedUserId) async {
    try {
      return await _safetyRepository.unblockUser(blockedUserId);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
