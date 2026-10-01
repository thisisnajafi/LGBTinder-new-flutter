import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'image_upload_compressor.dart';
import 'square_crop_geometry.dart';

/// Reads pixel size and writes a 1:1 JPEG from [SquareCropGeometry].
class ProfilePhotoCropEncoder {
  ProfilePhotoCropEncoder._();

  static const int outputSize = 1080;

  static Future<ui.Size> readImageSize(File file) async {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final size = ui.Size(
      frame.image.width.toDouble(),
      frame.image.height.toDouble(),
    );
    frame.image.dispose();
    return size;
  }

  static Future<File> encodeSquare({
    required File source,
    required SquareCropGeometry geometry,
  }) async {
    final rect = geometry.sourceRect;
    if (rect.width <= 0 || rect.height <= 0) {
      throw StateError('Crop rectangle is empty');
    }

    final bytes = await source.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final original = frame.image;

    ui.Image oriented = original;
    var disposedOriented = false;
    final turns = geometry.normalizedTurns;
    if (turns != 0) {
      oriented = await _rotate(original, turns);
      disposedOriented = true;
      original.dispose();
    }

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final dest = ui.Rect.fromLTWH(
      0,
      0,
      outputSize.toDouble(),
      outputSize.toDouble(),
    );
    canvas.drawImageRect(
      oriented,
      rect,
      dest,
      ui.Paint()..filterQuality = ui.FilterQuality.high,
    );
    final picture = recorder.endRecording();
    final cropped = await picture.toImage(outputSize, outputSize);
    picture.dispose();
    if (disposedOriented) {
      oriented.dispose();
    } else {
      original.dispose();
    }

    final png = await cropped.toByteData(format: ui.ImageByteFormat.png);
    cropped.dispose();
    if (png == null) {
      throw StateError('Failed to encode cropped photo');
    }

    final pngFile = File(
      '${Directory.systemTemp.path}/profile_crop_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await pngFile.writeAsBytes(png.buffer.asUint8List(), flush: true);

    try {
      final jpeg = await ImageUploadCompressor.prepareForPreview(pngFile);
      if (jpeg.path != pngFile.path && await pngFile.exists()) {
        await pngFile.delete();
      }
      return jpeg;
    } catch (_) {
      return pngFile;
    }
  }

  static Future<ui.Image> _rotate(ui.Image image, int turns) async {
    final odd = turns.isOdd;
    final width = odd ? image.height : image.width;
    final height = odd ? image.width : image.height;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.translate(width / 2, height / 2);
    canvas.rotate(turns * math.pi / 2);
    canvas.translate(-image.width / 2, -image.height / 2);
    canvas.drawImage(image, ui.Offset.zero, ui.Paint());
    final picture = recorder.endRecording();
    final rotated = await picture.toImage(width, height);
    picture.dispose();
    return rotated;
  }
}
