// Structured logger for LGBTFinder
// In debug mode: prints formatted output to console
// Ready for crash reporting integration (Sentry, Firebase Crashlytics)

import 'package:flutter/foundation.dart';

enum LogLevel { verbose, debug, info, warning, error, fatal }

class AppLogger {
  AppLogger._();

  static bool _enabled = kDebugMode;
  static const String _reset = '\x1B[0m';
  static const String _grey = '\x1B[90m';
  static const String _cyan = '\x1B[36m';
  static const String _yellow = '\x1B[33m';
  static const String _red = '\x1B[31m';
  static const String _magenta = '\x1B[35m';

  static void verbose(String message, {String? tag}) =>
      _log(LogLevel.verbose, message, tag: tag);

  static void debug(String message, {String? tag}) =>
      _log(LogLevel.debug, message, tag: tag);

  static void info(String message, {String? tag}) =>
      _log(LogLevel.info, message, tag: tag);

  static void warning(String message, {String? tag, Object? error}) =>
      _log(LogLevel.warning, message, tag: tag, error: error);

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _log(LogLevel.error, message,
          tag: tag, error: error, stackTrace: stackTrace);

  static void fatal(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _log(LogLevel.fatal, message,
          tag: tag, error: error, stackTrace: stackTrace);

  /// Log an API request
  static void apiRequest(String method, String url, {Map? body}) {
    if (!_enabled) return;
    debugPrint('$_cyan[API ▶] $method $url$_reset');
    if (body != null && body.isNotEmpty) {
      debugPrint('$_grey       body: $body$_reset');
    }
  }

  /// Log an API response
  static void apiResponse(String method, String url, int statusCode,
      {dynamic body}) {
    if (!_enabled) return;
    final color = statusCode >= 400 ? _red : _cyan;
    debugPrint('$color[API ◀] $statusCode $method $url$_reset');
    if (statusCode >= 400 && body != null) {
      debugPrint('$_red       response: $body$_reset');
    }
  }

  /// Log navigation events
  static void navigation(String from, String to) {
    if (!_enabled) return;
    debugPrint('$_grey[NAV] $from → $to$_reset');
  }

  /// Log provider state changes
  static void providerState(String providerName, String state) {
    if (!_enabled) return;
    debugPrint('$_grey[PROVIDER] $providerName: $state$_reset');
  }

  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_enabled) return;

    final time = DateTime.now().toIso8601String().substring(11, 23);
    final prefix = _prefix(level);
    final tagStr = tag != null ? '[$tag] ' : '';

    debugPrint('$prefix [$time] $tagStr$message$_reset');

    if (error != null) {
      debugPrint('$_red  ↳ ${error.runtimeType}: $error$_reset');
    }
    if (stackTrace != null) {
      final lines = stackTrace
          .toString()
          .split('\n')
          .take(8)
          .map((l) => '$_grey  $l$_reset')
          .join('\n');
      debugPrint(lines);
    }
  }

  static String _prefix(LogLevel level) {
    switch (level) {
      case LogLevel.verbose:
        return '$_grey[VERBOSE]';
      case LogLevel.debug:
        return '$_grey[DEBUG]  ';
      case LogLevel.info:
        return '$_cyan[INFO]   ';
      case LogLevel.warning:
        return '$_yellow[WARN]   ';
      case LogLevel.error:
        return '$_red[ERROR]  ';
      case LogLevel.fatal:
        return '$_magenta[FATAL]  ';
    }
  }
}
