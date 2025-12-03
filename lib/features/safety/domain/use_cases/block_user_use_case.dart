import '../../data/repositories/safety_repository.dart';
import '../../data/models/block.dart';

/// Use Case: BlockUserUseCase
/// Handles blocking users for safety and privacy
class BlockUserUseCase {
  final SafetyRepository _safetyRepository;

  BlockUserUseCase(this._safetyRepository);

  /// Execute block user use case
  /// Returns [BlockedUser] with block details
  Future<BlockedUser> execute(BlockUserRequest request) async {
    try {
      return await _safetyRepository.blockUser(request);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
