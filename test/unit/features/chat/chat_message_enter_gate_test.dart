import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/utils/chat_message_enter_gate.dart';

void main() {
  group('ChatMessageEnterGate', () {
    test('identity prefers client_id over server id', () {
      expect(
        ChatMessageEnterGate.identity(clientId: 'abc', id: 9),
        'c:abc',
      );
      expect(ChatMessageEnterGate.identity(id: 9), 'i:9');
      expect(ChatMessageEnterGate.identity(id: 0), isNull);
      expect(ChatMessageEnterGate.identity(kind: 'call', id: 1), isNull);
      expect(
        ChatMessageEnterGate.identity(kind: 'unread_separator', id: 1),
        isNull,
      );
    });

    test('takeNew is true only once per sent identity', () {
      final gate = ChatMessageEnterGate();
      final row = {'client_id': 'c1', 'is_sent': true};

      expect(gate.takeNew(row), isTrue);
      expect(gate.takeNew(row), isFalse);
    });

    test('takeNew is true only once per incoming id', () {
      final gate = ChatMessageEnterGate();
      final row = {'id': 4, 'is_sent': false};

      expect(gate.takeNew(row), isTrue);
      expect(gate.takeNew(row), isFalse);
      expect(
        gate.takeNew({'client_id': 'peer-x', 'is_sent': false}),
        isTrue,
      );
    });

    test('markAll prevents history send and receive from animating', () {
      final gate = ChatMessageEnterGate();
      final history = [
        {'client_id': 'old', 'is_sent': true},
        {'id': 2, 'is_sent': false},
      ];
      gate.markAll(history);

      expect(gate.takeNew(history[0]), isFalse);
      expect(gate.takeNew(history[1]), isFalse);
      expect(
        gate.takeNew({'client_id': 'new-in', 'is_sent': false}),
        isTrue,
      );
    });

    test('cache hydrate is skipped; unseen incoming still plays', () {
      final gate = ChatMessageEnterGate();
      gate.markAll([
        {'id': 10, 'is_sent': false},
        {'id': 11, 'is_sent': false},
      ]);

      expect(gate.takeNew({'id': 10, 'is_sent': false}), isFalse);
      expect(gate.takeNew({'id': 11, 'is_sent': false}), isFalse);
      expect(
        gate.takeNew({'id': 12, 'is_sent': false, 'client_id': 'pusher-12'}),
        isTrue,
      );
    });
  });
}
