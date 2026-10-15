import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_logger.dart';
import '../utils/chat_active_heartbeat.dart';
import 'active_chat_provider.dart';
import 'chat_providers.dart';

/// Lets app lifecycle clear the server "chat is open" flag without Riverpod.
class ChatActiveBackendSyncBridge {
  static Future<void> Function()? onAppBackground;
  static Future<void> Function()? onAppResume;
}

/// POSTs `/chat/{id}/active` while a real conversation is open (CHAT-NOTIF-003).
///
/// Not autoDispose: ChatPage may pop before the 900ms close debounce clears the session.
/// Background and terminated apps must not keep the flag, or the server skips the
/// message push the user should see in the tray (RT-009).
final chatActiveBackendSyncProvider = Provider<void>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  Timer? heartbeat;
  int? reportedId;
  var appInForeground = _lifecycleIsForeground();

  Future<void> post(int conversationId, bool active) async {
    final report =
        active &&
        ChatActiveHeartbeat.shouldReportActive(
          appInForeground: appInForeground && _lifecycleIsForeground(),
          conversationId: conversationId,
          peerUserId: null,
        );
    try {
      await chatService.setConversationActive(
        conversationId: conversationId,
        active: report,
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

  ChatActiveBackendSyncBridge.onAppBackground = () async {
    appInForeground = false;
    stopHeartbeat();
    final id = reportedId;
    if (id != null) await post(id, false);
  };
  ChatActiveBackendSyncBridge.onAppResume = () async {
    appInForeground = true;
    final id = reportedId;
    if (id == null) return;
    await post(id, true);
    startHeartbeat(id);
  };

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
    ChatActiveBackendSyncBridge.onAppBackground = null;
    ChatActiveBackendSyncBridge.onAppResume = null;
    final id = reportedId;
    reportedId = null;
    if (id != null) {
      unawaited(post(id, false));
    }
  });
});

bool _lifecycleIsForeground() {
  final lifecycle = WidgetsBinding.instance.lifecycleState;
  return lifecycle == null || lifecycle == AppLifecycleState.resumed;
}
