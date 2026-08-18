import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/chat/providers/chat_pusher_providers.dart';
import '../services/app_logger.dart';
import '../services/presence_service.dart';
import 'cache_manager.dart';

/// Revalidates caches when the app returns to the foreground.
/// Also drives presence markOnline / markOffline from app lifecycle.
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
    // Cold start: app is already resumed — lifecycle callback is not fired.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeMarkOnline(reason: 'cold_start');
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool get _canMarkPresence {
    final auth = ref.read(authProvider);
    return auth.isAuthenticated && !auth.isLoading;
  }

  void _maybeMarkOnline({required String reason}) {
    if (!_canMarkPresence) {
      AppLogger.info(
        'Skip markOnline ($reason): not authenticated yet',
        tag: 'Lifecycle',
      );
      return;
    }
    AppLogger.info(
      'App lifecycle → marking online ($reason)',
      tag: 'Lifecycle',
    );
    unawaited(ref.read(presenceServiceProvider).onForeground());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AppLogger.info('App lifecycle: $state', tag: 'Lifecycle');

    switch (state) {
      case AppLifecycleState.resumed:
        if (_canMarkPresence) {
          // Mark online FIRST, then revalidate profile so is_online is fresh.
          unawaited(() async {
            AppLogger.info(
              'App lifecycle: resumed → marking online then revalidating',
              tag: 'Lifecycle',
            );
            await ref.read(presenceServiceProvider).onForeground();
            await ref.read(appCacheManagerProvider).revalidateAll();
            unawaited(
              ref.read(chatPusherLifecycleProvider.notifier).reconnect(),
            );
          }());
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        if (_canMarkPresence) {
          AppLogger.info(
            'App lifecycle: $state → marking offline',
            tag: 'Lifecycle',
          );
          unawaited(ref.read(presenceServiceProvider).onBackground());
        }
        break;
      case AppLifecycleState.inactive:
        // Transitioning — do not flip presence.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // When auth completes after cold start, mark online immediately.
    ref.listen<AuthProviderState>(authProvider, (previous, next) {
      final wasAuthed = previous?.isAuthenticated == true &&
          previous?.isLoading == false;
      final isAuthed = next.isAuthenticated && !next.isLoading;
      if (!wasAuthed && isAuthed) {
        AppLogger.info(
          'Auth confirmed → marking online',
          tag: 'Lifecycle',
        );
        unawaited(ref.read(presenceServiceProvider).onForeground());
      }
    });

    return widget.child;
  }
}
