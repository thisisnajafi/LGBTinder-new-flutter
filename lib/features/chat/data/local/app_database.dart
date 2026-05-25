import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/local_conversations.dart';
import 'tables/local_messages.dart';
import 'tables/media_cache_meta.dart';
import 'tables/outbox_entries.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    LocalConversations,
    LocalMessages,
    OutboxEntries,
    MediaCacheMeta,
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
  int get schemaVersion => 1;
}
