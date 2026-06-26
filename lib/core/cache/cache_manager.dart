import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/matching/data/models/match.dart';
import '../../features/matching/data/services/likes_service.dart';
import '../../features/matching/providers/likes_providers.dart';
import '../../features/profile/data/models/user_profile.dart';
import '../../features/profile/data/services/profile_service.dart';
import '../../features/profile/providers/profile_providers.dart';
import '../providers/api_providers.dart';
import 'cache_config.dart';
import 'cache_providers.dart';
import '../providers/subscription_provider.dart';
import 'user_cache_service.dart';
import 'cache_invalidator.dart';
import 'user_profile_providers.dart';

/// Central cache orchestrator — stale-while-revalidate for profiles and matches.
class AppCacheManager {
  AppCacheManager(this._ref);

  final Ref _ref;

  UserCacheService get _userCache => _ref.read(userCacheServiceProvider);
  ProfileService get _profileService => _ref.read(profileServiceProvider);
  LikesService get _likesService => _ref.read(likesServiceProvider);

  Future<String?> _currentUserId() async {
    final session =
        await _ref.read(tokenStorageServiceProvider).getUserSession();
    return session?.user.id.toString();
  }

  /// Revalidate a single user profile; updates [userProfileProvider] on change.
  Future<void> revalidate(String userId) async {
    final currentId = await _currentUserId();
    final ttl = CacheConfig.profileTtlForUser(userId, currentId);

    final cached = await _userCache.getProfile(userId, allowStale: true);
    if (cached != null) {
      _ref.read(userProfileProvider(userId).notifier).applyCached(cached.data);
    }

    try {
      final numericId = int.parse(userId);
      final fresh = await _profileService.getUserProfile(numericId);

      if (cached == null || !_profilesEqual(cached.data, fresh)) {
        await _userCache.saveProfile(userId, fresh, ttl: ttl);
        _ref.read(userProfileProvider(userId).notifier).applyFresh(fresh);
      }
      _ref.read(servingCachedContentProvider.notifier).state = false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppCacheManager.revalidate($userId): $e');
      }
      if (cached != null) {
        _ref.read(servingCachedContentProvider.notifier).state = true;
        _ref
            .read(userProfileProvider(userId).notifier)
            .applyCached(cached.data);
      } else {
        _ref.read(userProfileProvider(userId).notifier).applyError(
              e,
              StackTrace.current,
            );
      }
    }
  }

  /// Revalidate logged-in user's own profile.
  Future<void> revalidateOwnProfile() async {
    final userId = await _currentUserId();
    if (userId == null) return;

    final cached = await _userCache.getProfile(userId, allowStale: true);
    if (cached != null) {
      _ref.read(ownProfileProvider.notifier).applyCached(cached.data);
    }

    try {
      final fresh = await _profileService.getMyProfile();
      if (cached == null || !_profilesEqual(cached.data, fresh)) {
        await _userCache.saveProfile(
          userId,
          fresh,
          ttl: CacheConfig.ownProfileTtl,
        );
        _ref.read(ownProfileProvider.notifier).applyFresh(fresh);
      }
      _ref.read(servingCachedContentProvider.notifier).state = false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppCacheManager.revalidateOwnProfile: $e');
      }
      if (cached != null) {
        _ref.read(servingCachedContentProvider.notifier).state = true;
        _ref.read(ownProfileProvider.notifier).applyCached(cached.data);
      }
    }
  }

  /// Pull-to-refresh: own profile + match list.
  Future<void> revalidateAll() async {
    final userId = await _currentUserId();
    if (userId == null) return;

    await Future.wait([
      revalidateOwnProfile(),
      revalidateMatchList(userId),
      _ref.read(subscriptionRefreshProvider).refresh(),
    ]);
  }

  Future<void> revalidateMatchList(String userId) async {
    final cached = await _userCache.getMatchList(userId, allowStale: true);
    if (cached != null) {
      _ref.read(cachedMatchesProvider.notifier).applyCached(cached.data);
    }

    try {
      final fresh = await _likesService.getMatches();
      if (cached == null || !_matchesEqual(cached.data, fresh)) {
        await _userCache.saveMatchList(userId, fresh);
        _ref.read(cachedMatchesProvider.notifier).applyFresh(fresh);
      }
      _ref.read(servingCachedContentProvider.notifier).state = false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppCacheManager.revalidateMatchList: $e');
      }
      if (cached != null) {
        _ref.read(servingCachedContentProvider.notifier).state = true;
        _ref.read(cachedMatchesProvider.notifier).applyCached(cached.data);
      }
    }
  }

  bool _profilesEqual(UserProfile a, UserProfile b) {
    return a.toJson().toString() == b.toJson().toString();
  }

  bool _matchesEqual(List<Match> a, List<Match> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].toJson().toString() != b[i].toJson().toString()) return false;
    }
    return true;
  }
}

final appCacheManagerProvider = Provider<AppCacheManager>((ref) {
  return AppCacheManager(ref);
});

/// Call when a new match is detected (swipe, push, websocket, etc.).
Future<void> notifyNewMatch(WidgetRef ref) async {
  await ref.read(cacheInvalidatorProvider).purgeMatchList();
  final session =
      await ref.read(tokenStorageServiceProvider).getUserSession();
  final userId = session?.user.id.toString();
  if (userId != null) {
    await ref.read(appCacheManagerProvider).revalidateMatchList(userId);
  }
}

/// Same as [notifyNewMatch] but for contexts with [Ref] only (not [WidgetRef]).
Future<void> notifyNewMatchRef(Ref ref) async {
  await ref.read(cacheInvalidatorProvider).purgeMatchList();
  final session =
      await ref.read(tokenStorageServiceProvider).getUserSession();
  final userId = session?.user.id.toString();
  if (userId != null) {
    await ref.read(appCacheManagerProvider).revalidateMatchList(userId);
  }
}
