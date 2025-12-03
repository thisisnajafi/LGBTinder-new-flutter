import '../../data/repositories/chat_repository.dart';

/// Use Case: DeleteMessageUseCase
/// Handles deleting messages
class DeleteMessageUseCase {
  final ChatRepository _chatRepository;

  DeleteMessageUseCase(this._chatRepository);

  /// Execute delete message use case
  /// Returns void on successful deletion
  Future<void> execute(int messageId) async {
    try {
      return await _chatRepository.deleteMessage(messageId);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
