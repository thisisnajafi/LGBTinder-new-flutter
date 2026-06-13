import '../../../core/cache/image_cache_service.dart';
import '../data/models/discovery_profile.dart';

/// Prefetches discovery card photos into [LgbtfinderImageCacheManager]
/// before the swipe stack reveals them.
class DiscoveryImagePrefetch {
  DiscoveryImagePrefetch._();

  static List<String> collectUrls({
    List<String>? imageUrls,
    String? primaryImageUrl,
    String? avatarUrl,
  }) {
    final seen = <String>{};
    final list = <String>[];

    void add(String? url) {
      final trimmed = url?.trim();
      if (trimmed == null || trimmed.isEmpty || !seen.add(trimmed)) return;
      list.add(trimmed);
    }

    add(primaryImageUrl);
    add(avatarUrl);
    if (imageUrls != null) {
      for (final url in imageUrls) {
        add(url);
      }
    }
    return list;
  }

  static List<String> urlsFromProfile(DiscoveryProfile profile) {
    return collectUrls(
      imageUrls: profile.imageUrls,
      primaryImageUrl: profile.primaryImageUrl,
    );
  }

  static List<String> urlsFromCardMap(Map<String, dynamic> card) {
    final raw = card['image_urls'];
    final urls = raw is List
        ? raw.map((e) => e?.toString()).whereType<String>().toList()
        : null;
    return collectUrls(
      imageUrls: urls,
      avatarUrl: card['avatar_url']?.toString(),
    );
  }

  static Future<void> prefetchUrl(
    String url, {
    LgbtfinderImageCacheManager? cacheManager,
  }) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    final cache = cacheManager ?? LgbtfinderImageCacheManager();
    try {
      await cache.downloadFile(trimmed);
    } catch (_) {
      // Non-fatal — UI still loads via CachedNetworkImage.
    }
  }

  static Future<void> prefetchUrls(
    Iterable<String> urls, {
    LgbtfinderImageCacheManager? cacheManager,
  }) async {
    final cache = cacheManager ?? LgbtfinderImageCacheManager();
    for (final url in urls) {
      await prefetchUrl(url, cacheManager: cache);
    }
  }

  /// Downloads the front card fully, then the first photo of cards behind it.
  static Future<void> prefetchCardStack(
    List<Map<String, dynamic>> cards, {
    int visibleCount = 3,
  }) async {
    if (cards.isEmpty) return;

    final cache = LgbtfinderImageCacheManager();
    await prefetchUrls(urlsFromCardMap(cards.first), cacheManager: cache);

    for (var i = 1; i < visibleCount && i < cards.length; i++) {
      final urls = urlsFromCardMap(cards[i]);
      if (urls.isNotEmpty) {
        await prefetchUrl(urls.first, cacheManager: cache);
      }
    }
  }

  /// Prefetches photos for the next profiles in the feed (cache/API merge).
  static Future<void> prefetchProfiles(
    Iterable<DiscoveryProfile> profiles, {
    int count = 5,
  }) async {
    final cache = LgbtfinderImageCacheManager();
    var index = 0;
    for (final profile in profiles) {
      if (index >= count) break;
      final urls = urlsFromProfile(profile);
      if (index == 0) {
        await prefetchUrls(urls, cacheManager: cache);
      } else if (urls.isNotEmpty) {
        await prefetchUrl(urls.first, cacheManager: cache);
      }
      index++;
    }
  }
}
