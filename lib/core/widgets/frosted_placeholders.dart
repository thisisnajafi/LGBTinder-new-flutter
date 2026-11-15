import 'package:flutter/material.dart';

import 'optimized_image.dart';

/// Blurred-looking stand-ins for content a plan hides (locked message
/// previews, restricted "who liked you" avatars).
///
/// They replace `ImageFiltered(blur)` inside scrolling rows. A real blur
/// needs an offscreen layer and a filter pass per visible row; these get the
/// same frosted look from primitives the rasterizer already draws cheaply.

/// One line of text rendered as soft smudges, as if the text were blurred.
///
/// The smudges follow the word lengths of [text], so each row keeps its own
/// rhythm (a short reply looks short, a long message looks long) without
/// exposing a single character. Nothing from [text] reaches semantics.
///
/// Usage:
/// ```dart
/// FrostedTextPlaceholder(
///   text: lastMessage,
///   style: theme.textTheme.bodySmall,
///   color: mutedColor,
/// )
/// ```
class FrostedTextPlaceholder extends StatelessWidget {
  /// Hidden text. Only the length of each word is used.
  final String text;

  /// Style the real text would use (font size and line height).
  final TextStyle? style;

  /// Colour the real text would use.
  final Color color;

  const FrostedTextPlaceholder({
    super.key,
    required this.text,
    required this.color,
    this.style,
  });

  static const double _fallbackFontSize = 12;

  /// Longest word still drawn at full width. Longer words (URLs) are capped
  /// so one token cannot fill the row.
  static const int _maxWordChars = 14;

  /// At most this many smudges are laid out; the row clips the rest anyway.
  static const int _maxWords = 12;

  /// Rhythm used when there is no text to mirror.
  static const List<int> _defaultRhythm = [5, 3, 7, 4];

  /// Word lengths of [text], bounded. Exposed for tests.
  @visibleForTesting
  static List<int> rhythmOf(String text) {
    final words = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(_maxWords)
        .map((w) => w.characters.length.clamp(1, _maxWordChars))
        .toList(growable: false);
    return words.isEmpty ? _defaultRhythm : words;
  }

  @override
  Widget build(BuildContext context) {
    final baseSize = style?.fontSize ?? _fallbackFontSize;
    final fontSize = MediaQuery.textScalerOf(context).scale(baseSize);
    final lineHeight = fontSize * (style?.height ?? 1.35);

    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size(double.infinity, lineHeight),
          painter: _FrostedTextPainter(
            rhythm: rhythmOf(text),
            fontSize: fontSize,
            color: color,
            rtl: Directionality.of(context) == TextDirection.rtl,
          ),
        ),
      ),
    );
  }
}

class _FrostedTextPainter extends CustomPainter {
  final List<int> rhythm;
  final double fontSize;
  final Color color;
  final bool rtl;

  const _FrostedTextPainter({
    required this.rhythm,
    required this.fontSize,
    required this.color,
    required this.rtl,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Proportions of blurred body text: glyph body about 0.6 em tall, average
    // advance about half an em, word gap about a third of an em.
    final barHeight = fontSize * 0.6;
    final charWidth = fontSize * 0.5;
    final gap = fontSize * 0.42;
    final top = (size.height - barHeight) / 2;
    final radius = Radius.circular(barHeight / 2);

    // A rounded-rect mask blur is solved analytically by the rasterizer:
    // no offscreen layer and no image filter, unlike ImageFiltered.
    final paint = Paint()
      ..color = color.withValues(alpha: color.a * 0.5)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, fontSize * 0.2);

    // Keep the blur halo inside the row.
    canvas.clipRect(Offset.zero & size);

    var cursor = 0.0;
    for (final chars in rhythm) {
      final width = chars * charWidth;
      if (cursor >= size.width) break;
      final visible = width.clamp(0.0, size.width - cursor);
      final left = rtl ? size.width - cursor - visible : cursor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, visible, barHeight),
          radius,
        ),
        paint,
      );
      cursor += width + gap;
    }
  }

  @override
  bool shouldRepaint(_FrostedTextPainter oldDelegate) {
    return oldDelegate.fontSize != fontSize ||
        oldDelegate.color != color ||
        oldDelegate.rtl != rtl ||
        !_sameRhythm(oldDelegate.rhythm, rhythm);
  }

  static bool _sameRhythm(List<int> a, List<int> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// A network photo shown as an unrecognisable soft blur.
///
/// The bitmap is decoded only [decodeWidth] pixels wide and stretched with
/// bilinear filtering, which reads as a heavy gaussian blur: the colours of
/// the photo survive, the face does not. Cost is a few hundred bytes of
/// decoded pixels and an ordinary image draw.
///
/// [fallback] shows while loading, on error, and when [imageUrl] is empty.
///
/// Usage:
/// ```dart
/// ClipOval(
///   child: FrostedImagePlaceholder(
///     imageUrl: avatarUrl,
///     size: 44,
///     fallback: lockedIcon,
///   ),
/// )
/// ```
class FrostedImagePlaceholder extends StatelessWidget {
  final String? imageUrl;

  /// Width and height in logical pixels. Null fills the parent.
  final double? size;

  final Widget fallback;

  /// Decoded bitmap width. Small enough that nobody is identifiable.
  final int decodeWidth;

  const FrostedImagePlaceholder({
    super.key,
    required this.imageUrl,
    required this.fallback,
    this.size,
    this.decodeWidth = 8,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) return fallback;

    return ExcludeSemantics(
      child: OptimizedImage(
        imageUrl: url,
        width: size ?? double.infinity,
        height: size ?? double.infinity,
        fit: BoxFit.cover,
        size: ImageSize.thumbnail,
        memoryCacheWidth: decodeWidth,
        showDownloadProgress: false,
        placeholder: fallback,
        errorWidget: fallback,
      ),
    );
  }
}
