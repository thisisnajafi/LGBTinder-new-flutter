import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/discover/providers/discover_cache_provider.dart';
import '../../shared/services/cache_service.dart';
import '../providers/api_providers.dart';
import 'cache_providers.dart';
import 'session_cache_providers.dart';
import 'image_cache_service.dart';
import 'user_cache_service.dart';
import 'package:lgbtindernew/core/services/app_logger.dart';

/// Centralized cache invalidation for app events.
class CacheInvalidator {
  CacheInvalidator(this._ref);

  final Ref _ref;

  UserCacheService get _userCache => _ref.read(userCacheServiceProvider);
  CacheService get _legacyCache => _ref.read(cacheServiceProvider);

  /// Full purge on logout.
  Future<void> purgeAll() async {
    await _userCache.invalidateAll();
    await _legacyCache.clearAllCache();
    try {
      await _ref.read(sessionDataCacheServiceProvider).clearAll();
    } catch (e) {
      AppLogger.warning(
        'Session cache purge failed',
        tag: 'cache_invalidator',
        error: e,
      );
    }
    try {
      await LgbtfinderImageCacheManager().emptyCache();
    } catch (e) { AppLogger.warning('Silently caught exception', tag: 'cache_invalidator', error: e); }
  }

  /// Own or other user profile updated / blocked / reported.
  Future<void> purgeProfile(String userId) async {
    await _userCache.invalidateProfile(userId);
    final numericId = int.tryParse(userId);
    if (numericId != null) {
      await _legacyCache.clearCache(CacheKeys.userProfile(numericId));
    }
    final currentId = await _resolveCurrentUserId();
    if (currentId != null && userId == currentId) {
      await _legacyCache.clearCache(CacheKeys.myProfile);
      await _legacyCache.clearCache(CacheKeys.currentUser);
    }
  }

  Future<void> purgeMatchList({String? userId}) async {
    final id = userId ?? await _resolveCurrentUserId();
    if (id != null) {
      await _userCache.invalidateMatchList(id);
      final numericId = int.tryParse(id);
      if (numericId != null) {
        await _legacyCache.clearCache(CacheKeys.userMatches(numericId));
      }
    }
  }

  Future<void> purgeDiscoveryCards({String? userId}) async {
    final id = userId ?? await _resolveCurrentUserId();
    if (id != null) {
      await _userCache.invalidateDiscoveryCards(id);
    }
    await _legacyCache.clearCache(CacheKeys.discoverFeed);
    _ref.read(discoverCacheProvider.notifier).loadFromCache();
  }

  Future<String?> _resolveCurrentUserId() async {
    try {
      final session =
          await _ref.read(tokenStorageServiceProvider).getUserSession();
      return session?.user.id.toString();
    } catch (_) {
      return null;
    }
  }
}

final cacheInvalidatorProvider = Provider<CacheInvalidator>((ref) {
  return CacheInvalidator(ref);
});
