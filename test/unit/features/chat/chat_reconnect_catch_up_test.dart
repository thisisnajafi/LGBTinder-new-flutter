import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/data/models/message.dart';
import 'package:lgbtindernew/features/chat/data/services/chat_service.dart';
import 'package:lgbtindernew/features/chat/utils/chat_reconnect_catch_up.dart';

Message _msg(int id) => Message.fromJson({
      'id': id,
      'sender_id': 2,
      'receiver_id': 1,
      'message': 'm$id',
    });

void main() {
  test('lastServerId ignores optimistic and call rows', () {
    expect(
      ChatReconnectCatchUp.lastServerId([
        {'id': 0, 'client_id': 'local'},
        {'kind': 'call', 'id': 99},
        {'id': 12},
        {'id': '7'},
      ]),
      12,
    );
    expect(ChatReconnectCatchUp.lastServerId(const []), isNull);
  });

  test('fetchAllAfter loops until 50 missed messages are collected', () async {
    final missed = List<Message>.generate(50, (i) => _msg(11 + i));
    var calls = 0;

    final collected = await ChatReconnectCatchUp.fetchAllAfter(
      lastId: 10,
      fetchPage: (afterId) async {
        calls++;
        final newer = missed.where((m) => m.id > afterId).toList();
        final take = newer.take(ChatReconnectCatchUp.pageSize).toList();
        final remaining = newer.length - take.length;
        // API is newest-first.
        return ChatHistoryResult(
          messages: take.reversed.toList(),
          hasMore: remaining > 0,
          nextAfterId: take.isEmpty ? null : take.last.id,
        );
      },
    );

    expect(collected.map((m) => m.id), missed.map((m) => m.id));
    expect(calls, 1);
  });

  test('fetchAllAfter pages when the gap is larger than page size', () async {
    final missed = List<Message>.generate(120, (i) => _msg(11 + i));
    var calls = 0;

    final collected = await ChatReconnectCatchUp.fetchAllAfter(
      lastId: 10,
      fetchPage: (afterId) async {
        calls++;
        final newer = missed.where((m) => m.id > afterId).toList();
        final take = newer.take(20).toList();
        final remaining = newer.length - take.length;
        return ChatHistoryResult(
          messages: take.reversed.toList(),
          hasMore: remaining > 0,
          nextAfterId: take.isEmpty ? null : take.last.id,
        );
      },
    );

    expect(collected.length, 120);
    expect(collected.first.id, 11);
    expect(collected.last.id, 130);
    expect(calls, 6);
  });
}
