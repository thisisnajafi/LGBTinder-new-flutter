import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/safety/presentation/screens/report_user_screen.dart';
import 'package:lgbtindernew/screens/blocked_users_screen.dart';
import 'package:lgbtindernew/screens/emergency_contacts_screen.dart';
import 'package:lgbtindernew/screens/safety_settings_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../config/test_credentials.dart';
import '../helpers/app_bootstrap.dart';
import '../helpers/auth_helpers.dart';
import 'package:lgbtindernew/features/safety/data/services/user_actions_service.dart';
import 'package:lgbtindernew/features/safety/providers/user_actions_providers.dart';

class MockUserActionsService extends Mock implements UserActionsService {}

/// Safety: block, report, emergency contacts (TEST-084 – TEST-093).
void main() {
  group('Safety screens', () {
    // TEST-084
    testWidgets('TEST-084: safety settings screen renders', (tester) async {
      e2eSetPhoneViewport(tester);
      addTearDown(() => e2eResetViewport(tester));

      await tester.pumpWidget(
        const MaterialApp(home: SafetySettingsScreen()),
      );
      await e2ePumpFrames(tester, frames: 3);

      expect(find.text('Safety Settings'), findsOneWidget);
      expect(find.byType(SafetySettingsScreen), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Emergency Contacts'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Blocked Users'), findsOneWidget);
      expect(find.text('Emergency Contacts'), findsOneWidget);
    });

    // TEST-085
    testWidgets('TEST-085: report user screen renders submit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReportUserScreen(userId: 99),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ReportUserScreen), findsOneWidget);
    });

    // TEST-088
    testWidgets('TEST-088: blocked users screen renders', (tester) async {
      final actions = MockUserActionsService();
      when(() => actions.getBlockedUsers()).thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userActionsServiceProvider.overrideWithValue(actions),
          ],
          child: const MaterialApp(home: BlockedUsersScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BlockedUsersScreen), findsOneWidget);
    });

    // TEST-091
    testWidgets('TEST-091: emergency contacts screen renders', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: EmergencyContactsScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(EmergencyContactsScreen), findsOneWidget);
    });
  });

  group('Live safety API', () {
    test('TEST-092: add emergency contact skipped without API', () {
      skipIfNoApiCredentials();
      if (TestCredentials.isPlaceholder(TestCredentials.targetUserId)) {
        markTestSkipped('targetUserId not configured');
      }
    }, skip: TestCredentials.hasApiBaseUrl ? null : 'API not configured');
  });
}
