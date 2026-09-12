import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../../core/services/app_logger.dart';

/// Tiny 20×20 JPEG + aspect metadata for optimistic/network photo bubbles
/// (CHAT-IMG-002).
class ChatImagePlaceholderData {
  final Uint8List bytes;
  final int? width;
  final int? height;

  const ChatImagePlaceholderData({
    required this.bytes,
    this.width,
    this.height,
  });

  String get dataUri => ChatImagePlaceholder.toDataUri(bytes);

  double? get aspectRatio => ChatImagePlaceholder.aspectRatioOf(
        width: width,
        height: height,
      );
}

/// Header probe + 20×20 JPEG generator (Telegram-style blur source).
class ChatImagePlaceholder {
  ChatImagePlaceholder._();

  static const int pixelSize = 20;
  /// Decoded memory cap for bubble photos (CHAT-IMG-003).
  static const int memCacheSize = 800;
  static const double blurSigma = 12;
  static const double fallbackHeight = 200;
  static const double minHeight = 120;
  static const double maxHeight = 320;

  static String toDataUri(Uint8List bytes) =>
      'data:image/jpeg;base64,${base64Encode(bytes)}';

  static Uint8List? fromDataUri(String? value) {
    if (value == null || value.isEmpty) return null;
    final comma = value.indexOf(',');
    final payload = comma >= 0 ? value.substring(comma + 1) : value;
    try {
      final bytes = base64Decode(payload);
      return bytes.isEmpty ? null : bytes;
    } catch (e) {
      AppLogger.warning(
        'Invalid chat image placeholder data URI',
        tag: 'Chat',
        error: e,
      );
      return null;
    }
  }

  static double? aspectRatioOf({int? width, int? height}) {
    if (width == null || height == null || width <= 0 || height <= 0) {
      return null;
    }
    return width / height;
  }

  static double reservedHeight({
    required double boxWidth,
    double? aspectRatio,
  }) {
    if (boxWidth <= 0 || !boxWidth.isFinite) return fallbackHeight;
    if (aspectRatio == null || aspectRatio <= 0) return fallbackHeight;
    return (boxWidth / aspectRatio).clamp(minHeight, maxHeight);
  }

  static ImageHeaderSize? probeHeader(Uint8List bytes) =>
      ImageHeaderSize.probe(bytes);

  static Future<ChatImagePlaceholderData?> fromFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;

      final header = await _readHeader(file);
      final probed = ImageHeaderSize.probe(header);

      final compressed = await FlutterImageCompress.compressWithFile(
        path,
        minWidth: pixelSize,
        minHeight: pixelSize,
        quality: 35,
        format: CompressFormat.jpeg,
      );
      if (compressed == null || compressed.isEmpty) return null;

      return ChatImagePlaceholderData(
        bytes: Uint8List.fromList(compressed),
        width: probed?.width,
        height: probed?.height,
      );
    } catch (e) {
      AppLogger.warning(
        'Chat 20x20 placeholder failed',
        tag: 'Chat',
        error: e,
      );
      return null;
    }
  }

  static Future<Uint8List> _readHeader(File file) async {
    final raf = await file.open();
    try {
      return await raf.read(65536);
    } finally {
      await raf.close();
    }
  }
}

class ImageHeaderSize {
  final int width;
  final int height;

  const ImageHeaderSize(this.width, this.height);

  static ImageHeaderSize? probe(Uint8List bytes) {
    if (bytes.length < 10) return null;
    if (bytes[0] == 0x89 && bytes[1] == 0x50) {
      return _png(bytes);
    }
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return _jpeg(bytes);
    }
    if (bytes.length >= 30 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return _webp(bytes);
    }
    return null;
  }

  static ImageHeaderSize? _png(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    final width = data.getUint32(16);
    final height = data.getUint32(20);
    if (width <= 0 || height <= 0) return null;
    return ImageHeaderSize(width, height);
  }

  static ImageHeaderSize? _jpeg(Uint8List bytes) {
    var offset = 2;
    while (offset + 8 < bytes.length) {
      if (bytes[offset] != 0xFF) {
        offset += 1;
        continue;
      }
      final marker = bytes[offset + 1];
      if (marker == 0xD8 || marker == 0xD9 || (marker >= 0xD0 && marker <= 0xD7)) {
        offset += 2;
        continue;
      }
      if (offset + 3 >= bytes.length) return null;
      final segmentLength = (bytes[offset + 2] << 8) | bytes[offset + 3];
      final isSof = marker == 0xC0 ||
          marker == 0xC1 ||
          marker == 0xC2 ||
          marker == 0xC3 ||
          marker == 0xC5 ||
          marker == 0xC6 ||
          marker == 0xC7 ||
          marker == 0xC9 ||
          marker == 0xCA ||
          marker == 0xCB ||
          marker == 0xCD ||
          marker == 0xCE ||
          marker == 0xCF;
      if (isSof && offset + 8 < bytes.length) {
        final height = (bytes[offset + 5] << 8) | bytes[offset + 6];
        final width = (bytes[offset + 7] << 8) | bytes[offset + 8];
        if (width <= 0 || height <= 0) return null;
        return ImageHeaderSize(width, height);
      }
      if (segmentLength < 2) return null;
      offset += 2 + segmentLength;
    }
    return null;
  }

  static ImageHeaderSize? _webp(Uint8List bytes) {
    // VP8X extended: bytes 12-15 = VP8X, canvas size at 24-29 (24-bit little endian, +1)
    if (bytes[12] == 0x56 && bytes[13] == 0x50 && bytes[14] == 0x38 && bytes[15] == 0x58) {
      if (bytes.length < 30) return null;
      final width = 1 +
          (bytes[24] | (bytes[25] << 8) | (bytes[26] << 16));
      final height = 1 +
          (bytes[27] | (bytes[28] << 8) | (bytes[29] << 16));
      if (width <= 0 || height <= 0) return null;
      return ImageHeaderSize(width, height);
    }
    return null;
  }
}
