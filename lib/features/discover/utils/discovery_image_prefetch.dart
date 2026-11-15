import 'package:flutter/widgets.dart';

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

  /// Longest the Discover stack holds its skeleton for the front photo. After
  /// that the card is shown anyway; it has its own photo placeholder.
  static const Duration frontPhotoWait = Duration(milliseconds: 1500);

  /// Replaces the disk-cache fetch in tests.
  @visibleForTesting
  static Future<void> Function(String url)? debugFetch;

  /// Makes sure [url] is in the disk cache.
  ///
  /// A photo that is already cached and still valid is not requested again
  /// (`getSingleFile`). `downloadFile` asks the server every time, which
  /// re-fetched every photo of the stack on each swipe.
  static Future<void> prefetchUrl(
    String url, {
    LgbtfinderImageCacheManager? cacheManager,
  }) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    try {
      final fetch = debugFetch;
      if (fetch != null) {
        await fetch(trimmed);
      } else {
        final cache = cacheManager ?? LgbtfinderImageCacheManager();
        await cache.getSingleFile(trimmed);
      }
    } catch (_) {
      // Non-fatal — UI still loads via CachedNetworkImage.
    }
  }

  /// First photo of the front card of [cards], or null when it has none.
  static String? frontPhotoUrl(List<Map<String, dynamic>> cards) {
    if (cards.isEmpty) return null;
    final urls = urlsFromCardMap(cards.first);
    return urls.isEmpty ? null : urls.first;
  }

  static Future<void> prefetchUrls(
    Iterable<String> urls, {
    LgbtfinderImageCacheManager? cacheManager,
  }) async {
    for (final url in urls) {
      await prefetchUrl(url, cacheManager: cacheManager);
    }
  }

  /// Downloads the front card fully, then the first photo of cards behind it.
  static Future<void> prefetchCardStack(
    List<Map<String, dynamic>> cards, {
    int visibleCount = 3,
  }) async {
    if (cards.isEmpty) return;

    final frontUrls = urlsFromCardMap(cards.first);
    final behindUrls = <String>[
      for (var i = 1; i < visibleCount && i < cards.length; i++)
        ...urlsFromCardMap(cards[i]).take(1),
    ];
    // Profiles without photos: nothing to fetch, so do not open the disk
    // cache at all.
    if (frontUrls.isEmpty && behindUrls.isEmpty) return;

    await prefetchUrls(frontUrls);
    for (final url in behindUrls) {
      await prefetchUrl(url);
    }
  }

  /// First photo URL for each of the next [nextCount] cards behind the front.
  @visibleForTesting
  static List<String> nextCardPreviewUrls(
    List<DiscoveryProfile> stack, {
    int nextCount = 2,
  }) {
    final urls = <String>[];
    for (var i = 1; i <= nextCount && i < stack.length; i++) {
      final found = urlsFromProfile(stack[i]);
      if (found.isNotEmpty) urls.add(found.first);
    }
    return urls;
  }

  /// Image provider with the same cache key the Discover card uses for a
  /// photo decoded at [decodeWidth] pixels.
  ///
  /// The card shows photos through `CachedNetworkImage(memCacheWidth: w)`,
  /// which stores them in Flutter's image cache as a [ResizeImage]. Warming
  /// the cache with the plain provider decodes a second, full-size copy the
  /// card never reads. Pass null for the full-size provider.
  static ImageProvider<Object> cardPhotoProvider(String url, {int? decodeWidth}) {
    return ResizeImage.resizeIfNeeded(
      decodeWidth,
      null,
      lgbtfinderCachedImageProvider(url.trim()),
    );
  }

  /// Decodes one card photo into Flutter's image cache so showing it later
  /// (next photo tap, next card) does not flash a placeholder.
  static Future<void> precacheCardPhoto(
    BuildContext context,
    String url, {
    int? decodeWidth,
  }) async {
    if (!context.mounted || url.trim().isEmpty) return;
    try {
      await precacheImage(
        cardPhotoProvider(url, decodeWidth: decodeWidth),
        context,
        // Non-fatal: the card still loads the photo itself.
        onError: (_, __) {},
      );
    } catch (_) {
      // Non-fatal — the card still loads via CachedNetworkImage.
    }
  }

  /// Decode the next two stack photos into Flutter's image cache
  /// (PERF-PAGE-DISCOVERY-002).
  ///
  /// Pass the card's [decodeWidth] (`SwipeableCard.photoDecodeWidth`) so the
  /// decoded copy is the one the card reads.
  static Future<void> precacheNextTwo(
    BuildContext context,
    List<DiscoveryProfile> stack, {
    int? decodeWidth,
  }) async {
    if (!context.mounted) return;
    for (final url in nextCardPreviewUrls(stack)) {
      await precacheCardPhoto(context, url, decodeWidth: decodeWidth);
      if (!context.mounted) return;
    }
  }

  /// Prefetches photos for the next profiles in the feed (cache/API merge).
  static Future<void> prefetchProfiles(
    Iterable<DiscoveryProfile> profiles, {
    int count = 5,
  }) async {
    var index = 0;
    for (final profile in profiles) {
      if (index >= count) break;
      final urls = urlsFromProfile(profile);
      if (index == 0) {
        await prefetchUrls(urls);
      } else if (urls.isNotEmpty) {
        await prefetchUrl(urls.first);
      }
      index++;
    }
  }
}
