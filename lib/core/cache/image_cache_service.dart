import 'package:cached_network_image/cached_network_image.dart';
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
        );
}

/// Alias used by image widgets.
typedef ImageCacheService = LgbtfinderImageCacheManager;

/// [ImageProvider] for [PhotoView], [DecorationImage], etc.
CachedNetworkImageProvider lgbtfinderCachedImageProvider(String imageUrl) {
  return CachedNetworkImageProvider(
    imageUrl,
    cacheManager: LgbtfinderImageCacheManager(),
  );
}
