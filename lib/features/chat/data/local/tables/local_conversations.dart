import 'package:drift/drift.dart';

/// Cached chat list row (other user as primary key).
class LocalConversations extends Table {
  IntColumn get otherUserId => integer()();

  IntColumn get conversationId => integer().nullable()();

  TextColumn get firstName => text()();

  TextColumn get lastName => text().nullable()();

  TextColumn get primaryImageUrl => text().nullable()();

  TextColumn get lastMessagePreview => text().nullable()();

  DateTimeColumn get lastMessageAt => dateTime().nullable()();

  IntColumn get unreadCount =>
      integer().withDefault(const Constant(0))();

  BoolColumn get isMuted =>
      boolean().withDefault(const Constant(false))();

  /// When this row was last written from network or Pusher.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {otherUserId};
}
