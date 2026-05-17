import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/payments/presentation/screens/google_play_billing_test_screen.dart';
import 'package:lgbtindernew/features/payments/presentation/screens/subscription_plans_screen.dart';
import 'package:lgbtindernew/screens/subscription_status_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../config/test_credentials.dart';
import '../helpers/auth_helpers.dart';
import '../helpers/mock_services.dart';
import 'package:lgbtindernew/features/payments/data/services/payment_service.dart';
import 'package:lgbtindernew/features/payments/providers/payment_providers.dart';
import 'package:lgbtindernew/features/payments/data/services/plan_limits_service.dart';

class MockPaymentService extends Mock implements PaymentService {}

/// Google Play billing & subscriptions (TEST-111 – TEST-121).
void main() {
  group('Subscription UI', () {
    // TEST-111
    testWidgets('TEST-111: subscription plans screen builds', (tester) async {
      final payment = MockPaymentService();
      when(() => payment.getPlans()).thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [paymentServiceProvider.overrideWithValue(payment)],
          child: const MaterialApp(home: SubscriptionPlansScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SubscriptionPlansScreen), findsOneWidget);
    });

    // TEST-107
    testWidgets('TEST-107: subscription status screen builds', (tester) async {
      final planLimits = MockPlanLimitsService();
      when(() => planLimits.getPlanLimits(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => planLimitsForTier('basid'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [planLimitsServiceProvider.overrideWithValue(planLimits)],
          child: const MaterialApp(home: SubscriptionStatusScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SubscriptionStatusScreen), findsOneWidget);
    });

    // TEST-113
    testWidgets('TEST-113: Google Play billing test screen builds', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: GooglePlayBillingTestScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Google Play Billing Test'), findsOneWidget);
    });
  });

  group('Credentials guard', () {
    // TEST-121
    test('TEST-121: skips live billing when apiBaseUrl placeholder', () {
      if (!TestCredentials.hasApiBaseUrl) {
        markTestSkipped('API credentials not configured');
      }
      expect(TestCredentials.hasApiBaseUrl, isTrue);
    }, skip: TestCredentials.hasApiBaseUrl ? null : 'apiBaseUrl not configured');
  });
}
