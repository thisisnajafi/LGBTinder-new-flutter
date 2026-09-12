import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/features/chat/utils/chat_image_placeholder.dart';
import 'package:lgbtindernew/features/chat/utils/chat_image_memory.dart';
import 'package:lgbtindernew/widgets/chat/chat_bubble_photo.dart';
import 'package:lgbtindernew/core/widgets/optimized_image.dart';

void main() {
  test('chat image fade-in is capped at 200ms', () {
    expect(AppAnimations.imageFadeIn.inMilliseconds, lessThanOrEqualTo(200));
    expect(ChatImagePlaceholder.memCacheSize, 800);
  });

  testWidgets('network bubble decodes near display size, not both 800 axes',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 240,
              child: ChatBubblePhoto(
                imageUrl: 'https://cdn.example/photo.jpg',
                aspectRatio: 4 / 3,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final photo = tester.widget<OptimizedImage>(find.byType(OptimizedImage));
    final expectedWidth = ChatImageMemory.bubbleDecodePx(
      logicalWidth: 240,
      logicalHeight: 180,
      devicePixelRatio: tester.view.devicePixelRatio,
    );
    expect(photo.memoryCacheWidth, expectedWidth);
    expect(photo.memoryCacheHeight, isNull);
    expect(photo.showDownloadProgress, isFalse);

    final cached =
        tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
    expect(cached.memCacheWidth, expectedWidth);
    expect(cached.memCacheHeight, isNull);
    expect(cached.fadeInDuration, AppAnimations.imageFadeIn);
    expect(cached.fadeInDuration.inMilliseconds, lessThanOrEqualTo(200));

    expect(tester.getSize(find.byType(ChatBubblePhoto)), const Size(240, 180));
  });

  testWidgets('Reduce Motion skips the progressive fade', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const Scaffold(
              body: SizedBox(
                width: 240,
                child: ChatBubblePhoto(
                  imageUrl: 'https://cdn.example/photo.jpg',
                  aspectRatio: 4 / 3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final cached =
        tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
    expect(cached.fadeInDuration, Duration.zero);
    expect(cached.fadeOutDuration, Duration.zero);
    expect(tester.getSize(find.byType(ChatBubblePhoto)), const Size(240, 180));
  });
}
