import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/app_logger.dart';
import '../../core/services/startup_cache_service.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Primes session caches after auth and on foreground resume (>5 min).
class StartupCacheListener extends ConsumerStatefulWidget {
  const StartupCacheListener({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<StartupCacheListener> createState() =>
      _StartupCacheListenerState();
}

class _StartupCacheListenerState extends ConsumerState<StartupCacheListener> {
  AppLifecycleListener? _lifecycleListener;
  bool _hasPrimedThisSession = false;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        final startup = ref.read(startupCacheServiceProvider);
        if (startup.shouldReprimeOnForeground()) {
          AppLogger.info(
            'Foreground resume — repriming startup cache',
            tag: 'StartupCache',
          );
          unawaited(startup.primeCache());
        }
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    super.dispose();
  }

  void _maybePrime() {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated || auth.isLoading) return;
    if (_hasPrimedThisSession) return;

    _hasPrimedThisSession = true;
    AppLogger.info(
      'Auth confirmed — priming startup cache in background',
      tag: 'StartupCache',
    );
    unawaited(ref.read(startupCacheServiceProvider).primeCache());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthProviderState>(authProvider, (previous, next) {
      if (next.isAuthenticated && !next.isLoading) {
        _maybePrime();
      }
      if (!next.isAuthenticated) {
        _hasPrimedThisSession = false;
      }
    });

    final auth = ref.watch(authProvider);
    if (auth.isAuthenticated && !auth.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybePrime());
    }

    return widget.child;
  }
}
