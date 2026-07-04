import 'package:flutter/material.dart';

import 'app_breakpoints.dart';

/// Shows completely different layouts per breakpoint.
class ResponsiveLayout extends StatelessWidget {
  final Widget phone;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    required this.phone,
    this.tablet,
    this.desktop,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (AppBreakpoints.isDesktop(context) && desktop != null) {
      return desktop!;
    }
    if (AppBreakpoints.isTablet(context) && tablet != null) {
      return tablet!;
    }
    return phone;
  }
}
