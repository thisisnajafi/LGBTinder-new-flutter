import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/chat/data/local/app_database.dart';
import 'package:lgbtindernew/features/chat/data/local/chat_local_repository.dart';
import 'package:lgbtindernew/features/chat/data/models/chat.dart';
import 'package:lgbtindernew/features/chat/data/models/message.dart';
import 'package:lgbtindernew/features/chat/utils/chat_message_search.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('groupMessageSearchHits', () {
    test('keeps the newest preview per peer', () {
      final grouped = groupMessageSearchHits([
        ChatMessageSearchHit(
          otherUserId: 1,
          name: 'A',
          preview: 'old',
          createdAt: DateTime(2026, 1, 1),
        ),
        ChatMessageSearchHit(
          otherUserId: 1,
          name: 'A',
          preview: 'new',
          createdAt: DateTime(2026, 2, 1),
        ),
        ChatMessageSearchHit(
          otherUserId: 2,
          name: 'B',
          preview: 'other',
          createdAt: DateTime(2026, 1, 15),
        ),
      ]);

      expect(grouped.map((h) => h.otherUserId), [1, 2]);
      expect(grouped.first.preview, 'new');
    });

    test('parses API hits from other_user', () {
      final hit = chatMessageSearchHitFromApi({
        'message': 'hello there',
        'created_at': '2026-09-12T10:00:00Z',
        'conversation_id': 99,
        'other_user': {
          'id': 7,
          'name': 'Sam',
          'avatar_url': 'https://example.com/s.png',
        },
      });

      expect(hit, isNotNull);
      expect(hit!.otherUserId, 7);
      expect(hit.name, 'Sam');
      expect(hit.preview, 'hello there');
    });
  });

  group('ChatLocalRepository.searchMessagesLocal', () {
    late AppDatabase db;
    late ChatLocalRepository repo;

    setUp(() {
      db = AppDatabase.forTesting();
      repo = ChatLocalRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('finds cached text and skips deleted rows', () async {
      await repo.upsertConversation(
        Chat(
          id: 1,
          userId: 42,
          firstName: 'Alex',
        ),
      );
      await repo.upsertMessage(
        Message(
          id: 10,
          senderId: 1,
          receiverId: 42,
          message: 'Coffee at noon',
          createdAt: DateTime.utc(2026, 9, 1),
        ),
        42,
      );
      await repo.upsertMessage(
        Message(
          id: 11,
          senderId: 42,
          receiverId: 1,
          message: 'Tea later',
          createdAt: DateTime.utc(2026, 9, 2),
        ),
        42,
      );
      await repo.markMessageDeletedByServerId(11);

      final hits = await repo.searchMessagesLocal(query: 'coffee');
      expect(hits, hasLength(1));
      expect(hits.first.otherUserId, 42);
      expect(hits.first.preview, 'Coffee at noon');
      expect(hits.first.name, 'Alex');

      final tea = await repo.searchMessagesLocal(query: 'tea');
      expect(tea, isEmpty);
    });
  });
}
