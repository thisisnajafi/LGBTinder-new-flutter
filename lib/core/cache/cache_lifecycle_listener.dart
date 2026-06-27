import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/chat/providers/chat_pusher_providers.dart';
import '../services/presence_service.dart';
import 'cache_manager.dart';

/// Revalidates caches when the app returns to the foreground.
class CacheLifecycleListener extends ConsumerStatefulWidget {
  const CacheLifecycleListener({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<CacheLifecycleListener> createState() =>
      _CacheLifecycleListenerState();
}

class _CacheLifecycleListenerState extends ConsumerState<CacheLifecycleListener>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(appCacheManagerProvider).revalidateAll();
      unawaited(ref.read(chatPusherLifecycleProvider.notifier).reconnect());
      unawaited(ref.read(presenceServiceProvider).onForeground());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(ref.read(presenceServiceProvider).onBackground());
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
