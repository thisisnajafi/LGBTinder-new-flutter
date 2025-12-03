import '../../data/repositories/chat_repository.dart';
import '../../data/models/message.dart';

/// Use Case: GetChatHistoryUseCase
/// Handles retrieving chat history with a specific user
class GetChatHistoryUseCase {
  final ChatRepository _chatRepository;

  GetChatHistoryUseCase(this._chatRepository);

  /// Execute get chat history use case
  /// Returns [List<Message>] with chat messages
  Future<List<Message>> execute(int userId, {
    int? page,
    int? limit,
  }) async {
    try {
      return await _chatRepository.getChatHistory(
        userId,
        page: page,
        limit: limit,
      );
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
