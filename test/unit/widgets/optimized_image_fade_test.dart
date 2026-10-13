import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/utils/blur_hash_average.dart';
import 'package:lgbtindernew/core/widgets/optimized_image.dart';

void main() {
  test('list image sizes skip fade; detail sizes still fade', () {
    expect(OptimizedImage.shouldFade(ImageSize.thumbnail), isFalse);
    expect(OptimizedImage.shouldFade(ImageSize.small), isFalse);
    expect(OptimizedImage.shouldFade(ImageSize.medium), isFalse);
    expect(OptimizedImage.shouldFade(ImageSize.large), isTrue);
    expect(OptimizedImage.shouldFade(ImageSize.original), isTrue);
  });

  test('BlurHash DC color decodes from a valid hash', () {
    const hash = 'LEHV6nWB2yk8pyo0adR*.7kCMdnj';
    final color = BlurHashAverage.tryColor(hash);
    expect(color, isNotNull);
    expect(color!.alpha, 255);
  });

  testWidgets('decode cap uses one axis so photos keep their aspect ratio', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: OptimizedImage(
              imageUrl: 'https://cdn.example/avatar.jpg',
              width: 48,
              height: 48,
              size: ImageSize.thumbnail,
              memoryCacheWidth: 100,
              memoryCacheHeight: 100,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final cached = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(cached.memCacheWidth, 100);
    expect(cached.memCacheHeight, isNull);
    expect(cached.fit, BoxFit.cover);
  });

  testWidgets('size presets decode by width only', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: OptimizedImage(
              imageUrl: 'https://cdn.example/photo.jpg',
              size: ImageSize.medium,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final cached = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(cached.memCacheWidth, 400);
    expect(cached.memCacheHeight, isNull);
  });

  test('BlurHash DC color rejects short or invalid hashes', () {
    expect(BlurHashAverage.tryColor(null), isNull);
    expect(BlurHashAverage.tryColor('abc'), isNull);
    expect(BlurHashAverage.tryColor('!!!!!!'), isNull);
  });
}
