import '../../data/repositories/chat_repository.dart';
import '../../data/models/message.dart';
import '../../data/models/message_attachment.dart';

/// Use Case: SendMessageUseCase
/// Handles sending messages with optional attachments
class SendMessageUseCase {
  final ChatRepository _chatRepository;

  SendMessageUseCase(this._chatRepository);

  /// Execute send message use case
  /// Returns [Message] with the sent message details
  Future<Message> execute(int receiverId, String message, {
    String messageType = 'text',
    MessageAttachment? attachment,
  }) async {
    try {
      return await _chatRepository.sendMessage(
        receiverId,
        message,
        messageType: messageType,
        attachment: attachment,
      );
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
