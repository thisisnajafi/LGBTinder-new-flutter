import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/auth/utils/otp_rate_limit.dart';
import 'package:lgbtindernew/shared/models/api_error.dart';

void main() {
  group('OtpRateLimit Laravel contract fixtures', () {
    /// Exact burned-code body from OtpAttemptLimiter / AuthController.
    const otpTooManyAttemptsBody = <String, dynamic>{
      'status': false,
      'message':
          'Too many incorrect codes. Please request a new code or try again later.',
      'error_code': 'OTP_TOO_MANY_ATTEMPTS',
      'retry_after': 600,
    };

    /// IP limiter: retry_after only, no error_code (top-level seconds).
    const ipLimiterBodyTopLevel = <String, dynamic>{
      'status': false,
      'message': 'Too Many Attempts.',
      'retry_after': 3600,
    };

    /// IP limiter: nested fractional retry_after (ceil -> 3543).
    const ipLimiterBodyNestedDecimal = <String, dynamic>{
      'status': false,
      'message': 'Too Many Attempts.',
      'data': {'retry_after': 3542.71},
    };

    test('OTP_TOO_MANY_ATTEMPTS clears-code lock with retry_after 600', () {
      final error = OtpRateLimit.tryParseRateLimit(
        statusCode: 429,
        body: otpTooManyAttemptsBody,
      );
      expect(error, isNotNull);
      expect(error!.errorCode, 'OTP_TOO_MANY_ATTEMPTS');
      expect(OtpRateLimit.matches(error), isTrue);
      expect(OtpRateLimit.isCodeInvalidated(error), isTrue);
      expect(error.isOtpRateLimited, isTrue);

      final lock = OtpRateLimit.lockFrom(error);
      expect(lock, isNotNull);
      expect(lock!.retryAfterSeconds, 600);
      expect(lock.codeInvalidated, isTrue);
      expect(
        OtpRateLimit.waitMessage(600, codeInvalidated: true),
        'Too many attempts. Please wait 10:00, then request a new code.',
      );
    });

    test('IP limiter top-level retry_after 3600 keeps code', () {
      final error = OtpRateLimit.tryParseRateLimit(
        statusCode: 429,
        body: ipLimiterBodyTopLevel,
      );
      expect(error, isNotNull);
      expect(error!.errorCode, isNot(equals('OTP_TOO_MANY_ATTEMPTS')));
      expect(OtpRateLimit.isCodeInvalidated(error), isFalse);
      expect(error.isOtpRateLimited, isFalse);

      final lock = OtpRateLimit.lockFrom(error);
      expect(lock, isNotNull);
      expect(lock!.retryAfterSeconds, 3600);
      expect(lock.codeInvalidated, isFalse);
      expect(
        OtpRateLimit.waitMessage(3600, codeInvalidated: false),
        'Too many requests. Please wait 60:00.',
      );
    });

    test('IP limiter data.retry_after 3542.71 rounds UP to 3543', () {
      final error = OtpRateLimit.tryParseRateLimit(
        statusCode: 429,
        body: ipLimiterBodyNestedDecimal,
      );
      expect(error, isNotNull);
      final lock = OtpRateLimit.lockFrom(error!);
      expect(lock, isNotNull);
      expect(lock!.retryAfterSeconds, 3543);
      expect(lock.codeInvalidated, isFalse);
      expect(error.retryAfterSeconds, 3543);
    });

    test('never reads failed_attempts or restriction_tier', () {
      final body = <String, dynamic>{
        ...otpTooManyAttemptsBody,
        'data': {
          'failed_attempts': 99,
          'restriction_tier': 'hard',
          'retry_after': 12,
        },
      };
      final error = OtpRateLimit.tryParseRateLimit(
        statusCode: 429,
        body: body,
      )!;
      // Top-level retry_after wins over nested when both present.
      expect(OtpRateLimit.retryAfterSeconds(error), 600);
      expect(error.responseData?['data']?['failed_attempts'], 99);
      // Contract: helpers must not branch on these keys.
      expect(OtpRateLimit.isCodeInvalidated(error), isTrue);
    });
  });

  group('OtpRateLimit parsing', () {
    test('matches 429 with OTP_TOO_MANY_ATTEMPTS', () {
      final error = ApiError(
        code: 429,
        message: 'Too many attempts',
        errorCode: OtpRateLimit.errorCode,
        responseData: {'error_code': OtpRateLimit.errorCode, 'retry_after': 90},
      );
      expect(OtpRateLimit.matches(error), isTrue);
      expect(error.isOtpRateLimited, isTrue);
      expect(OtpRateLimit.retryAfterSeconds(error), 90);
      expect(error.retryAfterSeconds, 90);
    });

    test('reads nested retry_after and formats countdown', () {
      final error = ApiError(
        code: 429,
        message: 'locked',
        errorCode: OtpRateLimit.errorCode,
        responseData: {
          'error_code': OtpRateLimit.errorCode,
          'data': {'retry_after': '65'},
        },
      );
      expect(OtpRateLimit.retryAfterSeconds(error), 65);
      expect(OtpRateLimit.formatCountdown(65), '1:05');
      expect(
        OtpRateLimit.waitMessage(65, codeInvalidated: true),
        'Too many attempts. Please wait 1:05, then request a new code.',
      );
      expect(
        OtpRateLimit.waitMessage(0, codeInvalidated: true),
        'You can request a new code now.',
      );
      expect(
        OtpRateLimit.waitMessage(0, codeInvalidated: false),
        'You can try again now.',
      );
    });

    test('ceils decimal string retry_after and falls back to 60', () {
      final fractional = ApiError(
        code: 429,
        message: 'wait',
        responseData: {'retry_after': '1.01'},
      );
      expect(OtpRateLimit.retryAfterSeconds(fractional), 2);

      final missing = ApiError(
        code: 429,
        message: 'locked',
        errorCode: OtpRateLimit.errorCode,
        responseData: {'error_code': OtpRateLimit.errorCode},
      );
      expect(
        OtpRateLimit.retryAfterSeconds(missing),
        OtpRateLimit.defaultRetryAfterSeconds,
      );

      final zero = ApiError(
        code: 429,
        message: 'wait',
        responseData: {'retry_after': 0},
      );
      expect(
        OtpRateLimit.retryAfterSeconds(zero),
        OtpRateLimit.defaultRetryAfterSeconds,
      );
    });

    test('fromDioException preserves error_code and retry_after', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/auth/verify-otp'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/verify-otp'),
          statusCode: 429,
          data: {
            'status': false,
            'message':
                'Too many incorrect codes. Please request a new code or try again later.',
            'error_code': 'OTP_TOO_MANY_ATTEMPTS',
            'retry_after': 600,
          },
        ),
        type: DioExceptionType.badResponse,
      );
      final error = ApiError.fromDioException(dio);
      expect(error.code, 429);
      expect(error.errorCode, 'OTP_TOO_MANY_ATTEMPTS');
      expect(error.isOtpRateLimited, isTrue);
      expect(error.retryAfterSeconds, 600);
      expect(
        error.getUserFriendlyMessage(),
        'Too many code attempts. Please wait and request a new code.',
      );
    });

    test('tryParseRateLimit rejects other 429 bodies', () {
      expect(
        OtpRateLimit.tryParseRateLimit(
          statusCode: 429,
          body: {'error_code': 'SWIPE_LIMIT_REACHED'},
        ),
        isNull,
      );
      final parsed = OtpRateLimit.tryParseRateLimit(
        statusCode: 429,
        body: {
          'error_code': 'OTP_TOO_MANY_ATTEMPTS',
          'retry_after': 30,
          'message': 'Wait',
        },
      );
      expect(parsed, isNotNull);
      expect(OtpRateLimit.retryAfterSeconds(parsed!), 30);
    });
  });
}
