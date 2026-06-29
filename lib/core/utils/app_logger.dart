import '../../shared/models/api_error.dart';
import '../services/app_logger.dart';

export '../services/app_logger.dart';

/// Central logging for startup, auth, routing, API, and screen changes.
/// Legacy helpers delegate to [AppLogger] for backward compatibility.

void startupLog(String message) {
  // Startup breadcrumbs suppressed in quiet console mode.
}

void authLog(String message) {
  // Auth breadcrumbs suppressed in quiet console mode.
}

void routeLog(String message) {
  // Routing diagnostics are verbose; enable via AppLogger.verbose if needed.
}

void apiLog(String message) {
  AppLogger.apiLine(message);
}

void screenLog(String screenName, String event, [Map<String, dynamic>? data]) {
  // Screen lifecycle logs suppressed in quiet console mode.
}

/// Profile load, cache, and parse diagnostics.
void profileLog(String message) {
  // Profile breadcrumbs suppressed in quiet console mode.
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
      AppLogger.apiLine(
        'PROFILE $stage responseData=${error.responseData}',
      );
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
