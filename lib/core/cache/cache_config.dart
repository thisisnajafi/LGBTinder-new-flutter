/// Central cache configuration: TTLs, key patterns, and size limits.
class CacheConfig {
  CacheConfig._();

  // ── TTLs ──────────────────────────────────────────────────────────────────
  static const Duration ownProfileTtl = Duration(minutes: 10);
  static const Duration otherProfileTtl = Duration(minutes: 5);
  static const Duration discoveryCardsTtl = Duration(minutes: 2);
  static const Duration matchListTtl = Duration(minutes: 3);
  static const Duration avatarTtl = Duration(minutes: 30);
  static const Duration profileImageTtl = Duration(minutes: 30);
  static const Duration referenceDataTtl = Duration(hours: 24);

  // ── Key patterns ──────────────────────────────────────────────────────────
  static String userProfileKey(String userId) => 'user:profile:$userId';
  static String discoveryCardsKey(String userId) => 'discovery:cards:$userId';
  static String matchListKey(String userId) => 'matches:$userId';
  static String avatarKey(String userId) => 'avatar:$userId';
  static String profileImageKey(String userId, int index) =>
      'images:$userId:$index';
  static String referenceDataKey(String type) => 'ref:$type';

  // ── Disk prefix (shared_preferences) ─────────────────────────────────────
  static const String diskPrefix = 'lgbtfinder_cache_';
  static const String diskTimestampSuffix = '_ts';
  static const String diskTtlSuffix = '_ttl';

  // ── Image cache (flutter_cache_manager) ───────────────────────────────────
  static const String imageCacheKey = 'lgbtfinder_image_cache';
  static const int imageCacheMaxObjects = 500;
  static const Duration imageCacheStalePeriod = Duration(hours: 30);

  static Duration profileTtlForUser(String userId, String? currentUserId) {
    if (currentUserId != null && userId == currentUserId) {
      return ownProfileTtl;
    }
    return otherProfileTtl;
  }
}
