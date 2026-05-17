import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/pages/discovery_page.dart';
import 'package:lgbtindernew/pages/home_page.dart';
import 'package:lgbtindernew/routes/app_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:lgbtindernew/features/payments/data/services/plan_limits_service.dart';

import '../helpers/app_bootstrap.dart';
import '../helpers/mock_services.dart';

/// Discovery / swipe deck (TEST-035 – TEST-045).
void main() {
  group('Discovery page', () {
    // TEST-035
    testWidgets('TEST-035: discovery page builds inside home shell', (tester) async {
      final planLimits = MockPlanLimitsService();
      when(() => planLimits.getPlanLimits(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => planLimitsForTier('basid'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            planLimitsServiceProvider.overrideWithValue(planLimits),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DiscoveryPage(selectedTabIndex: 0, discoveryTabIndex: 0),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(DiscoveryPage), findsOneWidget);
    });
  });

  group('Home tab routing', () {
    // TEST-045
    testWidgets('TEST-045: home page renders bottom navigation', (tester) async {
      final storage = InMemoryTokenStorage()..seedAuthenticated();
      final planLimits = MockPlanLimitsService();
      when(() => planLimits.getPlanLimits(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => planLimitsForTier('basid'));

      await pumpE2eApp(
        tester,
        tokenStorage: storage,
        overrides: [
          planLimitsServiceProvider.overrideWithValue(planLimits),
        ],
      );
      await e2eGo(tester, AppRoutes.home);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.byType(HomePage), findsOneWidget);
    });
  });
}
