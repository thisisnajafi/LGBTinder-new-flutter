import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat.dart';
import '../models/message.dart';
import '../models/message_delivery_status.dart';
import '../services/chat_outbound_queue_service.dart';
import '../services/chat_service.dart';
import 'app_database.dart';
import 'package:lgbtindernew/core/services/app_logger.dart';

/// Saved cursor state for loading older messages in a conversation.
class ChatHistoryPaginationMeta {
  const ChatHistoryPaginationMeta({
    required this.hasMore,
    this.nextCursor,
  });

  final bool hasMore;
  final ChatHistoryCursor? nextCursor;

  Map<String, dynamic> toJson() => {
        'has_more': hasMore,
        if (nextCursor != null)
          'next_cursor': {
            'before_id': nextCursor!.beforeId,
            if (nextCursor!.beforeCreatedAt != null)
              'before_created_at':
                  nextCursor!.beforeCreatedAt!.toIso8601String(),
          },
      };

  factory ChatHistoryPaginationMeta.fromJson(Map<String, dynamic> json) {
    ChatHistoryCursor? cursor;
    final rawCursor = json['next_cursor'];
    if (rawCursor is Map<String, dynamic>) {
      cursor = ChatHistoryCursor.fromJson(rawCursor);
    }
    return ChatHistoryPaginationMeta(
      hasMore: json['has_more'] == true,
      nextCursor: cursor,
    );
  }
}

/// Local-first read/write for chat list, messages, and outbound queue.
class ChatLocalRepository {
  ChatLocalRepository(this._db);

  final AppDatabase _db;

  // --- Outbox (PERF-INFRA-004) ---

  Future<List<QueuedChatMessage>> getOutboxEntries() async {
    final rows = await (_db.select(_db.outboxEntries)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    return rows
        .map(
          (r) => QueuedChatMessage(
            clientId: r.clientId,
            receiverId: r.receiverId,
            senderId: r.senderId,
            message: r.message,
            messageType: r.messageType,
            createdAt: r.createdAt,
          ),
        )
        .toList();
  }

  Future<void> enqueueOutbox(QueuedChatMessage message) async {
    final pending = await getOutboxEntries();
    final sortOrder = pending.isEmpty
        ? 0
        : (await (_db.select(_db.outboxEntries)
                  ..orderBy([(t) => OrderingTerm.desc(t.sortOrder)]))
                .getSingle())
            .sortOrder +
            1;

    await _db.into(_db.outboxEntries).insertOnConflictUpdate(
          OutboxEntriesCompanion.insert(
            clientId: message.clientId,
            receiverId: message.receiverId,
            senderId: message.senderId,
            message: message.message,
            messageType: Value(message.messageType),
            createdAt: message.createdAt,
            sortOrder: sortOrder,
          ),
        );
  }

  Future<void> removeOutboxEntry(String clientId) async {
    await (_db.delete(_db.outboxEntries)
          ..where((t) => t.clientId.equals(clientId)))
        .go();
  }

  Future<void> clearOutbox() async {
    await _db.delete(_db.outboxEntries).go();
  }

  /// Wipes all local chat data for the current session (logout / account switch).
  Future<void> clearAllSessionData() async {
    await _db.transaction(() async {
      await _db.delete(_db.localConversations).go();
      await _db.delete(_db.localMessages).go();
      await _db.delete(_db.outboxEntries).go();
      await _db.delete(_db.mediaCacheMeta).go();
    });

    final prefs = await SharedPreferences.getInstance();
    final historyKeys = prefs
        .getKeys()
        .where((key) => key.startsWith('chat_local_history_meta_'));
    for (final key in historyKeys) {
      await prefs.remove(key);
    }
    await prefs.remove(chatOutboundLegacyStorageKey);

    AppLogger.info(
      'Chat local session data cleared',
      tag: 'ChatLocalRepository',
    );
  }

  /// One-time migration from SharedPreferences queue (legacy).
  Future<void> migrateLegacyOutboxIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(chatOutboundLegacyStorageKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      for (final item in decoded) {
        if (item is! Map<String, dynamic>) continue;
        await enqueueOutbox(QueuedChatMessage.fromJson(item));
      }
      await prefs.remove(chatOutboundLegacyStorageKey);
    } catch (e) {
      AppLogger.warning(
        'Legacy chat outbox migration failed',
        tag: 'ChatLocalRepository',
        error: e,
      );
      // Keep legacy data if migration fails; do not block startup.
    }
  }

