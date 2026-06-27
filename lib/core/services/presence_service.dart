import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/chat/providers/chat_providers.dart';
import '../providers/api_providers.dart';
import '../services/app_logger.dart';

/// Keeps user online status and session activity in sync with the backend.
class PresenceService {
  PresenceService(this._ref);

  final Ref _ref;
  Timer? _heartbeatTimer;

  static const Duration heartbeatInterval = Duration(seconds: 90);

  Future<void> onForeground() async {
    try {
      await _ref.read(chatRepositoryProvider).setOnlineStatus(true);
      await _reportSessionActivity();
      _startHeartbeat();
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to mark user online',
        tag: 'Presence',
        error: e,
      );
      AppLogger.debug('Presence foreground stack: $stack', tag: 'Presence');
    }
  }

  Future<void> onBackground() async {
    _stopHeartbeat();
    try {
      await _ref.read(chatRepositoryProvider).setOnlineStatus(false);
    } catch (e) {
      AppLogger.warning(
        'Failed to mark user offline',
        tag: 'Presence',
        error: e,
      );
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
      unawaited(_reportSessionActivity());
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _reportSessionActivity() async {
    await _ref.read(sessionApiServiceProvider).reportActivity();
  }

  void dispose() {
    _stopHeartbeat();
  }
}

final presenceServiceProvider = Provider<PresenceService>((ref) {
  final service = PresenceService(ref);
  ref.onDispose(service.dispose);
  return service;
});
