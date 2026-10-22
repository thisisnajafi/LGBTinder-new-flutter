import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lgbtindernew/shared/services/notification_avatar_bitmap.dart';

void main() {
  test('circle crop is 128px and transparent in the corner', () {
    final source = img.Image(width: 40, height: 20, numChannels: 3);
    img.fill(source, color: img.ColorRgb8(200, 20, 20));
    final png = NotificationAvatarBitmap.circlePng(
      img.encodePng(source),
    );
    expect(png, isNotNull);
    final decoded = img.decodePng(png!);
    expect(decoded, isNotNull);
    expect(decoded!.width, NotificationAvatarBitmap.size);
    expect(decoded.height, NotificationAvatarBitmap.size);
    expect(decoded.getPixel(0, 0).a, 0);
    expect(decoded.getPixel(64, 64).a, greaterThan(0));
  });

  test('empty bytes do not invent an icon', () {
    expect(NotificationAvatarBitmap.circlePng(Uint8List(0)), isNull);
    expect(NotificationAvatarBitmap.largeIcon(null), isNull);
    expect(NotificationAvatarBitmap.personIcon(null), isNull);
  });

  test('download cap and cache name stay stable', () {
    expect(NotificationAvatarBitmap.withinDownloadCap(0), isFalse);
    expect(NotificationAvatarBitmap.withinDownloadCap(100), isTrue);
    expect(
      NotificationAvatarBitmap.withinDownloadCap(
        NotificationAvatarBitmap.maxDownloadBytes + 1,
      ),
      isFalse,
    );
    const url = 'https://cdn.example/a.png';
    expect(
      NotificationAvatarBitmap.cacheFileName(url),
      NotificationAvatarBitmap.cacheFileName(url),
    );
  });
}
