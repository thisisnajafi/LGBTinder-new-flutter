import 'package:flutter/foundation.dart';

import '../../shared/models/api_error.dart';
import '../services/app_logger.dart';

export '../services/app_logger.dart';

/// Central logging for startup, auth, routing, API, and screen changes.
/// Legacy helpers delegate to [AppLogger] for backward compatibility.

void startupLog(String message) {
  AppLogger.info(message, tag: 'STARTUP');
}

void authLog(String message) {
  AppLogger.info(message, tag: 'AUTH');
}

void routeLog(String message) {
  AppLogger.debug(message, tag: 'ROUTE');
}

void apiLog(String message) {
  AppLogger.debug(message, tag: 'API');
}

void screenLog(String screenName, String event, [Map<String, dynamic>? data]) {
  if (!kDebugMode) return;
  final extra = data != null && data.isNotEmpty ? ' ${data.toString()}' : '';
  AppLogger.debug('$screenName: $event$extra', tag: 'SCREEN');
}

/// Profile load, cache, and parse diagnostics.
void profileLog(String message) {
  AppLogger.debug(message, tag: 'PROFILE');
}

void profileLogError(String stage, Object error, [StackTrace? stackTrace]) {
  if (error is ApiError) {
    AppLogger.error(
      '$stage ApiError code=${error.code} message=${error.message}',
      tag: 'PROFILE',
      error: error,
      stackTrace: stackTrace,
    );
    if (error.responseData != null) {
      profileLog('$stage responseData=${error.responseData}');
    }
  } else {
    AppLogger.error(
      '$stage [${error.runtimeType}] $error',
      tag: 'PROFILE',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
