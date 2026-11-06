import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/payments/data/services/google_play_billing_service.dart';
import 'package:lgbtindernew/shared/models/api_error.dart';
import 'package:lgbtindernew/shared/models/api_response.dart';

/// Exact Laravel lifecycle bodies for activate / restore.
void main() {
  group('subscriptions activate/restore Laravel contract', () {
    const successBody = <String, dynamic>{
      'status': 'success',
      'data': {
        'subscription': {'id': 42, 'plan': 'gold', 'status': 'active'},
      },
    };

    const errorBody = <String, dynamic>{
      'status': 'error',
      'message':
          'SQLSTATE[HY000]: Internal debugging detail that must not reach users',
    };

    test('200 success envelope parses isSuccess with subscription data', () {
      final response = ApiResponse<Map<String, dynamic>>.fromJson(
        successBody,
        (json) => Map<String, dynamic>.from(json as Map),
      );
      expect(response.isSuccess, isTrue);
      expect(response.data, isNotNull);
      expect(response.data!['subscription'], isA<Map>());
      expect(response.data!['subscription']['id'], 42);
    });

    test('422 error envelope is not success and UI uses generic copy', () {
      final response = ApiResponse<Map<String, dynamic>>.fromJson(
        errorBody,
        (json) => Map<String, dynamic>.from(json as Map),
      );
      expect(response.isSuccess, isFalse);
      expect(response.message, contains('SQLSTATE'));

      // Mimic billing service: never surface response.message to the user.
      final userMessage = response.isSuccess
          ? GooglePlayBillingService.restoreSuccessMessage
          : GooglePlayBillingService.restoreBackendFailedMessage;
      expect(userMessage, GooglePlayBillingService.restoreBackendFailedMessage);
      expect(userMessage.contains('SQLSTATE'), isFalse);

      final apiError = ApiError.fromResponse(errorBody, statusCode: 422);
      expect(apiError.code, 422);
      expect(apiError.message, errorBody['message']);
      // Screen / confirmer must use the generic constant, not apiError.message.
      expect(
        GooglePlayBillingService.restoreBackendFailedMessage.contains(
          'SQLSTATE',
        ),
        isFalse,
      );
    });
  });
}
