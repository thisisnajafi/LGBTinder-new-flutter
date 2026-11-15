import 'package:flutter/widgets.dart';

/// Decode-size caps for network photos shown with [BoxFit.cover].
///
/// Without a cap, a 4000px upload is decoded at full size even when it is
/// drawn in a 72px thumbnail, which costs memory and a slow first frame.
class ImageDecodeSize {
  ImageDecodeSize._();

  /// Smallest decode width handed out; keeps tiny boxes from looking soft.
  static const int minDecode = 96;

  /// Largest decode width handed out; enough for a full-width phone photo.
  static const int maxDecode = 1400;

  /// Share of the box height the decode width must also cover.
  ///
  /// A photo as wide as 4:3 still fills the box at this ratio without being
  /// stretched past its decoded size.
  static const double heightCoverRatio = 0.75;

  /// Decode width in physical pixels for a box of [width] x [height] logical
  /// pixels filled with [BoxFit.cover].
  static int cover({
    required double width,
    required double height,
    required double devicePixelRatio,
    int max = maxDecode,
  }) {
    final safeWidth = width.isFinite && width > 0 ? width : 0.0;
    final safeHeight = height.isFinite && height > 0 ? height : 0.0;
    final byHeight = safeHeight * heightCoverRatio;
    final logical = safeWidth > byHeight ? safeWidth : byHeight;
    final dpr = devicePixelRatio.isFinite && devicePixelRatio > 0
        ? devicePixelRatio
        : 1.0;
    final px = (logical * dpr).round();
    if (px < minDecode) return minDecode;
    if (px > max) return max;
    return px;
  }

  /// [cover] for a box whose size is known in logical pixels.
  static int coverOf(
    BuildContext context, {
    required double width,
    required double height,
    int max = maxDecode,
  }) {
    return cover(
      width: width,
      height: height,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      max: max,
    );
  }

  /// [cover] for a box that fills its parent; falls back to the screen size
  /// when the parent gives no finite constraint.
  static int coverOfConstraints(
    BuildContext context,
    BoxConstraints constraints, {
    int max = maxDecode,
  }) {
    final screen = MediaQuery.sizeOf(context);
    return coverOf(
      context,
      width: constraints.maxWidth.isFinite ? constraints.maxWidth : screen.width,
      height:
          constraints.maxHeight.isFinite ? constraints.maxHeight : screen.height,
      max: max,
    );
  }
}
