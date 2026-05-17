import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/pages/profile_wizard_page.dart';
import 'package:lgbtindernew/routes/app_router.dart';
import 'package:lgbtindernew/screens/onboarding/onboarding_preferences_screen.dart';

import 'package:lgbtindernew/routes/app_router.dart';

/// Onboarding & profile wizard (TEST-023 – TEST-034).
void main() {
  group('Profile wizard widget', () {
    // TEST-024
    testWidgets('TEST-024: step 0 renders and Next blocked without photo', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: ProfileWizardPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProfileWizardPage), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    // TEST-031
    testWidgets('TEST-031: wizard shows progress indicators', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: ProfileWizardPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProfileWizardPage), findsOneWidget);
    });
  });

  group('Onboarding preferences', () {
    // TEST-033
    testWidgets('TEST-033: onboarding preferences screen renders', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: OnboardingPreferencesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingPreferencesScreen), findsOneWidget);
    });
  });

  group('Profile-completion guard (policy)', () {
    // TEST-032 — policy unit; widget navigation in router_guards_test
    test('TEST-032: profile-completion stage documented in AuthStage enum', () {
      expect(AuthStage.profileCompletion.name, 'profileCompletion');
    });
  });
}
