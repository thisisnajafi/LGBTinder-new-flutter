import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/user_tier.dart';
import '../providers/feature_flags_provider.dart';
import 'session_data_cache_service.dart';

final sessionDataCacheServiceProvider = Provider<SessionDataCacheService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  if (prefs == null) {
    throw StateError('SharedPreferences not initialized');
  }
  return SessionDataCacheService(prefs);
});

/// Cached superlike remaining count — updated on startup and after each send.
final superlikesRemainingProvider =
    StateNotifierProvider<SuperlikesRemainingNotifier, int?>((ref) {
  final cache = ref.watch(sessionDataCacheServiceProvider);
  return SuperlikesRemainingNotifier(cache);
});

class SuperlikesRemainingNotifier extends StateNotifier<int?> {
  SuperlikesRemainingNotifier(this._cache) : super(_cache.getSuperlikesRemainingSync());

  final SessionDataCacheService _cache;

  void refreshFromCache() {
    state = _cache.getSuperlikesRemainingSync();
  }

  Future<void> setCount(int count) async {
    await _cache.setSuperlikesRemaining(count);
    state = count;
  }
}

/// Cached user tier string (basid|silder|golden).
final cachedUserTierProvider =
    StateNotifierProvider<CachedUserTierNotifier, String?>((ref) {
  final cache = ref.watch(sessionDataCacheServiceProvider);
  return CachedUserTierNotifier(cache);
});

class CachedUserTierNotifier extends StateNotifier<String?> {
  CachedUserTierNotifier(this._cache) : super(_cache.getUserTierSync());

  final SessionDataCacheService _cache;

  void refreshFromCache() {
    state = _cache.getUserTierSync();
  }

  Future<void> setTier(String tier) async {
    await _cache.setUserTier(tier);
    state = tier;
  }

  UserTier? get asUserTier {
    final value = state;
    if (value == null) return null;
    return UserTier.values.firstWhere(
      (t) => t.key == value,
      orElse: () => UserTier.basid,
    );
  }
}
