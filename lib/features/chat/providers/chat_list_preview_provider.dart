import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/peer_avatar_cache.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/utils/media_url.dart';
import '../../profile/presentation/widgets/own_profile/profile_photo_utils.dart';
import '../../profile/providers/profile_providers.dart';
import '../data/models/chat.dart';
import '../data/models/message.dart';
import '../utils/chat_list_incoming_apply.dart';
import '../utils/chat_message_preview.dart';
import '../../../shared/services/pusher_websocket_service.dart';
import 'chat_local_sync_provider.dart';
import 'chat_pusher_providers.dart';
import 'chat_providers.dart';
import 'user_presence_cache_provider.dart';

DateTime? _lastListCatchUpAt;

Future<void> catchUpChatListFromApi(Ref ref) async {
  final now = DateTime.now();
  if (_lastListCatchUpAt != null &&
      now.difference(_lastListCatchUpAt!) < const Duration(seconds: 2)) {
    return;
  }
  _lastListCatchUpAt = now;
  try {
    final chats =
        await ref.read(chatServiceProvider).getChatUsers(forceRefresh: true);
    await ref.read(chatLocalRepositoryProvider).replaceAllConversations(chats);
    ref.read(chatListPreviewProvider.notifier).seedFromChats(chats);
  } catch (e) {
    AppLogger.warning(
      'Chat list catch-up from API failed',
      tag: 'Chat',
      error: e,
    );
  }
}

Future<void> resyncPeerPreviewAfterMessageChange(
  Ref ref, {
  required int? conversationId,
  required int messageId,
  bool expired = false,
  bool forEveryone = false,
}) async {
  final localRepo = ref.read(chatLocalRepositoryProvider);
  var peerId = await localRepo.otherUserIdForServerMessage(messageId);
  peerId ??= conversationId == null
      ? null
      : await localRepo.otherUserIdForConversation(conversationId);
  if (peerId == null || peerId <= 0) {
    await catchUpChatListFromApi(ref);
    return;
  }

  if (forEveryone) {
    await localRepo.markMessageDeletedByServerId(messageId);
  } else if (!expired) {
    await localRepo.deleteMessageByServerId(messageId);
  }

  final latest = await localRepo.getMessagesForOtherUser(
    peerId,
    limit: 1,
    excludeDeleted: !forEveryone,
  );
  final message = latest.isEmpty ? null : latest.first;
  final isExpired = expired && message != null && message.id == messageId;
  final preview = message == null
      ? ''
      : chatMessagePreviewText(
          message: message.message,
          messageType: message.messageType,
          mediaDuration: message.mediaDuration,
          isExpired: isExpired,
          isDeleted: message.isDeleted,
        );

  await localRepo.patchConversationPreview(
    otherUserId: peerId,
    lastMessagePreview: preview,
    lastMessageAt: message?.createdAt,
  );
  ref.read(chatListPreviewProvider.notifier).applyLatestPreview(
        peerUserId: peerId,
        lastMessage: preview,
        lastMessageType: isExpired ? 'expired' : message?.messageType,
        lastMessageTime: message?.createdAt,
        lastMessageFromMe: message != null && message.senderId != peerId,
        lastMessageIsRead: message?.isRead ?? false,
        lastMessageIsDelivered: message?.isDelivered ?? message?.isRead ?? false,
        lastMessageId: message?.id ?? 0,
      );
}

/// Total unread chats (conversations with unread messages) for bottom-nav badge.
final unreadChatCountProvider = Provider<int>((ref) {
  final preview = ref.watch(chatListPreviewProvider);
  if (preview.isSeeded) {
    return preview.items.where((item) => item.unreadCount > 0).length;
  }
  return ref.watch(unreadChatCountAsyncProvider).valueOrNull ?? 0;
});

/// Row shown on the chat list (matches [ChatListPage] map shape).
class ChatListPreviewItem {
  final int id;
  final int chatId;
  final String name;
  final String? avatarUrl;
  final String lastMessage;
  final String? lastMessageType;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final bool isTyping;
  final bool isMuted;
  final bool isPinned;
  final bool lastMessageFromMe;
  final bool lastMessageIsRead;
  final bool lastMessageIsDelivered;
  final int lastMessageId;
  final DateTime? lastSeenAt;

