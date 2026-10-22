import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/animation_constants.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/services/app_logger.dart';
import '../../../shared/services/push_notification_service.dart';
import '../../matching/widgets/match_celebration_launcher.dart';
import '../../user/providers/user_providers.dart';
import '../data/models/message.dart';
import '../utils/chat_fcm_suppress.dart';
import '../utils/chat_message_preview.dart';
import '../utils/in_app_chat_banner.dart';
import 'active_chat_peer_bridge.dart';
import 'chat_list_preview_provider.dart';
import 'chat_pusher_providers.dart';
import 'conversation_mute_cache_provider.dart';

/// Lets FCM (non-Riverpod singleton) show an in-app banner.
class InAppChatBannerBridge {
  static bool Function(InAppChatBannerItem item)? present;

  static bool tryPresent(InAppChatBannerItem item) {
    return present?.call(item) ?? false;
  }
}

bool inAppChatBannerAppForeground() {
  final state = WidgetsBinding.instance.lifecycleState;
  return state == null || state == AppLifecycleState.resumed;
}

final inAppChatBannerProvider =
    NotifierProvider<InAppChatBannerNotifier, List<InAppChatBannerItem>>(
  InAppChatBannerNotifier.new,
);

class InAppChatBannerNotifier extends Notifier<List<InAppChatBannerItem>> {
  InAppChatBannerNotifier({
    this.autoDismiss = AppAnimations.inAppChatBannerHold,
  });

  final Duration autoDismiss;
  final Map<String, Timer> _timers = {};
  final Set<String> _seenIds = {};

  @override
  List<InAppChatBannerItem> build() {
    ref.onDispose(_cancelAllTimers);
    return const [];
  }

  bool show(InAppChatBannerItem item) {
    if (item.isChat && item.peerUserId <= 0) return false;
    if ((item.type == 'match' || item.type == 'new_match') &&
        MatchCelebrationDedupe.shouldSuppressBanner(
          matchId: int.tryParse(item.routeData['match_id']?.toString() ?? ''),
          peerUserId: item.peerUserId,
        )) {
      // The match overlay is (or was just) on screen for this match.
      return true;
    }
    if (_seenIds.contains(item.id)) return false;
    _seenIds.add(item.id);
    if (_seenIds.length > 40) {
      _seenIds.remove(_seenIds.first);
    }

    final replaced = item.peerUserId > 0
        ? state.where((e) => e.peerUserId == item.peerUserId)
        : state.where((e) => e.id == item.id);
    for (final old in replaced) {
      _cancelTimer(old.id);
    }

    state = InAppChatBannerPolicy.push(state, item);
    _armTimer(item.id);
    return true;
  }

  void dismiss(String id) {
    _cancelTimer(id);
    state = state.where((item) => item.id != id).toList();
  }

  void dismissAll() {
    _cancelAllTimers();
    state = const [];
  }

  void _armTimer(String id) {
    _cancelTimer(id);
    if (autoDismiss <= Duration.zero) return;
    _timers[id] = Timer(autoDismiss, () => dismiss(id));
  }

  void _cancelTimer(String id) {
    _timers.remove(id)?.cancel();
  }

  void _cancelAllTimers() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }
}

/// Pusher messages from other chats while the app is open.
final inAppChatBannerSyncProvider = Provider<void>((ref) {
  final notifier = ref.read(inAppChatBannerProvider.notifier);
  InAppChatBannerBridge.present = (item) => notifier.show(item);
  ref.onDispose(() {
    InAppChatBannerBridge.present = null;
  });

  final sub = ref.watch(pusherWebSocketServiceProvider).messageStream.listen(
    (message) => _presentFromPusher(ref, message),
  );
  ref.onDispose(sub.cancel);
});

void _presentFromPusher(Ref ref, Message message) {
  final currentUserId = ref.read(chatPusherLifecycleProvider).userId ??
      ref.read(cachedCurrentUserProvider).valueOrNull?.id;
  final own = currentUserId != null && message.senderId == currentUserId;
  final suppressed = ChatFcmSuppress.shouldSuppress(
    InAppChatBannerPolicy.suppressPayloadForMessage(message),
    isActivePeer: ActiveChatPeerBridge.isActivePeer,
    isActiveConversation: ActiveChatPeerBridge.isActiveConversation,
    isMutedPeer: ConversationMuteBridge.isPeerMuted,
  );
  final foreground = inAppChatBannerAppForeground();
  ChatListPreviewItem? previewItem;
  for (final item in ref.read(chatListPreviewProvider).items) {
    if (item.id == message.senderId) {
      previewItem = item;
      break;
    }
  }
  final hideText = _hideLockedMessageText(
    message: message,
    preview: previewItem,
    isPremium: ref.read(isPremiumProvider),
  );

  if (!own &&
      !suppressed &&
      PushNotificationService().fcmToken == null) {
    final preview = hideText
        ? 'New message'
        : chatMessagePreviewText(
            message: message.message,
            messageType: message.messageType,
            mediaDuration: message.mediaDuration,
            isExpired: message.isExpired,
          );
    unawaited(
      PushNotificationService().showLocalChatAlert(
        messageId: message.id,
        title: 'New message',
        body: preview,
        senderId: message.senderId,
      ),
    );
  }
  if (!InAppChatBannerPolicy.shouldPresent(
    isChatPayload: true,
    suppressedOpenOrMuted: suppressed,
    isOwnMessage: own,
    appForeground: foreground,
  )) {
    return;
  }

  final shown = ref.read(inAppChatBannerProvider.notifier).show(
        hideText
            ? InAppChatBannerItem(
                id: message.id > 0
                    ? '${message.id}'
                    : 'local_${message.clientId ?? message.createdAt.millisecondsSinceEpoch}',
                peerUserId: message.senderId,
                title: previewItem?.name ?? 'New message',
                body: 'New message',
                avatarUrl: previewItem?.avatarUrl,
              )
            : InAppChatBannerPolicy.fromMessage(
                message,
                fallbackName: previewItem?.name,
                fallbackAvatarUrl: previewItem?.avatarUrl,
              ),
      );
  if (shown) {
    AppLogger.info(
      'In-app chat banner for peer ${message.senderId}',
      tag: 'Notifications',
    );
  }
}

/// Free, non-match chats must not reveal message text in banners or alerts.
bool _hideLockedMessageText({
  required Message message,
  required ChatListPreviewItem? preview,
  required bool isPremium,
}) {
  if (message.isLocked) return true;
  if (isPremium) return false;
  if (preview == null) return false;
  return !preview.isMatch && !preview.isOfficial;
}
