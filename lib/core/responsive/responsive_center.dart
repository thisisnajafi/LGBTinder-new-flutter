import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_breakpoints.dart';

/// Centers [child] and caps its width on expanded layouts.
///
/// The default cap is 720dp, for forms, settings, profile, and paywall.
/// Phone widths are left unchanged. Height stays bounded so descendants
/// can use [Expanded].
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 720,
    this.onlyWhenExpanded = true,
  });

  final Widget child;
  final double maxWidth;

  /// When true, the cap applies only at [AppBreakpoints.expanded] and up.
  final bool onlyWhenExpanded;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final shouldCap = !onlyWhenExpanded || width >= AppBreakpoints.expanded;
        final cap = shouldCap ? math.min(maxWidth, width) : width;
        if (!width.isFinite || cap >= width) return child;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: cap,
            height: constraints.maxHeight,
            child: child,
          ),
        );
      },
    );
  }
}

/// Caps the text scaler for decorative or hero copy.
///
/// Body copy should keep the system scaler. Use this only where a display
/// style would overflow at large accessibility sizes.
class ClampedTextScale extends StatelessWidget {
  const ClampedTextScale({
    super.key,
    required this.child,
    this.maxScaleFactor = 1.3,
  });

  final Widget child;
  final double maxScaleFactor;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context).clamp(
      maxScaleFactor: maxScaleFactor,
    );
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: scaler),
      child: child,
    );
  }
}
