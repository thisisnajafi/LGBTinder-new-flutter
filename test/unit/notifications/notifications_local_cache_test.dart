import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/chat/data/local/app_database.dart';
import 'package:lgbtindernew/features/notifications/data/local/notifications_local_repository.dart';
import 'package:lgbtindernew/features/notifications/data/models/notification.dart'
    as app_models;

app_models.Notification _n({
  required int id,
  String type = 'like',
  bool isRead = false,
  Map<String, dynamic>? data,
}) {
  return app_models.Notification(
    id: id,
    type: type,
    title: 'Title $id',
    message: 'Body $id',
    createdAt: DateTime.utc(2026, 9, 12, 12),
    isRead: isRead,
    data: data,
    userId: 7,
    userName: 'Alex',
    userImageUrl: 'https://example.com/a.png',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationsLocalSnapshot.fromCacheMap', () {
    test('parses prefs payload and drops chat messages', () {
      final snapshot = NotificationsLocalSnapshot.fromCacheMap({
        'current_page': 3,
        'has_more': true,
        'unread_count': 2,
        'notifications': [
          _n(id: 1).toJson(),
          _n(id: 2, type: 'message').toJson(),
        ],
      });

      expect(snapshot, isNotNull);
      expect(snapshot!.notifications, hasLength(1));
      expect(snapshot.notifications.first.id, 1);
      expect(snapshot.currentPage, 3);
      expect(snapshot.hasMore, isTrue);
      expect(snapshot.unreadCount, 2);
    });

    test('returns null for an empty list', () {
      expect(
        NotificationsLocalSnapshot.fromCacheMap({'notifications': []}),
        isNull,
      );
    });
  });

  group('NotificationsLocalRepository', () {
    late AppDatabase db;
    late NotificationsLocalRepository repo;

    setUp(() {
      db = AppDatabase.forTesting();
      repo = NotificationsLocalRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('replace then load round-trips rows and pagination', () async {
      await repo.replace(
        ownerUserId: 11,
        notifications: [
          _n(id: 10, data: {'match_id': 4}),
          _n(id: 11, type: 'message'),
          _n(id: 12, isRead: true),
        ],
        currentPage: 2,
        hasMore: true,
        unreadCount: 1,
      );

      final loaded = await repo.load(11);
      expect(loaded, isNotNull);
      expect(loaded!.notifications.map((n) => n.id), [10, 12]);
      expect(loaded.notifications.first.data?['match_id'], 4);
      expect(loaded.notifications.first.userName, 'Alex');
      expect(loaded.currentPage, 2);
      expect(loaded.hasMore, isTrue);
      expect(loaded.unreadCount, 1);
    });

    test('keeps users isolated', () async {
      await repo.replace(
        ownerUserId: 1,
        notifications: [_n(id: 1)],
        currentPage: 1,
        hasMore: false,
      );
      await repo.replace(
        ownerUserId: 2,
        notifications: [_n(id: 2)],
        currentPage: 1,
        hasMore: false,
      );

      expect((await repo.load(1))!.notifications.single.id, 1);
      expect((await repo.load(2))!.notifications.single.id, 2);
    });

    test('clear removes list and meta', () async {
      await repo.replace(
        ownerUserId: 11,
        notifications: [_n(id: 1)],
        currentPage: 2,
        hasMore: true,
      );
      await repo.clear(11);
      expect(await repo.load(11), isNull);
    });
  });
}
