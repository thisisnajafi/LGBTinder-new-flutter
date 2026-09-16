import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Gradient ring around the floating tab bar (PERF-COMP-NAV-001 / 003 / 004).
enum NavBarGradientStyle {
  /// Rose → violet brand ring used by the live tab bar.
  brandLinear,

  /// Pride sweep used by the unused labeled navbar stub.
  prideSweep,
}

/// Paints a cached gradient (or solid) **ring** so the shader is not rebuilt
/// on every tab-body frame. The interior stays transparent so glass + icons
/// composite on top (Impeller + BackdropFilter used to swallow a filled rect).
class NavBarGradientShell extends StatelessWidget {
  const NavBarGradientShell({
    super.key,
    required this.child,
    required this.borderRadius,
    required this.borderWidth,
    required this.isDark,
    required this.solid,
    this.style = NavBarGradientStyle.brandLinear,
  });

  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final bool isDark;
  final bool solid;
  final NavBarGradientStyle style;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          color: solid ? _solidRingColor(isDark) : null,
          boxShadow: _shadows(isDark: isDark, solid: solid),
        ),
        child: CustomPaint(
          painter: solid
              ? null
              : _CachedNavBarGradientPainter(
                  isDark: isDark,
                  style: style,
                  borderRadius: borderRadius,
                  borderWidth: borderWidth,
                ),
          child: Padding(padding: EdgeInsets.all(borderWidth), child: child),
        ),
      ),
    );
  }

  static Color _solidRingColor(bool isDark) => isDark
      ? AppColors.accentPurple.withValues(alpha: 0.85)
      : AppColors.accentPink.withValues(alpha: 0.72);

  static List<BoxShadow> _shadows({required bool isDark, required bool solid}) {
    if (solid) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
    }
    if (isDark) {
      return [
        BoxShadow(
          color: AppColors.accentPurple.withValues(alpha: 0.28),
          blurRadius: 22,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: AppColors.accentRose.withValues(alpha: 0.14),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.28),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];
    }
    return [
      BoxShadow(
        color: AppColors.accentPurple.withValues(alpha: 0.2),
        blurRadius: 22,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: AppColors.accentRose.withValues(alpha: 0.1),
        blurRadius: 14,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.07),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ];
  }
}

class _CachedNavBarGradientPainter extends CustomPainter {
  _CachedNavBarGradientPainter({
    required this.isDark,
    required this.style,
    required this.borderRadius,
    required this.borderWidth,
  });

  final bool isDark;
  final NavBarGradientStyle style;
  final double borderRadius;
  final double borderWidth;

  ui.Shader? _shader;
  Size? _size;
  bool? _cachedDark;
  NavBarGradientStyle? _cachedStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    if (_shader == null ||
        _size != size ||
        _cachedDark != isDark ||
        _cachedStyle != style) {
      _size = size;
      _cachedDark = isDark;
      _cachedStyle = style;
      final rect = Offset.zero & size;
      _shader = switch (style) {
        NavBarGradientStyle.brandLinear => ui.Gradient.linear(
          rect.topLeft,
          rect.bottomRight,
          _brandColors(isDark),
          const [0.0, 0.5, 1.0],
        ),
        NavBarGradientStyle.prideSweep => ui.Gradient.sweep(
          rect.center,
          _prideSweepColors,
          _prideSweepStops,
        ),
      };
    }

    final inset = borderWidth.clamp(0.5, size.shortestSide / 2);
    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );
    final innerRadius = math.max(0.0, borderRadius - inset);
    final inner = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        inset,
        inset,
        math.max(0, size.width - inset * 2),
        math.max(0, size.height - inset * 2),
      ),
      Radius.circular(innerRadius),
    );
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRRect(outer)
      ..addRRect(inner);

    canvas.drawPath(
      path,
      Paint()
        ..shader = _shader
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _CachedNavBarGradientPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.style != style ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.borderWidth != borderWidth;
  }

  static List<Color> _brandColors(bool isDark) {
    if (isDark) {
      return [
        AppColors.accentRose.withValues(alpha: 0.92),
        AppColors.accentPurple.withValues(alpha: 0.95),
        AppColors.lgbtGradient[4].withValues(alpha: 0.88),
      ];
    }
    return [
      AppColors.accentRose.withValues(alpha: 0.72),
      AppColors.accentPurple.withValues(alpha: 0.82),
      AppColors.accentPink.withValues(alpha: 0.68),
    ];
  }

  static final List<Color> _prideSweepColors = [
    ...AppColors.lgbtGradient,
    AppColors.lgbtGradient.first,
  ];

  static final List<double> _prideSweepStops = [
    for (var i = 0; i < _prideSweepColors.length; i++)
      i / (_prideSweepColors.length - 1),
  ];
}
