import 'package:flutter/foundation.dart';

/// Central logging for startup, auth, routing, API, and screen changes.
/// All logs are debug-only (kDebugMode). Filter examples:
///   adb logcat | findstr "STARTUP"   — main(), runApp, first frame, push init
///   adb logcat | findstr "AUTH"      — token check, API validation, redirects
///   adb logcat | findstr "ROUTE"     — GoRouter, go(), redirects
///   adb logcat | findstr "API"       — request URI, body; response status, body
///   adb logcat | findstr "SCREEN"    — initState/build per screen

void startupLog(String message) {
  if (kDebugMode) debugPrint('[STARTUP] $message');
}

void authLog(String message) {
  if (kDebugMode) debugPrint('[AUTH] $message');
}

void routeLog(String message) {
  if (kDebugMode) debugPrint('[ROUTE] $message');
}

void apiLog(String message) {
  if (kDebugMode) debugPrint('[API] $message');
}

void screenLog(String screenName, String event, [Map<String, dynamic>? data]) {
  if (!kDebugMode) return;
  final extra = data != null && data.isNotEmpty ? ' ${data.toString()}' : '';
  debugPrint('[SCREEN] $screenName: $event$extra');
}
