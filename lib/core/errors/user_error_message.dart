import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../shared/models/api_error.dart';
import '../services/app_logger.dart';

/// Generic text shown when an error has no known, user-safe message.
const String kGenericErrorMessage = 'Something went wrong. Please try again.';
const String kNoInternetMessage =
    'No internet connection. Please check your network.';
const String kTimeoutMessage =
    'Connection timeout. Please check your internet connection.';

/// Central mapper: turns any thrown object into text that is safe to show.
///
/// Known, user-facing messages (validation errors the backend meant for the
/// user, mapped error codes, connectivity, plan gates) are kept. Anything
/// that looks technical (stack traces, exception class names, SQL, URLs,
/// JSON, file paths, Dio text) becomes [kGenericErrorMessage]. The original
/// error is logged privately via [AppLogger].
String userErrorMessage(
  Object? error, {
  StackTrace? stackTrace,
  String? context,
  String fallback = kGenericErrorMessage,
}) {
  if (error == null) return fallback;
  if (context != null || stackTrace != null) {
    AppLogger.error(
      context ?? 'User-facing error',
      tag: 'UserError',
      error: error,
      stackTrace: stackTrace,
    );
  }

  if (error is String) return sanitizeUserMessage(error, fallback: fallback);

  if (error is ApiError) return _fromApiError(error, fallback);

  if (error is DioException) {
    return _fromApiError(ApiError.fromDioException(error), fallback);
  }

  if (error is SocketException) return kNoInternetMessage;
  if (error is TimeoutException) return kTimeoutMessage;
  if (error is HttpException) return fallback;

  // Domain exceptions whose message was written for the user.
  final dynamic dyn = error;
  if (error is Exception) {
    try {
      final msg = dyn.message;
      if (msg is String) return sanitizeUserMessage(msg, fallback: fallback);
    } catch (_) {}
    final text = error.toString();
    const prefix = 'Exception: ';
    if (text.startsWith(prefix)) {
      return sanitizeUserMessage(text.substring(prefix.length),
          fallback: fallback);
    }
  }
  // Errors (TypeError, StateError, RangeError, ...) are always bugs.
  return fallback;
}

String _fromApiError(ApiError error, String fallback) {
  final code = error.code;
  if (code != null && code >= 500) return kGenericErrorMessage;
  if (error.errorCode != null &&
      backendErrorMessages.containsKey(error.errorCode)) {
    return backendErrorMessages[error.errorCode]!;
  }
  final first = error.firstError;
  if (first != null && first.isNotEmpty) {
    return sanitizeUserMessage(first, fallback: fallback);
  }
  final msg = sanitizeUserMessage(error.message, fallback: '');
  if (msg.isNotEmpty &&
      msg != 'An error occurred' &&
      msg != 'An unexpected error occurred' &&
      msg != 'Server error occurred') {
    return msg;
  }
  if (code != null && httpErrorMessages.containsKey(code)) {
    return httpErrorMessages[code]!;
  }
  return fallback;
}

final List<RegExp> _technicalPatterns = [
  RegExp(r'#\d+\s+\S'), // stack frame
  RegExp(r'\.(dart|php|java|kt|swift|js)\b', caseSensitive: false),
  RegExp(r'https?://', caseSensitive: false),
  RegExp(r'\b(SQLSTATE|SELECT\s|INSERT\s|UPDATE\s+\w+\s+SET|DELETE\s+FROM|syntax error)', caseSensitive: false),
  RegExp(r'(Dio(Exception|Error)|SocketException|HttpException|FormatException|PlatformException|HandshakeException|MissingPluginException|StateError|TypeError|RangeError|NoSuchMethodError|Null check operator|is not a subtype|LateInitializationError|Instance of )'),
  RegExp(r'\b\w+(Exception|Error)\s*[:(]'),
  RegExp(r'^\s*[\[{]'), // JSON
  RegExp(r'"\w+"\s*:'), // JSON key
  RegExp(r'(^|\s)(/[\w.\-]+){2,}'), // unix path
  RegExp(r'[A-Za-z]:\\'), // windows path
  RegExp(r'\bstatus code of \d{3}\b', caseSensitive: false),
  RegExp(r'\b(stack ?trace|trace:|errno|exception)\b', caseSensitive: false),
  RegExp(r'\b(Bearer\s|token=|api[_-]?key)', caseSensitive: false),
];

/// True when [message] contains technical details unsafe for end users.
bool looksTechnical(String message) {
  if (message.length > 220) return true;
  if (message.contains('\n') && message.split('\n').length > 3) return true;
  return _technicalPatterns.any((p) => p.hasMatch(message));
}

/// Returns [message] if it is user-safe, otherwise [fallback].
String sanitizeUserMessage(String? message,
    {String fallback = kGenericErrorMessage}) {
  if (message == null) return fallback;
  final trimmed = message.trim();
  if (trimmed.isEmpty) return fallback;
  if (looksTechnical(trimmed)) {
    if (kDebugMode) {
      AppLogger.warning('Hid technical error from UI: $trimmed',
          tag: 'UserError');
    }
    return fallback;
  }
  return trimmed;
}
