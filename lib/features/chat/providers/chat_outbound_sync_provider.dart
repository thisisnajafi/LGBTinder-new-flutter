import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/api_providers.dart';
import '../../../core/services/app_logger.dart';
import '../data/services/chat_outbound_queue_service.dart';
import 'chat_provider.dart';

/// Flushes queued outbound chat messages FIFO when connectivity returns.
final chatOutboundSyncProvider = Provider<void>((ref) {
  final connectivity = ref.watch(connectivityServiceProvider);
  final notifier = ref.read(chatProvider.notifier);

  Future<void> flush() async {
    AppLogger.info(
      'Online — flushing chat outbound queue',
      tag: ChatOutboundQueueService.logTag,
    );
    await notifier.flushOutboundQueue();
  }

  final subscription = connectivity.connectivityStream.listen((isOnline) {
    if (isOnline) unawaited(flush());
  });

  ref.onDispose(subscription.cancel);

  if (connectivity.isOnline) {
    Future.microtask(flush);
  }
});
