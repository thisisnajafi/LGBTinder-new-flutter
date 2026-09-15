import 'package:drift/drift.dart';

/// Cached in-app notification row (PERF-INFRA-005).
class LocalNotifications extends Table {
  IntColumn get ownerUserId => integer()();

  IntColumn get serverId => integer()();

  TextColumn get type => text()();

  TextColumn get title => text()();

  TextColumn get message => text()();

  DateTimeColumn get createdAt => dateTime()();

  BoolColumn get isRead =>
      boolean().withDefault(const Constant(false))();

  /// JSON for `Notification.data`.
  TextColumn get payloadJson => text().nullable()();

  IntColumn get actorUserId => integer().nullable()();

  TextColumn get actorName => text().nullable()();

  TextColumn get actorImageUrl => text().nullable()();

  TextColumn get actionUrl => text().nullable()();

  BoolColumn get isPlanRestricted =>
      boolean().withDefault(const Constant(false))();

  BoolColumn get upgradeRequired =>
      boolean().withDefault(const Constant(false))();

  IntColumn get sortOrder =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {ownerUserId, serverId};
}
