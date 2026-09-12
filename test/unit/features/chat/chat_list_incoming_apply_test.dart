import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/utils/chat_list_incoming_apply.dart';

void main() {
  test('unread increments only for incoming messages not in the open thread', () {
    expect(
      ChatListIncomingApply.shouldIncrementUnread(
        isIncoming: true,
        isOpenThread: false,
      ),
      isTrue,
    );
    expect(
      ChatListIncomingApply.shouldIncrementUnread(
        isIncoming: true,
        isOpenThread: true,
      ),
      isFalse,
    );
    expect(
      ChatListIncomingApply.shouldIncrementUnread(
        isIncoming: false,
        isOpenThread: false,
      ),
      isFalse,
    );
  });

  test('open thread clears unread instead of incrementing', () {
    expect(
      ChatListIncomingApply.nextUnreadCount(
        currentUnread: 4,
        increment: true,
        isOpenThread: true,
      ),
      0,
    );
    expect(
      ChatListIncomingApply.nextUnreadCount(
        currentUnread: 4,
        increment: true,
        isOpenThread: false,
      ),
      5,
    );
  });

  test('older or replayed ids do not replace the preview', () {
    final now = DateTime(2026, 9, 11, 12);
    expect(
      ChatListIncomingApply.shouldReplacePreview(
        messageId: 10,
        createdAt: now,
        lastMessageId: 10,
        lastMessageTime: now,
      ),
      isFalse,
    );
    expect(
      ChatListIncomingApply.shouldReplacePreview(
        messageId: 9,
        createdAt: now.subtract(const Duration(minutes: 1)),
        lastMessageId: 10,
        lastMessageTime: now,
      ),
      isFalse,
    );
    expect(
      ChatListIncomingApply.shouldReplacePreview(
        messageId: 11,
        createdAt: now.add(const Duration(minutes: 1)),
        lastMessageId: 10,
        lastMessageTime: now,
      ),
      isTrue,
    );
  });

  test('outgoing payloads do not overwrite an existing peer name', () {
    expect(
      ChatListIncomingApply.resolveName(
        isIncoming: false,
        payloadName: 'Me',
        existingName: 'Alex',
      ),
      'Alex',
    );
    expect(
      ChatListIncomingApply.resolveName(
        isIncoming: false,
        payloadName: 'Me',
        existingName: 'User',
      ),
      ChatListIncomingApply.placeholderName,
    );
  });

  test('missing avatar falls back to the peer cache', () {
    expect(
      ChatListIncomingApply.resolveAvatar(
        isIncoming: true,
        payloadAvatar: null,
        existingAvatar: null,
        cachedAvatar: 'https://cdn.example/alex.jpg',
      ),
      'https://cdn.example/alex.jpg',
    );
  });
}
