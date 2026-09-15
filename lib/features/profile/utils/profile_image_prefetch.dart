import 'package:flutter/widgets.dart';

import '../../../core/cache/image_cache_service.dart';

/// Prefetches the current profile photo plus its neighbors (PERF-COMP-PROF-001).
class ProfileImagePrefetch {
  ProfileImagePrefetch._();

  /// Current [index], then previous and next URLs (deduped, in that order).
  static List<String> adjacentUrls(List<String> urls, int index) {
    if (urls.isEmpty) return const [];
    final seen = <String>{};
    final out = <String>[];

    void add(int i) {
      if (i < 0 || i >= urls.length) return;
      final url = urls[i].trim();
      if (url.isEmpty || !seen.add(url)) return;
      out.add(url);
    }

    add(index);
    add(index - 1);
    add(index + 1);
    return out;
  }

  static Future<void> prefetchAdjacent(
    BuildContext context,
    List<String> urls,
    int index,
  ) async {
    if (!context.mounted) return;
    for (final url in adjacentUrls(urls, index)) {
      if (!context.mounted) return;
      try {
        await precacheImage(lgbtfinderCachedImageProvider(url), context);
      } catch (_) {
        // Non-fatal — [OptimizedImage] still loads on screen.
      }
    }
  }
}
