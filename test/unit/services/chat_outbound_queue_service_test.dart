import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/chat/data/local/app_database.dart';
import 'package:lgbtindernew/features/chat/data/local/chat_local_repository.dart';
import 'package:lgbtindernew/features/chat/data/services/chat_outbound_queue_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChatOutboundQueueService', () {
    late AppDatabase db;
    late ChatLocalRepository repo;
    late ChatOutboundQueueService service;

    setUp(() {
      db = AppDatabase.forTesting();
      repo = ChatLocalRepository(db);
      service = ChatOutboundQueueService(repo);
    });

    tearDown(() async {
      await db.close();
    });

    test('enqueue and getPending round-trip', () async {
      final message = QueuedChatMessage(
        clientId: 'local_1',
        receiverId: 42,
        senderId: 7,
        message: 'Hello offline',
        createdAt: DateTime(2026, 5, 24),
      );

      await service.enqueue(message);
      final pending = await service.getPending();

      expect(pending, hasLength(1));
      expect(pending.first.clientId, 'local_1');
      expect(pending.first.receiverId, 42);
      expect(pending.first.message, 'Hello offline');
    });

    test('remove deletes a queued message', () async {
      await service.enqueue(
        QueuedChatMessage(
          clientId: 'local_1',
          receiverId: 1,
          senderId: 2,
          message: 'A',
          createdAt: DateTime.now(),
        ),
      );
      await service.remove('local_1');

      expect(await service.getPending(), isEmpty);
    });

    test('clear removes all queued messages', () async {
      await service.enqueue(
        QueuedChatMessage(
          clientId: 'local_1',
          receiverId: 1,
          senderId: 2,
          message: 'A',
          createdAt: DateTime.now(),
        ),
      );
      await service.clear();

      expect(await service.getPending(), isEmpty);
    });
  });
}
