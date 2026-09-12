import 'package:flutter/material.dart';

import 'app_breakpoints.dart';

/// Shows completely different layouts per breakpoint.
///
/// Pass [WidgetBuilder]s — not pre-built widgets — so unused breakpoints are
/// never constructed. Eager `Widget` args used to crash phone screens when the
/// tablet tree threw during [ChatListPage] build.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    required this.phone,
    this.tablet,
    this.desktop,
    super.key,
  });

  final WidgetBuilder phone;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  @override
  Widget build(BuildContext context) {
    if (AppBreakpoints.isDesktop(context) && desktop != null) {
      return desktop!(context);
    }
    if (AppBreakpoints.isTablet(context) && tablet != null) {
      return tablet!(context);
    }
    return phone(context);
  }
}
