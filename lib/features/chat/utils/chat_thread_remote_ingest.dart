import '../data/models/message.dart';
import '../providers/chat_thread_providers.dart';
import 'chat_edited_apply.dart';
import 'chat_message_dedup.dart';
import 'chat_optimistic.dart';
import 'chat_reaction_summary.dart';
import 'chat_read_receipt_apply.dart';
import 'chat_thread_row_map.dart';
import 'chat_timeline_merger.dart';

/// Result of merging a remote [Message] into the open thread maps.
class ChatThreadIngestResult {
  const ChatThreadIngestResult({
    required this.updatedExistingServerRow,
    required this.insertedNew,
  });

  final bool updatedExistingServerRow;
  final bool insertedNew;

  bool get added => !updatedExistingServerRow;
}

/// Applies Pusher / local-DB [Message] rows onto [chatThreadMessagesProvider].
class ChatThreadRemoteIngest {
  ChatThreadRemoteIngest._();

  static ChatThreadIngestResult apply({
    required ChatThreadMessagesNotifier thread,
    required Message message,
    required int peerUserId,
    int? currentUserId,
  }) {
    thread.ensureIndex();
    final mapped = ChatThreadRowMap.fromMessage(
      message,
      peerUserId: peerUserId,
      currentUserId: currentUserId,
      replyPreview: (id) =>
          ChatThreadRowMap.replyPreviewIn(thread.rows, id),
    );

    if (message.id > 0) {
      final existingIndex = thread.index.byServerId(message.id);
      if (existingIndex != null) {
        thread.replaceAt(existingIndex, {
          ...thread.rows[existingIndex],
          ...mapped,
        });
        return const ChatThreadIngestResult(
          updatedExistingServerRow: true,
          insertedNew: false,
        );
      }
    }

    final optimisticIndex =
        thread.index.byClientId(message.clientId) ??
        ChatMessageDedup.indexOfRow(
          thread.rows,
          clientId: message.clientId,
        );
    if (optimisticIndex >= 0) {
      thread.replaceAt(optimisticIndex, mapped);
      return const ChatThreadIngestResult(
        updatedExistingServerRow: false,
        insertedNew: false,
      );
    }

    thread.setRows(
      ChatTimelineMerger.sortChronologically([...thread.rows, mapped]),
    );
    return const ChatThreadIngestResult(
      updatedExistingServerRow: false,
      insertedNew: true,
    );
  }

  static void applyReadReceipts(
    ChatThreadMessagesNotifier thread,
    List<int> messageIds,
  ) {
    thread.setRows(
      ChatReadReceiptApply.apply(
        messages: thread.rows,
        messageIds: messageIds,
      ),
    );
  }

  static void applyDeliveryReceipts(
    ChatThreadMessagesNotifier thread,
    List<int> messageIds,
  ) {
    thread.setRows(
      ChatDeliveryReceiptApply.apply(
        messages: thread.rows,
        messageIds: messageIds,
      ),
    );
  }

  static void applyExpired(ChatThreadMessagesNotifier thread, int messageId) {
    thread.mapRows((msg) {
      if (!ChatOptimistic.sameMessageId(msg['id'], messageId)) return msg;
      return {
        ...msg,
        'is_expired': true,
        'remaining_seconds': 0,
        'attachment_url': null,
      };
    });
  }

  static void applyDeletedTombstone(
    ChatThreadMessagesNotifier thread,
    int messageId,
  ) {
    thread.mapRows((msg) {
      if (!ChatOptimistic.sameMessageId(msg['id'], messageId)) return msg;
      return {
        ...msg,
        'is_deleted': true,
        'text': '',
        'attachment_url': null,
        'reactions': <String, int>{},
        'my_reaction': null,
      };
    });
  }

  static void removeByServerId(
    ChatThreadMessagesNotifier thread,
    int messageId,
  ) {
    thread.setRows([
      for (final msg in thread.rows)
        if (!ChatOptimistic.sameMessageId(msg['id'], messageId)) msg,
    ]);
  }

  static void applyEdited({
    required ChatThreadMessagesNotifier thread,
    required int messageId,
    required String content,
    required DateTime editedAt,
    Map<String, dynamic>? extra,
  }) {
    thread.mapRows((msg) {
      if (!ChatOptimistic.sameMessageId(msg['id'], messageId)) return msg;
      return ChatEditedApply.patchRow(
        msg,
        content: content,
        editedAt: editedAt,
        extra: extra,
      );
    });
  }

  static ChatReactionSummary? applyReaction({
    required ChatThreadMessagesNotifier thread,
    required int messageId,
    required int reactorId,
    required int currentUserId,
    required Map<String, int> counts,
    required String emoji,
    required bool reacted,
  }) {
    ChatReactionSummary? next;
    thread.mapRows((msg) {
      if (!ChatOptimistic.sameMessageId(msg['id'], messageId)) return msg;
      next = ChatReactionSummary.applyEvent(
        current: ChatReactionSummary.fromMap(msg),
        reactorId: reactorId,
        currentUserId: currentUserId,
        counts: counts,
        emoji: emoji,
        reacted: reacted,
      );
      return {...msg, 'reactions': next!.counts, 'my_reaction': next!.mine};
    });
    return next;
  }
}
