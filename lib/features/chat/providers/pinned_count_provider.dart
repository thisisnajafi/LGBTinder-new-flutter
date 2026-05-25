import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_providers.dart';

/// Pinned message count for a peer (PERF-PAGE-CHAT-003 — no FutureBuilder in build).
final pinnedCountProvider = FutureProvider.family<int, int>((ref, userId) async {
  if (userId <= 0) return 0;
  try {
    final chatService = ref.watch(chatServiceProvider);
    return await chatService.getPinnedMessagesCount(userId);
  } catch (_) {
    return 0;
  }
});
