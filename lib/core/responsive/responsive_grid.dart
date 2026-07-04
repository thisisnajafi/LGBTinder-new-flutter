import 'package:flutter/material.dart';

import 'app_breakpoints.dart';

/// Grid and max-width helpers for responsive layouts.
class ResponsiveGrid {
  ResponsiveGrid._();

  /// Columns for photo grids, interest chips, etc.
  static int photoColumns(BuildContext context) =>
      AppBreakpoints.value(context, phone: 3, tablet: 4, desktop: 5);

  static int cardColumns(BuildContext context) =>
      AppBreakpoints.value(context, phone: 1, tablet: 2, desktop: 3);

  /// Max content width — prevents content from stretching too wide on tablets.
  static double maxContentWidth(BuildContext context) =>
      AppBreakpoints.value(
        context,
        phone: double.infinity,
        tablet: 600.0,
        desktop: 800.0,
      );

  /// Onboarding / auth welcome max width on tablet.
  static double onboardingMaxWidth(BuildContext context) =>
      AppBreakpoints.value(
        context,
        phone: double.infinity,
        tablet: 500.0,
        desktop: 500.0,
      );

  /// Discovery card max width on tablet.
  static double discoverCardMaxWidth(BuildContext context) =>
      AppBreakpoints.value(
        context,
        phone: double.infinity,
        tablet: 420.0,
        desktop: 420.0,
      );

  /// Chat master panel width on tablet.
  static const double chatMasterPanelWidth = 300.0;

  /// Max width for chat message bubbles (caps width on tablet).
  static double chatBubbleMaxWidth(
    BuildContext context, {
    double fraction = 0.75,
  }) {
    final calculated = MediaQuery.sizeOf(context).width * fraction;
    final cap = AppBreakpoints.value(
      context,
      phone: double.infinity,
      tablet: 420.0,
      desktop: 480.0,
    );
    if (cap == double.infinity) return calculated;
    return calculated.clamp(0, cap);
  }

  /// Bottom nav max width on tablet/desktop.
  static double bottomNavMaxWidth(BuildContext context) =>
      AppBreakpoints.value(
        context,
        phone: double.infinity,
        tablet: 680.0,
        desktop: 720.0,
      );

  /// Center content with max width on tablets/desktop.
  static Widget constrained(BuildContext context, Widget child) {
    final max = maxContentWidth(context);
    if (max == double.infinity) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: max),
        child: child,
      ),
    );
  }

  /// Center content with a custom max width on tablet/desktop.
  static Widget constrainedTo(
    BuildContext context,
    Widget child, {
    required double tablet,
    double? desktop,
  }) {
    final max = AppBreakpoints.value(
      context,
      phone: double.infinity,
      tablet: tablet,
      desktop: desktop ?? tablet,
    );
    if (max == double.infinity) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: max),
        child: child,
      ),
    );
  }
}
