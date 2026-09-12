import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/utils/chat_active_heartbeat.dart';

void main() {
  group('ChatActiveHeartbeat', () {
    test('skips missing or peer-id conversation ids', () {
      expect(
        ChatActiveHeartbeat.reportableConversationId(
          conversationId: null,
          peerUserId: 42,
        ),
        isNull,
      );
      expect(
        ChatActiveHeartbeat.reportableConversationId(
          conversationId: 0,
          peerUserId: 42,
        ),
        isNull,
      );
      expect(
        ChatActiveHeartbeat.reportableConversationId(
          conversationId: 42,
          peerUserId: 42,
        ),
        isNull,
      );
    });

    test('accepts a real conversation id', () {
      expect(
        ChatActiveHeartbeat.reportableConversationId(
          conversationId: 99,
          peerUserId: 42,
        ),
        99,
      );
    });

    test('heartbeat interval is 3 minutes', () {
      expect(ChatActiveHeartbeat.interval, const Duration(minutes: 3));
    });
  });
}
