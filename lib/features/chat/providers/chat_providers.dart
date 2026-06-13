import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_providers.dart';
export '../data/local/chat_database_provider.dart';
import '../data/local/chat_database_provider.dart';
import '../data/repositories/chat_repository.dart';
import '../data/services/chat_service.dart';
import '../data/services/websocket_service.dart';
import '../data/services/chat_outbound_queue_service.dart';
import '../domain/use_cases/delete_message_use_case.dart';
import '../domain/use_cases/get_chat_history_use_case.dart';
import '../domain/use_cases/get_chats_use_case.dart';
import '../domain/use_cases/mark_as_read_use_case.dart';
import '../domain/use_cases/send_message_use_case.dart';
import '../domain/use_cases/set_typing_use_case.dart';

/// Chat outbound queue (text messages pending send while offline)
final chatOutboundQueueServiceProvider = Provider<ChatOutboundQueueService>((ref) {
  return ChatOutboundQueueService(ref.watch(chatLocalRepositoryProvider));
});

/// Chat Service Provider
final chatServiceProvider = Provider<ChatService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ChatService(apiService);
});

/// WebSocket Service Provider
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final tokenStorage = ref.watch(tokenStorageServiceProvider);
  return WebSocketService(tokenStorage);
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(chatServiceProvider));
});

final getChatHistoryUseCaseProvider = Provider<GetChatHistoryUseCase>((ref) {
  return GetChatHistoryUseCase(ref.watch(chatRepositoryProvider));
});

final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  return SendMessageUseCase(ref.watch(chatRepositoryProvider));
});

final markAsReadUseCaseProvider = Provider<MarkAsReadUseCase>((ref) {
  return MarkAsReadUseCase(ref.watch(chatRepositoryProvider));
});

final deleteMessageUseCaseProvider = Provider<DeleteMessageUseCase>((ref) {
  return DeleteMessageUseCase(ref.watch(chatRepositoryProvider));
});

final setTypingUseCaseProvider = Provider<SetTypingUseCase>((ref) {
  return SetTypingUseCase(ref.watch(chatRepositoryProvider));
});

final getChatsUseCaseProvider = Provider<GetChatsUseCase>((ref) {
  return GetChatsUseCase(ref.watch(chatRepositoryProvider));
});

/// Unread chat messages for the bottom-nav Messenger badge.
final unreadChatCountAsyncProvider = FutureProvider<int>((ref) async {
  return ref.watch(chatServiceProvider).getUnreadCount();
});

