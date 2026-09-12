import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/data/models/message.dart';
import 'package:lgbtindernew/features/chat/data/models/message_delivery_status.dart';
import 'package:lgbtindernew/features/chat/utils/chat_thread_local_apply.dart';
import 'package:lgbtindernew/features/chat/utils/chat_thread_row_map.dart';

Message _msg({
  required int id,
  required int senderId,
  String text = 'hi',
  String? clientId,
  MessageDeliveryStatus status = MessageDeliveryStatus.sent,
}) {
  return Message(
    id: id,
    senderId: senderId,
    receiverId: senderId == 1 ? 2 : 1,
    message: text,
    createdAt: DateTime.utc(2026, 9, 12, 12),
    clientId: clientId,
    deliveryStatus: status,
  );
}

void main() {
  test('fromMessage marks outgoing when sender is current user', () {
    final row = ChatThreadRowMap.fromMessage(
      _msg(id: 9, senderId: 1, text: 'yo'),
      peerUserId: 2,
      currentUserId: 1,
    );
    expect(row['is_sent'], isTrue);
    expect(row['text'], 'yo');
    expect(row['id'], 9);
  });

  test('combine keeps in-flight optimistic rows missing from Drift', () {
    final sending = <String, dynamic>{
      'id': 0,
      'client_id': 'c-local',
      'text': 'pending',
      'delivery_status': MessageDeliveryStatus.sending,
      'kind': 'message',
    };
    final combined = ChatThreadLocalApply.combine(
      messages: [_msg(id: 4, senderId: 2)],
      peerUserId: 2,
      currentUserId: 1,
      callRows: const [],
      previousRows: [sending],
    );
    expect(
      combined.any((row) => row['client_id'] == 'c-local'),
      isTrue,
    );
    expect(combined.any((row) => row['id'] == 4), isTrue);
  });

  test('combine keeps a just-received server row until Drift catches up', () {
    final pending = <String, dynamic>{
      'id': 88,
      'client_id': 'c-88',
      'text': 'live',
      'kind': 'message',
      'delivery_status': MessageDeliveryStatus.sent,
    };
    final combined = ChatThreadLocalApply.combine(
      messages: [_msg(id: 4, senderId: 2)],
      peerUserId: 2,
      currentUserId: 1,
      callRows: const [],
      previousRows: [pending],
    );
    expect(combined.any((row) => row['id'] == 88), isTrue);
  });

  test('sameSnapshot ignores new map instances with the same fingerprint', () {
    final a = [
      ChatThreadRowMap.fromMessage(
        _msg(id: 4, senderId: 2, text: 'hi'),
        peerUserId: 2,
        currentUserId: 1,
      ),
    ];
    final b = [
      ChatThreadRowMap.fromMessage(
        _msg(id: 4, senderId: 2, text: 'hi'),
        peerUserId: 2,
        currentUserId: 1,
      ),
    ];
    expect(ChatThreadLocalApply.sameSnapshot(a, b), isTrue);
    b[0] = {...b[0], 'text': 'changed'};
    expect(ChatThreadLocalApply.sameSnapshot(a, b), isFalse);
  });

  test('combine keeps live read/expired flags until Drift persists them', () {
    final previous = ChatThreadRowMap.fromMessage(
      _msg(id: 4, senderId: 1, text: 'yo'),
      peerUserId: 2,
      currentUserId: 1,
    );
    previous['is_read'] = true;
    previous['is_delivered'] = true;
    previous['is_expired'] = true;

    final combined = ChatThreadLocalApply.combine(
      messages: [_msg(id: 4, senderId: 1, text: 'yo')],
      peerUserId: 2,
      currentUserId: 1,
      callRows: const [],
      previousRows: [previous],
    );
    expect(combined.single['is_read'], isTrue);
    expect(combined.single['is_delivered'], isTrue);
    expect(combined.single['is_expired'], isTrue);
  });
}
