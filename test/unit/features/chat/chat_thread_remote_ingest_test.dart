import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/data/models/message.dart';
import 'package:lgbtindernew/features/chat/providers/chat_thread_providers.dart';
import 'package:lgbtindernew/features/chat/utils/chat_thread_remote_ingest.dart';

Message _msg({
  required int id,
  required int senderId,
  String text = 'hi',
  String? clientId,
  bool isRead = false,
  bool isDelivered = false,
}) {
  return Message(
    id: id,
    senderId: senderId,
    receiverId: senderId == 1 ? 2 : 1,
    message: text,
    createdAt: DateTime.utc(2026, 9, 12, 12),
    clientId: clientId,
    isRead: isRead,
    isDelivered: isDelivered,
  );
}

void main() {
  test('apply inserts a new peer row', () {
    final thread = ChatThreadMessagesNotifier();
    final result = ChatThreadRemoteIngest.apply(
      thread: thread,
      message: _msg(id: 10, senderId: 2, text: 'hello'),
      peerUserId: 2,
      currentUserId: 1,
    );
    expect(result.insertedNew, isTrue);
    expect(result.updatedExistingServerRow, isFalse);
    expect(thread.state.rows.single['text'], 'hello');
    expect(thread.state.rows.single['is_sent'], isFalse);
  });

  test('apply replaces an optimistic row with the same client id', () {
    final thread = ChatThreadMessagesNotifier();
    thread.setRows([
      {
        'id': 0,
        'client_id': 'c-1',
        'text': 'pending',
        'is_sent': true,
      },
    ]);
    final result = ChatThreadRemoteIngest.apply(
      thread: thread,
      message: _msg(id: 44, senderId: 1, text: 'sent', clientId: 'c-1'),
      peerUserId: 2,
      currentUserId: 1,
    );
    expect(result.insertedNew, isFalse);
    expect(result.added, isTrue);
    expect(thread.state.rows.single['id'], 44);
    expect(thread.state.rows.single['text'], 'sent');
  });

  test('applyReadReceipts marks matching sent rows read and delivered', () {
    final thread = ChatThreadMessagesNotifier();
    thread.setRows([
      {'id': 10, 'is_sent': true, 'is_read': false, 'is_delivered': true},
      {'id': 11, 'is_sent': true, 'is_read': false, 'is_delivered': false},
    ]);
    ChatThreadRemoteIngest.applyReadReceipts(thread, const [10]);
    expect(thread.state.rows[0]['is_read'], isTrue);
    expect(thread.state.rows[0]['is_delivered'], isTrue);
    expect(thread.state.rows[1]['is_read'], isFalse);
  });

  test('applyExpired clears attachment and remaining seconds', () {
    final thread = ChatThreadMessagesNotifier();
    thread.setRows([
      {
        'id': 7,
        'attachment_url': 'https://cdn.example/a.jpg',
        'remaining_seconds': 12,
        'is_expired': false,
      },
    ]);
    ChatThreadRemoteIngest.applyExpired(thread, 7);
    expect(thread.state.rows.single['is_expired'], isTrue);
    expect(thread.state.rows.single['remaining_seconds'], 0);
    expect(thread.state.rows.single['attachment_url'], isNull);
  });

  test('applyDeletedTombstone keeps the row and clears content', () {
    final thread = ChatThreadMessagesNotifier();
    thread.setRows([
      {
        'id': 9,
        'text': 'secret',
        'attachment_url': 'https://cdn.example/a.jpg',
        'reactions': {'❤️': 1},
        'my_reaction': '❤️',
      },
    ]);
    ChatThreadRemoteIngest.applyDeletedTombstone(thread, 9);
    expect(thread.state.rows.single['is_deleted'], isTrue);
    expect(thread.state.rows.single['text'], '');
    expect(thread.state.rows.single['attachment_url'], isNull);
    expect(thread.state.rows.single['reactions'], isEmpty);
  });

  test('removeByServerId drops the matching row', () {
    final thread = ChatThreadMessagesNotifier();
    thread.setRows([
      {'id': 1, 'text': 'keep'},
      {'id': 2, 'text': 'drop'},
    ]);
    ChatThreadRemoteIngest.removeByServerId(thread, 2);
    expect(thread.state.rows, [
      {'id': 1, 'text': 'keep'},
    ]);
  });
}
