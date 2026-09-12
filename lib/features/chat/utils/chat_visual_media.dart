import '../../../core/cache/image_cache_service.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/utils/media_url.dart';
import '../data/models/message.dart';
import '../data/models/shared_media_item.dart';

/// Collects sticker, photo, video, and profile-card image URLs from chat messages.
class ChatVisualMedia {
  ChatVisualMedia._();

  static bool isSelfDestruct(Message message) {
    final type = message.messageType.toLowerCase();
    return message.isExpired ||
        message.expiresInSeconds != null ||
        message.remainingSeconds != null ||
        type == 'self_destruct' ||
        type.startsWith('disappearing_');
  }

  static String? displayUrl(Message message) {
    final type = message.messageType.toLowerCase();
    if (type == 'sticker') {
      return _firstUrl([
        message.attachmentUrl,
        message.secureMediaUrl,
        message.mediaThumbnailUrl,
        message.metadata?['image_url']?.toString(),
        message.metadata?['url']?.toString(),
        message.metadata?['sticker_url']?.toString(),
      ]);
    }
    return _firstUrl([
      message.attachmentUrl,
      message.secureMediaUrl,
      message.mediaThumbnailUrl,
    ]);
  }

  static SharedMediaItem? sharedItem(Message message) {
    if (isSelfDestruct(message)) return null;
    final type = message.messageType.toLowerCase();
    final isImage = type == 'image';
    final isVideo = type == 'video';
    if (!isImage && !isVideo) return null;

    final url = displayUrl(message);
    if (url == null) return null;
    return SharedMediaItem(
      url: url,
      isVideo: isVideo,
      messageId: message.id > 0 ? message.id : null,
    );
  }

  static List<SharedMediaItem> sharedFromMessages(Iterable<Message> messages) {
    final seen = <String>{};
    final items = <SharedMediaItem>[];
    for (final message in messages) {
      final item = sharedItem(message);
      if (item == null || !seen.add(item.url)) continue;
      items.add(item);
    }
    return items;
  }

  static List<String> prefetchUrls(Message message) {
    if (isSelfDestruct(message)) return const [];
    final urls = <String>[];
    final type = message.messageType.toLowerCase();

    void add(String? value) {
      final resolved = MediaUrl.resolve(value);
      if (resolved != null) urls.add(resolved);
    }

    if (type == 'image' || type == 'video' || type == 'sticker') {
      add(displayUrl(message));
    }
    if (type == 'profile_link') {
      add(message.profileCard?['avatar_url']?.toString());
    }
    return urls;
  }

  static Future<void> prefetchMessages(
    Iterable<Message> messages, {
    LgbtfinderImageCacheManager? cacheManager,
  }) async {
    final cache = cacheManager ?? LgbtfinderImageCacheManager();
    final seen = <String>{};
    for (final message in messages) {
      for (final url in prefetchUrls(message)) {
        if (!seen.add(url)) continue;
        try {
          await cache.downloadFile(
            url,
            key: MediaUrl.cacheKey(url: url),
          );
        } catch (e) {
          AppLogger.warning(
            'Chat media prefetch failed',
            tag: 'Chat',
            error: e,
          );
        }
      }
    }
  }

  static Future<void> prefetchUrlsList(
    Iterable<String> urls, {
    LgbtfinderImageCacheManager? cacheManager,
  }) async {
    final cache = cacheManager ?? LgbtfinderImageCacheManager();
    final seen = <String>{};
    for (final raw in urls) {
      final url = MediaUrl.resolve(raw);
      if (url == null || !seen.add(url)) continue;
      try {
        await cache.downloadFile(
          url,
          key: MediaUrl.cacheKey(url: url),
        );
      } catch (e) {
        AppLogger.warning(
          'Chat media URL prefetch failed',
          tag: 'Chat',
          error: e,
        );
      }
    }
  }

  static String? _firstUrl(List<String?> values) {
    for (final value in values) {
      final resolved = MediaUrl.resolve(value);
      if (resolved != null) return resolved;
    }
    return null;
  }
}
