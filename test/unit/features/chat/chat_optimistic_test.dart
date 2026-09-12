import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/utils/chat_client_id.dart';
import 'package:lgbtindernew/features/chat/utils/chat_optimistic.dart';

void main() {
  group('ChatClientIds', () {
    test('next ids are unique UUIDs', () {
      final a = ChatClientIds.next();
      final b = ChatClientIds.next();
      expect(a, isNot(b));
      expect(a, matches(RegExp(r'^[0-9a-f-]{36}$')));
      expect(a, isNot(contains('local_')));
    });
  });

  group('ChatOptimistic', () {
    test('matches on client_id', () {
      expect(
        ChatOptimistic.isClientIdMatch('abc', 'abc'),
        isTrue,
      );
      expect(ChatOptimistic.isClientIdMatch('abc', 'zzz'), isFalse);
      expect(ChatOptimistic.isClientIdMatch(null, 'abc'), isFalse);
    });

    test('http success after pusher echo keeps a single bubble', () {
      final merged = ChatOptimistic.replaceWithServer(
        messages: [
          {
            'id': 42,
            'client_id': 'temp-1',
            'text': 'Hi',
          },
        ],
        clientId: 'temp-1',
        serverId: 42,
        serverMap: {
          'id': 42,
          'client_id': 'temp-1',
          'text': 'Hi',
        },
      );

      expect(merged, hasLength(1));
      expect(merged.single['id'], 42);
    });

    test('http success after pusher echo drops the leftover optimistic row', () {
      final merged = ChatOptimistic.replaceWithServer(
        messages: [
          {
            'id': 42,
            'client_id': 'temp-1',
            'text': 'Hi',
          },
          {
            'id': 0,
            'client_id': 'temp-1',
            'text': 'Hi',
          },
        ],
        clientId: 'temp-1',
        serverId: 42,
        serverMap: {
          'id': 42,
          'client_id': 'temp-1',
          'text': 'Hi',
        },
      );

      expect(merged, hasLength(1));
      expect(merged.single['id'], 42);
    });

    test('http success without pusher swaps the optimistic row', () {
      final merged = ChatOptimistic.replaceWithServer(
        messages: [
          {
            'id': 0,
            'client_id': 'temp-1',
            'text': 'Hi',
          },
        ],
        clientId: 'temp-1',
        serverId: 42,
        serverMap: {
          'id': 42,
          'client_id': 'temp-1',
          'text': 'Hi',
        },
      );

      expect(merged, hasLength(1));
      expect(merged.single['id'], 42);
    });
  });
}
