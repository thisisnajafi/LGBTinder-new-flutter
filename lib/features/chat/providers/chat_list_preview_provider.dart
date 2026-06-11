import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/chat.dart';
import '../data/models/message.dart';
import '../utils/chat_message_preview.dart';
import 'chat_local_sync_provider.dart';
import 'chat_pusher_providers.dart';

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
  });

  ChatListPreviewItem copyWith({
    String? name,
    String? avatarUrl,
    String? lastMessage,
    String? lastMessageType,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isOnline,
    bool? isTyping,
    bool? isMuted,
  }) {
    return ChatListPreviewItem(
      id: id,
      chatId: chatId,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
      isTyping: isTyping ?? this.isTyping,
      isMuted: isMuted ?? this.isMuted,
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
      };

  factory ChatListPreviewItem.fromChat(Chat chat) {
    return ChatListPreviewItem(
      id: chat.userId,
      chatId: chat.id,
      name: chat.displayName,
      avatarUrl: chat.primaryImageUrl,
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
  @override
  ChatListPreviewState build() => const ChatListPreviewState();

  void seedFromChats(List<Chat> chats) {
    state = ChatListPreviewState(
      items: chats.map(ChatListPreviewItem.fromChat).toList(),
      isSeeded: true,
    );
  }

  void seedFromMaps(List<Map<String, dynamic>> maps) {
    state = ChatListPreviewState(
      items: maps.map(_fromMap).toList(),
      isSeeded: true,
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
      avatarUrl: map['avatar_url']?.toString(),
      lastMessage: map['last_message']?.toString() ?? '',
      lastMessageType: map['last_message_type']?.toString(),
      lastMessageTime: map['last_message_time'] is DateTime
          ? map['last_message_time'] as DateTime
          : DateTime.tryParse(map['last_message_time']?.toString() ?? ''),
      unreadCount: map['unread_count'] as int? ?? 0,
      isOnline: map['is_online'] == true,
      isTyping: map['is_typing'] == true,
      isMuted: map['is_muted'] == true,
    );
  }

  void applyIncomingMessage(
    Message message, {
    required int currentUserId,
    int? activeChatPeerId,
  }) {
    if (currentUserId <= 0) return;

    final peerId = message.senderId == currentUserId
        ? message.receiverId
        : message.senderId;
    if (peerId <= 0) return;

    final previewText = _previewTextForMessage(message);
    final isIncoming = message.senderId != currentUserId;
    final inActiveChat = activeChatPeerId != null && activeChatPeerId == peerId;

    final existingIndex =
        state.items.indexWhere((item) => item.id == peerId);
    ChatListPreviewItem updated;
    if (existingIndex >= 0) {
      final existing = state.items[existingIndex];
      updated = existing.copyWith(
        lastMessage: previewText,
        lastMessageType: message.messageType,
        lastMessageTime: message.createdAt,
        unreadCount: inActiveChat
            ? 0
            : isIncoming
                ? existing.unreadCount + 1
                : existing.unreadCount,
      );
    } else {
      updated = ChatListPreviewItem(
        id: peerId,
        chatId: 0,
        name: _nameFromSenderPayload(message),
        lastMessage: previewText,
        lastMessageType: message.messageType,
        lastMessageTime: message.createdAt,
        unreadCount: inActiveChat || !isIncoming ? 0 : 1,
      );
    }

    final others = state.items.where((item) => item.id != peerId).toList();
    state = state.copyWith(
      items: [updated, ...others],
      isSeeded: true,
    );
  }

  void clearUnreadForPeer(int peerUserId) {
    final index = state.items.indexWhere((item) => item.id == peerUserId);
    if (index < 0) return;
    final updated = state.items[index].copyWith(unreadCount: 0);
    final items = [...state.items];
    items[index] = updated;
    state = state.copyWith(items: items);
  }

  void bumpOutgoingMessage({
    required int peerUserId,
    required String previewText,
    String? lastMessageType,
    required DateTime timestamp,
  }) {
    final index = state.items.indexWhere((item) => item.id == peerUserId);
    if (index < 0) return;
    final updated = state.items[index].copyWith(
      lastMessage: previewText,
      lastMessageType: lastMessageType,
      lastMessageTime: timestamp,
      unreadCount: 0,
    );
    final others = state.items.where((item) => item.id != peerUserId).toList();
    state = state.copyWith(items: [updated, ...others]);
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
      final name = nested['name']?.toString().trim();
      if (name != null && name.isNotEmpty) return name;
    }
    return 'User';
  }

  String _previewTextForMessage(Message message) {
    return chatMessagePreviewText(
      message: message.message,
      messageType: message.messageType,
      mediaDuration: message.mediaDuration,
    );
  }
}

/// Wires Pusher message + read events into [chatListPreviewProvider].
final chatListSyncProvider = Provider<void>((ref) {
  ref.watch(chatLocalSyncProvider);
  ref.watch(chatPusherLifecycleProvider);

  final pusher = ref.watch(pusherWebSocketServiceProvider);
  final preview = ref.read(chatListPreviewProvider.notifier);

  final messageSub = pusher.messageStream.listen((message) {
    final lifecycle = ref.read(chatPusherLifecycleProvider);
    final userId = lifecycle.userId ?? pusher.currentUserId;
    if (userId == null || userId <= 0) return;

    preview.applyIncomingMessage(
      message,
      currentUserId: userId,
      activeChatPeerId: lifecycle.activePeerUserId,
    );
  });

  final readSub = pusher.readReceiptStream.listen((event) {
    final lifecycle = ref.read(chatPusherLifecycleProvider);
    final userId = lifecycle.userId ?? pusher.currentUserId;
    if (userId == null || userId <= 0) return;
    if (event.readerId == userId && event.readerId > 0) {
      // Current user read messages — clear unread for the peer in the conversation.
      final peerId = lifecycle.activePeerUserId;
      if (peerId != null && peerId > 0) {
        preview.clearUnreadForPeer(peerId);
      }
    }
  });

  ref.onDispose(() {
    unawaited(messageSub.cancel());
    unawaited(readSub.cancel());
  });
});
