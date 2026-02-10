import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_providers.dart';
import '../../../shared/services/cache_service.dart';
import '../data/services/user_service.dart';
import '../data/models/user_info.dart';

/// User Service Provider
final userServiceProvider = Provider<UserService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return UserService(apiService);
});

/// User Info Provider (FutureProvider for async data)
final userInfoProvider = FutureProvider<UserInfo>((ref) async {
  final userService = ref.watch(userServiceProvider);
  return await userService.getUserInfo();
});

/// Cached current user: load from cache first (instant on page switch), then refresh from API.
/// If API response differs, cache is updated and UI shows new data.
final cachedCurrentUserProvider =
    StateNotifierProvider<CachedCurrentUserNotifier, AsyncValue<UserInfo>>((ref) {
  return CachedCurrentUserNotifier(
    ref.read(userServiceProvider),
    ref.read(cacheServiceProvider),
  );
});

class CachedCurrentUserNotifier extends StateNotifier<AsyncValue<UserInfo>> {
  CachedCurrentUserNotifier(this._userService, this._cacheService)
      : super(const AsyncValue.loading()) {
    load();
  }

  final UserService _userService;
  final CacheService _cacheService;

  /// Load current user: show from cache immediately, then fetch from API and update if different.
  Future<void> load() async {
    // 1) Load from cache so UI can show immediately when switching to discover
    final cached = await _cacheService.getCached<UserInfo>(
      CacheKeys.currentUser,
      (json) => UserInfo.fromJson(json),
      customExpiry: CacheDuration.profile,
    );
    if (cached != null) {
      state = AsyncData(cached);
    }

    // 2) Fetch from API
    try {
      final raw = await _userService.getUserInfoRaw();
      if (raw == null) return;

      final fromApi = UserInfo.fromJson(raw);

      // 3) Update cache and state (if different, set new cache and show)
      await _cacheService.cacheData(
        CacheKeys.currentUser,
        raw,
        duration: CacheDuration.profile,
      );
      state = AsyncData(fromApi);
    } catch (e, st) {
      if (!state.hasValue) {
        state = AsyncError(e, st);
      }
    }
  }

  /// Invalidate cache (e.g. after profile update or logout)
  Future<void> invalidate() async {
    await _cacheService.clearCache(CacheKeys.currentUser);
    state = const AsyncValue.loading();
    await load();
  }
}
