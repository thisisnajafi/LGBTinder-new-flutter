import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/chat.dart';
import '../data/models/message.dart';
import '../data/models/message_attachment.dart';
import '../domain/use_cases/get_chat_history_use_case.dart';
import '../domain/use_cases/send_message_use_case.dart';
import '../domain/use_cases/mark_as_read_use_case.dart';
import '../domain/use_cases/delete_message_use_case.dart';
import '../domain/use_cases/set_typing_use_case.dart';

/// Chat provider - manages chat state and operations
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final getChatHistoryUseCase = ref.watch(getChatHistoryUseCaseProvider);
  final sendMessageUseCase = ref.watch(sendMessageUseCaseProvider);
  final markAsReadUseCase = ref.watch(markAsReadUseCaseProvider);
  final deleteMessageUseCase = ref.watch(deleteMessageUseCaseProvider);
  final setTypingUseCase = ref.watch(setTypingUseCaseProvider);

  return ChatNotifier(
    getChatHistoryUseCase: getChatHistoryUseCase,
    sendMessageUseCase: sendMessageUseCase,
    markAsReadUseCase: markAsReadUseCase,
    deleteMessageUseCase: deleteMessageUseCase,
    setTypingUseCase: setTypingUseCase,
  );
});

/// Chat state
class ChatState {
  final List<Chat> chats;
  final List<Message> currentMessages;
  final int? currentChatUserId;
  final bool isLoading;
  final bool isSendingMessage;
  final bool isTyping;
  final String? error;
  final bool hasMoreMessages;
  final int currentPage;
  final Map<int, bool> typingUsers; // userId -> isTyping
  final Map<int, int> unreadCounts; // chatId -> unreadCount

  ChatState({
    this.chats = const [],
    this.currentMessages = const [],
    this.currentChatUserId,
    this.isLoading = false,
    this.isSendingMessage = false,
    this.isTyping = false,
    this.error,
    this.hasMoreMessages = true,
    this.currentPage = 1,
    this.typingUsers = const {},
    this.unreadCounts = const {},
  });

  ChatState copyWith({
    List<Chat>? chats,
    List<Message>? currentMessages,
    int? currentChatUserId,
    bool? isLoading,
    bool? isSendingMessage,
    bool? isTyping,
    String? error,
    bool? hasMoreMessages,
    int? currentPage,
    Map<int, bool>? typingUsers,
    Map<int, int>? unreadCounts,
  }) {
    return ChatState(
      chats: chats ?? this.chats,
      currentMessages: currentMessages ?? this.currentMessages,
      currentChatUserId: currentChatUserId ?? this.currentChatUserId,
      isLoading: isLoading ?? this.isLoading,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
      isTyping: isTyping ?? this.isTyping,
      error: error ?? this.error,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      currentPage: currentPage ?? this.currentPage,
      typingUsers: typingUsers ?? this.typingUsers,
      unreadCounts: unreadCounts ?? this.unreadCounts,
    );
  }
}

/// Chat notifier
class ChatNotifier extends StateNotifier<ChatState> {
  final GetChatHistoryUseCase _getChatHistoryUseCase;
  final SendMessageUseCase _sendMessageUseCase;
  final MarkAsReadUseCase _markAsReadUseCase;
  final DeleteMessageUseCase _deleteMessageUseCase;
  final SetTypingUseCase _setTypingUseCase;

  ChatNotifier({
    required GetChatHistoryUseCase getChatHistoryUseCase,
    required SendMessageUseCase sendMessageUseCase,
    required MarkAsReadUseCase markAsReadUseCase,
    required DeleteMessageUseCase deleteMessageUseCase,
    required SetTypingUseCase setTypingUseCase,
  }) : _getChatHistoryUseCase = getChatHistoryUseCase,
       _sendMessageUseCase = sendMessageUseCase,
       _markAsReadUseCase = markAsReadUseCase,
       _deleteMessageUseCase = deleteMessageUseCase,
       _setTypingUseCase = setTypingUseCase,
       super(ChatState());

