import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'chat_local_repository.dart';

/// Singleton Drift database for chat local-first storage.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final chatLocalRepositoryProvider = Provider<ChatLocalRepository>((ref) {
  return ChatLocalRepository(ref.watch(appDatabaseProvider));
});

/// Runs legacy outbox migration once per app start (non-blocking).
final chatLocalInitProvider = FutureProvider<void>((ref) async {
  await ref.read(chatLocalRepositoryProvider).migrateLegacyOutboxIfNeeded();
});
