import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/chat/providers/chat_pusher_providers.dart';
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
