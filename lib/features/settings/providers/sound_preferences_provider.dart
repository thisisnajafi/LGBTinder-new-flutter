import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/app_logger.dart';
import '../../../core/providers/feature_flags_provider.dart';
import '../../../core/providers/api_providers.dart';
import '../../chat/providers/chat_pusher_providers.dart';
import '../../chat/providers/conversation_mute_cache_provider.dart';
import '../data/models/sound_preferences.dart';
import '../data/services/sound_preferences_service.dart';

const _prefsMessageKey = 'sound_message';
const _prefsCallKey = 'sound_call_ringtone';
const _prefsNotificationKey = 'sound_notification';
const _prefsVibrationKey = 'sound_vibration_enabled';

/// Singleton that plays in-app sounds and exposes selected ringtone ids.
///
/// Uses [audioplayers] (already used for voice messages). Do not use
/// `just_audio` here — its Android plugin crashes the process with
/// `NoClassDefFoundError: AudioPlayer$1` on several devices/emulators.
class SoundService {
  static final SoundService instance = SoundService._();

  static const _messageDefaultAsset = 'assets/sounds/message_default.wav';
  static const _ringbackAsset = 'assets/sounds/call_ringback.wav';
  static const _busyAsset = 'assets/sounds/call_busy.wav';
  static const _endAsset = 'assets/sounds/call_end.wav';
  static const _connectAsset = 'assets/sounds/call_connect.wav';

  AudioPlayer? _previewPlayer;
  AudioPlayer? _callPlayer;
  bool _playersUnavailable = false;
  final Map<String, String> _materializedAssets = {};
  SoundPreferences _preferences = const SoundPreferences();
  SoundCatalog _catalog = const SoundCatalog();
  SharedPreferences? _prefs;
  bool _initialized = false;

  SoundService._();

