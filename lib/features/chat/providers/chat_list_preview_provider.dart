import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/chat.dart';
import '../data/models/message.dart';
import 'chat_local_sync_provider.dart';
import 'chat_pusher_providers.dart';

/// Row shown on the chat list (matches [ChatListPage] map shape).
class ChatListPreviewItem {
  final int id;
  final int chatId;
  final String name;
  final String? avatarUrl;
  final String lastMessage;
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
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isTyping = false,
    this.isMuted = false,
  });

  ChatListPreviewItem copyWith({
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isOnline,
    bool? isTyping,
    bool? isMuted,
  }) {
    return ChatListPreviewItem(
      id: id,
      chatId: chatId,
      name: name,
      avatarUrl: avatarUrl,
      lastMessage: lastMessage ?? this.lastMessage,
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
        'last_message_time': lastMessageTime,
        'unread_count': unreadCount,
        'is_online': isOnline,
        'is_typing': isTyping,
        'is_muted': isMuted,
      };

  factory ChatListPreviewItem.fromChat(Chat chat) {
    final name = chat.lastName != null
        ? '${chat.firstName} ${chat.lastName}'
        : chat.firstName;
    return ChatListPreviewItem(
      id: chat.userId,
      chatId: chat.id,
      name: name,
      avatarUrl: chat.primaryImageUrl,
      lastMessage: chat.lastMessage?.message ?? '',
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

  ChatListPreviewItem _fromMap(Map<String, dynamic> map) {
    return ChatListPreviewItem(
      id: map['id'] as int? ?? 0,
      chatId: map['chat_id'] as int? ?? 0,
      name: map['name']?.toString() ?? 'User',
      avatarUrl: map['avatar_url']?.toString(),
      lastMessage: map['last_message']?.toString() ?? '',
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
        name: 'User',
        lastMessage: previewText,
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
    required DateTime timestamp,
  }) {
    final index = state.items.indexWhere((item) => item.id == peerUserId);
    if (index < 0) return;
    final updated = state.items[index].copyWith(
      lastMessage: previewText,
      lastMessageTime: timestamp,
      unreadCount: 0,
    );
    final others = state.items.where((item) => item.id != peerUserId).toList();
    state = state.copyWith(items: [updated, ...others]);
  }

  String _previewTextForMessage(Message message) {
    switch (message.messageType) {
      case 'sticker':
        return 'Sticker';
      case 'image':
      case 'disappearing_image':
      case 'self_destruct':
        return 'Photo';
      case 'voice':
        return 'Voice message';
      case 'profile_link':
        return 'Shared a profile';
      case 'video':
        return 'Video';
      default:
        final text = message.message.trim();
        return text.isNotEmpty ? text : 'Message';
    }
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