  const ChatListPreviewItem({
    required this.id,
    required this.chatId,
    required this.name,
    this.avatarUrl,
    this.lastMessage = '',
    this.lastMessageType,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isTyping = false,
    this.isMuted = false,
    this.isPinned = false,
    this.lastMessageFromMe = false,
    this.lastMessageIsRead = false,
    this.lastMessageIsDelivered = false,
    this.lastMessageId = 0,
    this.lastSeenAt,
  });

  ChatListPreviewItem copyWith({
    int? chatId,
    String? name,
    String? avatarUrl,
    String? lastMessage,
    String? lastMessageType,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isOnline,
    bool? isTyping,
    bool? isMuted,
    bool? isPinned,
    bool? lastMessageFromMe,
    bool? lastMessageIsRead,
    bool? lastMessageIsDelivered,
    int? lastMessageId,
    DateTime? lastSeenAt,
  }) {
    return ChatListPreviewItem(
      id: id,
      chatId: chatId ?? this.chatId,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
      isTyping: isTyping ?? this.isTyping,
      isMuted: isMuted ?? this.isMuted,
      isPinned: isPinned ?? this.isPinned,
      lastMessageFromMe: lastMessageFromMe ?? this.lastMessageFromMe,
      lastMessageIsRead: lastMessageIsRead ?? this.lastMessageIsRead,
      lastMessageIsDelivered:
          lastMessageIsDelivered ?? this.lastMessageIsDelivered,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'chat_id': chatId,
        'name': name,
        'avatar_url': avatarUrl,
        'last_message': lastMessage,
        if (lastMessageType != null) 'last_message_type': lastMessageType,
        'last_message_time': lastMessageTime,
        'unread_count': unreadCount,
        'is_online': isOnline,
        'is_typing': isTyping,
        'is_muted': isMuted,
        'is_pinned': isPinned,
        'last_message_from_me': lastMessageFromMe,
        'last_message_is_read': lastMessageIsRead,
        'last_message_is_delivered': lastMessageIsDelivered,
        'last_message_id': lastMessageId,
        'last_seen': lastSeenAt,
      };

  factory ChatListPreviewItem.fromChat(Chat chat) {
    return ChatListPreviewItem(
      id: chat.userId,
      chatId: chat.id,
      name: chat.displayName,
      avatarUrl: MediaUrl.resolve(chat.primaryImageUrl),
      lastMessage: chatMessagePreviewText(
        message: chat.lastMessage?.message,
        messageType: chat.lastMessage?.messageType,
        mediaDuration: chat.lastMessage?.mediaDuration,
      ),
      lastMessageType: chat.lastMessage?.messageType,
      lastMessageTime: chat.lastMessageAt ?? chat.lastMessage?.createdAt,
      unreadCount: chat.unreadCount,
      isOnline: chat.isOnline,
      isTyping: chat.isTyping,
      isMuted: chat.isMuted,
      isPinned: chat.isPinned,
      lastMessageFromMe:
          chat.lastMessage != null && chat.lastMessage!.senderId != chat.userId,
      lastMessageIsRead: chat.lastMessage?.isRead ?? false,
      lastMessageIsDelivered: chat.lastMessage?.isDelivered ??
          chat.lastMessage?.isRead ??
          false,
      lastMessageId: chat.lastMessage?.id ?? 0,
      lastSeenAt: chat.lastSeen,
    );
  }
}

class ChatListPreviewState {
  final List<ChatListPreviewItem> items;
  final bool isSeeded;

  const ChatListPreviewState({
    this.items = const [],
    this.isSeeded = false,
  });

  ChatListPreviewState copyWith({
    List<ChatListPreviewItem>? items,
    bool? isSeeded,
  }) {
    return ChatListPreviewState(
      items: items ?? this.items,
      isSeeded: isSeeded ?? this.isSeeded,
    );
  }
}

/// Live chat list previews (last message + unread) updated via Pusher.
final chatListPreviewProvider =
    NotifierProvider<ChatListPreviewNotifier, ChatListPreviewState>(
  ChatListPreviewNotifier.new,
);

class ChatListPreviewNotifier extends Notifier<ChatListPreviewState> {
  final Set<int> _hydratingPeerIds = <int>{};

