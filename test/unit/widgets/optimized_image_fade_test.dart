import 'package:flutter/material.dart';
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

  test('BlurHash DC color rejects short or invalid hashes', () {
    expect(BlurHashAverage.tryColor(null), isNull);
    expect(BlurHashAverage.tryColor('abc'), isNull);
    expect(BlurHashAverage.tryColor('!!!!!!'), isNull);
  });
}
