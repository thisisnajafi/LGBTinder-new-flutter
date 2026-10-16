import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

/// Downloads the notification avatar URL and crops a circle.
///
/// Only [avatarUrl] from the payload is requested. The app does not substitute
/// a profile or gallery URL.
class NotificationAvatarBitmap {
  NotificationAvatarBitmap._();

  static const int size = 128;
  static final Map<String, Uint8List> _cache = {};

  static Future<Uint8List?> pngFor(String? avatarUrl) async {
    final url = avatarUrl?.trim() ?? '';
    if (url.isEmpty) return null;
    final cached = _cache[url];
    if (cached != null) return cached;
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        return null;
      }
      final png = circlePng(response.bodyBytes);
      if (png == null) return null;
      _cache[url] = png;
      return png;
    } catch (_) {
      return null;
    }
  }

  /// Center-crop, scale to [size], and keep pixels inside the circle.
  static Uint8List? circlePng(Uint8List bytes) {
    if (bytes.isEmpty) return null;
    final img.Image? decoded;
    try {
      decoded = img.decodeImage(bytes);
    } catch (_) {
      return null;
    }
    if (decoded == null) return null;
    final side = decoded.width < decoded.height ? decoded.width : decoded.height;
    final cropped = img.copyCrop(
      decoded,
      x: (decoded.width - side) ~/ 2,
      y: (decoded.height - side) ~/ 2,
      width: side,
      height: side,
    );
    final square = img.copyResize(cropped, width: size, height: size);
    final out = img.Image(width: size, height: size, numChannels: 4);
    final radius = size / 2;
    final limit = radius * radius;
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final dx = x + 0.5 - radius;
        final dy = y + 0.5 - radius;
        if (dx * dx + dy * dy <= limit) {
          out.setPixel(x, y, square.getPixel(x, y));
        }
      }
    }
    return Uint8List.fromList(img.encodePng(out));
  }

  static ByteArrayAndroidBitmap? largeIcon(Uint8List? png) {
    if (png == null || png.isEmpty) return null;
    return ByteArrayAndroidBitmap(png);
  }
}
