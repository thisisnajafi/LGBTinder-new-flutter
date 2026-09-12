import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/cache/cache_config.dart';
import 'package:lgbtindernew/core/cache/image_cache_service.dart';
import 'package:lgbtindernew/features/chat/utils/chat_image_memory.dart';
import 'package:lgbtindernew/features/chat/utils/chat_image_placeholder.dart';

void main() {
  test('chat bubble photos cap decoded memory at 800px', () {
    expect(ChatImageMemory.bubbleMaxDecode, 800);
    expect(ChatImagePlaceholder.memCacheSize, 800);
  });

  test('bubble decode follows display px and caps at 800', () {
    expect(
      ChatImageMemory.bubbleDecodePx(
        logicalWidth: 240,
        logicalHeight: 180,
        devicePixelRatio: 1,
      ),
      240,
    );
    expect(
      ChatImageMemory.bubbleDecodePx(
        logicalWidth: 240,
        logicalHeight: 180,
        devicePixelRatio: 3,
      ),
      720,
    );
    expect(
      ChatImageMemory.bubbleDecodePx(
        logicalWidth: 400,
        logicalHeight: 320,
        devicePixelRatio: 3,
      ),
      ChatImageMemory.bubbleMaxDecode,
    );
  });

  test('viewer decode follows the longest screen side and caps at 1920', () {
    expect(
      ChatImageMemory.viewerDecodePx(
        screen: const Size(400, 800),
        devicePixelRatio: 2,
      ),
      1600,
    );
    expect(
      ChatImageMemory.viewerDecodePx(
        screen: const Size(1080, 1920),
        devicePixelRatio: 3,
      ),
      ChatImageMemory.viewerMaxDecode,
    );
  });

  test('decoded ImageCache RAM is bounded', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    ImageCacheService.applyMemoryLimits();
    final cache = PaintingBinding.instance.imageCache;
    expect(cache.maximumSize, CacheConfig.imageMemoryMaxLiveImages);
    expect(cache.maximumSizeBytes, CacheConfig.imageMemoryMaxBytes);
    expect(CacheConfig.imageCacheMaxObjects, 500);
  });
}
