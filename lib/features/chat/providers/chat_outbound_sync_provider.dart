import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/api_providers.dart';
import 'chat_provider.dart';
import 'chat_providers.dart';

/// Flushes queued outbound chat messages when connectivity returns.
final chatOutboundSyncProvider = Provider<void>((ref) {
  final connectivity = ref.watch(connectivityServiceProvider);
  final notifier = ref.read(chatProvider.notifier);

  final subscription = connectivity.connectivityStream.listen((isOnline) {
    if (isOnline) {
      if (kDebugMode) {
        debugPrint('📡 Online — flushing chat outbound queue');
      }
      unawaited(notifier.flushOutboundQueue());
    }
  });

  ref.onDispose(subscription.cancel);

  // Attempt flush on startup when already online.
  if (connectivity.isOnline) {
    Future.microtask(() => notifier.flushOutboundQueue());
  }
});
