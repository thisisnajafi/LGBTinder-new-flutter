import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/pusher_config.dart';
import '../../../core/providers/api_providers.dart';
import '../../../shared/services/pusher_websocket_service.dart';
import '../../user/data/models/user_info.dart';
import '../../user/providers/user_providers.dart';

/// Singleton Pusher service for chat + matches.
final pusherWebSocketServiceProvider = Provider<PusherWebSocketService>((ref) {
  final service = PusherWebSocketService();
  ref.onDispose(service.dispose);
  return service;
});

/// Keeps Pusher connected for the logged-in user; reconnects on app resume.
final chatPusherLifecycleProvider =
    NotifierProvider<ChatPusherLifecycleNotifier, ChatPusherLifecycleState>(
  ChatPusherLifecycleNotifier.new,
);

class ChatPusherLifecycleState {
  final bool isReady;
  final int? userId;
  final int? activeConversationId;
  final int? activePeerUserId;

  const ChatPusherLifecycleState({
    this.isReady = false,
    this.userId,
    this.activeConversationId,
    this.activePeerUserId,
  });

  ChatPusherLifecycleState copyWith({
    bool? isReady,
    int? userId,
    int? activeConversationId,
    int? activePeerUserId,
    bool clearConversation = false,
  }) {
    return ChatPusherLifecycleState(
      isReady: isReady ?? this.isReady,
      userId: userId ?? this.userId,
      activeConversationId: clearConversation
          ? null
          : (activeConversationId ?? this.activeConversationId),
      activePeerUserId: clearConversation
          ? null
          : (activePeerUserId ?? this.activePeerUserId),
    );
  }
}

class ChatPusherLifecycleNotifier extends Notifier<ChatPusherLifecycleState> {
  @override
  ChatPusherLifecycleState build() {
    ref.listen<AsyncValue<UserInfo>>(cachedCurrentUserProvider, (prev, next) {
      next.whenData((user) {
        if (user.id > 0) {
          unawaited(connectForUser(user.id));
        }
      });
    });

    final current = ref.read(cachedCurrentUserProvider);
    current.whenData((user) {
      if (user.id > 0) {
        Future.microtask(() => connectForUser(user.id));
      }
    });

    return const ChatPusherLifecycleState();
  }

  PusherWebSocketService get _pusher => ref.read(pusherWebSocketServiceProvider);

  Future<String?> _token() =>
      ref.read(tokenStorageServiceProvider).getAuthToken();

  /// Connect Pusher and subscribe to user-global channels.
  Future<void> connectForUser(int userId) async {
    if (!PusherConfig.isConfigured) return;
    if (state.isReady && state.userId == userId) return;

    try {
      if (!_pusher.isConnected) {
        await _pusher.initialize(tokenProvider: _token);
      }
      await _pusher.connectUser(userId);
      state = ChatPusherLifecycleState(
        isReady: true,
        userId: userId,
        activeConversationId: state.activeConversationId,
      );
    } catch (e) {
      debugPrint('ChatPusherLifecycle connect failed: $e');
    }
  }

  /// Open a 1:1 chat: subscribe to `private-conversation.{id}`.
  Future<void> openConversation({
    required int conversationId,
    required int otherUserId,
  }) async {
    if (!PusherConfig.isConfigured) return;

    var userId = state.userId;
    if (userId == null || userId <= 0) {
      final user = ref.read(cachedCurrentUserProvider).valueOrNull;
      if (user != null && user.id > 0) {
        await connectForUser(user.id);
        userId = user.id;
      }
    }

    if (state.activeConversationId != null &&
        state.activeConversationId != conversationId) {
      await closeConversation();
    }

    try {
      if (!_pusher.isConnected && userId != null) {
        await connectForUser(userId);
      }
      await _pusher.subscribeConversation(conversationId);
      await _pusher.subscribeUserStatus(otherUserId);
      state = state.copyWith(
        activeConversationId: conversationId,
        activePeerUserId: otherUserId,
      );
    } catch (e) {
      debugPrint('ChatPusherLifecycle openConversation failed: $e');
    }
  }

  Future<void> closeConversation() async {
    final id = state.activeConversationId;
    if (id != null) {
      await _pusher.unsubscribeConversation(id);
    }
    state = state.copyWith(clearConversation: true);
  }

  /// Re-subscribe after app resume or connection drop.
  Future<void> reconnect() async {
    final userId = state.userId;
    if (userId == null || !PusherConfig.isConfigured) return;

    try {
      await _pusher.disconnect();
      await _pusher.initialize(tokenProvider: _token);
      await _pusher.connectUser(userId);
      final convId = state.activeConversationId;
      if (convId != null) {
        await _pusher.subscribeConversation(convId);
      }
      final peerId = state.activePeerUserId;
      if (peerId != null && peerId > 0) {
        await _pusher.subscribeUserStatus(peerId);
      }
      state = state.copyWith(isReady: true, userId: userId);
    } catch (e) {
      debugPrint('ChatPusherLifecycle reconnect failed: $e');
    }
  }
}
