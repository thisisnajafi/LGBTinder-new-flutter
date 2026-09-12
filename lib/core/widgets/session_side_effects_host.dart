import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/calls/data/services/call_kit_service.dart';
import '../../features/calls/providers/incoming_call_provider.dart';
import '../../features/payments/providers/payment_providers.dart';
import '../../shared/services/deep_linking_service.dart';
import '../../shared/services/push_notification_service.dart';
import '../auth/banned_handler.dart';
import '../auth/unauthorized_handler.dart';
import '../services/app_logger.dart';
import '../utils/app_logger.dart' show authLog;
import '../../routes/app_router.dart';

/// One-shot 401 / CallKit wiring via [ref.listen] (PERF-MAIN-002).
///
/// Must not live in [MaterialApp] `build` — those callbacks are side effects.
class SessionSideEffectsHost extends ConsumerStatefulWidget {
  const SessionSideEffectsHost({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<SessionSideEffectsHost> createState() =>
      _SessionSideEffectsHostState();
}

class _SessionSideEffectsHostState extends ConsumerState<SessionSideEffectsHost> {
  bool _wired = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthProviderState>(authProvider, (previous, next) {
      if (next.isAuthenticated && previous?.isAuthenticated != true) {
        _attachCallKit();
      }
    });

    if (!_wired) {
      _wired = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _wire(ref.read(appRouterProvider));
      });
    }

    return widget.child;
  }

  void _wire(GoRouter router) {
    DeepLinkingService().initialize(router);
    PushNotificationService().setPremiumAccessChangeHandler(() async {
      await ref.read(subscriptionSyncProvider).onSubscriptionChangeNotification();
    });
    BannedHandler.setCallback(() {
      authLog('403 Banned: redirecting to banned screen');
      router.go(AppRoutes.accountBanned);
    });
    UnauthorizedHandler.setCallback(() {
      authLog('401 Unauthorized: redirecting to welcome');
      try {
        router.go(AppRoutes.welcome);
        Future.microtask(() async {
          try {
            await ref.read(authProvider.notifier).logout(silent: true);
          } catch (e, stack) {
            AppLogger.warning(
              'Silent logout after 401 failed',
              tag: 'Auth',
              error: e,
            );
            AppLogger.debug('Logout stack: $stack', tag: 'Auth');
          }
        });
      } catch (e, stack) {
        AppLogger.error(
          'UnauthorizedHandler callback error',
          tag: 'Auth',
          error: e,
          stackTrace: stack,
        );
      }
    });
    _attachCallKit();
    unawaited(FlutterCallkitIncoming.requestFullIntentPermission());
  }

  void _attachCallKit() {
    unawaited(CallKitService.instance.initialize(
      onAccept: (callId) =>
          ref.read(incomingCallProvider.notifier).acceptFromCallKit(callId),
      onDecline: (callId) =>
          ref.read(incomingCallProvider.notifier).rejectFromCallKit(callId),
      onCallback: (callId) =>
          ref.read(incomingCallProvider.notifier).callbackFromCallKit(callId),
      onTimeout: (callId) =>
          ref.read(incomingCallProvider.notifier).timeoutDismissFor(callId),
    ));
  }
}
