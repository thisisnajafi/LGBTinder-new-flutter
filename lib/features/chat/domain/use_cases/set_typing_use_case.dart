import '../../data/repositories/chat_repository.dart';

/// Use Case: SetTypingUseCase
/// Handles setting typing status in chat
class SetTypingUseCase {
  final ChatRepository _chatRepository;

  SetTypingUseCase(this._chatRepository);

  /// Execute set typing use case
  /// Returns void on successful status update
  Future<void> execute(int userId, bool isTyping) async {
    try {
      return await _chatRepository.setTyping(userId, isTyping);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> executeForConversation(int conversationId, bool isTyping) async {
    try {
      return await _chatRepository.setConversationTyping(conversationId, isTyping);
    } catch (e) {
      rethrow;
    }
  }
}
