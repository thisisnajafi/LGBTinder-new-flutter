import '../../../shared/models/api_error.dart';

/// Helpers for backend OTP lockouts (`OTP_TOO_MANY_ATTEMPTS` + `retry_after`).
///
/// Returned by verify-login-code, verify-otp, reset-password, and
/// send-verification (registration) as HTTP 429.
/// The code is invalidated; the user must wait, then request a new code.
abstract final class OtpRateLimit {
  static const String errorCode = 'OTP_TOO_MANY_ATTEMPTS';
  static const int defaultRetryAfterSeconds = 60;

  static bool matches(ApiError error) =>
      error.code == 429 &&
      (error.errorCode == errorCode ||
          error.responseData?['error_code']?.toString() == errorCode);

  /// Seconds to wait before a new code can be requested.
  static int retryAfterSeconds(ApiError error) {
    final data = error.responseData;
    Object? raw = data?['retry_after'] ?? data?['retryAfter'];
    if (raw == null) {
      final nested = data?['data'];
      if (nested is Map) {
        raw = nested['retry_after'] ?? nested['retryAfter'];
      }
    }
    final parsed = switch (raw) {
      final int n => n,
      final num n => n.toInt(),
      final String s => int.tryParse(s),
      _ => null,
    };
    if (parsed == null || parsed <= 0) return defaultRetryAfterSeconds;
    return parsed;
  }

  static String formatCountdown(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;
    final minutes = safe ~/ 60;
    final secs = safe % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  /// Clear wait message shown while the lockout countdown runs.
  static String waitMessage(int seconds) {
    final remaining = seconds < 0 ? 0 : seconds;
    if (remaining <= 0) {
      return 'You can request a new code now.';
    }
    return 'Too many attempts. Please wait ${formatCountdown(remaining)}, '
        'then request a new code.';
  }

  /// Parse a Dio/API JSON body the same way [ApiError.fromDioException] does.
  static ApiError? tryParseRateLimit({
    required int? statusCode,
    required Map<String, dynamic>? body,
  }) {
    if (statusCode != 429 || body == null) return null;
    final code = body['error_code']?.toString() ?? body['code']?.toString();
    if (code != errorCode) return null;
    return ApiError(
      code: 429,
      message:
          body['message']?.toString() ??
          'Too many code attempts. Please wait and request a new code.',
      errorCode: errorCode,
      responseData: body,
    );
  }
}
