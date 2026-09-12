import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/utils/chat_message_index.dart';
import 'package:lgbtindernew/features/chat/utils/chat_optimistic.dart';

void main() {
  test('rebuild maps server id and client_id to the row index', () {
    final index = ChatMessageIndex()
      ..rebuild([
        {'id': 1, 'client_id': 'a', 'text': 'one'},
        {'kind': 'call', 'call_id': 9, 'id': 9},
        {'id': '2', 'client_id': 'b', 'text': 'two'},
      ]);

    expect(index.byServerId(1), 0);
    expect(index.byServerId('2'), 2);
    expect(index.byClientId('b'), 2);
    expect(index.byServerId(9), isNull);
    expect(index.serverIdCount, 2);
  });

  test('replaceAt updates maps in place so a later echo is O(1)', () {
    final messages = <Map<String, dynamic>>[
      {'id': 0, 'client_id': 'temp-1', 'text': 'Hi'},
      {'id': 7, 'client_id': 'other', 'text': 'Yo'},
    ];
    final index = ChatMessageIndex()..rebuild(messages);

    index.replaceAt(messages, 0, {
      'id': 42,
      'client_id': 'temp-1',
      'text': 'Hi',
    });

    expect(index.byClientId('temp-1'), 0);
    expect(index.byServerId(42), 0);
    expect(index.byServerId(0), isNull);
    expect(messages[0]['id'], 42);
    expect(index.byServerId(7), 1);
  });

  test('sending then receiving the echo never duplicates', () {
    final messages = <Map<String, dynamic>>[
      {'id': 0, 'client_id': 'temp-1', 'text': 'Hi'},
    ];
    final index = ChatMessageIndex()..rebuild(messages);
    final optimisticAt = index.byClientId('temp-1');
    expect(optimisticAt, 0);

    index.replaceAt(messages, optimisticAt!, {
      'id': 42,
      'client_id': 'temp-1',
      'text': 'Hi',
    });
    expect(messages, hasLength(1));

    expect(index.byServerId(42), 0);
    expect(index.byClientId('temp-1'), 0);
  });

  test('parseMessageId accepts int and string ids', () {
    expect(ChatOptimistic.parseMessageId(12), 12);
    expect(ChatOptimistic.parseMessageId('12'), 12);
    expect(ChatOptimistic.parseMessageId(null), 0);
  });
}
