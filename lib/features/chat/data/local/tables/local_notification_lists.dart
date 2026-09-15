import 'package:drift/drift.dart';

/// Pagination / badge snapshot for the cached notification list.
class LocalNotificationLists extends Table {
  IntColumn get ownerUserId => integer()();

  IntColumn get currentPage =>
      integer().withDefault(const Constant(1))();

  BoolColumn get hasMore =>
      boolean().withDefault(const Constant(true))();

  IntColumn get unreadCount => integer().nullable()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {ownerUserId};
}
