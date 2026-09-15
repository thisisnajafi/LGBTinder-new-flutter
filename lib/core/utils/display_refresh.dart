import 'dart:ui' show FlutterView;

import 'package:flutter/widgets.dart';

/// Current Flutter view refresh rate in Hz (PERF-ANDROID-003).
///
/// On a 120Hz panel this is typically `120`. Tests and most emulators report
/// `60`. Returns `0` when no view is registered yet.
double displayRefreshRateHz([FlutterView? view]) {
  if (view != null) return view.display.refreshRate;
  final views = WidgetsBinding.instance.platformDispatcher.views;
  if (views.isEmpty) return 0;
  return views.first.display.refreshRate;
}
