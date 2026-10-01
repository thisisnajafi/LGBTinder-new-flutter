import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/core/utils/square_crop_geometry.dart';

void main() {
  group('SquareCropGeometry', () {
    test('cover-fit of a wide image crops the sides at scale 1', () {
      const geometry = SquareCropGeometry(
        imageSize: Size(200, 100),
        viewportSize: Size(100, 100),
      );

      expect(geometry.fittedScale, 1);
      expect(geometry.sourceRect, const Rect.fromLTWH(50, 0, 100, 100));
    });

    test('panning to the left edge maps the crop to x=0', () {
      const geometry = SquareCropGeometry(
        imageSize: Size(200, 100),
        viewportSize: Size(100, 100),
        pan: Offset(50, 0),
      );

      expect(geometry.clampedPan, const Offset(50, 0));
      expect(geometry.sourceRect, const Rect.fromLTWH(0, 0, 100, 100));
    });

    test('clamps pan so the square stays covered', () {
      const geometry = SquareCropGeometry(
        imageSize: Size(200, 100),
        viewportSize: Size(100, 100),
        pan: Offset(400, 400),
      );

      expect(geometry.clampedPan, const Offset(50, 0));
    });

    test('odd quarter turns swap image axes before cropping', () {
      const geometry = SquareCropGeometry(
        imageSize: Size(200, 100),
        viewportSize: Size(100, 100),
        quarterTurns: 1,
      );

      expect(geometry.orientedImageSize, const Size(100, 200));
      expect(geometry.sourceRect, const Rect.fromLTWH(0, 50, 100, 100));
    });

    test('zoom 2x shrinks the source rect around the center', () {
      const geometry = SquareCropGeometry(
        imageSize: Size(200, 100),
        viewportSize: Size(100, 100),
        scale: 2,
      );

      expect(geometry.sourceRect, const Rect.fromLTWH(75, 25, 50, 50));
    });
  });
}
