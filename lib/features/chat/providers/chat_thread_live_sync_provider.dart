import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_logger.dart';
import '../../user/providers/user_providers.dart';
import '../data/models/message.dart';
import '../utils/chat_thread_remote_ingest.dart';
import '../utils/chat_thread_row_map.dart';
import '../utils/chat_unseen_incoming.dart';
import 'chat_local_sync_provider.dart';
import 'chat_providers.dart';
import 'chat_pusher_providers.dart';
import 'chat_thread_providers.dart';
import 'user_presence_cache_provider.dart';

/// Latest remote ingest so [ChatPage] can pin-to-latest without owning Pusher.
class ChatThreadLiveTick {
  const ChatThreadLiveTick({
    required this.seq,
    required this.insertedNew,
    required this.fromPeer,
  });

  final int seq;
  final bool insertedNew;
  final bool fromPeer;
}

class ChatThreadLiveTickNotifier extends StateNotifier<ChatThreadLiveTick?> {
  ChatThreadLiveTickNotifier() : super(null);

  int _seq = 0;

  void emit({required bool insertedNew, required bool fromPeer}) {
    _seq += 1;
    state = ChatThreadLiveTick(
      seq: _seq,
      insertedNew: insertedNew,
      fromPeer: fromPeer,
    );
  }
}

final chatThreadLiveTickProvider = StateNotifierProvider.autoDispose
    .family<ChatThreadLiveTickNotifier, ChatThreadLiveTick?, int>(
      (ref, peerUserId) => ChatThreadLiveTickNotifier(),
    );

/// Pushes Pusher + local SQLite rows into [chatThreadMessagesProvider]
/// (PERF-PAGE-CHAT-001 / 008). ChatPage must `watch` this while open.
final chatThreadLiveSyncProvider = Provider.autoDispose.family<void, int>((
  ref,
  peerUserId,
) {
  if (peerUserId <= 0) return;

  ref.watch(chatLocalSyncProvider);

  final pusher = ref.watch(pusherWebSocketServiceProvider);
  final localRepo = ref.read(chatLocalRepositoryProvider);
  final thread = ref.read(chatThreadMessagesProvider(peerUserId).notifier);

  int? currentUserId() =>
      ref.read(cachedCurrentUserProvider).valueOrNull?.id ??
      ref.read(chatPusherLifecycleProvider).userId;

  int? activeConversationId() =>
      ref.read(chatPusherLifecycleProvider).activeConversationId;

  bool sameConversation(int? eventId) {
    if (eventId == null || eventId <= 0) return true;
    final active = activeConversationId();
    if (active == null || active <= 0) return true;
    return eventId == active;
  }

  void ingest(Message message, {required bool emitTick}) {
    if (message.senderId != peerUserId && message.receiverId != peerUserId) {
      return;
    }
    final me = currentUserId();
    final result = ChatThreadRemoteIngest.apply(
      thread: thread,
      message: message,
      peerUserId: peerUserId,
      currentUserId: me,
    );
    final fromPeer = message.senderId == peerUserId;
    final nearBottom = ref.read(isAtBottomProvider(peerUserId));
    if (ChatUnseenIncoming.shouldIncrementBadge(
      insertedNewRow: result.insertedNew,
      fromPeer: fromPeer,
      nearBottom: nearBottom,
    )) {
      ref
          .read(chatThreadViewportProvider(peerUserId).notifier)
          .incrementUnseen();
    }
    if (fromPeer && me != null && me > 0) {
      final ids = [
        if (message.receiverId == me &&
            message.id > 0 &&
            !message.isDelivered &&
            !message.isRead)
          message.id,
      ];
      if (ids.isNotEmpty) {
        unawaited(() async {
          try {
            await ref.read(chatServiceProvider).markMessagesDelivered(ids);
          } catch (e) {
            AppLogger.warning(
              'Failed to ack messages as delivered',
              tag: 'Chat',
              error: e,
            );
          }
        }());
      }
    }
    final conversationId = message.conversationId;
    if (conversationId != null && conversationId > 0) {
      unawaited(
        ref
            .read(chatPusherLifecycleProvider.notifier)
            .openConversation(
              conversationId: conversationId,
              otherUserId: peerUserId,
            ),
      );
    }
    if (emitTick && result.added) {
      ref
          .read(chatThreadLiveTickProvider(peerUserId).notifier)
          .emit(insertedNew: result.insertedNew, fromPeer: fromPeer);
    }
  }

  final messageSub = pusher.messageStream.listen((message) {
    ingest(message, emitTick: true);
  });

  final readSub = pusher.readReceiptStream.listen((event) {
    if (!sameConversation(event.conversationId)) return;
    if (event.readerId != peerUserId) return;
    unawaited(localRepo.markServerMessagesRead(event.messageIds));
    ChatThreadRemoteIngest.applyReadReceipts(thread, event.messageIds);
  });

  final expiredSub = pusher.messageExpiredStream.listen((event) {
    if (!sameConversation(event.conversationId)) return;
    unawaited(localRepo.markServerMessageExpired(event.messageId));
    ChatThreadRemoteIngest.applyExpired(thread, event.messageId);
  });

  final deletedSub = pusher.messageDeletedStream.listen((event) {
    if (!sameConversation(event.conversationId)) return;
    if (event.forEveryone) {
      ChatThreadRemoteIngest.applyDeletedTombstone(thread, event.messageId);
    } else {
      ChatThreadRemoteIngest.removeByServerId(thread, event.messageId);
    }
  });

  final editedSub = pusher.messageEditedStream.listen((event) {
    if (!sameConversation(event.conversationId)) return;
    final extra = event.message == null
        ? null
        : ChatThreadRowMap.fromMessage(
            event.message!,
            peerUserId: peerUserId,
            currentUserId: currentUserId(),
          );
    ChatThreadRemoteIngest.applyEdited(
      thread: thread,
      messageId: event.messageId,
      content: event.content,
      editedAt: event.editedAt,
      extra: extra,
    );
  });

  final reactedSub = pusher.messageReactedStream.listen((event) {
    if (!sameConversation(event.conversationId)) return;
    final summary = ChatThreadRemoteIngest.applyReaction(
      thread: thread,
      messageId: event.messageId,
      reactorId: event.userId,
      currentUserId: currentUserId() ?? 0,
      counts: event.counts,
      emoji: event.emoji,
      reacted: event.reacted,
    );
    if (summary != null && event.messageId > 0) {
      unawaited(
        localRepo.patchMessageReactions(
          serverId: event.messageId,
          counts: summary.counts,
          mine: summary.mine,
        ),
      );
    }
  });

  final deliveredSub = pusher.messageDeliveredStream.listen((event) {
    if (!sameConversation(event.conversationId)) return;
    final me = currentUserId();
    if (me != null && me > 0 && event.senderId > 0 && event.senderId != me) {
      return;
    }
    unawaited(localRepo.markServerMessagesDelivered(event.messageIds));
    ChatThreadRemoteIngest.applyDeliveryReceipts(thread, event.messageIds);
  });

  final presenceSub = pusher.presenceStream.listen((event) {
    if (event.userId != peerUserId) return;
    ref.read(userPresenceCacheProvider.notifier).apply(event);
  });

  ref.onDispose(() {
    unawaited(messageSub.cancel());
    unawaited(readSub.cancel());
    unawaited(expiredSub.cancel());
    unawaited(deletedSub.cancel());
    unawaited(editedSub.cancel());
    unawaited(reactedSub.cancel());
    unawaited(deliveredSub.cancel());
    unawaited(presenceSub.cancel());
  });
});
