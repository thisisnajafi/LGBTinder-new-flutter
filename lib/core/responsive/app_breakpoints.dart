import 'package:flutter/material.dart';

/// Breakpoint helpers for phone / tablet / desktop layouts.
class AppBreakpoints {
  AppBreakpoints._();

  static const double phone = 0;

  /// Widths below this are compact phones (320dp class).
  static const double compact = 360;

  static const double tablet = 600;

  /// Same threshold as [tablet]. Expanded layouts start here.
  static const double expanded = tablet;

  static const double desktop = 900;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compact;

  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= expanded;

  /// Compact under 360, medium through 599, expanded at 600 and up.
  static AppWindowSize windowSize(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < compact) return AppWindowSize.compact;
    if (width < expanded) return AppWindowSize.medium;
    return AppWindowSize.expanded;
  }

  static bool isPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < tablet;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= tablet && width < desktop;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;

  /// Returns a value based on screen size.
  ///
  /// Usage: `AppBreakpoints.value(context, phone: 16, tablet: 24)`
  static T value<T>(
    BuildContext context, {
    required T phone,
    T? tablet,
    T? desktop,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= AppBreakpoints.desktop && desktop != null) {
      return desktop;
    }
    if (width >= AppBreakpoints.tablet && tablet != null) {
      return tablet;
    }
    return phone;
  }
}

/// Width class used by responsive wrappers.
enum AppWindowSize { compact, medium, expanded }
