import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/pusher_config.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/services/app_logger.dart';
import '../../../shared/services/pusher_websocket_service.dart';
import '../../user/data/models/user_info.dart';
import '../../user/providers/user_providers.dart';
import '../utils/chat_connection_ui.dart';
import '../utils/chat_pusher_log.dart';
import 'active_chat_peer_bridge.dart';

/// Filled by the messenger list so reconnect can restore presence channels.
class ChatListPresencePeersBridge {
  static Set<int> Function()? getPeerIds;
}

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
  /// Delay before unsubscribing so chat → messenger → same chat does not drop the channel.
  static const Duration conversationCloseDebounce = Duration(milliseconds: 900);

  Timer? _closeDebounce;
  Timer? _backoffTimer;
  StreamSubscription<ConnectionStatus>? _connectionSub;
  int _generation = 0;
  int? _desiredConversationId;
  int _reconnectAttempt = 0;
  bool _reconnectInFlight = false;

  @override
  ChatPusherLifecycleState build() {
    _bindActiveChatBridge();
    _connectionSub?.cancel();
    _connectionSub = _pusher.connectionStream.listen(_onConnectionStatus);
    ref.onDispose(() {
      _closeDebounce?.cancel();
      _backoffTimer?.cancel();
      _connectionSub?.cancel();
      final conversationId = state.activeConversationId ?? _desiredConversationId;
      if (conversationId != null && conversationId > 0) {
        unawaited(
          ref
              .read(pusherWebSocketServiceProvider)
              .unsubscribeConversation(conversationId),
        );
      }
      ActiveChatPeerBridge.getActivePeerUserId = null;
      ActiveChatPeerBridge.getActiveConversationId = null;
      unawaited(ActiveChatPeerBridge.clearActiveSession());
    });
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

  void _bindActiveChatBridge() {
    ActiveChatPeerBridge.getActivePeerUserId = () => state.activePeerUserId;
    ActiveChatPeerBridge.getActiveConversationId =
        () => state.activeConversationId;
  }

  /// Records the open thread for FCM suppression. Independent of Pusher.
  void markActiveChat({
    required int peerUserId,
    int? conversationId,
  }) {
    if (peerUserId <= 0) return;
    _closeDebounce?.cancel();
    final resolvedConversationId =
        (conversationId != null && conversationId > 0) ? conversationId : null;
    final peerChanged =
        state.activePeerUserId != null && state.activePeerUserId != peerUserId;
    final nextConversationId = resolvedConversationId ??
        (peerChanged ? null : state.activeConversationId);
    if (nextConversationId != null) {
      _desiredConversationId = nextConversationId;
    }
    state = ChatPusherLifecycleState(
      isReady: state.isReady,
      userId: state.userId,
      activeConversationId: nextConversationId,
      activePeerUserId: peerUserId,
    );
    ActiveChatPeerBridge.clearPendingPeer();
    unawaited(
      ActiveChatPeerBridge.setActiveSession(
        peerUserId: peerUserId,
        conversationId: nextConversationId,
      ),
    );
  }

  void _clearActiveChat() {
    ActiveChatPeerBridge.clearPendingPeer();
    state = state.copyWith(clearConversation: true);
    unawaited(ActiveChatPeerBridge.clearActiveSession());
  }

  /// Connect Pusher and subscribe to user-global channels.
  Future<void> connectForUser(int userId) async {
    if (!PusherConfig.isConfigured) return;
    if (state.isReady && state.userId == userId) return;

    try {
      if (!_pusher.isConnected) {
        await _pusher.initialize(tokenProvider: _token);
      }
      await _pusher.connectUser(userId);
      setConnectedUser(userId);
    } catch (e) {
      AppLogger.warning(
        'ChatPusherLifecycle connect failed',
        tag: ChatPusherLog.tag,
        error: e,
      );
    }
  }

  /// Marks Pusher ready for [userId] without dropping the open conversation.
  void setConnectedUser(int userId) {
    if (userId <= 0) return;
    if (state.userId != null && state.userId != userId) {
      _clearActiveChat();
    }
    state = state.copyWith(isReady: true, userId: userId);
  }

  Set<int> presencePeerIdsForReconnect() {
    final peerId = state.activePeerUserId;
    final listPeers =
        ChatListPresencePeersBridge.getPeerIds?.call() ?? const <int>{};
    return {
      ...listPeers,
      if (peerId != null && peerId > 0) peerId,
    };
  }

  /// Open a 1:1 chat: subscribe to `private-conversation.{id}`.
  Future<void> openConversation({
    required int conversationId,
    required int otherUserId,
  }) async {
    final previousConversationId = state.activeConversationId;

    markActiveChat(
      peerUserId: otherUserId,
      conversationId: conversationId,
    );

    if (!PusherConfig.isConfigured) return;

    if (previousConversationId == conversationId) {
      await _pusher.subscribeConversation(conversationId);
      await _pusher.subscribeUserStatus(otherUserId);
      return;
    }

    final generation = ++_generation;

    var userId = state.userId;
    if (userId == null || userId <= 0) {
      final user = ref.read(cachedCurrentUserProvider).valueOrNull;
      if (user != null && user.id > 0) {
        await connectForUser(user.id);
        userId = user.id;
      }
    }

    if (generation != _generation) return;

    if (previousConversationId != null &&
        previousConversationId != conversationId) {
      await closeConversation(
        conversationId: previousConversationId,
        immediate: true,
      );
    }

    if (generation != _generation) return;

    try {
      if (!_pusher.isConnected && userId != null) {
        await connectForUser(userId);
      }
      if (generation != _generation) return;
      await _pusher.subscribeConversation(conversationId);
      await _pusher.subscribeUserStatus(otherUserId);
      if (generation != _generation) return;
      markActiveChat(
        peerUserId: otherUserId,
        conversationId: conversationId,
      );
      ChatPusherLog.logEvent(
        eventType: 'openConversation',
        conversationId: conversationId,
      );
    } catch (e) {
      AppLogger.warning(
        'ChatPusherLifecycle openConversation failed',
        tag: ChatPusherLog.tag,
        error: e,
      );
    }
  }

  /// Delay unsubscribe so chat → messenger → same chat does not drop the channel.
  void scheduleCloseConversation({int? conversationId}) {
    _closeDebounce?.cancel();
    if (conversationId == null || _desiredConversationId == conversationId) {
      _desiredConversationId = null;
    }
    _closeDebounce = Timer(conversationCloseDebounce, () {
      unawaited(closeConversation(conversationId: conversationId));
    });
  }

  Future<void> closeConversation({
    int? conversationId,
    bool immediate = false,
  }) async {
    if (immediate) {
      _closeDebounce?.cancel();
    }
    final id = conversationId ?? state.activeConversationId;
    if (id == null) {
      if (!immediate && _desiredConversationId != null) return;
      _clearActiveChat();
      return;
    }
    if (_desiredConversationId == id && !immediate) {
      return;
    }
    if (immediate && _desiredConversationId == id) {
      _desiredConversationId = null;
    }

    await _pusher.unsubscribeConversation(id);
    if (_desiredConversationId == id) {
      await _pusher.subscribeConversation(id);
      return;
    }
    if (state.activeConversationId == id) {
      _clearActiveChat();
    }
  }

  void _onConnectionStatus(ConnectionStatus status) {
    if (status == ConnectionStatus.connected) {
      _backoffTimer?.cancel();
      _reconnectAttempt = 0;
      return;
    }
    if (status == ConnectionStatus.disconnected && !_reconnectInFlight) {
      _scheduleBackoffReconnect();
    }
  }

  void _scheduleBackoffReconnect() {
    if (state.userId == null || !PusherConfig.isConfigured) return;
    _backoffTimer?.cancel();
    _reconnectAttempt += 1;
    final delay = ChatConnectionBackoff.delayFor(_reconnectAttempt);
    AppLogger.info(
      'Pusher reconnect in ${delay.inMilliseconds}ms (attempt $_reconnectAttempt)',
      tag: ChatPusherLog.tag,
    );
    _backoffTimer = Timer(delay, () {
      unawaited(reconnect());
    });
  }

  /// Re-subscribe after app resume, connection drop, or a manual banner tap.
  Future<void> reconnect({bool manual = false}) async {
    if (_reconnectInFlight) return;
    final userId = state.userId;
    if (userId == null || !PusherConfig.isConfigured) return;

    if (manual) {
      _backoffTimer?.cancel();
      _reconnectAttempt = 0;
    }

    _reconnectInFlight = true;
    _backoffTimer?.cancel();
    final convId = state.activeConversationId;
    try {
      if (_pusher.connectionStatus != ConnectionStatus.disconnected) {
        await _pusher.disconnect();
      }
      await _pusher.initialize(tokenProvider: _token);
      await _pusher.connectUser(userId);
      if (convId != null) {
        await _pusher.subscribeConversation(convId);
      }
      final presencePeers = presencePeerIdsForReconnect();
      if (presencePeers.isNotEmpty) {
        await _pusher.syncUserStatusSubscriptions(presencePeers);
      }
      setConnectedUser(userId);
    } catch (e) {
      AppLogger.warning(
        'ChatPusherLifecycle reconnect failed',
        tag: ChatPusherLog.tag,
        error: e,
      );
      _scheduleBackoffReconnect();
    } finally {
      _reconnectInFlight = false;
    }
  }
}
