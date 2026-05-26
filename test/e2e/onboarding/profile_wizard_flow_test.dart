import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lgbtindernew/pages/onboarding_page.dart';
import 'package:lgbtindernew/pages/profile_wizard_page.dart';
import 'package:lgbtindernew/routes/app_router.dart';
import 'package:lgbtindernew/screens/auth/welcome_screen.dart';
import 'package:lgbtindernew/screens/onboarding/onboarding_preferences_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lgbtindernew/features/auth/data/models/complete_registration_request.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/app_bootstrap.dart';
import '../helpers/mock_services.dart';
import '../helpers/wizard_test_helpers.dart';

/// Onboarding & profile wizard (TEST-023 – TEST-034).
void main() {
  setUpAll(() {
    registerFallbackValue(File(''));
    registerFallbackValue(0);
    registerFallbackValue(
      CompleteRegistrationRequest(
        deviceName: 'e2e',
        phoneNumber: '+10000000000',
        countryId: 1,
        cityId: 10,
        gender: 2,
        birthDate: '1990-01-01',
        minAgePreference: 18,
        maxAgePreference: 99,
        profileBio: 'bio',
        height: 170,
        weight: 70,
        smoke: false,
        drink: false,
        gym: false,
        musicGenres: const [8],
        educations: const [4],
        jobs: const [3],
        languages: const [5],
        interests: const [6],
        preferredGenders: const [2],
        relationGoals: const [9],
      ),
    );
  });

  group('Intro onboarding', () {
    // TEST-023
    testWidgets('TEST-023: completing intro marks seen for next launch', (tester) async {
      SharedPreferences.setMockInitialValues({'intro_onboarding_seen': false});

      final router = GoRouter(
        initialLocation: AppRoutes.onboarding,
        routes: [
          GoRoute(path: AppRoutes.onboarding, builder: (_, __) => const OnboardingPage()),
          GoRoute(
            path: AppRoutes.welcome,
            builder: (_, __) => const Scaffold(body: Text('Welcome Landed')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await e2ePumpFrames(tester, frames: 3);

      await tester.tap(find.text('Skip'));
      await e2ePumpFrames(tester, frames: 4);

      expect(find.text('Welcome Landed'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('intro_onboarding_seen'), isTrue);
    });
  });

  group('Profile wizard steps', () {
    // TEST-024
    testWidgets('TEST-024: step 0 blocks Next without profile photo', (tester) async {
      await pumpProfileWizard(tester);

      expect(find.text('Profile Photo'), findsOneWidget);
      await tapWizardNext(tester);

      expect(find.text('Please upload a profile photo'), findsOneWidget);
      expect(find.text('Basic Information & Contact'), findsNothing);
    });

    // TEST-025
    testWidgets('TEST-025: step 1 blocks Next without required contact fields', (tester) async {
      await pumpProfileWizard(tester);
      await seedWizardPhoto(tester);
      await jumpToWizardStep(tester, 1);
      seedWizardStep1Phone(tester);

      expect(find.text('Basic Information & Contact'), findsOneWidget);
      await tapWizardNext(tester);

      expect(find.text('Please select your country'), findsOneWidget);
    });

    // TEST-026
    testWidgets('TEST-026: step 2 blocks Next without bio and selections', (tester) async {
      await pumpProfileWizard(tester);
      await seedWizardPhoto(tester);
      await jumpToWizardStep(tester, 2);

      expect(find.text('About You'), findsOneWidget);
      await tapWizardNext(tester);

      expect(find.text('Please enter your bio'), findsOneWidget);
    });

    // TEST-027
    testWidgets('TEST-027: step 3 blocks Next without preferences', (tester) async {
      await pumpProfileWizard(tester);
      await seedWizardPhoto(tester);
      await jumpToWizardStep(tester, 3);

      expect(find.text('Preferences & Lifestyle'), findsOneWidget);
      await tapWizardNext(tester);

      expect(find.text('Please select at least one preferred gender'), findsOneWidget);
    });

    // TEST-028
    testWidgets('TEST-028: step 4 blocks Next without interests and music', (tester) async {
      await pumpProfileWizard(tester);
      await seedWizardPhoto(tester);
      await jumpToWizardStep(tester, 4);

      expect(find.text('Interests & Music'), findsOneWidget);
      await tapWizardNext(tester);

      expect(find.text('Please select at least one interest'), findsOneWidget);
    });

    // TEST-029
    testWidgets('TEST-029: step 5 additional photos allows forward and back', (tester) async {
      await pumpProfileWizard(tester);
      await seedWizardPhoto(tester);
      await jumpToWizardStep(tester, 5);

      expect(find.text('Additional Photos'), findsOneWidget);
      await tapWizardNext(tester);
      await e2ePumpFrames(tester, frames: 6);

      expect(find.textContaining('All Set'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);

      await tapWizardBack(tester);
      await e2ePumpFrames(tester, frames: 6);

      expect(wizardCurrentStep(tester), 5);
      expect(find.text('Additional Photos'), findsOneWidget);
    });

    // TEST-031
    testWidgets('TEST-031: back preserves entered name on step 1', (tester) async {
      await pumpProfileWizard(tester, initialFirstName: 'Jordan');
      await seedWizardPhoto(tester);
      await jumpToWizardStep(tester, 1);

      expect(find.text('Jordan'), findsOneWidget);
      await jumpToWizardStep(tester, 2);
      await tapWizardBack(tester);
      await e2ePumpFrames(tester, frames: 4);

      expect(find.text('Jordan'), findsOneWidget);
    });
  });

  group('Wizard completion', () {
    // TEST-030
    testWidgets('TEST-030: complete wizard navigates to home', (tester) async {
      final auth = MockAuthService();
      final overrides = wizardServiceOverrides(auth: auth);

      final router = GoRouter(
        initialLocation: AppRoutes.profileWizard,
        routes: [
          GoRoute(
            path: AppRoutes.profileWizard,
            builder: (_, __) => const ProfileWizardPage(),
          ),
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => const Scaffold(body: Text('Home After Wizard')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await e2ePumpFrames(tester, frames: 8);

      final photo = wizardPhotoFile();
      seedCompleteWizardState(tester, photo);
      await tester.pump();

      await tapWizardComplete(tester);

      expect(find.text('Home After Wizard'), findsOneWidget);
      verify(() => auth.completeRegistration(any())).called(1);
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
      await e2ePumpFrames(tester, frames: 3);

      expect(find.byType(OnboardingPreferencesScreen), findsOneWidget);
    });
  });

  group('Profile-completion guard (policy)', () {
    // TEST-032
    test('TEST-032: profile-completion stage documented in AuthStage enum', () {
      expect(AuthStage.profileCompletion.name, 'profileCompletion');
    });

    // TEST-034
    test('TEST-034: authenticated user can access home discovery route', () {
      final decision = evaluateGuardDecision(
        location: '${AppRoutes.home}/discovery',
        hasLeftStartupFlow: true,
        authStage: AuthStage.authenticated,
        isPublicRoute: false,
        isAuthEntryRoute: false,
        isProtectedRoute: true,
        hasPendingProtectedRoute: false,
      );
      expect(decision.redirectTo, isNull);
    });
  });
}
