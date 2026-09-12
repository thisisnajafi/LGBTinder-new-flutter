import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_logger.dart';
import '../data/local/chat_info_cache.dart';
import 'chat_providers.dart';

/// Pinned message count for a peer (PERF-PAGE-CHAT-003 — no FutureBuilder in build).
final pinnedCountProvider = FutureProvider.family<int, int>((ref, userId) async {
  if (userId <= 0) return 0;
  final cached =
      ref.read(chatInfoCacheProvider.notifier).snapshotFor(userId).pinnedCount;
  try {
    return await ref.watch(chatServiceProvider).getPinnedMessagesCount(userId);
  } catch (e) {
    AppLogger.warning(
      'Pinned count fetch failed; using cache',
      tag: 'Chat',
      error: e,
    );
    return cached;
  }
});
