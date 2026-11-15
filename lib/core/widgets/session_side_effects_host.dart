import 'dart:async';

import 'package:flutter/material.dart';
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

/// Session expired (401): clear the local session, *then* open welcome.
///
/// The order is load-bearing. The route guard decides from the stored
/// session, and welcome is an auth-entry route: opening it while the token is
/// still stored is read as "signed-in user on the login screen" and
/// redirected straight back to Home, where the user stayed with a dead
/// session. [logout] is the optimistic one (local only, no network wait), so
/// this adds no visible delay.
@visibleForTesting
Future<void> endSessionThenOpenWelcome({
  required Future<void> Function() logout,
  required void Function() openWelcome,
}) async {
  try {
    await logout();
  } catch (e, stack) {
    AppLogger.warning(
      'Silent logout after 401 failed',
      tag: 'Auth',
      error: e,
    );
    AppLogger.debug('Logout stack: $stack', tag: 'Auth');
  }
  try {
    openWelcome();
  } catch (e, stack) {
    AppLogger.error(
      'UnauthorizedHandler callback error',
      tag: 'Auth',
      error: e,
      stackTrace: stack,
    );
  }
}

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
      authLog('401 Unauthorized: ending session, then welcome');
      unawaited(
        endSessionThenOpenWelcome(
          logout: () => ref.read(authProvider.notifier).logout(silent: true),
          openWelcome: () => router.go(AppRoutes.welcome),
        ),
      );
    });
    _attachCallKit();
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
