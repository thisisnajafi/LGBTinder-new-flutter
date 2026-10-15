import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/chat/providers/chat_providers.dart';
import '../providers/api_providers.dart';
import '../providers/own_presence_provider.dart';
import '../services/app_logger.dart';
import 'presence_lifecycle.dart';

/// Keeps user online status and session activity in sync with the backend.
class PresenceService {
  PresenceService(this._ref);

  final Ref _ref;
  Timer? _heartbeatTimer;
  final PresenceChangeDebouncer _debouncer = PresenceChangeDebouncer(
    window: PresenceService.statusDebounce,
  );
  bool? _appliedOnline;

  /// Inside the server presence TTL (90s) and no more often than once a minute.
  static const Duration heartbeatInterval = Duration(seconds: 45);

  /// Lifecycle flaps (permission UI, app switcher) wait this long.
  static const Duration statusDebounce = Duration(seconds: 2);

  void onForeground() {
    _schedule(true);
  }

  void onBackground() {
    stopHeartbeat();
    _schedule(false);
  }

  void _schedule(bool online) {
    _debouncer.schedule(online, (value) {
      if (_appliedOnline == value) {
        if (value) startHeartbeat();
        return;
      }
      _appliedOnline = value;
      if (value) {
        unawaited(_goOnline());
      } else {
        unawaited(_goOffline());
      }
    });
  }

  Future<void> _goOnline() async {
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

  Future<void> _goOffline() async {
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
    AppLogger.info(
      'Heartbeat started (${heartbeatInterval.inSeconds}s interval)',
      tag: 'Presence',
    );
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
    _debouncer.dispose();
    stopHeartbeat();
  }
}

final presenceServiceProvider = Provider<PresenceService>((ref) {
  final service = PresenceService(ref);
  ref.onDispose(service.dispose);
  return service;
});
