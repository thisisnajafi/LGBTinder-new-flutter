import '../../../shared/models/api_error.dart';

/// Active wait after an HTTP 429 on an OTP/code screen.
class OtpWaitLock {
  const OtpWaitLock({
    required this.retryAfterSeconds,
    required this.codeInvalidated,
  });

  final int retryAfterSeconds;

  /// When true (`OTP_TOO_MANY_ATTEMPTS`), the code was burned — clear fields
  /// and offer Resend after the countdown. When false (IP/retry-only 429),
  /// keep the entered code and only block submit/resend until the wait ends.
  final bool codeInvalidated;
}

/// Helpers for HTTP 429 waits on OTP / verification code screens.
///
/// Endpoints: verify-login-code, verify-otp, reset-password, send-verification.
///
/// - Any 429 with `retry_after` (top-level or under `data`) starts a countdown.
/// - With `error_code: OTP_TOO_MANY_ATTEMPTS` the code is invalidated.
/// - Without that code (older IP limiter) the entered digits are kept.
///
/// Intentionally ignores `data.failed_attempts` and `restriction_tier`.
abstract final class OtpRateLimit {
  static const String errorCode = 'OTP_TOO_MANY_ATTEMPTS';
  static const int defaultRetryAfterSeconds = 60;

  /// True when this is a 429 that carries a usable `retry_after`.
  static bool matches(ApiError error) {
    if (error.code != 429) return false;
    return _rawRetryAfter(error.responseData) != null ||
        isCodeInvalidated(error);
  }

  /// Burned-code lockout from the per-email OTP attempt limiter.
  static bool isCodeInvalidated(ApiError error) =>
      error.code == 429 &&
      (error.errorCode == errorCode ||
          error.responseData?['error_code']?.toString() == errorCode ||
          _nestedErrorCode(error.responseData) == errorCode);

  static String? _nestedErrorCode(Map<String, dynamic>? data) {
    final nested = data?['data'];
    if (nested is Map) {
      return nested['error_code']?.toString();
    }
    return null;
  }

  static Object? _rawRetryAfter(Map<String, dynamic>? data) {
    if (data == null) return null;
    Object? raw = data['retry_after'] ?? data['retryAfter'];
    if (raw == null) {
      final nested = data['data'];
      if (nested is Map) {
        raw = nested['retry_after'] ?? nested['retryAfter'];
      }
    }
    return raw;
  }

  /// Parse `retry_after` as int / num / decimal string; round fractional
  /// values UP (ceil). Returns null when missing or non-positive.
  static int? _parseSeconds(Object? raw) {
    final double? asDouble = switch (raw) {
      final int n => n.toDouble(),
      final num n => n.toDouble(),
      final String s => double.tryParse(s.trim()),
      _ => null,
    };
    if (asDouble == null || asDouble <= 0) return null;
    // Round UP so a partial second still blocks for a full second.
    return asDouble.ceil();
  }

  /// Seconds to wait. Prefers body `retry_after` (top-level or under `data`);
  /// falls back to [defaultRetryAfterSeconds] when missing or <= 0.
  static int retryAfterSeconds(ApiError error) {
    final parsed = _parseSeconds(_rawRetryAfter(error.responseData));
    if (parsed != null && parsed > 0) return parsed;
    return defaultRetryAfterSeconds;
  }

  /// Build the UI lock from a 429 [ApiError], or `null` if it should not wait.
  static OtpWaitLock? lockFrom(ApiError error) {
    if (!matches(error)) return null;
    return OtpWaitLock(
      retryAfterSeconds: retryAfterSeconds(error),
      codeInvalidated: isCodeInvalidated(error),
    );
  }

  static String formatCountdown(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;
    final minutes = safe ~/ 60;
    final secs = safe % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  static String waitMessage(int seconds, {required bool codeInvalidated}) {
    final remaining = seconds < 0 ? 0 : seconds;
    if (remaining <= 0) {
      return codeInvalidated
          ? 'You can request a new code now.'
          : 'You can try again now.';
    }
    if (codeInvalidated) {
      return 'Too many attempts. Please wait ${formatCountdown(remaining)}, '
          'then request a new code.';
    }
    return 'Too many requests. Please wait ${formatCountdown(remaining)}.';
  }

  /// Parse a 429 JSON body into [ApiError] for contract tests / Dio-free paths.
  ///
  /// Accepts top-level or nested `retry_after`. Does not read
  /// `failed_attempts` or `restriction_tier`.
  static ApiError? tryParseRateLimit({
    required int? statusCode,
    required Map<String, dynamic>? body,
  }) {
    if (statusCode != 429 || body == null) return null;
    final hasRetry = _rawRetryAfter(body) != null;
    final code = body['error_code']?.toString() ?? _nestedErrorCode(body);
    final isBurn = code == errorCode;
    if (!hasRetry && !isBurn) return null;
    return ApiError(
      code: 429,
      message:
          body['message']?.toString() ??
          (isBurn
              ? 'Too many code attempts. Please wait and request a new code.'
              : 'Too many requests. Please wait a moment.'),
      errorCode: isBurn ? errorCode : code,
      responseData: body,
    );
  }
}
