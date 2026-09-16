import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lgbtindernew/core/cache/peer_avatar_cache.dart';
import 'package:lgbtindernew/features/chat/data/models/chat.dart';
import 'package:lgbtindernew/features/chat/data/models/message.dart';
import 'package:lgbtindernew/features/chat/providers/chat_list_preview_provider.dart';
import 'package:lgbtindernew/features/chat/providers/chat_pusher_providers.dart';
import 'package:lgbtindernew/features/chat/utils/chat_message_preview.dart';

void main() {
  test('expired preview text is Expired', () {
    expect(
      chatMessagePreviewText(messageType: 'image', isExpired: true),
      'Expired',
    );
    expect(chatMessagePreviewText(messageType: 'expired'), 'Expired');
  });

  test('deleted preview text is the tombstone caption', () {
    expect(
      chatMessagePreviewText(message: 'Hello', isDeleted: true),
      'This message was deleted',
    );
  });

  test('system screenshot preview is Screenshot taken', () {
    expect(
      chatMessagePreviewText(
        messageType: 'system',
        message: 'screenshot',
      ),
      'Screenshot taken',
    );
  });

  test('fromChat toMap keeps outbound tick flags', () {
    final chat = Chat(
      id: 40,
      userId: 12,
      firstName: 'Alex',
      lastMessage: Message(
        id: 99,
        senderId: 7,
        receiverId: 12,
        message: 'hey',
        createdAt: DateTime(2026, 8, 22),
        isRead: true,
        isDelivered: true,
      ),
    );

    final map = ChatListPreviewItem.fromChat(chat).toMap();
    expect(map['last_message_from_me'], isTrue);
    expect(map['last_message_is_read'], isTrue);
    expect(map['last_message_is_delivered'], isTrue);
    expect(map['last_message_id'], 99);
  });

  test('fromChat keeps last-seen for empty presence copy', () {
    final seen = DateTime(2026, 9, 11, 8);
    final chat = Chat(
      id: 40,
      userId: 12,
      firstName: 'Alex',
      isOnline: false,
      lastSeen: seen,
    );

    final item = ChatListPreviewItem.fromChat(chat);
    expect(item.lastSeenAt, seen);
    expect(item.toMap()['last_seen'], seen);
  });

  test('seedFromItems marks the preview seeded without page maps', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(chatListPreviewProvider.notifier);
    notifier.seedFromItems(const [
      ChatListPreviewItem(id: 9, chatId: 40, name: 'Sam', lastMessage: 'hi'),
    ]);
    final state = container.read(chatListPreviewProvider);
    expect(state.isSeeded, isTrue);
    expect(state.items.single.id, 9);
    expect(state.items.single.toMap()['last_message'], 'hi');
  });

  test('applyPeerPresence skips same-status heartbeats', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(chatListPreviewProvider.notifier);
    notifier.seedFromMaps([
      {
        'id': 12,
        'name': 'Alex',
        'is_online': false,
        'last_message': 'hey',
      },
    ]);
    final first = container.read(chatListPreviewProvider);

    notifier.applyPeerPresence(peerUserId: 12, isOnline: false);
    expect(
      identical(container.read(chatListPreviewProvider), first),
      isTrue,
    );

    notifier.applyPeerPresence(peerUserId: 12, isOnline: true);
    expect(container.read(chatListPreviewProvider).items.single.isOnline, isTrue);
  });

  test('applyLatestPreview rewinds text without changing unread', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(chatListPreviewProvider.notifier);
    notifier.seedFromMaps([
      {
        'id': 12,
        'chat_id': 12,
        'name': 'Alex',
        'last_message': 'Photo',
        'last_message_type': 'image',
        'last_message_time': DateTime(2026, 8, 22),
        'unread_count': 3,
      },
    ]);

    notifier.applyLatestPreview(
      peerUserId: 12,
      lastMessage: 'hey',
      lastMessageType: 'text',
      lastMessageTime: DateTime(2026, 8, 21),
    );

    final item = container.read(chatListPreviewProvider).items.single;
    expect(item.lastMessage, 'hey');
    expect(item.lastMessageType, 'text');
    expect(item.unreadCount, 3);
  });

  test('seeded list exposes peer ids for Pusher reconnect', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(chatListPreviewProvider.notifier).seedFromMaps([
      {'id': 12, 'chat_id': 12, 'name': 'Alex'},
      {'id': 15, 'chat_id': 15, 'name': 'Sam'},
    ]);

    expect(ChatListPresencePeersBridge.getPeerIds?.call(), {12, 15});
  });

  test('peer MessageRead updates last outgoing ticks', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(chatListPreviewProvider.notifier);
    notifier.seedFromMaps([
      {
        'id': 12,
        'chat_id': 12,
        'name': 'Alex',
        'last_message': 'hey',
        'last_message_type': 'text',
        'last_message_time': DateTime(2026, 8, 22),
        'unread_count': 0,
        'last_message_from_me': true,
        'last_message_is_read': false,
        'last_message_is_delivered': true,
        'last_message_id': 99,
      },
    ]);

    notifier.applyPeerRead(peerUserId: 12, messageIds: const [99]);

    final item = container.read(chatListPreviewProvider).items.single;
    expect(item.lastMessageFromMe, isTrue);
    expect(item.lastMessageIsRead, isTrue);
    expect(item.lastMessageIsDelivered, isTrue);
  });

  test('peer MessageDelivered updates last outgoing ticks without read', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(chatListPreviewProvider.notifier);
    notifier.seedFromMaps([
      {
        'id': 12,
        'chat_id': 12,
        'name': 'Alex',
        'last_message': 'hey',
        'last_message_type': 'text',
        'last_message_time': DateTime(2026, 8, 22),
        'unread_count': 0,
        'last_message_from_me': true,
        'last_message_is_read': false,
        'last_message_is_delivered': false,
        'last_message_id': 99,
      },
    ]);

    notifier.applyPeerDelivered(peerUserId: 12, messageIds: const [99]);

    final item = container.read(chatListPreviewProvider).items.single;
    expect(item.lastMessageFromMe, isTrue);
    expect(item.lastMessageIsDelivered, isTrue);
    expect(item.lastMessageIsRead, isFalse);
  });

  test('applyPeerDelivered skips when last message id is not in the event', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(chatListPreviewProvider.notifier);
    notifier.seedFromMaps([
      {
        'id': 12,
        'chat_id': 12,
        'name': 'Alex',
        'last_message_from_me': true,
        'last_message_is_read': false,
        'last_message_is_delivered': false,
        'last_message_id': 99,
      },
    ]);

    notifier.applyPeerDelivered(peerUserId: 12, messageIds: const [88]);

    expect(
      container.read(chatListPreviewProvider).items.single.lastMessageIsDelivered,
      isFalse,
    );
  });

  test('applyEditedMessage updates preview text for last message', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(chatListPreviewProvider.notifier);
    notifier.seedFromMaps([
      {
        'id': 12,
        'chat_id': 12,
        'name': 'Alex',
        'last_message': 'hey',
        'last_message_type': 'text',
        'last_message_id': 99,
      },
    ]);

    notifier.applyEditedMessage(
      peerUserId: 12,
      messageId: 99,
      previewText: 'hello edited',
    );

    expect(
      container.read(chatListPreviewProvider).items.single.lastMessage,
      'hello edited',
    );
  });

  test('first-ever incoming row uses sender name and avatar', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(chatListPreviewProvider.notifier);
    notifier.applyIncomingMessage(
      Message(
        id: 44,
        senderId: 12,
        receiverId: 99,
        message: 'Hi',
        createdAt: DateTime(2026, 9, 11, 10),
        conversationId: 7,
        metadata: {
          'sender_name': 'Alex',
          'sender_avatar_url': 'https://cdn.example/alex.jpg',
        },
      ),
      currentUserId: 99,
    );

    final item = container.read(chatListPreviewProvider).items.single;
    expect(item.id, 12);
    expect(item.chatId, 7);
    expect(item.name, 'Alex');
    expect(item.avatarUrl, 'https://cdn.example/alex.jpg');
    expect(item.unreadCount, 1);
  });

  test('clearUnreadForPeer zeros the list badge', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(chatListPreviewProvider.notifier);
    notifier.seedFromMaps([
      {
        'id': 12,
        'chat_id': 12,
        'name': 'Alex',
        'unread_count': 4,
      },
    ]);

    notifier.clearUnreadForPeer(12);

    expect(container.read(chatListPreviewProvider).items.single.unreadCount, 0);
  });

  test('clearUnreadForPeer is a no-op when unread is already zero', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(chatListPreviewProvider.notifier);
    notifier.seedFromMaps([
      {
        'id': 12,
        'chat_id': 12,
        'name': 'Alex',
        'unread_count': 0,
      },
    ]);

    final before = container.read(chatListPreviewProvider);
    notifier.clearUnreadForPeer(12);

    expect(identical(container.read(chatListPreviewProvider), before), isTrue);
  });

  test('background incoming message moves the row to top and increments unread', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(chatListPreviewProvider.notifier);
    notifier.seedFromMaps([
      {
        'id': 10,
        'chat_id': 1,
        'name': 'Alex',
        'last_message': 'old',
        'last_message_time': DateTime(2026, 9, 11, 9),
        'last_message_id': 1,
        'unread_count': 0,
      },
      {
        'id': 12,
        'chat_id': 2,
        'name': 'Sam',
        'last_message': 'earlier',
        'last_message_time': DateTime(2026, 9, 11, 8),
        'last_message_id': 2,
        'unread_count': 0,
        'avatar_url': 'https://cdn.example/sam.jpg',
      },
    ]);

    notifier.applyIncomingMessage(
      Message(
        id: 50,
        senderId: 12,
        receiverId: 99,
        message: 'ping',
        createdAt: DateTime(2026, 9, 11, 10),
        conversationId: 2,
        metadata: {
          'sender_name': 'Sam',
          'sender_avatar_url': 'https://cdn.example/sam.jpg',
        },
      ),
      currentUserId: 99,
    );

    final items = container.read(chatListPreviewProvider).items;
    expect(items.first.id, 12);
    expect(items.first.lastMessage, 'ping');
    expect(items.first.unreadCount, 1);
    expect(items.last.id, 10);
    expect(items.last.unreadCount, 0);
  });

  test('incoming unpinned message stays below pinned rows', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(chatListPreviewProvider.notifier);
    notifier.seedFromMaps([
      {
        'id': 10,
        'chat_id': 1,
        'name': 'Alex',
        'last_message': 'old',
        'last_message_time': DateTime(2026, 9, 11, 9),
        'last_message_id': 1,
        'is_pinned': true,
        'avatar_url': 'https://cdn.example/alex.jpg',
      },
      {
        'id': 12,
        'chat_id': 2,
        'name': 'Sam',
        'last_message': 'earlier',
        'last_message_time': DateTime(2026, 9, 11, 8),
        'last_message_id': 2,
        'is_pinned': false,
        'avatar_url': 'https://cdn.example/sam.jpg',
      },
    ]);

    notifier.applyIncomingMessage(
      Message(
        id: 50,
        senderId: 12,
        receiverId: 99,
        message: 'ping',
        createdAt: DateTime(2026, 9, 11, 10),
        conversationId: 2,
        metadata: {
          'sender_name': 'Sam',
          'sender_avatar_url': 'https://cdn.example/sam.jpg',
        },
      ),
      currentUserId: 99,
    );

    final items = container.read(chatListPreviewProvider).items;
    expect(items.map((item) => item.id), [10, 12]);
    expect(items.first.isPinned, isTrue);
    expect(items.last.lastMessage, 'ping');
  });

  test('open-thread incoming does not increment unread but still jumps to top', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(chatListPreviewProvider.notifier);
    notifier.seedFromMaps([
      {
        'id': 10,
        'chat_id': 1,
        'name': 'Alex',
        'last_message': 'old',
        'last_message_time': DateTime(2026, 9, 11, 9),
        'last_message_id': 1,
        'unread_count': 0,
        'avatar_url': 'https://cdn.example/alex.jpg',
      },
      {
        'id': 12,
        'chat_id': 2,
        'name': 'Sam',
        'last_message': 'earlier',
        'last_message_time': DateTime(2026, 9, 11, 8),
        'last_message_id': 2,
        'unread_count': 3,
        'avatar_url': 'https://cdn.example/sam.jpg',
      },
    ]);

    notifier.applyIncomingMessage(
      Message(
        id: 50,
        senderId: 12,
        receiverId: 99,
        message: 'here',
        createdAt: DateTime(2026, 9, 11, 10),
        conversationId: 2,
        metadata: {
          'sender_name': 'Sam',
          'sender_avatar_url': 'https://cdn.example/sam.jpg',
        },
      ),
      currentUserId: 99,
      activeChatPeerId: 12,
    );

    final item = container.read(chatListPreviewProvider).items.first;
    expect(item.id, 12);
    expect(item.unreadCount, 0);
  });

  test('outgoing echo does not label the row with the current user name', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(chatListPreviewProvider.notifier);
    notifier.seedFromMaps([
      {
        'id': 12,
        'chat_id': 2,
        'name': 'Sam',
        'last_message': 'earlier',
        'last_message_time': DateTime(2026, 9, 11, 8),
        'last_message_id': 2,
        'avatar_url': 'https://cdn.example/sam.jpg',
      },
    ]);

    notifier.applyIncomingMessage(
      Message(
        id: 51,
        senderId: 99,
        receiverId: 12,
        message: 'sent',
        createdAt: DateTime(2026, 9, 11, 10),
        conversationId: 2,
        metadata: {
          'sender_name': 'Me',
          'sender_avatar_url': 'https://cdn.example/me.jpg',
        },
      ),
      currentUserId: 99,
    );

    final item = container.read(chatListPreviewProvider).items.single;
    expect(item.name, 'Sam');
    expect(item.lastMessageFromMe, isTrue);
    expect(item.unreadCount, 0);
  });

  test('missing sender avatar hydrates from peerAvatarCache', () {
    final container = ProviderContainer(
      overrides: [
        peerAvatarCacheProvider.overrideWith(_SeededPeerAvatarCache.new),
      ],
    );
    addTearDown(container.dispose);

    container.read(chatListPreviewProvider.notifier).applyIncomingMessage(
          Message(
            id: 44,
            senderId: 12,
            receiverId: 99,
            message: 'Hi',
            createdAt: DateTime(2026, 9, 11, 10),
            conversationId: 7,
            metadata: const {'sender_name': 'Sam'},
          ),
          currentUserId: 99,
        );

    expect(
      container.read(chatListPreviewProvider).items.single.avatarUrl,
      'https://cdn.example/cached-sam.jpg',
    );
  });

  test('stale chats API seed keeps a newer live preview at the top', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(chatListPreviewProvider.notifier);
    notifier.seedFromMaps([
      {
        'id': 10,
        'chat_id': 1,
        'name': 'Alex',
        'last_message': 'old',
        'last_message_time': DateTime(2026, 9, 11, 9),
        'last_message_id': 1,
        'unread_count': 0,
      },
      {
        'id': 12,
        'chat_id': 2,
        'name': 'Sam',
        'last_message': 'earlier',
        'last_message_time': DateTime(2026, 9, 11, 8),
        'last_message_id': 2,
        'unread_count': 0,
        'avatar_url': 'https://cdn.example/sam.jpg',
      },
    ]);

    notifier.applyIncomingMessage(
      Message(
        id: 50,
        senderId: 12,
        receiverId: 99,
        message: 'ping',
        createdAt: DateTime(2026, 9, 11, 10),
        conversationId: 2,
        metadata: {
          'sender_name': 'Sam',
          'sender_avatar_url': 'https://cdn.example/sam.jpg',
        },
      ),
      currentUserId: 99,
    );

    notifier.seedFromMaps([
      {
        'id': 10,
        'chat_id': 1,
        'name': 'Alex',
        'last_message': 'old',
        'last_message_time': DateTime(2026, 9, 11, 9),
        'last_message_id': 1,
        'unread_count': 0,
      },
      {
        'id': 12,
        'chat_id': 2,
        'name': 'Sam',
        'last_message': 'earlier',
        'last_message_time': DateTime(2026, 9, 11, 8),
        'last_message_id': 2,
        'unread_count': 0,
        'avatar_url': 'https://cdn.example/sam.jpg',
      },
    ]);

    final items = container.read(chatListPreviewProvider).items;
    expect(items.first.id, 12);
    expect(items.first.lastMessage, 'ping');
    expect(items.first.unreadCount, 1);
  });
}

class _SeededPeerAvatarCache extends PeerAvatarCache {
  @override
  Map<int, String> build() => {
        12: 'https://cdn.example/cached-sam.jpg',
      };
}
