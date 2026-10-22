import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

/// Downloaded notification avatar, cropped and cached on disk.
class NotificationAvatarImage {
  final Uint8List png;
  final String filePath;

  const NotificationAvatarImage({required this.png, required this.filePath});
}

/// Downloads the notification avatar URL and crops a circle.
///
/// Only [avatarUrl] from the payload is requested. The app does not substitute
/// a profile or gallery URL. The background isolate uses the same file cache.
class NotificationAvatarBitmap {
  NotificationAvatarBitmap._();

  static const int size = 128;
  static const int maxDownloadBytes = 512 * 1024;
  static const Duration downloadTimeout = Duration(seconds: 3);

  static bool withinDownloadCap(int length) {
    return length > 0 && length <= maxDownloadBytes;
  }

  /// Stable file name so a second push for the same URL skips the network.
  static String cacheFileName(String url) {
    var hash = 0x811c9dc5;
    for (final code in url.codeUnits) {
      hash ^= code;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash.toRadixString(16);
  }

  static Future<NotificationAvatarImage?> load(String? avatarUrl) async {
    final url = avatarUrl?.trim() ?? '';
    if (url.isEmpty) return null;
    try {
      final dir = Directory(
        '${Directory.systemTemp.path}${Platform.pathSeparator}lgbtfinder_notification_avatars',
      );
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final file = File(
        '${dir.path}${Platform.pathSeparator}${cacheFileName(url)}.png',
      );
      if (file.existsSync()) {
        final cached = await file.readAsBytes();
        if (cached.isNotEmpty) {
          return NotificationAvatarImage(png: cached, filePath: file.path);
        }
      }

      final response = await http.get(Uri.parse(url)).timeout(downloadTimeout);
      if (response.statusCode != 200 || !withinDownloadCap(response.bodyBytes.length)) {
        return null;
      }
      final png = circlePng(response.bodyBytes);
      if (png == null || png.isEmpty) return null;
      await file.writeAsBytes(png, flush: true);
      return NotificationAvatarImage(png: png, filePath: file.path);
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

  static AndroidBitmap<Object>? largeIcon(NotificationAvatarImage? image) {
    if (image == null) return null;
    if (image.filePath.isNotEmpty) {
      return FilePathAndroidBitmap(image.filePath);
    }
    if (image.png.isEmpty) return null;
    return ByteArrayAndroidBitmap(image.png);
  }

  static ByteArrayAndroidIcon? personIcon(NotificationAvatarImage? image) {
    if (image == null || image.png.isEmpty) return null;
    return ByteArrayAndroidIcon(image.png);
  }
}
