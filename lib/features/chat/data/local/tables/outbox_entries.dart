import 'package:drift/drift.dart';

/// Outbound messages waiting for connectivity (replaces SharedPreferences queue).
class OutboxEntries extends Table {
  TextColumn get clientId => text()();

  IntColumn get receiverId => integer()();

  IntColumn get senderId => integer()();

  TextColumn get message => text()();

  TextColumn get messageType =>
      text().withDefault(const Constant('text'))();

  DateTimeColumn get createdAt => dateTime()();

  /// FIFO ordering within the queue.
  IntColumn get sortOrder => integer()();

  @override
  Set<Column<Object>> get primaryKey => {clientId};
}
