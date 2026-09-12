import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/feature_flags_provider.dart';
import '../utils/media_url.dart';
import 'cache_providers.dart';

/// Last-known-good peer avatars, keyed by user id.
class PeerAvatarCache extends Notifier<Map<int, String>> {
  static const prefsKey = 'lgbtfinder_peer_avatar_urls';

  SharedPreferences? get _prefs => ref.read(sharedPreferencesProvider);

  @override
  Map<int, String> build() => _read(_prefs);

  String? urlFor(int userId) => userId > 0 ? state[userId] : null;

  Future<void> remember(int userId, String? url) async {
    final resolved = MediaUrl.resolve(url);
    if (userId <= 0 || resolved == null) return;

    final existing = state[userId];
    if (existing == resolved) {
      unawaited(_prefetch(userId, resolved));
      return;
    }
    if (existing != null && MediaUrl.samePhoto(existing, resolved)) {
      unawaited(_prefetch(userId, existing));
      return;
    }

    // remember() is often called from widget build (ProfileImageWidget).
    // Yield so Riverpod is not notified during the current build pass.
    await Future<void>(() {});
    final latest = state[userId];
    if (latest == resolved ||
        (latest != null && MediaUrl.samePhoto(latest, resolved))) {
      unawaited(_prefetch(userId, latest ?? resolved));
      return;
    }

    state = {...state, userId: resolved};
    await _persist();
    unawaited(_prefetch(userId, resolved));
  }

  Future<void> rememberMany(Map<int, String?> urls) async {
    var changed = false;
    final next = {...state};
    final prefetch = <int, String>{};

    urls.forEach((userId, url) {
      if (userId <= 0) return;
      final resolved = MediaUrl.resolve(url);
      if (resolved == null) return;
      final existing = next[userId];
      if (existing == resolved ||
          (existing != null && MediaUrl.samePhoto(existing, resolved))) {
        prefetch[userId] = existing ?? resolved;
        return;
      }
      next[userId] = resolved;
      prefetch[userId] = resolved;
      changed = true;
    });

    if (changed) {
      await Future<void>(() {});
      state = next;
      await _persist();
    }

    for (final entry in prefetch.entries) {
      unawaited(_prefetch(entry.key, entry.value));
    }
  }

  Future<void> _persist() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final encoded = {
      for (final entry in state.entries) entry.key.toString(): entry.value,
    };
    await prefs.setString(prefsKey, jsonEncode(encoded));
  }

  Future<void> _prefetch(int userId, String url) async {
    try {
      await ref.read(imageCacheServiceProvider).downloadFile(
            url,
            key: MediaUrl.cacheKey(userId: userId, url: url),
          );
    } catch (_) {
      // Non-fatal — [CachedNetworkImage] still loads on screen.
    }
  }

  static Map<int, String> _read(SharedPreferences? prefs) {
    if (prefs == null) return {};
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final out = <int, String>{};
      decoded.forEach((key, value) {
        final id = int.tryParse(key.toString()) ?? 0;
        final url = MediaUrl.resolve(value?.toString());
        if (id > 0 && url != null) {
          out[id] = url;
        }
      });
      return out;
    } catch (_) {
      return {};
    }
  }
}

final peerAvatarCacheProvider =
    NotifierProvider<PeerAvatarCache, Map<int, String>>(PeerAvatarCache.new);
