import 'package:flutter/material.dart';

import 'app_breakpoints.dart';

/// Adaptive padding tokens for pages and cards.
class ResponsivePadding {
  ResponsivePadding._();

  /// Standard horizontal page padding.
  static EdgeInsets horizontal(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: AppBreakpoints.value(
        context,
        phone: 20.0,
        tablet: 40.0,
        desktop: 80.0,
      ),
    );
  }

  /// Standard page padding (horizontal + safe area aware vertical).
  static EdgeInsets page(BuildContext context) {
    final safeArea = MediaQuery.paddingOf(context);
    return EdgeInsets.fromLTRB(
      AppBreakpoints.value(context, phone: 20.0, tablet: 40.0),
      safeArea.top + 16,
      AppBreakpoints.value(context, phone: 20.0, tablet: 40.0),
      safeArea.bottom + 16,
    );
  }

  /// Section gap between major blocks.
  static double sectionGap(BuildContext context) =>
      AppBreakpoints.value(context, phone: 24.0, tablet: 32.0);

  /// Card inner padding.
  static EdgeInsets card(BuildContext context) {
    return EdgeInsets.all(
      AppBreakpoints.value(context, phone: 16.0, tablet: 20.0),
    );
  }
}
