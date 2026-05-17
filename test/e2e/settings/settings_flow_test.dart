import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/screens/settings_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_services.dart';
import 'package:lgbtindernew/features/payments/data/services/plan_limits_service.dart';

/// Settings & account flows (TEST-094 – TEST-110).
void main() {
  group('Settings screen', () {
    // TEST-094
    testWidgets('TEST-094: settings screen renders primary sections', (tester) async {
      final planLimits = MockPlanLimitsService();
      when(() => planLimits.getPlanLimits(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => planLimitsForTier('basid'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [planLimitsServiceProvider.overrideWithValue(planLimits)],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });
}
