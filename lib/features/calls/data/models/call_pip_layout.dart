import 'dart:ui';

/// Corner the local video PiP can rest on.
enum CallPipCorner { topLeft, topRight, bottomLeft, bottomRight }

/// Geometry for CALL-UI-006 (snap / default bottom-right / two sizes).
class CallPipLayout {
  CallPipLayout._();

  /// Height / width (120×160 and 160×213 are both ~3:4).
  static const double aspect = 4 / 3;

  /// Large PiP is 4/3 of the small width (120 → 160).
  static const double largeScale = 4 / 3;

  static Size pipSize({required double smallWidth, required bool large}) {
    final width = large ? smallWidth * largeScale : smallWidth;
    return Size(width, width * aspect);
  }

  static Offset offsetFor({
    required CallPipCorner corner,
    required Size viewport,
    required Size pipSize,
    required double topInset,
    required double leftInset,
    required double rightInset,
    required double bottomReserve,
  }) {
    final maxX =
        (viewport.width - pipSize.width - rightInset).clamp(0.0, viewport.width);
    final maxY = (viewport.height - pipSize.height - bottomReserve)
        .clamp(0.0, viewport.height);
    final minX = leftInset.clamp(0.0, maxX);
    final minY = topInset.clamp(0.0, maxY);
    switch (corner) {
      case CallPipCorner.topLeft:
        return Offset(minX, minY);
      case CallPipCorner.topRight:
        return Offset(maxX, minY);
      case CallPipCorner.bottomLeft:
        return Offset(minX, maxY);
      case CallPipCorner.bottomRight:
        return Offset(maxX, maxY);
    }
  }

  static CallPipCorner nearest({
    required Offset offset,
    required Size viewport,
    required Size pipSize,
    required double topInset,
    required double leftInset,
    required double rightInset,
    required double bottomReserve,
  }) {
    var best = CallPipCorner.bottomRight;
    var bestDist = double.infinity;
    for (final corner in CallPipCorner.values) {
      final target = offsetFor(
        corner: corner,
        viewport: viewport,
        pipSize: pipSize,
        topInset: topInset,
        leftInset: leftInset,
        rightInset: rightInset,
        bottomReserve: bottomReserve,
      );
      final dist = (target - offset).distanceSquared;
      if (dist < bestDist) {
        bestDist = dist;
        best = corner;
      }
    }
    return best;
  }

  static Offset clampToBounds({
    required Offset offset,
    required Size viewport,
    required Size pipSize,
    required double topInset,
    required double leftInset,
    required double rightInset,
    required double bottomReserve,
  }) {
    final maxX =
        (viewport.width - pipSize.width - rightInset).clamp(0.0, viewport.width);
    final maxY = (viewport.height - pipSize.height - bottomReserve)
        .clamp(0.0, viewport.height);
    final minX = leftInset.clamp(0.0, maxX);
    final minY = topInset.clamp(0.0, maxY);
    return Offset(
      offset.dx.clamp(minX, maxX),
      offset.dy.clamp(minY, maxY),
    );
  }
}
