import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/message.dart';
import '../data/local/chat_database_provider.dart';
import 'chat_pusher_providers.dart';

/// Persists Pusher message events to SQLite (PERF-INFRA-003).
/// UI layers should watch [chatProvider] / local streams — not call setState from here.
final chatLocalSyncProvider = Provider<void>((ref) {
  ref.watch(chatLocalInitProvider);
  ref.watch(chatPusherLifecycleProvider);

  final pusher = ref.watch(pusherWebSocketServiceProvider);
  final localRepo = ref.read(chatLocalRepositoryProvider);

  final messageSub = pusher.messageStream.listen((message) {
    final lifecycle = ref.read(chatPusherLifecycleProvider);
    final currentUserId = lifecycle.userId ?? pusher.currentUserId;
    if (currentUserId == null || currentUserId <= 0) return;

    final otherUserId = message.senderId == currentUserId
        ? message.receiverId
        : message.senderId;
    if (otherUserId <= 0) return;

    unawaited(localRepo.upsertMessage(message, otherUserId));
    unawaited(
      localRepo.patchConversationPreview(
        otherUserId: otherUserId,
        lastMessagePreview: _previewForMessage(message),
        lastMessageAt: message.createdAt,
      ),
    );
  });

  ref.onDispose(() {
    unawaited(messageSub.cancel());
  });
});

String _previewForMessage(Message message) {
  switch (message.messageType) {
    case 'image':
      return 'Photo';
    case 'voice':
      return 'Voice message';
    case 'video':
      return 'Video';
    case 'profile_link':
      return 'Shared a profile';
    default:
      final text = message.message.trim();
      return text.isNotEmpty ? text : 'Message';
  }
}
