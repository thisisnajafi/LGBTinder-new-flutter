import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/chat/providers/chat_pusher_providers.dart';
import '../../features/matching/providers/likes_providers.dart';
import '../../features/notifications/providers/notification_providers.dart';
import 'cache_manager.dart';

/// Subscribes to Pusher [matchStream] and invalidates match list cache.
final matchRealtimeSyncProvider = Provider<void>((ref) {
  ref.watch(chatPusherLifecycleProvider);
  final pusher = ref.watch(pusherWebSocketServiceProvider);
  final sub = pusher.matchStream.listen((_) {
    unawaited(notifyNewMatchRef(ref));
  });
  ref.onDispose(sub.cancel);
});

/// Subscribes to Pusher [likeStream] and refreshes likes-you + unread badge.
final newLikeRealtimeSyncProvider = Provider<void>((ref) {
  ref.watch(chatPusherLifecycleProvider);
  final pusher = ref.watch(pusherWebSocketServiceProvider);
  final sub = pusher.likeStream.listen((_) {
    ref.invalidate(unreadNotificationCountProvider);
    ref.read(likesReceivedEpochProvider.notifier).state++;
  });
  ref.onDispose(sub.cancel);
});
