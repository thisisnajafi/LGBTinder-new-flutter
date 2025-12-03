/// Unit tests for PaymentService
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:lgbtindernew/features/payments/data/services/payment_service.dart';
import 'package:lgbtindernew/shared/services/api_service.dart';
import 'package:lgbtindernew/features/payments/data/models/subscription_plan.dart';
import 'package:lgbtindernew/features/payments/data/models/subscribe_request.dart';
import 'package:lgbtindernew/shared/models/api_response.dart';

import 'payment_service_test.mocks.dart';

@GenerateMocks([ApiService])
void main() {
  late PaymentService paymentService;
  late MockApiService mockApiService;

  setUp(() {
    mockApiService = MockApiService();
    paymentService = PaymentService(mockApiService);
  });

  group('PaymentService', () {
    group('getPlans', () {
      test('should return list of subscription plans on successful call', () async {
        // Arrange
        final responseData = {
          'data': [
            {
              'id': 1,
              'name': 'Premium Monthly',
              'price': 9.99,
              'currency': 'USD',
              'duration': 30,
              'features': ['feature1', 'feature2'],
            },
            {
              'id': 2,
              'name': 'Premium Yearly',
              'price': 79.99,
              'currency': 'USD',
              'duration': 365,
              'features': ['feature1', 'feature2', 'feature3'],
            },
          ],
        };

        when(mockApiService.get<dynamic>(any)).thenAnswer((_) async =>
            ApiResponse<dynamic>(
              isSuccess: true,
              data: responseData,
              message: 'Plans retrieved',
            ));

        // Act
        final result = await paymentService.getPlans();

        // Assert
        expect(result, isNotNull);
        expect(result.length, equals(2));
        expect(result[0].id, equals(1));
        expect(result[0].name, equals('Premium Monthly'));
        expect(result[1].id, equals(2));
        expect(result[1].name, equals('Premium Yearly'));
      });

      test('should return empty list when no plans', () async {
        // Arrange
        when(mockApiService.get<dynamic>(any)).thenAnswer((_) async =>
            ApiResponse<dynamic>(
              isSuccess: true,
              data: {'data': []},
              message: 'No plans',
            ));

        // Act
        final result = await paymentService.getPlans();

        // Assert
        expect(result, isNotNull);
        expect(result.isEmpty, isTrue);
      });
    });

    group('getSubPlans', () {
      test('should return list of sub plans on successful call', () async {
        // Arrange
        final responseData = {
          'data': [
            {
              'id': 1,
              'name': 'Basic',
              'price': 4.99,
            },
            {
              'id': 2,
              'name': 'Premium',
              'price': 9.99,
            },
          ],
        };

        when(mockApiService.get<dynamic>(any)).thenAnswer((_) async =>
            ApiResponse<dynamic>(
              isSuccess: true,
              data: responseData,
              message: 'Sub plans retrieved',
            ));

        // Act
        final result = await paymentService.getSubPlans();

        // Assert
        expect(result, isNotNull);
        expect(result.length, equals(2));
        expect(result[0].id, equals(1));
        expect(result[1].id, equals(2));
      });
    });

    group('subscribeToPlan', () {
      test('should return SubscriptionStatus on successful subscription', () async {
        // Arrange
        final request = SubscribeRequest(
          planId: 1,
          paymentMethod: 'stripe',
        );

        final responseData = {
          'is_active': true,
          'plan_id': 1,
          'plan_name': 'Premium Monthly',
          'expires_at': '2024-02-01T00:00:00Z',
          'auto_renew': true,
        };

        when(mockApiService.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: true,
          data: responseData,
          message: 'Subscribed',
        ));

        // Act
        final result = await paymentService.subscribeToPlan(request);

        // Assert
        expect(result, isNotNull);
        expect(result.isActive, equals(true));
        expect(result.planId, equals(1));
        verify(mockApiService.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).called(1);
      });

      test('should throw exception on failed subscription', () async {
        // Arrange
        final request = SubscribeRequest(
          planId: 1,
          paymentMethod: 'stripe',
        );

        when(mockApiService.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: false,
          data: null,
          message: 'Subscription failed',
        ));

        // Act & Assert
        expect(
          () => paymentService.subscribeToPlan(request),
          throwsException,
        );
      });
    });

    group('getSubscriptionStatus', () {
      test('should return SubscriptionStatus on successful call', () async {
        // Arrange
        final responseData = {
          'is_active': true,
          'plan_id': 1,
          'plan_name': 'Premium Monthly',
          'expires_at': '2024-02-01T00:00:00Z',
          'auto_renew': true,
        };

        when(mockApiService.get<Map<String, dynamic>>(
          any,
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: true,
          data: responseData,
          message: 'Status retrieved',
        ));

        // Act
        final result = await paymentService.getSubscriptionStatus();

        // Assert
        expect(result, isNotNull);
        expect(result.isActive, equals(true));
        expect(result.planId, equals(1));
      });

      test('should throw exception on failed call', () async {
        // Arrange
        when(mockApiService.get<Map<String, dynamic>>(
          any,
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: false,
          data: null,
          message: 'Failed',
        ));

        // Act & Assert
        expect(
          () => paymentService.getSubscriptionStatus(),
          throwsException,
        );
      });
    });
  });
}