  @override
  ChatListPreviewState build() {
    ChatListPresencePeersBridge.getPeerIds = () => state.items
        .map((item) => item.id)
        .where((id) => id > 0)
        .toSet();
    ref.onDispose(() {
      ChatListPresencePeersBridge.getPeerIds = null;
    });
    return const ChatListPreviewState();
  }

  void seedFromChats(List<Chat> chats) {
    _seedMerged(chats.map(ChatListPreviewItem.fromChat).toList());
  }

  void seedFromItems(List<ChatListPreviewItem> items) {
    _seedMerged(items);
  }

  void seedFromMaps(List<Map<String, dynamic>> maps) {
    _seedMerged(maps.map(_fromMap).toList());
  }

  void _seedMerged(List<ChatListPreviewItem> apiItems) {
    state = ChatListPreviewState(
      items: _mergeLivePreview(apiItems: apiItems, liveItems: state.items),
      isSeeded: true,
    );
  }

  /// Keep a newer Pusher preview when the chats API is still stale (CHAT-RT-006).
  List<ChatListPreviewItem> _mergeLivePreview({
    required List<ChatListPreviewItem> apiItems,
    required List<ChatListPreviewItem> liveItems,
  }) {
    if (liveItems.isEmpty) return apiItems;

    final liveById = {for (final item in liveItems) item.id: item};
    final merged = <ChatListPreviewItem>[];
    final seen = <int>{};

    for (final api in apiItems) {
      seen.add(api.id);
      merged.add(_preferFresherPreview(api: api, live: liveById[api.id]));
    }
    for (final live in liveItems) {
      if (seen.add(live.id)) merged.add(live);
    }

    merged.sort(_comparePinnedThenTime);
    return merged;
  }

  ChatListPreviewItem _preferFresherPreview({
    required ChatListPreviewItem api,
    ChatListPreviewItem? live,
  }) {
    if (live == null) return api;

    final liveIsNewer = live.lastMessageTime != null &&
        ChatListIncomingApply.shouldReplacePreview(
          messageId: live.lastMessageId,
          createdAt: live.lastMessageTime!,
          lastMessageId: api.lastMessageId,
          lastMessageTime: api.lastMessageTime,
        );

    final name = api.name == ChatListIncomingApply.placeholderName
        ? live.name
        : api.name;
    final avatar =
        (api.avatarUrl == null || api.avatarUrl!.trim().isEmpty)
            ? live.avatarUrl
            : api.avatarUrl;

    if (!liveIsNewer) {
      return api.copyWith(name: name, avatarUrl: avatar);
    }

    return live.copyWith(
      chatId: live.chatId > 0 ? live.chatId : api.chatId,
      name: live.name == ChatListIncomingApply.placeholderName ? name : live.name,
      avatarUrl: (live.avatarUrl == null || live.avatarUrl!.trim().isEmpty)
          ? avatar
          : live.avatarUrl,
      isOnline: api.isOnline,
      isMuted: api.isMuted,
      isPinned: api.isPinned,
      lastSeenAt: live.lastSeenAt ?? api.lastSeenAt,
    );
  }

