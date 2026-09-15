import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/local_conversations.dart';
import 'tables/local_messages.dart';
import 'tables/local_notification_lists.dart';
import 'tables/local_notifications.dart';
import 'tables/media_cache_meta.dart';
import 'tables/outbox_entries.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    LocalConversations,
    LocalMessages,
    OutboxEntries,
    MediaCacheMeta,
    LocalNotifications,
    LocalNotificationLists,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.forTesting() : super(NativeDatabase.memory());

  factory AppDatabase.open() {
    return AppDatabase(
      driftDatabase(name: 'lgbtinder_chat.db'),
    );
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.createTable(localNotifications);
          await m.createTable(localNotificationLists);
        }
      },
    );
  }
}
