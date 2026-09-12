import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/data/models/message.dart';
import 'package:lgbtindernew/features/chat/data/models/message_delivery_status.dart';
import 'package:lgbtindernew/features/chat/utils/chat_message_dedup.dart';
import 'package:lgbtindernew/features/chat/utils/chat_optimistic.dart';

Message _msg({
  required int id,
  String? clientId,
  String text = 'Hi',
  int senderId = 1,
  MessageDeliveryStatus status = MessageDeliveryStatus.sent,
  bool isDelivered = false,
  bool isEdited = false,
}) {
  return Message(
    id: id,
    senderId: senderId,
    receiverId: 2,
    message: text,
    createdAt: DateTime(2026, 9, 11, 12),
    clientId: clientId,
    deliveryStatus: status,
    isDelivered: isDelivered,
    isEdited: isEdited,
  );
}

void main() {
  group('ChatMessageDedup.upsertMessage', () {
    test('send then echo replaces the optimistic row', () {
      final optimistic = _msg(
        id: 0,
        clientId: 'temp-1',
        status: MessageDeliveryStatus.sending,
      );
      final echo = _msg(
        id: 42,
        clientId: 'temp-1',
        status: MessageDeliveryStatus.sent,
        isDelivered: true,
      );

      final result = ChatMessageDedup.upsertMessage([optimistic], echo);

      expect(result.insertedNew, isFalse);
      expect(result.messages, hasLength(1));
      expect(result.messages.single.id, 42);
      expect(result.messages.single.isDelivered, isTrue);
    });

    test('second echo with the same server id updates in place', () {
      final first = _msg(id: 42, clientId: 'temp-1', text: 'Hi');
      final edited = _msg(
        id: 42,
        clientId: 'temp-1',
        text: 'Hi!',
        isEdited: true,
      );

      final result = ChatMessageDedup.upsertMessage([first], edited);

      expect(result.insertedNew, isFalse);
      expect(result.messages, hasLength(1));
      expect(result.messages.single.message, 'Hi!');
      expect(result.messages.single.isEdited, isTrue);
    });

    test('two identical texts without ids stay two bubbles', () {
      final a = _msg(id: 0, clientId: 'a', text: 'ok');
      final b = _msg(id: 0, clientId: 'b', text: 'ok');

      final result = ChatMessageDedup.upsertMessage([a], b);

      expect(result.insertedNew, isTrue);
      expect(result.messages, hasLength(2));
    });
  });

  group('ChatMessageDedup.fold', () {
    test('collapses duplicate server ids into the later row', () {
      final folded = ChatMessageDedup.fold([
        {'id': 5, 'text': 'old', 'kind': 'message'},
        {'id': 5, 'text': 'new', 'kind': 'message', 'is_edited': true},
      ]);

      expect(folded, hasLength(1));
      expect(folded.single['text'], 'new');
      expect(folded.single['is_edited'], isTrue);
    });

    test('replaces optimistic client_id with the server echo', () {
      final folded = ChatMessageDedup.fold([
        {
          'id': 0,
          'client_id': 'temp-1',
          'text': 'Hi',
          'kind': 'message',
        },
        {
          'id': 42,
          'client_id': 'temp-1',
          'text': 'Hi',
          'kind': 'message',
          'delivery_status': 'sent',
        },
      ]);

      expect(folded, hasLength(1));
      expect(folded.single['id'], 42);
      expect(folded.single['client_id'], 'temp-1');
    });

    test('does not let a later optimistic row overwrite a persisted id', () {
      final folded = ChatMessageDedup.fold([
        {'id': 42, 'client_id': 'temp-1', 'text': 'Hi', 'kind': 'message'},
        {
          'id': 0,
          'client_id': 'temp-1',
          'text': 'Hi',
          'kind': 'message',
          'delivery_status': 'sending',
        },
      ]);

      expect(folded, hasLength(1));
      expect(folded.single['id'], 42);
    });
  });

  group('ChatMessageDedup.indexOfRow', () {
    test('matches client_id only — not text', () {
      final rows = [
        {'id': 0, 'client_id': 'a', 'text': 'ok', 'kind': 'message'},
        {'id': 0, 'client_id': 'b', 'text': 'ok', 'kind': 'message'},
      ];

      expect(ChatMessageDedup.indexOfRow(rows, clientId: 'b'), 1);
      expect(ChatMessageDedup.indexOfRow(rows, clientId: 'missing'), -1);
      expect(
        ChatOptimistic.hasClientId(null),
        isFalse,
      );
    });
  });
}
