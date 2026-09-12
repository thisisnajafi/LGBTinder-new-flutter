import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat.dart';
import '../models/message.dart';
import '../models/message_delivery_status.dart';
import '../services/chat_outbound_queue_service.dart';
import '../services/chat_service.dart';
import '../../utils/chat_reaction_summary.dart';
import '../../utils/chat_visual_media.dart';
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
    final existing = await (_db.select(_db.outboxEntries)
          ..where((t) => t.clientId.equals(message.clientId)))
        .getSingleOrNull();

    late final int sortOrder;
    if (existing != null) {
      sortOrder = existing.sortOrder;
    } else {
      final newest = await (_db.select(_db.outboxEntries)
            ..orderBy([(t) => OrderingTerm.desc(t.sortOrder)])
            ..limit(1))
          .getSingleOrNull();
      sortOrder = (newest?.sortOrder ?? -1) + 1;
    }

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

  Future<void> trimOutboxToMax(int maxSize) async {
    if (maxSize < 0) return;
    final rows = await (_db.select(_db.outboxEntries)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    if (rows.length <= maxSize) return;
    final extra = rows.length - maxSize;
    for (var i = 0; i < extra; i++) {
      await removeOutboxEntry(rows[i].clientId);
    }
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
    await prefs.remove('lgbtfinder_chat_info_cache_v1');

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
    final existing = await (_db.select(_db.localConversations)
          ..where((t) => t.otherUserId.equals(chat.userId)))
        .getSingleOrNull();
    final incomingAvatar = chat.primaryImageUrl?.trim();
    final preview = chat.lastMessage?.message;
    await _db.into(_db.localConversations).insertOnConflictUpdate(
          LocalConversationsCompanion(
            otherUserId: Value(chat.userId),
            conversationId: Value(chat.id > 0 ? chat.id : null),
            firstName: Value(chat.firstName),
            lastName: Value(chat.lastName),
            primaryImageUrl: Value(
              (incomingAvatar != null && incomingAvatar.isNotEmpty)
                  ? incomingAvatar
                  : existing?.primaryImageUrl ?? chat.primaryImageUrl,
            ),
            lastMessagePreview: Value(preview),
            lastMessageAt: Value(chat.lastMessageAt ?? chat.lastMessage?.createdAt),
            unreadCount: Value(chat.unreadCount),
            isMuted: Value(chat.isMuted),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> replaceAllConversations(List<Chat> chats) async {
    final existingRows = await _db.select(_db.localConversations).get();
    final existingAvatars = <int, String>{
      for (final row in existingRows)
        if (row.primaryImageUrl != null &&
            row.primaryImageUrl!.trim().isNotEmpty)
          row.otherUserId: row.primaryImageUrl!,
    };

    await _db.transaction(() async {
      await _db.delete(_db.localConversations).go();
      for (final chat in chats) {
        final incoming = chat.primaryImageUrl?.trim();
        final avatar = (incoming != null && incoming.isNotEmpty)
            ? incoming
            : existingAvatars[chat.userId];
        await _db.into(_db.localConversations).insertOnConflictUpdate(
              LocalConversationsCompanion(
                otherUserId: Value(chat.userId),
                conversationId: Value(chat.id > 0 ? chat.id : null),
                firstName: Value(chat.firstName),
                lastName: Value(chat.lastName),
                primaryImageUrl: Value(avatar ?? chat.primaryImageUrl),
                lastMessagePreview: Value(chat.lastMessage?.message),
                lastMessageAt: Value(
                  chat.lastMessageAt ?? chat.lastMessage?.createdAt,
                ),
                unreadCount: Value(chat.unreadCount),
                isMuted: Value(chat.isMuted),
                updatedAt: Value(DateTime.now()),
              ),
            );
      }
    });
  }

  Future<void> patchPeerAppearance({
    required int otherUserId,
    String? name,
    String? primaryImageUrl,
  }) async {
    if (otherUserId <= 0) return;
    final existing = await (_db.select(_db.localConversations)
          ..where((t) => t.otherUserId.equals(otherUserId)))
        .getSingleOrNull();
    if (existing == null) return;

    String? firstName = existing.firstName;
    String? lastName = existing.lastName;
    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty && trimmedName != 'User') {
      final parts = trimmedName.split(RegExp(r'\s+'));
      firstName = parts.first;
      lastName = parts.length > 1 ? parts.sublist(1).join(' ') : lastName;
    }

    await (_db.update(_db.localConversations)
          ..where((t) => t.otherUserId.equals(otherUserId)))
        .write(
      LocalConversationsCompanion(
        firstName: Value(firstName),
        lastName: Value(lastName),
        primaryImageUrl: primaryImageUrl != null && primaryImageUrl.trim().isNotEmpty
            ? Value(primaryImageUrl.trim())
            : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
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

  Future<void> setConversationMuted(int otherUserId, bool muted) async {
    await (_db.update(_db.localConversations)
          ..where((t) => t.otherUserId.equals(otherUserId)))
        .write(
      LocalConversationsCompanion(
        isMuted: Value(muted),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<int>> getMutedPeerIds() async {
    final rows = await (_db.select(_db.localConversations)
          ..where((t) => t.isMuted.equals(true)))
        .get();
    return rows.map((row) => row.otherUserId).toList();
  }

  // --- Messages ---

  Future<List<Message>> getMessagesForOtherUser(
    int otherUserId, {
    int limit = 50,
    bool excludeDeleted = false,
  }) async {
    final query = _db.select(_db.localMessages)
      ..where((t) => t.otherUserId.equals(otherUserId));
    if (excludeDeleted) {
      query.where((t) => t.isDeleted.equals(false));
    }
    final rows = await (query
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

  /// All cached messages for a peer, oldest first. Emits on every local write.
  Stream<List<Message>> watchAllMessagesForOtherUser(int otherUserId) {
    final query = _db.select(_db.localMessages)
      ..where((t) => t.otherUserId.equals(otherUserId))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return query.watch().map((rows) => rows.map(_messageFromLocal).toList());
  }

  Future<void> upsertMessage(Message message, int otherUserId) async {
    final payload = <String, dynamic>{
      ...?message.metadata,
      if (message.mediaDuration != null) 'media_duration': message.mediaDuration,
      if (message.remainingSeconds != null)
        'remaining_seconds': message.remainingSeconds,
      if (message.expiresInSeconds != null)
        'expires_in_seconds': message.expiresInSeconds,
      'is_expired': message.isExpired,
      if (message.secureMediaUrl != null)
        'secure_media_url': message.secureMediaUrl,
      if (message.viewedAt != null)
        'viewed_at': message.viewedAt!.toIso8601String(),
      if (message.mediaThumbnailUrl != null)
        'media_thumbnail_url': message.mediaThumbnailUrl,
      if (message.conversationId != null)
        'conversation_id': message.conversationId,
      if (message.replyToMessageId != null)
        'reply_to_message_id': message.replyToMessageId,
      if (message.replyToText != null) 'reply_to_text': message.replyToText,
      if (message.replyToName != null) 'reply_to_name': message.replyToName,
      if (message.forwardedFromMessageId != null)
        'forwarded_from_message_id': message.forwardedFromMessageId,
      if (message.forwardedFromUserId != null)
        'forwarded_from_user_id': message.forwardedFromUserId,
      if (message.forwardedFromName != null)
        'forwarded_from_name': message.forwardedFromName,
      'is_delivered': message.isDelivered,
      'is_edited': message.isEdited,
      'reactions': message.reactions,
      if (message.myReaction != null) 'my_reaction': message.myReaction,
      if (message.deliveredAt != null)
        'delivered_at': message.deliveredAt!.toIso8601String(),
      if (message.editedAt != null)
        'edited_at': message.editedAt!.toIso8601String(),
    };
    final payloadJson = payload.isEmpty ? null : jsonEncode(payload);

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
      attachmentUrl: Value(
        ChatVisualMedia.displayUrl(message) ?? message.attachmentUrl,
      ),
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

  /// Merge live reaction counts into the cached payload (CHAT-FEAT-003).
  ///
  /// When [updateMine] is false, keep the stored `my_reaction` so another
  /// user's react/unreact does not wipe the current user's emoji.
  Future<void> patchMessageReactions({
    required int serverId,
    required Map<String, int> counts,
    String? mine,
    bool updateMine = true,
  }) async {
    if (serverId <= 0) return;
    await _patchServerMessage(
      serverId,
      payloadPatch: (payload) {
        payload['reactions'] = counts;
        if (!updateMine) return;
        if (mine == null || mine.isEmpty) {
          payload.remove('my_reaction');
        } else {
          payload['my_reaction'] = mine;
        }
      },
    );
  }

  /// Marks cached outgoing rows as read (and delivered) from a Pusher receipt.
  Future<void> markServerMessagesRead(List<int> serverIds) async {
    final ids = [for (final id in serverIds) if (id > 0) id];
    if (ids.isEmpty) return;
    await _db.transaction(() async {
      for (final id in ids) {
        await _patchServerMessage(
          id,
          companion: const LocalMessagesCompanion(isRead: Value(true)),
          payloadPatch: (payload) {
            payload['is_delivered'] = true;
          },
        );
      }
    });
  }

  /// Marks cached outgoing rows as delivered from a Pusher receipt.
  Future<void> markServerMessagesDelivered(List<int> serverIds) async {
    final ids = [for (final id in serverIds) if (id > 0) id];
    if (ids.isEmpty) return;
    await _db.transaction(() async {
      for (final id in ids) {
        await _patchServerMessage(
          id,
          payloadPatch: (payload) {
            payload['is_delivered'] = true;
          },
        );
      }
    });
  }

  /// Marks a disappearing message as expired in the local cache.
  Future<void> markServerMessageExpired(int serverId) async {
    if (serverId <= 0) return;
    await _patchServerMessage(
      serverId,
      companion: const LocalMessagesCompanion(attachmentUrl: Value(null)),
      payloadPatch: (payload) {
        payload['is_expired'] = true;
        payload['remaining_seconds'] = 0;
      },
    );
  }

  Future<void> _patchServerMessage(
    int serverId, {
    LocalMessagesCompanion? companion,
    void Function(Map<String, dynamic> payload)? payloadPatch,
  }) async {
    final row = await (_db.select(_db.localMessages)
          ..where((t) => t.serverId.equals(serverId)))
        .getSingleOrNull();
    if (row == null) return;

    var payload = <String, dynamic>{};
    if (row.payloadJson != null && row.payloadJson!.isNotEmpty) {
      try {
        final decoded = jsonDecode(row.payloadJson!);
        if (decoded is Map) {
          payload = Map<String, dynamic>.from(decoded);
        }
      } catch (e) {
        AppLogger.warning(
          'Failed to decode payload while patching local message $serverId',
          tag: 'Chat',
          error: e,
        );
      }
    }
    payloadPatch?.call(payload);

    await (_db.update(_db.localMessages)
          ..where((t) => t.localId.equals(row.localId)))
        .write(
          (companion ?? const LocalMessagesCompanion()).copyWith(
            payloadJson: Value(jsonEncode(payload)),
          ),
        );
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

  /// Keep the row and mark it as a for-everyone tombstone.
  Future<void> markMessageDeletedByServerId(int serverId) async {
    if (serverId <= 0) return;
    await (_db.update(_db.localMessages)
          ..where((t) => t.serverId.equals(serverId)))
        .write(const LocalMessagesCompanion(
          isDeleted: Value(true),
          message: Value(''),
          attachmentUrl: Value(null),
        ));
  }

  Future<int?> otherUserIdForServerMessage(int serverId) async {
    if (serverId <= 0) return null;
    final row = await (_db.select(_db.localMessages)
          ..where((t) => t.serverId.equals(serverId)))
        .getSingleOrNull();
    return row?.otherUserId;
  }

  Future<int?> otherUserIdForConversation(int conversationId) async {
    if (conversationId <= 0) return null;
    final row = await (_db.select(_db.localConversations)
          ..where((t) => t.conversationId.equals(conversationId)))
        .getSingleOrNull();
    return row?.otherUserId;
  }

  Future<int?> conversationIdForOtherUser(int otherUserId) async {
    if (otherUserId <= 0) return null;
    final row = await (_db.select(_db.localConversations)
          ..where((t) => t.otherUserId.equals(otherUserId)))
        .getSingleOrNull();
    final id = row?.conversationId;
    if (id == null || id <= 0) return null;
    // Messenger list historically stored the peer user id as `chat.id`.
    if (id == otherUserId) return null;
    return id;
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
      } catch (e) {
        AppLogger.warning(
          'Failed to decode local message payload JSON',
          tag: 'Chat',
          error: e,
        );
      }
    }

    return Message(
      id: row.serverId ?? 0,
      senderId: row.senderId,
      receiverId: row.receiverId,
      message: row.message,
      messageType: row.messageType,
      createdAt: row.createdAt,
      isRead: row.isRead,
      isDelivered: metadata?['is_delivered'] == true ||
          metadata?['delivered_at'] != null ||
          row.isRead,
      isEdited: metadata?['is_edited'] == true || metadata?['edited_at'] != null,
      deliveredAt: metadata?['delivered_at'] != null
          ? DateTime.tryParse(metadata!['delivered_at'].toString())
          : null,
      editedAt: metadata?['edited_at'] != null
          ? DateTime.tryParse(metadata!['edited_at'].toString())
          : null,
      isDeleted: row.isDeleted,
      attachmentUrl: row.attachmentUrl,
      metadata: metadata,
      clientId: row.clientId,
      deliveryStatus: _parseDeliveryStatus(row.deliveryStatus),
      mediaDuration: _payloadInt(metadata, 'media_duration'),
      remainingSeconds: _payloadInt(metadata, 'remaining_seconds'),
      expiresInSeconds: _payloadInt(metadata, 'expires_in_seconds'),
      isExpired: metadata?['is_expired'] == true,
      secureMediaUrl: metadata?['secure_media_url']?.toString(),
      viewedAt: metadata?['viewed_at'] != null
          ? DateTime.tryParse(metadata!['viewed_at'].toString())
          : null,
      mediaThumbnailUrl: metadata?['media_thumbnail_url']?.toString(),
      conversationId: _payloadInt(metadata, 'conversation_id'),
      replyToMessageId: _payloadInt(metadata, 'reply_to_message_id'),
      replyToText: metadata?['reply_to_text']?.toString(),
      replyToName: metadata?['reply_to_name']?.toString(),
      forwardedFromMessageId:
          _payloadInt(metadata, 'forwarded_from_message_id'),
      forwardedFromUserId: _payloadInt(metadata, 'forwarded_from_user_id'),
      forwardedFromName: metadata?['forwarded_from_name']?.toString(),
      reactions: ChatReactionSummary.parseCounts(metadata?['reactions']),
      myReaction: ChatReactionSummary.parseMine(metadata?['my_reaction']),
    );
  }

  int? _payloadInt(Map<String, dynamic>? metadata, String key) {
    final value = metadata?[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
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