  // --- Conversations ---

  Future<List<Chat>> getConversations() async {
    final rows = await (_db.select(_db.localConversations)
          ..orderBy([
            (t) => OrderingTerm.desc(t.lastMessageAt),
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .get();
    return rows.map(_chatFromLocalConversation).toList();
  }

  Stream<List<Chat>> watchConversations() {
    final query = _db.select(_db.localConversations)
      ..orderBy([
        (t) => OrderingTerm.desc(t.lastMessageAt),
        (t) => OrderingTerm.desc(t.updatedAt),
      ]);
    return query.watch().map(
          (rows) => rows.map(_chatFromLocalConversation).toList(),
        );
  }

  Future<void> upsertConversation(Chat chat) async {
    final preview = chat.lastMessage?.message;
    await _db.into(_db.localConversations).insertOnConflictUpdate(
          LocalConversationsCompanion(
            otherUserId: Value(chat.userId),
            conversationId: Value(chat.id > 0 ? chat.id : null),
            firstName: Value(chat.firstName),
            lastName: Value(chat.lastName),
            primaryImageUrl: Value(chat.primaryImageUrl),
            lastMessagePreview: Value(preview),
            lastMessageAt: Value(chat.lastMessageAt ?? chat.lastMessage?.createdAt),
            unreadCount: Value(chat.unreadCount),
            isMuted: Value(chat.isMuted),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> replaceAllConversations(List<Chat> chats) async {
    await _db.transaction(() async {
      await _db.delete(_db.localConversations).go();
      for (final chat in chats) {
        await upsertConversation(chat);
      }
    });
  }

  Future<void> patchConversationPreview({
    required int otherUserId,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
    int? unreadCount,
  }) async {
    final existing = await (_db.select(_db.localConversations)
          ..where((t) => t.otherUserId.equals(otherUserId)))
        .getSingleOrNull();
    if (existing == null) return;

    await (_db.update(_db.localConversations)
          ..where((t) => t.otherUserId.equals(otherUserId)))
        .write(
      LocalConversationsCompanion(
        lastMessagePreview: lastMessagePreview != null
            ? Value(lastMessagePreview)
            : const Value.absent(),
        lastMessageAt: lastMessageAt != null
            ? Value(lastMessageAt)
            : const Value.absent(),
        unreadCount: unreadCount != null
            ? Value(unreadCount)
            : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // --- Messages ---

  Future<List<Message>> getMessagesForOtherUser(
    int otherUserId, {
    int limit = 50,
  }) async {
    final rows = await (_db.select(_db.localMessages)
          ..where((t) => t.otherUserId.equals(otherUserId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
    return rows.map(_messageFromLocal).toList();
  }

  /// All cached messages for a peer, oldest first.
  Future<List<Message>> getAllMessagesForOtherUser(int otherUserId) async {
    final rows = await (_db.select(_db.localMessages)
          ..where((t) => t.otherUserId.equals(otherUserId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    return rows.map(_messageFromLocal).toList();
  }

  /// Older cached messages before [beforeCreatedAt] (newest-first batch).
  Future<List<Message>> getOlderMessagesForOtherUser(
    int otherUserId, {
    required DateTime beforeCreatedAt,
    int limit = 30,
  }) async {
    final rows = await (_db.select(_db.localMessages)
          ..where(
            (t) =>
                t.otherUserId.equals(otherUserId) &
                t.createdAt.isSmallerThanValue(beforeCreatedAt),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
    return rows.map(_messageFromLocal).toList();
  }

  Future<void> saveHistoryPagination(
    int otherUserId,
    ChatHistoryPaginationMeta meta,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _historyMetaKey(otherUserId),
      jsonEncode(meta.toJson()),
    );
  }

  Future<ChatHistoryPaginationMeta?> loadHistoryPagination(int otherUserId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyMetaKey(otherUserId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return ChatHistoryPaginationMeta.fromJson(decoded);
      }
    } catch (e) {
      AppLogger.warning(
        'Failed to parse chat history pagination meta',
        tag: 'ChatLocalRepository',
        error: e,
      );
    }
    return null;
  }

  Future<void> clearHistoryPagination(int otherUserId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyMetaKey(otherUserId));
  }

  String _historyMetaKey(int otherUserId) =>
      'chat_local_history_meta_$otherUserId';

  Stream<List<Message>> watchMessagesForOtherUser(
    int otherUserId, {
    int limit = 50,
  }) {
    final query = _db.select(_db.localMessages)
      ..where((t) => t.otherUserId.equals(otherUserId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit);
    return query.watch().map((rows) => rows.map(_messageFromLocal).toList());
  }

  Future<void> upsertMessage(Message message, int otherUserId) async {
    final payloadJson = message.metadata != null
        ? jsonEncode(message.metadata)
        : null;

    final existingByServer = message.id > 0
        ? await (_db.select(_db.localMessages)
              ..where((t) => t.serverId.equals(message.id)))
            .getSingleOrNull()
        : null;

    final existingByClient = message.clientId != null
        ? await (_db.select(_db.localMessages)
              ..where((t) => t.clientId.equals(message.clientId!)))
            .getSingleOrNull()
        : null;

    final companion = LocalMessagesCompanion(
      serverId: Value(message.id > 0 ? message.id : null),
      clientId: Value(message.clientId),
      otherUserId: Value(otherUserId),
      senderId: Value(message.senderId),
      receiverId: Value(message.receiverId),
      message: Value(message.message),
      messageType: Value(message.messageType),
      createdAt: Value(message.createdAt),
      isRead: Value(message.isRead),
      isDeleted: Value(message.isDeleted),
      attachmentUrl: Value(message.attachmentUrl),
      payloadJson: Value(payloadJson),
      deliveryStatus: Value(message.deliveryStatus.name),
    );

    if (existingByServer != null) {
      await (_db.update(_db.localMessages)
            ..where((t) => t.localId.equals(existingByServer.localId)))
          .write(companion);
      return;
    }

    if (existingByClient != null) {
      await (_db.update(_db.localMessages)
            ..where((t) => t.localId.equals(existingByClient.localId)))
          .write(companion);
      return;
    }

    await _db.into(_db.localMessages).insert(companion);
  }

  Future<void> upsertMessages(List<Message> messages, int otherUserId) async {
    await _db.transaction(() async {
      for (final message in messages) {
        await upsertMessage(message, otherUserId);
      }
    });
  }

  Future<void> deleteMessageByServerId(int serverId) async {
    await (_db.delete(_db.localMessages)
          ..where((t) => t.serverId.equals(serverId)))
        .go();
  }

  Chat _chatFromLocalConversation(LocalConversation row) {
    Message? lastMessage;
    if (row.lastMessagePreview != null &&
        row.lastMessagePreview!.isNotEmpty) {
      lastMessage = Message(
        id: 0,
        senderId: 0,
        receiverId: row.otherUserId,
        message: row.lastMessagePreview!,
        createdAt: row.lastMessageAt ?? row.updatedAt,
      );
    }

    return Chat(
      id: row.conversationId ?? 0,
      userId: row.otherUserId,
      firstName: row.firstName,
      lastName: row.lastName,
      primaryImageUrl: row.primaryImageUrl,
      lastMessage: lastMessage,
      lastMessageAt: row.lastMessageAt,
      unreadCount: row.unreadCount,
      isMuted: row.isMuted,
    );
  }

  Message _messageFromLocal(LocalMessage row) {
    Map<String, dynamic>? metadata;
    if (row.payloadJson != null && row.payloadJson!.isNotEmpty) {
      try {
        final decoded = jsonDecode(row.payloadJson!);
        if (decoded is Map<String, dynamic>) {
          metadata = decoded;
        } else if (decoded is Map) {
          metadata = Map<String, dynamic>.from(decoded);
        }
      } catch (e) { AppLogger.warning('Silently caught exception', tag: 'chat_local_repository', error: e); }
    }

    return Message(
      id: row.serverId ?? 0,
      senderId: row.senderId,
      receiverId: row.receiverId,
      message: row.message,
      messageType: row.messageType,
      createdAt: row.createdAt,
      isRead: row.isRead,
      isDeleted: row.isDeleted,
      attachmentUrl: row.attachmentUrl,
      metadata: metadata,
      clientId: row.clientId,
      deliveryStatus: _parseDeliveryStatus(row.deliveryStatus),
    );
  }

  MessageDeliveryStatus _parseDeliveryStatus(String value) {
    switch (value.toLowerCase()) {
      case 'sending':
        return MessageDeliveryStatus.sending;
      case 'queued':
        return MessageDeliveryStatus.queued;
      case 'failed':
        return MessageDeliveryStatus.failed;
      default:
        return MessageDeliveryStatus.sent;
    }
  }
}
