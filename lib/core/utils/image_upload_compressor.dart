import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// Prepares local image files for profile/gallery upload.
///
/// Backend allows 5MB (`max:5120` KB); nginx may return 413 before Laravel.
/// We target 4MB and downscale high-res camera photos from modern devices.
class ImageUploadCompressor {
  ImageUploadCompressor._();

  /// Laravel `max:5120` = 5MB; stay under with headroom for multipart overhead.
  static const int maxUploadBytes = 4 * 1024 * 1024;

  /// Skip re-encoding when already small enough.
  static const int compressThresholdBytes = 2500 * 1024;

  static const int defaultMaxSide = 1920;
  static const int defaultQuality = 85;

  static Future<File> prepareForUpload(File source) async {
    if (!await source.exists()) return source;

    final originalBytes = await source.length();
    if (originalBytes <= compressThresholdBytes) {
      return source;
    }

    final tempDir = await getTemporaryDirectory();
    var quality = defaultQuality;
    var maxSide = defaultMaxSide;
    File? best;

    for (var attempt = 0; attempt < 5; attempt++) {
      final targetPath =
          '${tempDir.path}/upload_${DateTime.now().millisecondsSinceEpoch}_$attempt.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        source.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxSide,
        minHeight: maxSide,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
      if (result == null) break;

      final compressed = File(result.path);
      if (!await compressed.exists()) break;

      final size = await compressed.length();
      best = compressed;
      if (size <= maxUploadBytes) {
        return compressed;
      }

      quality = (quality - 12).clamp(50, 95);
      maxSide = (maxSide * 0.8).round().clamp(960, defaultMaxSide);
    }

    if (best != null) return best;
    return source;
  }
}
