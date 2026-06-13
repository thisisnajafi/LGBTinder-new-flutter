import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/feature_flags_provider.dart';
import '../../../core/providers/api_providers.dart';
import '../../../shared/services/token_storage_service.dart';
import '../../chat/providers/chat_pusher_providers.dart';
import '../../chat/providers/conversation_mute_cache_provider.dart';
import '../../../shared/services/pusher_websocket_service.dart';
import '../data/models/sound_preferences.dart';
import '../data/services/sound_preferences_service.dart';

const _prefsMessageKey = 'sound_message';
const _prefsCallKey = 'sound_call_ringtone';
const _prefsNotificationKey = 'sound_notification';
const _prefsVibrationKey = 'sound_vibration_enabled';

/// Singleton that plays in-app sounds and exposes selected ringtone ids.
class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();

  final AudioPlayer _previewPlayer = AudioPlayer();
  SoundPreferences _preferences = const SoundPreferences();
  SoundCatalog _catalog = const SoundCatalog();
  SharedPreferences? _prefs;
  bool _initialized = false;

  SoundPreferences get preferences => _preferences;
  SoundCatalog get catalog => _catalog;
  bool get vibrationEnabled => _preferences.vibrationEnabled;

  Future<void> initialize({SharedPreferences? prefs}) async {
    if (_initialized) return;
    _prefs = prefs ?? await SharedPreferences.getInstance();
    _preferences = _loadFromPrefs();
    _initialized = true;
  }

  Future<void> syncFromApi(SoundPreferencesService service) async {
    try {
      final remote = await service.getPreferences();
      await applyPreferences(remote, persistLocally: true);
    } catch (e) {
      debugPrint('SoundService.syncFromApi failed: $e');
    }

    try {
      _catalog = await service.getAvailableSounds();
    } catch (e) {
      debugPrint('SoundService catalog fetch failed: $e');
    }
  }

  Future<void> applyPreferences(
    SoundPreferences prefs, {
    bool persistLocally = true,
  }) async {
    _preferences = prefs;
    if (persistLocally) {
      await _persistToPrefs(prefs);
    }
  }

  Future<void> playMessageSound() => _playSound(
        _preferences.messageSound,
        SoundCategory.message,
      );

  Future<void> playNotificationSound() => _playSound(
        _preferences.notificationSound,
        SoundCategory.notification,
      );

  Future<void> previewSound(String soundId, SoundCategory category) async {
    final asset = _assetForSoundId(soundId, category);
    if (asset == null) return;
    await _playAsset(asset);
  }

  String getCallRingtonePath() {
    final option = _catalog.findCallRingtone(_preferences.callRingtone);
    return option?.androidRaw ?? 'ringtone_default';
  }

  String? getNotificationAndroidRaw() {
    final option =
        _catalog.findNotificationSound(_preferences.notificationSound);
    return option?.androidRaw ?? 'message_default';
  }

  String? getNotificationAssetPath() {
    final option =
        _catalog.findNotificationSound(_preferences.notificationSound);
    return option?.asset ?? 'assets/sounds/message_default.wav';
  }

  Future<void> _playSound(String soundId, SoundCategory category) async {
    final asset = _assetForSoundId(soundId, category);
    if (asset == null) return;
    await _playAsset(asset);
    if (_preferences.vibrationEnabled) {
      await HapticFeedback.mediumImpact();
    }
  }

  String? _assetForSoundId(String soundId, SoundCategory category) {
    switch (category) {
      case SoundCategory.message:
        return _catalog.findMessageSound(soundId)?.asset ??
            'assets/sounds/$soundId.wav';
      case SoundCategory.call:
        return _catalog.findCallRingtone(soundId)?.asset ??
            'assets/sounds/$soundId.wav';
      case SoundCategory.notification:
        return _catalog.findNotificationSound(soundId)?.asset ??
            'assets/sounds/$soundId.wav';
    }
  }

  Future<void> _playAsset(String assetPath) async {
    try {
      await _previewPlayer.stop();
      await _previewPlayer.setAsset(assetPath);
      await _previewPlayer.play();
    } catch (e) {
      debugPrint('SoundService play failed for $assetPath: $e');
    }
  }

  SoundPreferences _loadFromPrefs() {
    final prefs = _prefs;
    if (prefs == null) return const SoundPreferences();
    return SoundPreferences(
      messageSound: prefs.getString(_prefsMessageKey) ?? 'message_default',
      callRingtone: prefs.getString(_prefsCallKey) ?? 'ringtone_default',
      notificationSound:
          prefs.getString(_prefsNotificationKey) ?? 'message_default',
      vibrationEnabled: prefs.getBool(_prefsVibrationKey) ?? true,
    );
  }

  Future<void> _persistToPrefs(SoundPreferences prefs) async {
    final storage = _prefs ?? await SharedPreferences.getInstance();
    _prefs = storage;
    await storage.setString(_prefsMessageKey, prefs.messageSound);
    await storage.setString(_prefsCallKey, prefs.callRingtone);
    await storage.setString(_prefsNotificationKey, prefs.notificationSound);
    await storage.setBool(_prefsVibrationKey, prefs.vibrationEnabled);
  }

  Future<void> dispose() async {
    await _previewPlayer.dispose();
  }
}

