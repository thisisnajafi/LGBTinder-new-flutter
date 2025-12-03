import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_providers.dart';
import '../../../shared/services/token_storage_service.dart';
import '../data/services/chat_service.dart';
import '../data/services/websocket_service.dart';

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

