import 'package:flutter/widgets.dart';

import '../../../core/cache/image_cache_service.dart';
import '../../../core/utils/media_url.dart';

/// Decodes the top messenger avatars into Flutter's image cache
/// (PERF-PAGE-CHATLIST-007). Disk fetch still happens via [PeerAvatarCache].
class ChatListAvatarPrefetch {
  ChatListAvatarPrefetch._();

  static const int topCount = 20;

  /// Unique resolved URLs from the top of the conversation list.
  static List<String> topUrls(
    Iterable<String?> avatars, {
    int limit = topCount,
  }) {
    final seen = <String>{};
    final urls = <String>[];
    for (final raw in avatars) {
      if (urls.length >= limit) break;
      final resolved = MediaUrl.resolve(raw);
      if (resolved == null || resolved.isEmpty || !seen.add(resolved)) {
        continue;
      }
      urls.add(resolved);
    }
    return urls;
  }

  static Future<void> precacheTop(
    BuildContext context,
    Iterable<String?> avatars, {
    int limit = topCount,
  }) async {
    if (!context.mounted) return;
    for (final url in topUrls(avatars, limit: limit)) {
      if (!context.mounted) return;
      try {
        await precacheImage(lgbtfinderCachedImageProvider(url), context);
      } catch (_) {
        // Non-fatal — [ProfileImageWidget] still loads on screen.
      }
    }
  }
}
