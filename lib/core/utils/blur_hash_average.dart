import 'package:flutter/material.dart';

/// Average (DC) color from a Wolt BlurHash — cheap list placeholder
/// without decoding a full bitmap (PERF-COMP-IMG-001).
class BlurHashAverage {
  BlurHashAverage._();

  static const _alphabet =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#\$%*+,-.:;=?@[]^_{|}~';

  /// Returns the packed sRGB DC color, or null when [hash] is not a BlurHash.
  static Color? tryColor(String? hash) {
    final value = hash?.trim();
    if (value == null || value.length < 6) return null;
    final dc = _decode83(value.substring(2, 6));
    if (dc == null) return null;
    return Color.fromARGB(255, (dc >> 16) & 255, (dc >> 8) & 255, dc & 255);
  }

  static int? _decode83(String input) {
    var acc = 0;
    for (var i = 0; i < input.length; i++) {
      final idx = _alphabet.indexOf(input[i]);
      if (idx < 0) return null;
      acc = acc * 83 + idx;
    }
    return acc;
  }
}
