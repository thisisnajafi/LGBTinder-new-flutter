import 'package:drift/drift.dart';

/// Cached messages for a 1:1 thread (keyed by [otherUserId]).
class LocalMessages extends Table {
  IntColumn get localId => integer().autoIncrement()();

  IntColumn get serverId => integer().nullable()();

  TextColumn get clientId => text().nullable()();

  IntColumn get otherUserId => integer()();

  IntColumn get senderId => integer()();

  IntColumn get receiverId => integer()();

  TextColumn get message => text()();

  TextColumn get messageType =>
      text().withDefault(const Constant('text'))();

  DateTimeColumn get createdAt => dateTime()();

  BoolColumn get isRead =>
      boolean().withDefault(const Constant(false))();

  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();

  TextColumn get attachmentUrl => text().nullable()();

  /// JSON blob for metadata / stickers / profile cards.
  TextColumn get payloadJson => text().nullable()();

  TextColumn get deliveryStatus =>
      text().withDefault(const Constant('sent'))();
}