  String _nameFromMap(Map<String, dynamic> map) {
    final name = map['name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;
    final first = map['first_name']?.toString().trim() ?? '';
    final last = map['last_name']?.toString().trim() ?? '';
    if (first.isNotEmpty) {
      return last.isNotEmpty ? '$first $last' : first;
    }
    return 'User';
  }

  ChatListPreviewItem _fromMap(Map<String, dynamic> map) {
    return ChatListPreviewItem(
      id: map['id'] as int? ?? 0,
      chatId: map['chat_id'] as int? ?? 0,
      name: _nameFromMap(map),
      avatarUrl: MediaUrl.resolve(map['avatar_url']?.toString()),
      lastMessage: map['last_message']?.toString() ?? '',
      lastMessageType: map['last_message_type']?.toString(),
      lastMessageTime: map['last_message_time'] is DateTime
          ? map['last_message_time'] as DateTime
          : DateTime.tryParse(map['last_message_time']?.toString() ?? ''),
      unreadCount: map['unread_count'] as int? ?? 0,
      isOnline: map['is_online'] == true || map['is_online'] == 1,
      isTyping: map['is_typing'] == true,
      isMuted: map['is_muted'] == true,
      isPinned: map['is_pinned'] == true || map['is_pinned'] == 1,
      lastMessageFromMe: map['last_message_from_me'] == true,
      lastMessageIsRead: map['last_message_is_read'] == true,
      lastMessageIsDelivered: map['last_message_is_delivered'] == true,
      lastMessageId: map['last_message_id'] as int? ?? 0,
      lastSeenAt: map['last_seen'] is DateTime
          ? map['last_seen'] as DateTime
          : DateTime.tryParse(
              map['last_seen']?.toString() ??
                  map['last_seen_at']?.toString() ??
                  '',
            ),
    );
  }

  void applyIncomingMessage(
    Message message, {
    required int currentUserId,
    int? activeChatPeerId,
  }) {
    if (currentUserId <= 0) return;

    final peerId = ChatListIncomingApply.peerId(
      senderId: message.senderId,
      receiverId: message.receiverId,
      currentUserId: currentUserId,
    );
    if (peerId <= 0) return;

    final isIncoming = ChatListIncomingApply.isIncoming(
      senderId: message.senderId,
      currentUserId: currentUserId,
    );
    final inActiveChat = ChatListIncomingApply.isOpenThread(
      peerId: peerId,
      activeChatPeerId: activeChatPeerId,
    );
    final previewText = _previewTextForMessage(message);
    final cachedAvatar = ref.read(peerAvatarCacheProvider)[peerId];

    final existingIndex = state.items.indexWhere((item) => item.id == peerId);
    final existing = existingIndex >= 0 ? state.items[existingIndex] : null;

    if (existing != null &&
        !ChatListIncomingApply.shouldReplacePreview(
          messageId: message.id,
          createdAt: message.createdAt,
          lastMessageId: existing.lastMessageId,
          lastMessageTime: existing.lastMessageTime,
        )) {
      return;
    }

    final payloadName = isIncoming ? _nameFromSenderPayload(message) : null;
    final payloadAvatar = isIncoming ? _avatarFromSenderPayload(message) : null;
    final name = ChatListIncomingApply.resolveName(
      isIncoming: isIncoming,
      payloadName: payloadName,
      existingName: existing?.name,
    );
    final avatar = ChatListIncomingApply.resolveAvatar(
      isIncoming: isIncoming,
      payloadAvatar: payloadAvatar,
      existingAvatar: existing?.avatarUrl,
      cachedAvatar: cachedAvatar,
    );
    final unread = ChatListIncomingApply.nextUnreadCount(
      currentUnread: existing?.unreadCount ?? 0,
      increment: ChatListIncomingApply.shouldIncrementUnread(
        isIncoming: isIncoming,
        isOpenThread: inActiveChat,
      ),
      isOpenThread: inActiveChat,
    );

    final conversationId = message.conversationId;
    final ChatListPreviewItem updated;
    if (existing != null) {
      updated = existing.copyWith(
        chatId: (conversationId != null && conversationId > 0)
            ? conversationId
            : existing.chatId,
        name: name,
        avatarUrl: avatar,
        lastMessage: previewText,
        lastMessageType: message.messageType,
        lastMessageTime: message.createdAt,
        lastMessageFromMe: !isIncoming,
        lastMessageIsRead: message.isRead,
        lastMessageIsDelivered: message.isDelivered || message.isRead,
        lastMessageId: message.id,
        unreadCount: unread,
      );
    } else {
      updated = ChatListPreviewItem(
        id: peerId,
        chatId: conversationId ?? 0,
        name: name,
        avatarUrl: avatar,
        lastMessage: previewText,
        lastMessageType: message.messageType,
        lastMessageTime: message.createdAt,
        lastMessageFromMe: !isIncoming,
        lastMessageIsRead: message.isRead,
        lastMessageIsDelivered: message.isDelivered || message.isRead,
        lastMessageId: message.id,
        unreadCount: unread,
      );
    }

    final others = state.items.where((item) => item.id != peerId).toList();
    final next = [updated, ...others]..sort(_comparePinnedThenTime);
    state = state.copyWith(
      items: next,
      isSeeded: true,
    );

    if (ChatListIncomingApply.needsHydrate(name: name, avatarUrl: avatar)) {
      unawaited(_hydrateUnknownPeer(peerId));
    }
  }

  Future<void> _hydrateUnknownPeer(int peerId) async {
    if (peerId <= 0 || !_hydratingPeerIds.add(peerId)) return;
    try {
      final cachedAvatar = ref.read(peerAvatarCacheProvider)[peerId];
      if (cachedAvatar != null && cachedAvatar.trim().isNotEmpty) {
        updatePeerAppearance(peerId, avatarUrl: cachedAvatar);
      }

      if (!ref.exists(chatListPreviewProvider)) return;
      final profile =
          await ref.read(profileServiceProvider).getUserProfile(peerId);
      if (!ref.exists(chatListPreviewProvider)) return;

      final first = profile.firstName.trim();
      final last = profile.lastName.trim();
      final displayName = first.isEmpty
          ? last
          : (last.isEmpty ? first : '$first $last');
      final primary = primaryProfileImage(profile.images);
      final avatar = MediaUrl.resolve(
        primary?.avatarDisplayUrl ?? primary?.imageUrl,
      );

      if (displayName.isNotEmpty || avatar != null) {
        updatePeerAppearance(
          peerId,
          name: displayName.isNotEmpty ? displayName : null,
          avatarUrl: avatar,
        );
      }
      if (avatar != null) {
        try {
          unawaited(
            ref.read(peerAvatarCacheProvider.notifier).remember(peerId, avatar),
          );
        } catch (e) {
          AppLogger.warning(
            'Peer avatar cache remember failed',
            tag: 'Chat',
            error: e,
          );
        }
      }
    } catch (e) {
      AppLogger.warning(
        'Failed to hydrate chat list peer appearance',
        tag: 'ChatListPreview',
        error: e,
      );
    } finally {
      _hydratingPeerIds.remove(peerId);
    }
  }

  void updatePeerAppearance(
    int peerUserId, {
    String? name,
    String? avatarUrl,
  }) {
    if (peerUserId <= 0) return;
    final index = state.items.indexWhere((item) => item.id == peerUserId);
    if (index < 0) return;
    final existing = state.items[index];
    final items = [...state.items];
    items[index] = existing.copyWith(
      name: name,
      avatarUrl: avatarUrl,
    );
    state = state.copyWith(items: items);
  }

  /// Rewind or replace the list preview without bumping the row to the top.
  void applyLatestPreview({
    required int peerUserId,
    required String lastMessage,
    String? lastMessageType,
    DateTime? lastMessageTime,
    bool? lastMessageFromMe,
    bool? lastMessageIsRead,
    bool? lastMessageIsDelivered,
    int? lastMessageId,
  }) {
    final index = state.items.indexWhere((item) => item.id == peerUserId);
    if (index < 0) return;
    final items = [...state.items];
    items[index] = items[index].copyWith(
      lastMessage: lastMessage,
      lastMessageType: lastMessageType,
      lastMessageTime: lastMessageTime,
      lastMessageFromMe: lastMessageFromMe,
      lastMessageIsRead: lastMessageIsRead,
      lastMessageIsDelivered: lastMessageIsDelivered,
      lastMessageId: lastMessageId,
    );
    state = state.copyWith(items: items);
  }

  void applyEditedMessage({
    required int peerUserId,
    required int messageId,
    required String previewText,
  }) {
    final index = state.items.indexWhere((item) => item.id == peerUserId);
    if (index < 0) return;
    final existing = state.items[index];
    if (existing.lastMessageId != 0 && existing.lastMessageId != messageId) {
      return;
    }
    final items = [...state.items];
    items[index] = existing.copyWith(lastMessage: previewText);
    state = state.copyWith(items: items);
  }

  void applyPeerRead({
    required int peerUserId,
    required List<int> messageIds,
  }) {
    final index = state.items.indexWhere((item) => item.id == peerUserId);
    if (index < 0) return;
    final existing = state.items[index];
    if (!existing.lastMessageFromMe) return;
    if (messageIds.isNotEmpty &&
        existing.lastMessageId > 0 &&
        !messageIds.contains(existing.lastMessageId)) {
      return;
    }
    final items = [...state.items];
    items[index] = existing.copyWith(
      lastMessageIsRead: true,
      lastMessageIsDelivered: true,
    );
    state = state.copyWith(items: items);
  }

  void applyPeerDelivered({
    required int peerUserId,
    required List<int> messageIds,
  }) {
    final index = state.items.indexWhere((item) => item.id == peerUserId);
    if (index < 0) return;
    final existing = state.items[index];
    if (!existing.lastMessageFromMe || existing.lastMessageIsRead) return;
    if (messageIds.isNotEmpty &&
        existing.lastMessageId > 0 &&
        !messageIds.contains(existing.lastMessageId)) {
      return;
    }
    final items = [...state.items];
    items[index] = existing.copyWith(lastMessageIsDelivered: true);
    state = state.copyWith(items: items);
  }

  void clearUnreadForPeer(int peerUserId) {
    final index = state.items.indexWhere((item) => item.id == peerUserId);
    if (index < 0) return;
    if (state.items[index].unreadCount == 0) return;
    final updated = state.items[index].copyWith(unreadCount: 0);
    final items = [...state.items];
    items[index] = updated;
    state = state.copyWith(items: items);
  }

  void setMuted(int peerUserId, bool muted) {
    final index = state.items.indexWhere((item) => item.id == peerUserId);
    if (index < 0) return;
    final items = [...state.items];
    items[index] = items[index].copyWith(isMuted: muted);
    state = state.copyWith(items: items);
  }

  void setPinned(int peerUserId, bool pinned) {
    final index = state.items.indexWhere((item) => item.id == peerUserId);
    if (index < 0) return;
    final items = [...state.items];
    items[index] = items[index].copyWith(isPinned: pinned);
    items.sort(_comparePinnedThenTime);
    state = state.copyWith(items: items);
  }

  static int _comparePinnedThenTime(
    ChatListPreviewItem a,
    ChatListPreviewItem b,
  ) {
    if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
    final at = a.lastMessageTime;
    final bt = b.lastMessageTime;
    if (at == null && bt == null) return 0;
    if (at == null) return 1;
    if (bt == null) return -1;
    return bt.compareTo(at);
  }

  void bumpOutgoingMessage({
    required int peerUserId,
    required String previewText,
    String? lastMessageType,
    required DateTime timestamp,
    int? lastMessageId,
    bool lastMessageIsDelivered = false,
    bool lastMessageIsRead = false,
  }) {
    final index = state.items.indexWhere((item) => item.id == peerUserId);
    if (index < 0) return;
    final updated = state.items[index].copyWith(
      lastMessage: previewText,
      lastMessageType: lastMessageType,
      lastMessageTime: timestamp,
      lastMessageFromMe: true,
      lastMessageIsRead: lastMessageIsRead,
      lastMessageIsDelivered: lastMessageIsDelivered,
      lastMessageId: lastMessageId ?? 0,
      unreadCount: 0,
    );
    final others = state.items.where((item) => item.id != peerUserId).toList();
    state = state.copyWith(
      items: [updated, ...others]..sort(_comparePinnedThenTime),
    );
  }

  /// Insert or promote a peer after superlike / new chat access (before next API refresh).
  void upsertPeer({
    required int peerUserId,
    String? name,
    String? avatarUrl,
    String? lastMessage,
    DateTime? lastMessageTime,
  }) {
    if (peerUserId <= 0) return;

    final timestamp = lastMessageTime ?? DateTime.now();
    final preview = lastMessage?.trim().isNotEmpty == true
        ? lastMessage!.trim()
        : '⭐ Superliked';

    final index = state.items.indexWhere((item) => item.id == peerUserId);
    final ChatListPreviewItem updated;
    if (index >= 0) {
      final existing = state.items[index];
      updated = existing.copyWith(
        name: name?.trim().isNotEmpty == true ? name!.trim() : existing.name,
        avatarUrl: avatarUrl ?? existing.avatarUrl,
        lastMessage: preview,
        lastMessageTime: timestamp,
      );
    } else {
      updated = ChatListPreviewItem(
        id: peerUserId,
        chatId: peerUserId,
        name: name?.trim().isNotEmpty == true ? name!.trim() : 'User',
        avatarUrl: avatarUrl,
        lastMessage: preview,
        lastMessageTime: timestamp,
      );
    }

    final others = state.items.where((item) => item.id != peerUserId).toList();
    state = ChatListPreviewState(
      items: [updated, ...others],
      isSeeded: true,
    );
  }

  void clearSeed() {
    state = const ChatListPreviewState();
  }

  /// Updates the Online filter flag. Same-status heartbeats are ignored so
  /// the list does not rebuild — [ChatListItem] watches presence cache instead.
  void applyPeerPresence({
    required int peerUserId,
    required bool isOnline,
    DateTime? lastSeenAt,
  }) {
    if (peerUserId <= 0) return;

    final index = state.items.indexWhere((item) => item.id == peerUserId);
    if (index < 0) return;

    final existing = state.items[index];
    if (existing.isOnline == isOnline) return;

    final items = [...state.items];
    items[index] = existing.copyWith(
      isOnline: isOnline,
      lastSeenAt: lastSeenAt ?? existing.lastSeenAt,
    );
    state = state.copyWith(items: items);
  }

  String _nameFromSenderPayload(Message message) {
    final meta = message.metadata;
    if (meta == null) return 'User';
    for (final key in ['sender_name', 'user_name', 'name', 'display_name']) {
      final value = meta[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    final sender = meta['sender'];
    if (sender is Map) {
      final nested = Map<String, dynamic>.from(sender);
      final first = nested['first_name']?.toString().trim() ?? '';
      final last = nested['last_name']?.toString().trim() ?? '';
      if (first.isNotEmpty) {
        return last.isNotEmpty ? '$first $last' : first;
      }
      final name = nested['display_name']?.toString().trim() ??
          nested['name']?.toString().trim();
      if (name != null && name.isNotEmpty) return name;
    }
    return 'User';
  }

  String? _avatarFromSenderPayload(Message message) {
    final meta = message.metadata;
    if (meta == null) return null;
    final direct = meta['sender_avatar_url']?.toString().trim();
    if (direct != null && direct.isNotEmpty) {
      return MediaUrl.resolve(direct);
    }
    final nested = meta['sender'];
    if (nested is Map) {
      return MediaUrl.resolve(nested['avatar_url']?.toString());
    }
    return MediaUrl.resolve(meta['avatar_url']?.toString());
  }

  String _previewTextForMessage(Message message) {
    return chatMessagePreviewText(
      message: message.message,
      messageType: message.messageType,
      mediaDuration: message.mediaDuration,
    );
  }
}

/// Wires Pusher message + read + presence events into [chatListPreviewProvider].
final chatListSyncProvider = Provider<void>((ref) {
  ref.watch(chatLocalSyncProvider);
  ref.watch(chatPusherLifecycleProvider);

  final pusher = ref.watch(pusherWebSocketServiceProvider);
  final preview = ref.read(chatListPreviewProvider.notifier);
  final presenceCache = ref.read(userPresenceCacheProvider.notifier);

  ref.listen(chatListPreviewProvider, (previous, next) {
    if (!next.isSeeded || next.items.isEmpty) return;
    final peerIds = next.items.map((item) => item.id).toSet();
    unawaited(pusher.syncUserStatusSubscriptions(peerIds));
  });

  final connectionSub = pusher.connectionStream.listen((status) {
    if (status != ConnectionStatus.connected) return;
    final next = ref.read(chatListPreviewProvider);
    if (next.isSeeded && next.items.isNotEmpty) {
      final peerIds = next.items.map((item) => item.id).toSet();
      unawaited(pusher.syncUserStatusSubscriptions(peerIds));
    }
    unawaited(catchUpChatListFromApi(ref));
  });

  final messageSub = pusher.messageStream.listen((message) {
    final lifecycle = ref.read(chatPusherLifecycleProvider);
    final userId = lifecycle.userId ?? pusher.currentUserId;
    if (userId == null || userId <= 0) return;

    preview.applyIncomingMessage(
      message,
      currentUserId: userId,
      activeChatPeerId: lifecycle.activePeerUserId,
    );
    if (message.receiverId == userId &&
        message.id > 0 &&
        !message.isDelivered &&
        !message.isRead) {
      unawaited(
        ref
            .read(chatServiceProvider)
            .markMessagesDelivered([message.id])
            .catchError((e) {
          AppLogger.warning(
            'Failed to ack messages as delivered',
            tag: 'ChatListSync',
            error: e,
          );
        }),
      );
    }
  });

  final readSub = pusher.readReceiptStream.listen((event) {
    final lifecycle = ref.read(chatPusherLifecycleProvider);
    final userId = lifecycle.userId ?? pusher.currentUserId;
    if (userId == null || userId <= 0) return;
    if (event.readerId == userId && event.readerId > 0) {
      // Current user read messages — clear unread for the peer in the conversation.
      final peerId = lifecycle.activePeerUserId;
      if (peerId != null && peerId > 0) {
        Future<void>(() => preview.clearUnreadForPeer(peerId));
      }
      return;
    }
    if (event.readerId > 0 && event.readerId != userId) {
      preview.applyPeerRead(
        peerUserId: event.readerId,
        messageIds: event.messageIds,
      );
    }
  });

  final deliveredSub = pusher.messageDeliveredStream.listen((event) {
    final lifecycle = ref.read(chatPusherLifecycleProvider);
    final userId = lifecycle.userId ?? pusher.currentUserId;
    if (userId == null || userId <= 0) return;
    if (event.recipientId <= 0 || event.recipientId == userId) return;
    preview.applyPeerDelivered(
      peerUserId: event.recipientId,
      messageIds: event.messageIds,
    );
  });

  final editedSub = pusher.messageEditedStream.listen((event) {
    final lifecycle = ref.read(chatPusherLifecycleProvider);
    final userId = lifecycle.userId ?? pusher.currentUserId;
    if (userId == null || userId <= 0) return;
    final message = event.message;
    final peerId = message == null
        ? null
        : (message.senderId == userId ? message.receiverId : message.senderId);
    if (peerId == null || peerId <= 0) return;
    preview.applyEditedMessage(
      peerUserId: peerId,
      messageId: event.messageId,
      previewText: chatMessagePreviewText(
        message: event.content,
        messageType: message?.messageType,
      ),
    );
  });

  final presenceSub = pusher.presenceStream.listen((event) {
    // Dot / last-seen copy live on ChatListItem via userPresenceCacheProvider
    // so heartbeats do not rebuild the messenger list (CHAT-MSG-005).
    presenceCache.apply(event);
  });

  final deletedSub = pusher.messageDeletedStream.listen((event) {
    unawaited(
      resyncPeerPreviewAfterMessageChange(
        ref,
        conversationId: event.conversationId,
        messageId: event.messageId,
        forEveryone: event.forEveryone,
      ),
    );
  });

  final expiredSub = pusher.messageExpiredStream.listen((event) {
    unawaited(
      resyncPeerPreviewAfterMessageChange(
        ref,
        conversationId: event.conversationId,
        messageId: event.messageId,
        expired: true,
      ),
    );
  });

  ref.onDispose(() {
    unawaited(messageSub.cancel());
    unawaited(readSub.cancel());
    unawaited(deliveredSub.cancel());
    unawaited(editedSub.cancel());
    unawaited(presenceSub.cancel());
    unawaited(connectionSub.cancel());
    unawaited(deletedSub.cancel());
    unawaited(expiredSub.cancel());
  });
});
