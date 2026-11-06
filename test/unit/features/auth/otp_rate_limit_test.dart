import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/auth/utils/otp_rate_limit.dart';
import 'package:lgbtindernew/shared/models/api_error.dart';

void main() {
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
        OtpRateLimit.waitMessage(65),
        'Too many attempts. Please wait 1:05, then request a new code.',
      );
      expect(OtpRateLimit.waitMessage(0), 'You can request a new code now.');
    });

    test('defaults retry_after when missing or invalid', () {
      final error = ApiError(
        code: 429,
        message: 'locked',
        errorCode: OtpRateLimit.errorCode,
        responseData: {'error_code': OtpRateLimit.errorCode},
      );
      expect(
        OtpRateLimit.retryAfterSeconds(error),
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
            'message': 'Too many attempts',
            'error_code': 'OTP_TOO_MANY_ATTEMPTS',
            'retry_after': 120,
          },
        ),
        type: DioExceptionType.badResponse,
      );
      final error = ApiError.fromDioException(dio);
      expect(error.code, 429);
      expect(error.errorCode, 'OTP_TOO_MANY_ATTEMPTS');
      expect(error.isOtpRateLimited, isTrue);
      expect(error.retryAfterSeconds, 120);
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
