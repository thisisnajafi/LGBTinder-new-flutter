import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

/// Encoded QR matrix produced off the UI isolate (PERF-SCR-SHARE-001).
class EncodedProfileQr {
  const EncodedProfileQr({
    required this.moduleCount,
    required this.modules,
  });

  final int moduleCount;
  final List<int> modules;
}

EncodedProfileQr encodeProfileQrSync(String data) {
  final code = QrCode.fromData(
    data: data,
    errorCorrectLevel: QrErrorCorrectLevel.M,
  );
  final qr = QrImage(code);
  final n = qr.moduleCount;
  final modules = List<int>.filled(n * n, 0);
  for (var y = 0; y < n; y++) {
    for (var x = 0; x < n; x++) {
      if (qr.isDark(y, x)) {
        modules[y * n + x] = 1;
      }
    }
  }
  return EncodedProfileQr(moduleCount: n, modules: modules);
}

Future<EncodedProfileQr> encodeProfileQr(String data) {
  return compute(encodeProfileQrSync, data);
}

/// Paints a pre-encoded QR matrix. Encoding itself must not run in [build].
class EncodedProfileQrPainter extends CustomPainter {
  EncodedProfileQrPainter({
    required this.qr,
    required this.foreground,
    required this.background,
  });

  final EncodedProfileQr qr;
  final Color foreground;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    if (qr.moduleCount <= 0) return;
    final cell = size.shortestSide / qr.moduleCount;
    final origin = Offset(
      (size.width - cell * qr.moduleCount) / 2,
      (size.height - cell * qr.moduleCount) / 2,
    );
    final dark = Paint()..color = foreground;
    for (var y = 0; y < qr.moduleCount; y++) {
      for (var x = 0; x < qr.moduleCount; x++) {
        if (qr.modules[y * qr.moduleCount + x] == 1) {
          canvas.drawRect(
            Rect.fromLTWH(
              origin.dx + x * cell,
              origin.dy + y * cell,
              cell,
              cell,
            ),
            dark,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant EncodedProfileQrPainter oldDelegate) {
    return oldDelegate.qr != qr ||
        oldDelegate.foreground != foreground ||
        oldDelegate.background != background;
  }
}
