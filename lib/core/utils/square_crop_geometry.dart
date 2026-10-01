import 'dart:math' as math;
import 'dart:ui';

/// Pan, zoom, and 1:1 source-rect math for [ProfilePhotoCropScreen].
///
/// [scale] is relative to cover-fit (`1` = the image just covers the square).
class SquareCropGeometry {
  const SquareCropGeometry({
    required this.imageSize,
    required this.viewportSize,
    this.scale = minScale,
    this.pan = Offset.zero,
    this.quarterTurns = 0,
  });

  static const double minScale = 1.0;
  static const double maxScale = 4.0;

  final Size imageSize;
  final Size viewportSize;
  final double scale;
  final Offset pan;
  final int quarterTurns;

  int get normalizedTurns => quarterTurns % 4;

  Size get orientedImageSize {
    return normalizedTurns.isOdd
        ? Size(imageSize.height, imageSize.width)
        : imageSize;
  }

  static double coverScale(Size image, Size viewport) {
    if (image.width <= 0 ||
        image.height <= 0 ||
        viewport.width <= 0 ||
        viewport.height <= 0) {
      return 1;
    }
    return math.max(
      viewport.width / image.width,
      viewport.height / image.height,
    );
  }

  double get fittedScale =>
      coverScale(orientedImageSize, viewportSize) * scale.clamp(minScale, maxScale);

  Size get displayedSize {
    final fitted = fittedScale;
    return Size(
      orientedImageSize.width * fitted,
      orientedImageSize.height * fitted,
    );
  }

  Offset get clampedPan {
    final display = displayedSize;
    final maxX = math.max(0.0, (display.width - viewportSize.width) / 2);
    final maxY = math.max(0.0, (display.height - viewportSize.height) / 2);
    return Offset(
      pan.dx.clamp(-maxX, maxX),
      pan.dy.clamp(-maxY, maxY),
    );
  }

  /// Top-left of the displayed image in viewport coordinates.
  Offset get imageOrigin {
    final display = displayedSize;
    final p = clampedPan;
    return Offset(
      (viewportSize.width - display.width) / 2 + p.dx,
      (viewportSize.height - display.height) / 2 + p.dy,
    );
  }

  /// Crop window mapped into oriented-image pixel space.
  Rect get sourceRect {
    final fitted = fittedScale;
    if (fitted <= 0) {
      return Offset.zero & orientedImageSize;
    }
    final origin = imageOrigin;
    final rect = Rect.fromLTWH(
      -origin.dx / fitted,
      -origin.dy / fitted,
      viewportSize.width / fitted,
      viewportSize.height / fitted,
    );
    return rect.intersect(Offset.zero & orientedImageSize);
  }

  SquareCropGeometry copyWith({
    Size? imageSize,
    Size? viewportSize,
    double? scale,
    Offset? pan,
    int? quarterTurns,
  }) {
    return SquareCropGeometry(
      imageSize: imageSize ?? this.imageSize,
      viewportSize: viewportSize ?? this.viewportSize,
      scale: scale ?? this.scale,
      pan: pan ?? this.pan,
      quarterTurns: quarterTurns ?? this.quarterTurns,
    ).clamped();
  }

  SquareCropGeometry clamped() {
    final next = SquareCropGeometry(
      imageSize: imageSize,
      viewportSize: viewportSize,
      scale: scale.clamp(minScale, maxScale),
      pan: pan,
      quarterTurns: quarterTurns,
    );
    return SquareCropGeometry(
      imageSize: next.imageSize,
      viewportSize: next.viewportSize,
      scale: next.scale,
      pan: next.clampedPan,
      quarterTurns: next.quarterTurns,
    );
  }
}
