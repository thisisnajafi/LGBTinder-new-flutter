import '../../data/repositories/chat_repository.dart';

/// Use Case: MarkAsReadUseCase
/// Handles marking messages as read
class MarkAsReadUseCase {
  final ChatRepository _chatRepository;

  MarkAsReadUseCase(this._chatRepository);

  /// Execute mark as read use case
  /// Returns void on successful marking
  Future<void> execute(int userId) async {
    try {
      return await _chatRepository.markAsRead(userId);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
