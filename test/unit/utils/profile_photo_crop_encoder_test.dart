import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/core/utils/profile_photo_crop_encoder.dart';
import 'package:lgbtindernew/core/utils/square_crop_geometry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('encodeSquare writes a 1:1 image from a wide source', () async {
    final dir = await Directory.systemTemp.createTemp('profile_crop_');
    addTearDown(() => dir.delete(recursive: true));

    final source = await _writePng(
      dir: dir,
      name: 'wide.png',
      width: 40,
      height: 20,
    );

    final size = await ProfilePhotoCropEncoder.readImageSize(source);
    expect(size, const Size(40, 20));

    final cropped = await ProfilePhotoCropEncoder.encodeSquare(
      source: source,
      geometry: SquareCropGeometry(
        imageSize: size,
        viewportSize: const Size(100, 100),
      ),
    );

    expect(await cropped.exists(), isTrue);
    final outSize = await ProfilePhotoCropEncoder.readImageSize(cropped);
    expect(outSize.width, outSize.height);
  });
}

Future<File> _writePng({
  required Directory dir,
  required String name,
  required int width,
  required int height,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
  );
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width / 2, height.toDouble()),
    Paint()..color = const Color(0xFFFF0000),
  );
  canvas.drawRect(
    Rect.fromLTWH(width / 2, 0, width / 2, height.toDouble()),
    Paint()..color = const Color(0xFF0000FF),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  final file = File('${dir.path}/$name');
  await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
  return file;
}