  /// Load chat list
  Future<void> loadChats() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // TODO: Implement get chats use case
      // final chats = await _getChatsUseCase.execute();
      // state = state.copyWith(chats: chats, isLoading: false);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load chat history for a specific user
  Future<void> loadChatHistory(int userId, {bool isRefresh = false}) async {
    if (state.isLoading && !isRefresh) return;
    if (!state.hasMoreMessages && !isRefresh) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final messages = await _getChatHistoryUseCase.execute(
        userId,
        page: isRefresh ? 1 : state.currentPage,
        limit: 20,
      );

      state = state.copyWith(
        currentMessages: isRefresh ? messages : [...messages, ...state.currentMessages],
        currentChatUserId: userId,
        isLoading: false,
        hasMoreMessages: messages.length == 20,
        currentPage: isRefresh ? 2 : state.currentPage + 1,
      );

      // Mark messages as read if this is the current chat
      if (state.currentChatUserId == userId) {
        await _markAsReadUseCase.execute(userId);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Send a message
  Future<Message?> sendMessage(int receiverId, String message, {
    String messageType = 'text',
    MessageAttachment? attachment,
  }) async {
    state = state.copyWith(isSendingMessage: true, error: null);

    try {
      final sentMessage = await _sendMessageUseCase.execute(
        receiverId,
        message,
        messageType: messageType,
        attachment: attachment,
      );

      // Add message to current messages
      final updatedMessages = [sentMessage, ...state.currentMessages];
      state = state.copyWith(
        currentMessages: updatedMessages,
        isSendingMessage: false,
      );

      return sentMessage;
    } catch (e) {
      state = state.copyWith(
        isSendingMessage: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Delete a message
  Future<void> deleteMessage(int messageId) async {
    try {
      await _deleteMessageUseCase.execute(messageId);

      // Remove message from current messages
      final updatedMessages = state.currentMessages.where((msg) => msg.id != messageId).toList();
      state = state.copyWith(currentMessages: updatedMessages);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Set typing status
  Future<void> setTyping(int userId, bool isTyping) async {
    try {
      await _setTypingUseCase.execute(userId, isTyping);
      state = state.copyWith(isTyping: isTyping);
    } catch (e) {
      // Don't set error for typing status
      state = state.copyWith(error: null);
    }
  }

  /// Update typing status for a user (received from websocket)
  void updateUserTyping(int userId, bool isTyping) {
    final updatedTypingUsers = Map<int, bool>.from(state.typingUsers);
    if (isTyping) {
      updatedTypingUsers[userId] = true;
    } else {
      updatedTypingUsers.remove(userId);
    }
    state = state.copyWith(typingUsers: updatedTypingUsers);
  }

  /// Add received message
  void addReceivedMessage(Message message) {
    final updatedMessages = [message, ...state.currentMessages];

    // Update unread count if message is not from current chat
    if (state.currentChatUserId != message.senderId) {
      final updatedUnreadCounts = Map<int, int>.from(state.unreadCounts);
      updatedUnreadCounts[message.senderId] = (updatedUnreadCounts[message.senderId] ?? 0) + 1;
      state = state.copyWith(
        currentMessages: updatedMessages,
        unreadCounts: updatedUnreadCounts,
      );
    } else {
      state = state.copyWith(currentMessages: updatedMessages);
    }
  }

  /// Mark chat as read
  void markChatAsRead(int userId) {
    final updatedUnreadCounts = Map<int, int>.from(state.unreadCounts);
    updatedUnreadCounts[userId] = 0;
    state = state.copyWith(unreadCounts: updatedUnreadCounts);
  }

  /// Clear current chat
  void clearCurrentChat() {
    state = state.copyWith(
      currentMessages: [],
      currentChatUserId: null,
      currentPage: 1,
      hasMoreMessages: true,
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset chat state
  void reset() {
    state = ChatState();
  }
}

// Use case providers
final getChatHistoryUseCaseProvider = Provider<GetChatHistoryUseCase>((ref) {
  throw UnimplementedError('GetChatHistoryUseCase must be overridden in the provider scope');
});

final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  throw UnimplementedError('SendMessageUseCase must be overridden in the provider scope');
});

final markAsReadUseCaseProvider = Provider<MarkAsReadUseCase>((ref) {
  throw UnimplementedError('MarkAsReadUseCase must be overridden in the provider scope');
});

final deleteMessageUseCaseProvider = Provider<DeleteMessageUseCase>((ref) {
  throw UnimplementedError('DeleteMessageUseCase must be overridden in the provider scope');
});

final setTypingUseCaseProvider = Provider<SetTypingUseCase>((ref) {
  throw UnimplementedError('SetTypingUseCase must be overridden in the provider scope');
});
