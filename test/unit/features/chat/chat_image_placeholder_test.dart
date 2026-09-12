import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/utils/chat_image_placeholder.dart';
import 'package:lgbtindernew/widgets/chat/chat_bubble_photo.dart';

void main() {
  test('PNG and JPEG headers expose width and height', () {
    final png = Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x01, 0x40, // 320
      0x00, 0x00, 0x00, 0xF0, // 240
    ]);
    expect(ImageHeaderSize.probe(png)?.width, 320);
    expect(ImageHeaderSize.probe(png)?.height, 240);

    final jpeg = Uint8List.fromList([
      0xFF, 0xD8, 0xFF, 0xC0, 0x00, 0x11, 0x08,
      0x00, 0x64, // height 100
      0x00, 0xC8, // width 200
      0x03, 0x01, 0x22, 0x00, 0x02, 0x11, 0x01, 0x03, 0x11, 0x01,
    ]);
    expect(ImageHeaderSize.probe(jpeg)?.width, 200);
    expect(ImageHeaderSize.probe(jpeg)?.height, 100);
  });

  test('data URI round-trip and reserved height clamps portrait', () {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    final uri = ChatImagePlaceholder.toDataUri(bytes);
    expect(ChatImagePlaceholder.fromDataUri(uri), bytes);
    expect(
      ChatImagePlaceholder.reservedHeight(boxWidth: 240, aspectRatio: 4 / 3),
      180,
    );
    expect(
      ChatImagePlaceholder.reservedHeight(boxWidth: 240, aspectRatio: 9 / 16),
      ChatImagePlaceholder.maxHeight,
    );
    expect(
      ChatImagePlaceholder.reservedHeight(boxWidth: 240),
      ChatImagePlaceholder.fallbackHeight,
    );
  });

  testWidgets('blur placeholder fills reserved box instead of empty grey',
      (tester) async {
    // 1×1 JPEG
    const dataUri =
        'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAn/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIQAxAAAAGcP//Z';

    await tester.pumpWidget(
      const ProviderScope(
        child: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 240,
                child: ChatBubblePhoto(
                  imageUrl: '/tmp/missing-photo.jpg',
                  placeholderDataUri: dataUri,
                  aspectRatio: 4 / 3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(ImageFiltered), findsOneWidget);
    final box = tester.getSize(find.byType(ChatBubblePhoto));
    expect(box.width, 240);
    expect(box.height, 180);
  });
}
