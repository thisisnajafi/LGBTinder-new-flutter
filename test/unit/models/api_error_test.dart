import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/shared/models/api_error.dart';

void main() {
  group('ApiError.shouldForceLogout', () {
    test('returns false for 403 regardless of body', () {
      expect(
        ApiError.shouldForceLogout(
          statusCode: 403,
          body: {'error_code': 'MATCHES_PREMIUM_REQUIRED'},
        ),
        isFalse,
      );
      expect(
        ApiError.shouldForceLogout(
          statusCode: 403,
          body: {'purchase_required': true},
        ),
        isFalse,
      );
    });

    test('returns true for 401 on protected routes', () {
      expect(
        ApiError.shouldForceLogout(
          statusCode: 401,
          requestPath: '/discover/feed',
        ),
        isTrue,
      );
    });

    test('returns false for 401 on login/register routes', () {
      expect(
        ApiError.shouldForceLogout(
          statusCode: 401,
          requestPath: '/auth/login',
        ),
        isFalse,
      );
    });

    test('returns false for 401 with upgrade_required body', () {
      expect(
        ApiError.shouldForceLogout(
          statusCode: 401,
          body: {'upgrade_required': true},
          requestPath: '/matches',
        ),
        isFalse,
      );
    });
  });

  group('ApiError.isFeatureForbiddenResponse', () {
    test('treats all 403 as feature forbidden', () {
      expect(
        ApiError.isFeatureForbiddenResponse(statusCode: 403),
        isTrue,
      );
    });

    test('detects purchase_required and known error codes', () {
      expect(
        ApiError.isFeatureForbiddenResponse(
          statusCode: 200,
          body: {'purchase_required': true},
        ),
        isTrue,
      );
      expect(
        ApiError.isFeatureForbiddenResponse(
          statusCode: 200,
          body: {'error_code': 'REWIND_PREMIUM_REQUIRED'},
        ),
        isTrue,
      );
    });
  });

  group('ApiError.requiresLogin', () {
    test('403 premium denial does not require login', () {
      final error = ApiError(
        code: 403,
        message: 'Upgrade required',
        errorCode: 'MATCHES_PREMIUM_REQUIRED',
        responseData: {'error_code': 'MATCHES_PREMIUM_REQUIRED'},
      );
      expect(error.requiresLogin, isFalse);
      expect(error.isFeatureForbidden, isTrue);
    });

    test('401 session expiry requires login', () {
      final error = ApiError(
        code: 401,
        message: 'Unauthenticated',
      );
      expect(error.requiresLogin, isTrue);
    });
  });
}
