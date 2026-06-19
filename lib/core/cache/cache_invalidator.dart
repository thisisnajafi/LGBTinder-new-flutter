import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/chat/providers/chat_list_preview_provider.dart';
import '../../features/chat/providers/chat_provider.dart';
import '../../features/chat/providers/chat_providers.dart';
import '../../features/chat/providers/conversation_mute_cache_provider.dart';
import '../../features/discover/providers/discover_cache_provider.dart';
import '../../features/notifications/providers/notifications_cache_provider.dart';
import '../../features/profile/providers/profile_page_cache_provider.dart';
import '../../features/user/providers/user_providers.dart';
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

  /// Full purge on logout or before a new login session.
  Future<void> purgeAll() async {
    try {
      await _ref.read(chatLocalRepositoryProvider).clearAllSessionData();
    } catch (e) {
      AppLogger.warning(
        'Chat local purge failed',
        tag: 'cache_invalidator',
        error: e,
      );
    }

    try {
      await _ref.read(chatOutboundQueueServiceProvider).clear();
    } catch (e) {
      AppLogger.warning(
        'Chat outbox purge failed',
        tag: 'cache_invalidator',
        error: e,
      );
    }

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
    } catch (e) {
      AppLogger.warning(
        'Silently caught exception',
        tag: 'cache_invalidator',
        error: e,
      );
    }

    _resetInMemorySessionState();

    AppLogger.info('Private session cache purged', tag: 'cache_invalidator');
  }

  void _resetInMemorySessionState() {
    try {
      _ref.read(chatProvider.notifier).reset();
    } catch (e) {
      AppLogger.warning(
        'Chat provider reset failed',
        tag: 'cache_invalidator',
        error: e,
      );
    }

    try {
      _ref.read(chatListPreviewProvider.notifier).clearSeed();
    } catch (e) {
      AppLogger.warning(
        'Chat preview reset failed',
        tag: 'cache_invalidator',
        error: e,
      );
    }

    try {
      _ref.read(conversationMuteCacheProvider.notifier).clearAll();
    } catch (e) {
      AppLogger.warning(
        'Conversation mute reset failed',
        tag: 'cache_invalidator',
        error: e,
      );
    }

    try {
      _ref.read(notificationsCacheProvider.notifier).clearAllLocal();
    } catch (e) {
      AppLogger.warning(
        'Notifications cache reset failed',
        tag: 'cache_invalidator',
        error: e,
      );
    }

    try {
      _ref.read(discoverCacheProvider.notifier).resetSession();
    } catch (e) {
      AppLogger.warning(
        'Discover cache reset failed',
        tag: 'cache_invalidator',
        error: e,
      );
    }

    try {
      _ref.read(profilePageCacheProvider.notifier).resetSession();
    } catch (e) {
      AppLogger.warning(
        'Profile page cache reset failed',
        tag: 'cache_invalidator',
        error: e,
      );
    }

    try {
      _ref.read(cachedCurrentUserProvider.notifier).invalidate();
    } catch (e) {
      AppLogger.warning(
        'Current user cache reset failed',
        tag: 'cache_invalidator',
        error: e,
      );
    }
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
    await _legacyCache.clearCacheByPattern('nearby_suggestions_');
    _ref.read(discoverCacheProvider.notifier).resetSession();
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
