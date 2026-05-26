import '../services/chat_service.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/message_attachment.dart';

/// Chat repository - wraps ChatService for use in use cases
class ChatRepository {
  final ChatService _chatService;

  ChatRepository(this._chatService);

  /// Get all chats for current user
  Future<List<Chat>> getChats() async {
    return await _chatService.getChats();
  }

  /// Get chat history with a specific user
  Future<List<Message>> getChatHistory(int userId, {
    int? page,
    int? limit,
  }) async {
    final result = await _chatService.getChatHistory(
      receiverId: userId,
      page: page,
      limit: limit,
    );
    return result.messages;
  }

  /// Chat history including `conversation_id` for Pusher subscription.
  Future<ChatHistoryResult> getChatHistoryWithMeta(int userId, {
    int? page,
    int? limit,
  }) async {
    return _chatService.getChatHistory(
      receiverId: userId,
      page: page,
      limit: limit,
    );
  }

  /// Send a message
  Future<Message> sendMessage(int receiverId, String message, {
    String messageType = 'text',
    MessageAttachment? attachment,
  }) async {
    return await _chatService.sendMessage(
      receiverId,
      message,
      messageType: messageType,
      attachment: attachment,
    );
  }

  /// Mark messages as read
  Future<void> markAsRead(int userId) async {
    return await _chatService.markAsRead(userId);
  }

  /// Delete a message
  Future<void> deleteMessage(int messageId) async {
    return await _chatService.deleteMessage(messageId);
  }

  /// Set typing status
  Future<void> setTyping(int userId, bool isTyping) async {
    return _chatService.setTypingStatus(userId, isTyping);
  }

  Future<void> setConversationTyping(int conversationId, bool isTyping) async {
    return _chatService.setConversationTyping(conversationId, isTyping);
  }

  /// Get unread message count
  Future<int> getUnreadCount() async {
    return await _chatService.getUnreadCount();
  }

  /// Upload attachment
  Future<MessageAttachment> uploadAttachment(String filePath, String filename) async {
    return await _chatService.uploadAttachment(filePath, filename);
  }

  /// Set online status
  Future<void> setOnlineStatus(bool isOnline) async {
    return await _chatService.setOnlineStatus(isOnline);
  }
}
