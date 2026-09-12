import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/data/models/message.dart';
import 'package:lgbtindernew/features/chat/data/models/message_delivery_status.dart';
import 'package:lgbtindernew/features/chat/data/services/chat_outbound_queue_service.dart';
import 'package:lgbtindernew/features/chat/providers/chat_outbox_ui_provider.dart';
import 'package:lgbtindernew/features/chat/utils/chat_outbox_ui.dart';

void main() {
  group('ChatOutboxUi', () {
    final queued = QueuedChatMessage(
      clientId: 'local_1',
      receiverId: 9,
      senderId: 3,
      message: 'hello',
      createdAt: DateTime(2026, 9, 12, 2),
    );

    test('rowsForPeer keeps only that chat', () {
      final rows = ChatOutboxUi.rowsForPeer(
        [
          queued,
          QueuedChatMessage(
            clientId: 'local_2',
            receiverId: 8,
            senderId: 3,
            message: 'other',
            createdAt: DateTime(2026, 9, 12, 3),
          ),
        ],
        9,
      );

      expect(rows, hasLength(1));
      expect(rows.single['client_id'], 'local_1');
      expect(rows.single['delivery_status'], MessageDeliveryStatus.queued);
      expect(rows.single['text'], 'hello');
    });

    test('applySent maps temp row to server id', () {
      final sent = Message(
        id: 44,
        senderId: 3,
        receiverId: 9,
        message: 'hello',
        createdAt: DateTime(2026, 9, 12, 2, 1),
        conversationId: 12,
        clientId: 'local_1',
      );
      final next = ChatOutboxUi.applySent(
        ChatOutboxUi.toThreadRow(queued),
        'local_1',
        sent,
      );

      expect(next['id'], 44);
      expect(next['delivery_status'], MessageDeliveryStatus.sent);
      expect(next['conversation_id'], 12);
      expect(next['client_id'], 'local_1');
    });
  });

  group('ChatOutboxUiState.visibleFor', () {
    test('requires flushing and that peer', () {
      const pendingOnly = ChatOutboxUiState(pendingReceiverIds: {9});
      expect(pendingOnly.visibleFor(9), isFalse);

      const flushing = ChatOutboxUiState(
        flushing: true,
        pendingReceiverIds: {9},
      );
      expect(flushing.visibleFor(9), isTrue);
      expect(flushing.visibleFor(8), isFalse);
    });
  });
}
