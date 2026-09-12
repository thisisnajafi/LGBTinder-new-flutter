import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/calls/data/models/call_pip_layout.dart';

void main() {
  const viewport = Size(400, 800);
  const pip = Size(120, 160);

  group('CallPipLayout', () {
    test('default bottom-right sits above the control reserve', () {
      final offset = CallPipLayout.offsetFor(
        corner: CallPipCorner.bottomRight,
        viewport: viewport,
        pipSize: pip,
        topInset: 48,
        leftInset: 16,
        rightInset: 16,
        bottomReserve: 120,
      );
      expect(offset.dx, 400 - 120 - 16);
      expect(offset.dy, 800 - 160 - 120);
    });

    test('nearest corner from the lower-right quadrant is bottomRight', () {
      final corner = CallPipLayout.nearest(
        offset: const Offset(250, 500),
        viewport: viewport,
        pipSize: pip,
        topInset: 48,
        leftInset: 16,
        rightInset: 16,
        bottomReserve: 120,
      );
      expect(corner, CallPipCorner.bottomRight);
    });

    test('nearest corner from the upper-left quadrant is topLeft', () {
      final corner = CallPipLayout.nearest(
        offset: const Offset(20, 60),
        viewport: viewport,
        pipSize: pip,
        topInset: 48,
        leftInset: 16,
        rightInset: 16,
        bottomReserve: 120,
      );
      expect(corner, CallPipCorner.topLeft);
    });

    test('large size is 4/3 of the small width with 3:4 aspect', () {
      final small = CallPipLayout.pipSize(smallWidth: 120, large: false);
      final large = CallPipLayout.pipSize(smallWidth: 120, large: true);
      expect(small, const Size(120, 160));
      expect(large.width, closeTo(160, 0.001));
      expect(large.height, closeTo(160 * CallPipLayout.aspect, 0.001));
    });
  });
}
