import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'cache_config.dart';

/// Custom [CacheManager] for profile and avatar images.
class LgbtfinderImageCacheManager extends CacheManager {
  static const String key = CacheConfig.imageCacheKey;

  static final LgbtfinderImageCacheManager _instance =
      LgbtfinderImageCacheManager._();

  factory LgbtfinderImageCacheManager() => _instance;

  LgbtfinderImageCacheManager._()
      : super(
          Config(
            key,
            stalePeriod: CacheConfig.imageCacheStalePeriod,
            maxNrOfCacheObjects: CacheConfig.imageCacheMaxObjects,
          ),
        ) {
    applyMemoryLimits();
  }

  /// Caps Flutter's decoded [ImageCache] (CHAT-PERF-002). Disk objects stay
  /// at [CacheConfig.imageCacheMaxObjects].
  static void applyMemoryLimits([ImageCache? cache]) {
    final target = cache ?? PaintingBinding.instance.imageCache;
    target.maximumSize = CacheConfig.imageMemoryMaxLiveImages;
    target.maximumSizeBytes = CacheConfig.imageMemoryMaxBytes;
  }
}

/// Alias used by image widgets.
typedef ImageCacheService = LgbtfinderImageCacheManager;

/// [ImageProvider] for [PhotoView], [DecorationImage], and chat viewers.
///
/// [maxWidth]/[maxHeight] decode caps; pass only one when possible so aspect
/// ratio is preserved.
CachedNetworkImageProvider lgbtfinderCachedImageProvider(
  String imageUrl, {
  int? maxWidth,
  int? maxHeight,
}) {
  return CachedNetworkImageProvider(
    imageUrl,
    cacheManager: LgbtfinderImageCacheManager(),
    maxWidth: maxWidth,
    maxHeight: maxHeight,
  );
}
