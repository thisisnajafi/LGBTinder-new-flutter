import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/app_logger.dart';
import '../../../shared/models/api_error.dart';
import '../data/models/chat.dart';
import '../data/models/message.dart';
import '../data/models/message_attachment.dart';
import '../data/models/message_delivery_status.dart';
import '../utils/chat_client_id.dart';
import '../utils/chat_message_dedup.dart';
import '../utils/chat_outbox_ui.dart';
import '../data/local/chat_local_repository.dart';
import '../data/services/chat_outbound_queue_service.dart';
import '../domain/use_cases/get_chat_history_use_case.dart';
import '../domain/use_cases/send_message_use_case.dart';
import '../domain/use_cases/mark_as_read_use_case.dart';
import '../domain/use_cases/delete_message_use_case.dart';
import '../domain/use_cases/set_typing_use_case.dart';
import '../domain/use_cases/get_chats_use_case.dart';
import 'chat_outbox_ui_provider.dart';
import 'chat_providers.dart';
import 'chat_thread_providers.dart';

/// Chat provider - manages chat state and operations
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final getChatHistoryUseCase = ref.watch(getChatHistoryUseCaseProvider);
  final sendMessageUseCase = ref.watch(sendMessageUseCaseProvider);
  final markAsReadUseCase = ref.watch(markAsReadUseCaseProvider);
  final deleteMessageUseCase = ref.watch(deleteMessageUseCaseProvider);
  final setTypingUseCase = ref.watch(setTypingUseCaseProvider);
  final getChatsUseCase = ref.watch(getChatsUseCaseProvider);
  final outboundQueue = ref.watch(chatOutboundQueueServiceProvider);
  final localRepo = ref.watch(chatLocalRepositoryProvider);

  return ChatNotifier(
    ref: ref,
    getChatHistoryUseCase: getChatHistoryUseCase,
    sendMessageUseCase: sendMessageUseCase,
    markAsReadUseCase: markAsReadUseCase,
    deleteMessageUseCase: deleteMessageUseCase,
    setTypingUseCase: setTypingUseCase,
    getChatsUseCase: getChatsUseCase,
    outboundQueue: outboundQueue,
    localRepo: localRepo,
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
  final Ref _ref;
  final GetChatHistoryUseCase _getChatHistoryUseCase;
  final SendMessageUseCase _sendMessageUseCase;
  final MarkAsReadUseCase _markAsReadUseCase;
  final DeleteMessageUseCase _deleteMessageUseCase;
  final SetTypingUseCase _setTypingUseCase;
  final GetChatsUseCase _getChatsUseCase;
  final ChatOutboundQueueService _outboundQueue;
  final ChatLocalRepository _localRepo;
  bool _isFlushingQueue = false;

  ChatNotifier({
    required Ref ref,
    required GetChatHistoryUseCase getChatHistoryUseCase,
    required SendMessageUseCase sendMessageUseCase,
    required MarkAsReadUseCase markAsReadUseCase,
    required DeleteMessageUseCase deleteMessageUseCase,
    required SetTypingUseCase setTypingUseCase,
    required GetChatsUseCase getChatsUseCase,
    required ChatOutboundQueueService outboundQueue,
    required ChatLocalRepository localRepo,
  }) : _ref = ref,
       _getChatHistoryUseCase = getChatHistoryUseCase,
       _sendMessageUseCase = sendMessageUseCase,
       _markAsReadUseCase = markAsReadUseCase,
       _deleteMessageUseCase = deleteMessageUseCase,
       _setTypingUseCase = setTypingUseCase,
       _getChatsUseCase = getChatsUseCase,
       _outboundQueue = outboundQueue,
       _localRepo = localRepo,
       super(ChatState());

  /// Load chat list (cached first, then network refresh).
  Future<void> loadChats() async {
    try {
      final cached = await _localRepo.getConversations();
      if (cached.isNotEmpty) {
        state = state.copyWith(chats: cached, isLoading: false, error: null);
      } else {
        state = state.copyWith(isLoading: true, error: null);
      }
    } catch (e) {
      AppLogger.warning(
        'Failed to load cached conversations',
        tag: 'Chat',
        error: e,
      );
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final chats = await _getChatsUseCase.execute();
      await _localRepo.replaceAllConversations(chats);
      state = state.copyWith(chats: chats, isLoading: false);
    } catch (e) {
      AppLogger.warning(
        'Failed to refresh conversations',
        tag: 'Chat',
        error: e,
      );
      state = state.copyWith(
        isLoading: false,
        error: state.chats.isEmpty ? e.toString() : null,
      );
    }
  }

  /// Load chat history for a specific user (local DB first, then network).
  Future<void> loadChatHistory(int userId, {bool isRefresh = false}) async {
    if (state.isLoading && !isRefresh) return;
    if (!state.hasMoreMessages && !isRefresh) return;

    if (isRefresh || state.currentChatUserId != userId) {
      try {
        final cached = await _localRepo.getMessagesForOtherUser(userId);
        if (cached.isNotEmpty) {
          state = state.copyWith(
            currentMessages: cached,
            currentChatUserId: userId,
            isLoading: false,
            error: null,
          );
        } else {
          state = state.copyWith(
            currentChatUserId: userId,
            isLoading: true,
            error: null,
          );
        }
      } catch (e) {
        AppLogger.warning(
          'Failed to load cached chat history',
          tag: 'Chat',
          error: e,
        );
        state = state.copyWith(
          currentChatUserId: userId,
          isLoading: true,
          error: null,
        );
      }
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final messages = await _getChatHistoryUseCase.execute(
        userId,
        page: isRefresh ? 1 : state.currentPage,
        limit: 20,
      );

      await _localRepo.upsertMessages(messages, userId);

      state = state.copyWith(
        currentMessages: isRefresh ? messages : [...messages, ...state.currentMessages],
        currentChatUserId: userId,
        isLoading: false,
        hasMoreMessages: messages.length == 20,
        currentPage: isRefresh ? 2 : state.currentPage + 1,
      );

      if (state.currentChatUserId == userId) {
        await _markAsReadUseCase.execute(userId);
      }
    } catch (e) {
      AppLogger.warning(
        'Failed to refresh chat history',
        tag: 'Chat',
        error: e,
      );
      state = state.copyWith(
        isLoading: false,
        error: state.currentMessages.isEmpty ? e.toString() : null,
      );
    }
  }

  /// Send a message with optimistic UI (sending → sent | failed).
  Future<Message?> sendMessage(
    int receiverId,
    String message, {
    required int senderId,
    String messageType = 'text',
    MessageAttachment? attachment,
  }) async {
    final clientId = ChatClientIds.next();
    final optimistic = Message.optimistic(
      clientId: clientId,
      senderId: senderId,
      receiverId: receiverId,
      message: message,
      messageType: messageType,
    );

    state = state.copyWith(
      currentMessages: [optimistic, ...state.currentMessages],
      isSendingMessage: true,
      error: null,
    );
    unawaited(_localRepo.upsertMessage(optimistic, receiverId));

    try {
      final sentMessage = await _sendMessageUseCase.execute(
        receiverId,
        message,
        messageType: messageType,
        attachment: attachment,
        clientId: clientId,
      );

      await _outboundQueue.remove(clientId);

      final delivered = sentMessage.copyWith(
        deliveryStatus: MessageDeliveryStatus.sent,
        clientId: clientId,
      );
      unawaited(_localRepo.upsertMessage(delivered, receiverId));

      state = state.copyWith(
        currentMessages: _replaceByClientId(clientId, sentMessage),
        isSendingMessage: false,
      );

      return sentMessage;
    } catch (e) {
      if (_shouldQueueForOffline(e)) {
        final queuedAt = DateTime.now();
        await _outboundQueue.enqueue(
          QueuedChatMessage(
            clientId: clientId,
            receiverId: receiverId,
            senderId: senderId,
            message: message,
            messageType: messageType,
            createdAt: queuedAt,
          ),
        );
        unawaited(
          _localRepo.upsertMessage(
            Message(
              id: 0,
              senderId: senderId,
              receiverId: receiverId,
              message: message,
              messageType: messageType,
              createdAt: queuedAt,
              clientId: clientId,
              deliveryStatus: MessageDeliveryStatus.queued,
            ),
            receiverId,
          ),
        );
        _ref.read(chatOutboxUiProvider.notifier).addReceiver(receiverId);

        state = state.copyWith(
          currentMessages: _markQueued(clientId),
          isSendingMessage: false,
          error: null,
        );
        return null;
      }

      state = state.copyWith(
        currentMessages: _markFailed(clientId),
        isSendingMessage: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Send queued messages FIFO when connectivity returns (CHAT-OFFLINE-001).
  Future<void> flushOutboundQueue() async {
    if (_isFlushingQueue) return;

    final pending = await _outboundQueue.getPending();
    if (pending.isEmpty) {
      _ref.read(chatOutboxUiProvider.notifier).sync(const [], flushing: false);
      return;
    }

    _isFlushingQueue = true;
    _ref.read(chatOutboxUiProvider.notifier).sync(pending, flushing: true);
    AppLogger.info(
      'Flushing ${pending.length} queued chat message(s)',
      tag: ChatOutboundQueueService.logTag,
    );
    try {
      for (final queued in pending) {
        final index = state.currentMessages.indexWhere(
          (m) => m.clientId == queued.clientId,
        );
        if (index >= 0) {
          state = state.copyWith(
            currentMessages: _replaceAt(
              index,
              state.currentMessages[index].copyWith(
                deliveryStatus: MessageDeliveryStatus.sending,
              ),
            ),
          );
        }
        _patchThreadStatus(
          queued.receiverId,
          queued.clientId,
          MessageDeliveryStatus.sending,
        );

        try {
          final sentMessage = await _sendMessageUseCase.execute(
            queued.receiverId,
            queued.message,
            messageType: queued.messageType,
            clientId: queued.clientId,
          );
          await _outboundQueue.remove(queued.clientId);
          final delivered = sentMessage.copyWith(
            deliveryStatus: MessageDeliveryStatus.sent,
            clientId: queued.clientId,
          );
          unawaited(
            _localRepo.upsertMessage(delivered, queued.receiverId),
          );
          state = state.copyWith(
            currentMessages: _replaceByClientId(queued.clientId, sentMessage),
          );
          _patchThreadSent(queued.receiverId, queued.clientId, delivered);
        } catch (e) {
          AppLogger.warning(
            'Outbound queue flush failed for ${queued.clientId}',
            tag: 'Chat',
            error: e,
          );
          if (_shouldQueueForOffline(e)) {
            _patchThreadStatus(
              queued.receiverId,
              queued.clientId,
              MessageDeliveryStatus.queued,
            );
            break;
          }
          state = state.copyWith(
            currentMessages: _markFailed(queued.clientId),
          );
          _patchThreadStatus(
            queued.receiverId,
            queued.clientId,
            MessageDeliveryStatus.failed,
          );
          await _outboundQueue.remove(queued.clientId);
        }
      }
    } finally {
      _isFlushingQueue = false;
      final remaining = await _outboundQueue.getPending();
      _ref.read(chatOutboxUiProvider.notifier).sync(
            remaining,
            flushing: false,
          );
    }
  }

  void _patchThreadStatus(
    int receiverId,
    String clientId,
    MessageDeliveryStatus status,
  ) {
    final family = chatThreadMessagesProvider(receiverId);
    if (!_ref.exists(family)) return;
    _ref.read(family.notifier).mapRows(
          (row) => ChatOutboxUi.markStatus(row, clientId, status),
        );
  }

  void _patchThreadSent(int receiverId, String clientId, Message sent) {
    final family = chatThreadMessagesProvider(receiverId);
    if (!_ref.exists(family)) return;
    _ref.read(family.notifier).mapRows(
          (row) => ChatOutboxUi.applySent(row, clientId, sent),
        );
  }

  bool _shouldQueueForOffline(Object error) {
    if (error is ApiError) {
      if (error.code == 0) return true;
      final message = error.message.toLowerCase();
      return message.contains('internet') ||
          message.contains('connection') ||
          message.contains('queued');
    }
    final text = error.toString().toLowerCase();
    return text.contains('socket') ||
        text.contains('connection') ||
        text.contains('network');
  }

  /// Retry a failed optimistic message.
  Future<Message?> retryMessage(String clientId) async {
    final index = state.currentMessages.indexWhere((m) => m.clientId == clientId);
    if (index < 0) return null;

    final failed = state.currentMessages[index];
    if (failed.deliveryStatus != MessageDeliveryStatus.failed) return null;

    state = state.copyWith(
      currentMessages: _replaceAt(
        index,
        failed.copyWith(deliveryStatus: MessageDeliveryStatus.sending),
      ),
      error: null,
    );

    try {
      final sentMessage = await _sendMessageUseCase.execute(
        failed.receiverId,
        failed.message,
        messageType: failed.messageType,
        clientId: clientId,
      );
      await _outboundQueue.remove(clientId);
      state = state.copyWith(
        currentMessages: _replaceByClientId(clientId, sentMessage),
      );
      return sentMessage;
    } catch (e) {
      if (_shouldQueueForOffline(e)) {
        final queuedAt = DateTime.now();
        await _outboundQueue.enqueue(
          QueuedChatMessage(
            clientId: clientId,
            receiverId: failed.receiverId,
            senderId: failed.senderId,
            message: failed.message,
            messageType: failed.messageType,
            createdAt: queuedAt,
          ),
        );
        _ref.read(chatOutboxUiProvider.notifier).addReceiver(failed.receiverId);
        state = state.copyWith(
          currentMessages: _markQueued(clientId),
          error: null,
        );
        return null;
      }
      state = state.copyWith(
        currentMessages: _markFailed(clientId),
        error: e.toString(),
      );
      return null;
    }
  }

  List<Message> _replaceByClientId(String clientId, Message serverMessage) {
    return state.currentMessages
        .map((m) => m.clientId == clientId
            ? serverMessage.copyWith(
                deliveryStatus: MessageDeliveryStatus.sent,
                clientId: clientId,
              )
            : m)
        .toList();
  }

  List<Message> _markFailed(String clientId) {
    return state.currentMessages
        .map((m) => m.clientId == clientId
            ? m.copyWith(deliveryStatus: MessageDeliveryStatus.failed)
            : m)
        .toList();
  }

  List<Message> _markQueued(String clientId) {
    return state.currentMessages
        .map((m) => m.clientId == clientId
            ? m.copyWith(deliveryStatus: MessageDeliveryStatus.queued)
            : m)
        .toList();
  }

  List<Message> _replaceAt(int index, Message message) {
    final updated = [...state.currentMessages];
    updated[index] = message;
    return updated;
  }

  /// Delete a message
  Future<void> deleteMessage(int messageId) async {
    try {
      await _deleteMessageUseCase.execute(messageId);

      // Remove message from current messages
      final updatedMessages = state.currentMessages.where((msg) => msg.id != messageId).toList();
      state = state.copyWith(currentMessages: updatedMessages);
    } catch (e) {
      AppLogger.warning(
        'Failed to delete message $messageId',
        tag: 'Chat',
        error: e,
      );
      state = state.copyWith(error: e.toString());
    }
  }

  /// Set typing status
  Future<void> setTyping(int userId, bool isTyping) async {
    try {
      await _setTypingUseCase.execute(userId, isTyping);
      state = state.copyWith(isTyping: isTyping);
    } catch (e) {
      AppLogger.warning(
        'Typing status update failed',
        tag: 'Chat',
        error: e,
      );
      // Don't set error for typing status
      state = state.copyWith(error: null);
    }
  }

  /// Update typing status for a user (from Pusher UserTyping / UserStoppedTyping).
  void updateUserTyping(int userId, bool isTyping) {
    final updatedTypingUsers = Map<int, bool>.from(state.typingUsers);
    if (isTyping) {
      updatedTypingUsers[userId] = true;
    } else {
      updatedTypingUsers.remove(userId);
    }
    state = state.copyWith(typingUsers: updatedTypingUsers);
  }

  /// Add received message: update in place by id, else replace by `client_id`.
  void addReceivedMessage(Message message) {
    final upsert = ChatMessageDedup.upsertMessage(
      state.currentMessages,
      message,
    );

    final peerId = state.currentChatUserId;
    if (peerId != null && peerId > 0) {
      unawaited(_localRepo.upsertMessage(message, peerId));
    }

    if (!upsert.insertedNew) {
      state = state.copyWith(currentMessages: upsert.messages);
      return;
    }

    if (state.currentChatUserId != message.senderId) {
      final updatedUnreadCounts = Map<int, int>.from(state.unreadCounts);
      updatedUnreadCounts[message.senderId] =
          (updatedUnreadCounts[message.senderId] ?? 0) + 1;
      state = state.copyWith(
        currentMessages: upsert.messages,
        unreadCounts: updatedUnreadCounts,
      );
    } else {
      state = state.copyWith(currentMessages: upsert.messages);
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

