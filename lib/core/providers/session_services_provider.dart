import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_logger.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'api_providers.dart';
import '../../features/chat/providers/chat_local_sync_provider.dart';
import '../../features/chat/providers/chat_outbound_sync_provider.dart';
import '../../features/chat/providers/chat_pusher_providers.dart';
import '../../features/chat/providers/chat_typing_providers.dart';
import '../../features/chat/providers/conversation_mute_cache_provider.dart';
import '../../features/calls/providers/incoming_call_provider.dart';
import '../../features/settings/providers/sound_preferences_provider.dart';
import '../cache/match_realtime_sync.dart';
import '../providers/startup_flow_provider.dart';
import '../services/presence_service.dart';

bool _deviceSessionRegistered = false;

/// Registers the current device with the sessions API (IP, location, device name).
final deviceSessionRegistrationProvider = Provider<void>((ref) {
  final startupComplete = ref.watch(startupFlowCompleteProvider);
  final auth = ref.watch(authProvider);
  if (!startupComplete || auth.isLoading || !auth.isAuthenticated) {
    _deviceSessionRegistered = false;
    return;
  }

  if (_deviceSessionRegistered) return;
  _deviceSessionRegistered = true;

  Future.microtask(() async {
    try {
      await ref.read(sessionApiServiceProvider).storeSession();
      await ref.read(presenceServiceProvider).onForeground();
    } catch (e, stack) {
      _deviceSessionRegistered = false;
      AppLogger.warning(
        'Failed to register device session',
        tag: 'Session',
        error: e,
      );
      AppLogger.debug('Session registration stack: $stack', tag: 'Session');
    }
  });
});

/// Starts chat, sound, and realtime services only after auth is confirmed.
/// Avoids authenticated API calls on splash/welcome for logged-out users.
final sessionServicesProvider = Provider<void>((ref) {
  final startupComplete = ref.watch(startupFlowCompleteProvider);
  final auth = ref.watch(authProvider);
  if (!startupComplete || auth.isLoading || !auth.isAuthenticated) return;

  ref.watch(deviceSessionRegistrationProvider);
  ref.watch(matchRealtimeSyncProvider);
  ref.watch(chatPusherLifecycleProvider);
  ref.watch(chatTypingSyncProvider);
  ref.watch(incomingCallListenerProvider);
  ref.watch(messageSoundListenerProvider);
  ref.watch(soundPreferencesProvider);
  ref.watch(chatOutboundSyncProvider);
  ref.watch(conversationMuteCacheProvider);
  ref.watch(chatLocalSyncProvider);
});
