import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_logger.dart';
import '../utils/chat_active_heartbeat.dart';
import 'active_chat_provider.dart';
import 'chat_providers.dart';

/// POSTs `/chat/{id}/active` while a real conversation is open (CHAT-NOTIF-003).
///
/// Not autoDispose: ChatPage may pop before the 900ms close debounce clears the session.
final chatActiveBackendSyncProvider = Provider<void>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  Timer? heartbeat;
  int? reportedId;

  Future<void> post(int conversationId, bool active) async {
    try {
      await chatService.setConversationActive(
        conversationId: conversationId,
        active: active,
      );
    } catch (e) {
      AppLogger.warning(
        'Chat active heartbeat failed',
        tag: 'ChatActive',
        error: e,
      );
    }
  }

  void stopHeartbeat() {
    heartbeat?.cancel();
    heartbeat = null;
  }

  void startHeartbeat(int conversationId) {
    stopHeartbeat();
    heartbeat = Timer.periodic(ChatActiveHeartbeat.interval, (_) {
      unawaited(post(conversationId, true));
    });
  }

  ref.listen<ActiveChatSession>(activeChatSessionProvider, (previous, next) {
    final nextId = ChatActiveHeartbeat.reportableConversationId(
      conversationId: next.conversationId,
      peerUserId: next.peerUserId,
    );

    if (nextId == reportedId) {
      return;
    }

    final previousId = reportedId;
    if (previousId != null) {
      unawaited(post(previousId, false));
    }

    reportedId = nextId;
    if (nextId != null) {
      unawaited(post(nextId, true));
      startHeartbeat(nextId);
    } else {
      stopHeartbeat();
    }
  }, fireImmediately: true);

  ref.onDispose(() {
    stopHeartbeat();
    final id = reportedId;
    reportedId = null;
    if (id != null) {
      unawaited(post(id, false));
    }
  });
});