final soundPreferencesServiceProvider = Provider<SoundPreferencesService>((ref) {
  return SoundPreferencesService(ref.watch(apiServiceProvider));
});

final soundCatalogProvider = FutureProvider<SoundCatalog>((ref) async {
  return ref.watch(soundPreferencesServiceProvider).getAvailableSounds();
});

final soundPreferencesProvider =
    AsyncNotifierProvider<SoundPreferencesNotifier, SoundPreferences>(
  SoundPreferencesNotifier.new,
);

class SoundPreferencesNotifier extends AsyncNotifier<SoundPreferences> {
  @override
  Future<SoundPreferences> build() async {
    final prefs = ref.watch(sharedPreferencesProvider);
    await SoundService.instance.initialize(prefs: prefs);

    final tokenStorage = ref.watch(tokenStorageServiceProvider);
    final isAuthenticated = await tokenStorage.isAuthenticated();
    if (!isAuthenticated) {
      return SoundService.instance.preferences;
    }

    final service = ref.watch(soundPreferencesServiceProvider);

    try {
      await SoundService.instance.syncFromApi(service);
      return SoundService.instance.preferences;
    } catch (_) {
      return SoundService.instance.preferences;
    }
  }

  Future<void> updatePreferences(SoundPreferences prefs) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(soundPreferencesServiceProvider);
      final updated = await service.updatePreferences(prefs);
      await SoundService.instance.applyPreferences(updated);
      return updated;
    });
  }

  Future<void> refresh() async {
    final tokenStorage = ref.read(tokenStorageServiceProvider);
    if (!await tokenStorage.isAuthenticated()) {
      state = AsyncData(SoundService.instance.preferences);
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(soundPreferencesServiceProvider);
      await SoundService.instance.syncFromApi(service);
      return SoundService.instance.preferences;
    });
  }
}

/// Plays message sounds for incoming Pusher messages when not in the active chat.
final messageSoundListenerProvider = Provider<void>((ref) {
  final sub = ref.watch(pusherWebSocketServiceProvider).messageStream.listen(
    (message) async {
      final lifecycle = ref.read(chatPusherLifecycleProvider);
      final currentUserId = lifecycle.userId;
      if (currentUserId == null || message.senderId == currentUserId) {
        return;
      }
      if (lifecycle.activePeerUserId == message.senderId) {
        return;
      }
      if (ref.read(conversationMuteCacheProvider).contains(message.senderId)) {
        return;
      }
      await SoundService.instance.playMessageSound();
    },
  );

  ref.onDispose(sub.cancel);
});
