import 'package:flutter/material.dart';

/// Breakpoint helpers for phone / tablet / desktop layouts.
class AppBreakpoints {
  AppBreakpoints._();

  static const double phone = 0;
  static const double tablet = 600;
  static const double desktop = 900;

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
