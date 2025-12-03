import '../../data/repositories/safety_repository.dart';

/// Use case for getting blocked users
class GetBlockedUsersUseCase {
  final SafetyRepository _repository;

  GetBlockedUsersUseCase(this._repository);

  /// Execute get blocked users use case
  Future<List<BlockedUser>> execute() async {
    try {
      return await _repository.getBlockedUsers();
    } catch (e) {
      rethrow;
    }
  }
}
