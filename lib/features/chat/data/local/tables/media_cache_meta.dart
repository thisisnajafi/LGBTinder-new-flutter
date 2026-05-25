import 'package:drift/drift.dart';

/// Tracks downloaded chat media on disk.
class MediaCacheMeta extends Table {
  TextColumn get url => text()();

  TextColumn get localPath => text().nullable()();

  IntColumn get fileSizeBytes => integer().nullable()();

  DateTimeColumn get cachedAt => dateTime()();

  DateTimeColumn get expiresAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {url};
}
