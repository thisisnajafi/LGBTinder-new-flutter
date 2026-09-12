import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_pusher_providers.dart';
import 'chat_thread_providers.dart';

/// Hides typing indicators on the chat list after 6s without a heartbeat.
const kTypingIndicatorHideDuration = Duration(seconds: 6);

/// Subscribes to Pusher typing events and updates [chatTypingUsersProvider].
final chatTypingSyncProvider = Provider<void>((ref) {
  ref.watch(chatPusherLifecycleProvider);

  final pusher = ref.watch(pusherWebSocketServiceProvider);
  final typing = ref.read(chatTypingUsersProvider.notifier);
  final hideTimers = <int, Timer>{};

  final subscription = pusher.typingStream.listen((event) {
    final userId = event.userId;
    if (userId <= 0) return;

    hideTimers[userId]?.cancel();
    hideTimers.remove(userId);

    if (event.isTyping) {
      typing.setTyping(userId, true);
      hideTimers[userId] = Timer(kTypingIndicatorHideDuration, () {
        typing.setTyping(userId, false);
        hideTimers.remove(userId);
      });
    } else {
      typing.setTyping(userId, false);
    }
  });

  ref.onDispose(() {
    subscription.cancel();
    for (final timer in hideTimers.values) {
      timer.cancel();
    }
    hideTimers.clear();
  });
});

/// Whether a user is currently typing (chat list / previews).
final isUserTypingProvider = Provider.family<bool, int>((ref, userId) {
  ref.watch(chatTypingSyncProvider);
  return ref.watch(chatTypingUsersProvider.select((m) => m[userId] == true));
});
