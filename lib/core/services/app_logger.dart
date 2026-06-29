// Structured logger for LGBTFinder
// Quiet by default: errors + API traffic only (see [_minLevel] / [_apiLogging]).

import 'package:flutter/foundation.dart';

enum LogLevel { verbose, debug, info, warning, error, fatal }

class AppLogger {
  AppLogger._();

  static const bool _enabled = kDebugMode;

  /// General app logs below this level are suppressed in debug console.
  static const LogLevel _minLevel = LogLevel.error;

  static const bool _apiLogging = true;

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

  /// Log an API request (always shown when [_apiLogging]).
  static void apiRequest(
    String method,
    String url, {
    Map? body,
    String? extra,
  }) {
    if (!_enabled || !_apiLogging) return;
    final suffix = extra != null && extra.isNotEmpty ? ' $extra' : '';
    debugPrint('$_cyan[API ▶] $method $url$suffix$_reset');
    if (body != null && body.isNotEmpty) {
      debugPrint('$_grey       req: $body$_reset');
    }
  }

  /// Log an API response (always shown when [_apiLogging]).
  static void apiResponse(
    String method,
    String url,
    int statusCode, {
    dynamic body,
  }) {
    if (!_enabled || !_apiLogging) return;
    final color = statusCode >= 400 ? _red : _cyan;
    debugPrint('$color[API ◀] $statusCode $method $url$_reset');
    if (statusCode >= 400 && body != null) {
      debugPrint('$_red       res: $body$_reset');
    }
  }

  /// Extra API detail line (errors, upload diagnostics).
  static void apiLine(String message) {
    if (!_enabled || !_apiLogging) return;
    debugPrint('$_cyan[API] $message$_reset');
  }

  /// Log navigation events (suppressed unless verbose).
  static void navigation(String from, String to) {
    _log(LogLevel.verbose, '$from → $to', tag: 'NAV');
  }

  /// Log provider state changes (suppressed unless verbose).
  static void providerState(String providerName, String state) {
    _log(LogLevel.verbose, '$providerName: $state', tag: 'PROVIDER');
  }

  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_enabled || level.index < _minLevel.index) return;

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
          .take(6)
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
