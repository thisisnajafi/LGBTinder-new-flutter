import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/chat/providers/chat_providers.dart';
import '../providers/api_providers.dart';
import '../providers/own_presence_provider.dart';
import '../services/app_logger.dart';

/// Keeps user online status and session activity in sync with the backend.
class PresenceService {
  PresenceService(this._ref);

  final Ref _ref;
  Timer? _heartbeatTimer;

  static const Duration heartbeatInterval = Duration(seconds: 90);

  Future<void> onForeground() async {
    try {
      AppLogger.info('Marking user online (foreground)', tag: 'Presence');
      await _ref.read(chatRepositoryProvider).setOnlineStatus(true);
      _ref.read(ownPresenceProvider.notifier).markOnline();
      AppLogger.info('Marked online successfully', tag: 'Presence');
      await _reportSessionActivity();
      startHeartbeat();
    } catch (e, stack) {
      AppLogger.error(
        'Failed to mark user online',
        tag: 'Presence',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> onBackground() async {
    stopHeartbeat();
    try {
      AppLogger.info('Marking user offline (background)', tag: 'Presence');
      await _ref.read(chatRepositoryProvider).setOnlineStatus(false);
      _ref.read(ownPresenceProvider.notifier).markOffline();
      AppLogger.info('Marked offline successfully', tag: 'Presence');
    } catch (e, stack) {
      AppLogger.error(
        'Failed to mark user offline',
        tag: 'Presence',
        error: e,
        stackTrace: stack,
      );
    }
  }

  void startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
      unawaited(_reportSessionActivity());
    });
    AppLogger.info('Heartbeat started (90s interval)', tag: 'Presence');
  }

  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    AppLogger.info('Heartbeat stopped', tag: 'Presence');
  }

  Future<void> _reportSessionActivity() async {
    try {
      await _ref.read(sessionApiServiceProvider).reportActivity();
      AppLogger.verbose('Heartbeat sent', tag: 'Presence');
    } catch (e) {
      AppLogger.warning(
        'Heartbeat failed',
        tag: 'Presence',
        error: e,
      );
    }
  }

  void dispose() {
    stopHeartbeat();
  }
}

final presenceServiceProvider = Provider<PresenceService>((ref) {
  final service = PresenceService(ref);
  ref.onDispose(service.dispose);
  return service;
});
