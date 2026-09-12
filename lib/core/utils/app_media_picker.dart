import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// File metadata for a picker result. Built off the UI isolate (PERF-SCR-VERIFY-001).
class PickedMediaFile {
  const PickedMediaFile({
    required this.path,
    required this.lengthBytes,
    required this.exists,
  });

  final String path;
  final int lengthBytes;
  final bool exists;
}

/// Top-level entry for [compute] — must not close over UI objects.
PickedMediaFile statPickedMediaFileSync(String path) {
  final file = File(path);
  final exists = file.existsSync();
  return PickedMediaFile(
    path: path,
    exists: exists,
    lengthBytes: exists ? file.lengthSync() : 0,
  );
}

Future<PickedMediaFile> statPickedMediaFile(String path) {
  return compute(statPickedMediaFileSync, path);
}

/// Shared camera/gallery picker. Native compression stays off the UI isolate;
/// Dart file stats run in [compute].
class AppMediaPicker {
  AppMediaPicker._();

  static final ImagePicker _picker = ImagePicker();

  static ImagePicker get instance => _picker;

  static const double defaultMaxWidth = 1920;
  static const int defaultImageQuality = 85;

  static Future<XFile?> pickImage({
    required ImageSource source,
    int imageQuality = defaultImageQuality,
    double maxWidth = defaultMaxWidth,
  }) {
    return _picker.pickImage(
      source: source,
      imageQuality: imageQuality,
      maxWidth: maxWidth,
    );
  }

  static Future<XFile?> pickVideo({
    required ImageSource source,
    Duration? maxDuration,
  }) {
    return _picker.pickVideo(
      source: source,
      maxDuration: maxDuration,
    );
  }

  static Future<List<XFile>> pickMultiImage({
    int? limit,
    int imageQuality = defaultImageQuality,
    double maxWidth = defaultMaxWidth,
  }) {
    return _picker.pickMultiImage(
      limit: limit,
      imageQuality: imageQuality,
      maxWidth: maxWidth,
    );
  }
}