  AudioPlayer? _playerOrNull({required bool preview}) {
    if (_playersUnavailable) return null;
    try {
      if (preview) {
        return _previewPlayer ??= AudioPlayer();
      }
      return _callPlayer ??= AudioPlayer();
    } catch (e, st) {
      _playersUnavailable = true;
      AppLogger.warning(
        'AudioPlayer init failed',
        tag: 'SoundService',
        error: e,
      );
      AppLogger.debug('$st', tag: 'SoundService');
      return null;
    }
  }

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
      AppLogger.warning('syncFromApi failed', tag: 'SoundService', error: e);
    }

    try {
      _catalog = await service.getAvailableSounds();
    } catch (e) {
      AppLogger.warning('catalog fetch failed', tag: 'SoundService', error: e);
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
    await _playPreview(asset);
  }

  /// Loop the user's selected incoming ringtone (in-app / foreground).
  Future<void> startIncomingRingtone() async {
    await _startCallLoop(getCallRingtoneAsset());
    if (_preferences.vibrationEnabled) {
      await HapticFeedback.mediumImpact();
    }
  }

  /// Loop the outgoing ringback tone until the callee answers.
  Future<void> startOutgoingRingback() => _startCallLoop(_ringbackAsset);

  Future<void> playCallConnect() => _playCallOneShot(_connectAsset);

  Future<void> playCallBusy() => _playCallOneShot(_busyAsset);

  Future<void> playCallEnded() => _playCallOneShot(_endAsset);

  Future<void> stopCallSounds() async {
    try {
      await _callPlayer?.stop();
    } catch (e) {
      AppLogger.warning('stopCallSounds failed', tag: 'SoundService', error: e);
    }
  }

  String getCallRingtonePath() {
    final option = _catalog.findCallRingtone(_preferences.callRingtone);
    return option?.androidRaw ?? 'ringtone_default';
  }

  String getCallRingtoneAsset() {
    return _catalog.findCallRingtone(_preferences.callRingtone)?.asset ??
        'assets/sounds/${_preferences.callRingtone}.wav';
  }

  String? getNotificationAndroidRaw() {
    final option =
        _catalog.findNotificationSound(_preferences.notificationSound);
    return option?.androidRaw ?? 'message_default';
  }

  String? getNotificationAssetPath() {
    final option =
        _catalog.findNotificationSound(_preferences.notificationSound);
    return option?.asset ?? _messageDefaultAsset;
  }

  Future<void> _playSound(String soundId, SoundCategory category) async {
    final asset = _assetForSoundId(soundId, category);
    if (asset == null) return;
    await _playPreview(asset);
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

  Future<void> _playPreview(String assetPath) async {
    final player = _playerOrNull(preview: true);
    if (player == null) {
      await _playSystemFallback();
      return;
    }
    final ok = await _playAsset(player, assetPath, loop: false);
    if (!ok) await _playSystemFallback();
  }

  Future<void> _startCallLoop(String assetPath) async {
    final player = _playerOrNull(preview: false);
    if (player == null) {
      await _playSystemFallback();
      return;
    }
    final ok = await _playAsset(player, assetPath, loop: true);
    if (!ok) await _playSystemFallback();
  }

  Future<void> _playCallOneShot(String assetPath) async {
    final player = _playerOrNull(preview: false);
    if (player == null) {
      await _playSystemFallback();
      return;
    }
    final ok = await _playAsset(player, assetPath, loop: false);
    if (!ok) await _playSystemFallback();
  }

  Future<bool> _playAsset(
    AudioPlayer player,
    String assetPath, {
    required bool loop,
  }) async {
    try {
      await player.stop();
      await player.setReleaseMode(
        loop ? ReleaseMode.loop : ReleaseMode.release,
      );
      if (kIsWeb) {
        await player.play(AssetSource(_assetSourcePath(assetPath)));
      } else {
        // File source avoids asset sniffing issues with bundled WAVs.
        final path = await _materializeAsset(assetPath);
        await player.play(DeviceFileSource(path));
      }
      return true;
    } catch (e) {
      AppLogger.warning(
        'play failed for $assetPath',
        tag: 'SoundService',
        error: e,
      );
      try {
        await player.stop();
      } catch (stopError) {
        AppLogger.warning(
          'stop after play failure failed',
          tag: 'SoundService',
          error: stopError,
        );
      }
      return false;
    }
  }

  /// audioplayers AssetSource paths are relative to the assets/ root.
  String _assetSourcePath(String assetPath) {
    const prefix = 'assets/';
    if (assetPath.startsWith(prefix)) {
      return assetPath.substring(prefix.length);
    }
    return assetPath;
  }

  Future<String> _materializeAsset(String assetPath) async {
    final cached = _materializedAssets[assetPath];
    if (cached != null && File(cached).existsSync()) {
      return cached;
    }

    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    if (bytes.length < 12 ||
        bytes[0] != 0x52 ||
        bytes[1] != 0x49 ||
        bytes[2] != 0x46 ||
        bytes[3] != 0x46) {
      throw StateError('Sound asset is not a RIFF WAV: $assetPath');
    }

    final dir = await getTemporaryDirectory();
    final soundDir = Directory('${dir.path}/lgbtinder_sounds');
    await soundDir.create(recursive: true);
    final file = File(
      '${soundDir.path}/${assetPath.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')}',
    );
    await file.writeAsBytes(bytes, flush: true);
    _materializedAssets[assetPath] = file.path;
    return file.path;
  }

  Future<void> _playSystemFallback() async {
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      AppLogger.warning(
        'system sound fallback failed',
        tag: 'SoundService',
        error: e,
      );
    }
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      AppLogger.warning(
        'haptic fallback failed',
        tag: 'SoundService',
        error: e,
      );
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
    try {
      await _previewPlayer?.dispose();
    } catch (e) {
      AppLogger.warning(
        'preview player dispose failed',
        tag: 'SoundService',
        error: e,
      );
    }
    try {
      await _callPlayer?.dispose();
    } catch (e) {
      AppLogger.warning(
        'call player dispose failed',
        tag: 'SoundService',
        error: e,
      );
    }
    _previewPlayer = null;
    _callPlayer = null;
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
    } catch (e) {
      AppLogger.warning(
        'sync preferences on build failed',
        tag: 'SoundService',
        error: e,
      );
      return SoundService.instance.preferences;
    }
  }

  Future<void> updatePreferences(SoundPreferences prefs) async {
    // PERF-FEAT-SET-002: keep prior data so the sound list does not unmount.
    final previous = state.valueOrNull;
    state = AsyncData(prefs);
    try {
      final service = ref.read(soundPreferencesServiceProvider);
      final updated = await service.updatePreferences(prefs);
      await SoundService.instance.applyPreferences(updated);
      state = AsyncData(updated);
    } catch (e, st) {
      if (previous != null) {
        state = AsyncData(previous);
      } else {
        state = AsyncError(e, st);
      }
      rethrow;
    }
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
