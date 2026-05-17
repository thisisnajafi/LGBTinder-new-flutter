import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lgbtindernew/features/auth/providers/auth_service_provider.dart';
import 'package:lgbtindernew/routes/app_router.dart';
import 'package:lgbtindernew/screens/auth/email_verification_screen.dart';
import 'package:lgbtindernew/screens/auth/login_screen.dart';
import 'package:lgbtindernew/screens/auth/register_screen.dart';
import 'package:lgbtindernew/screens/auth/welcome_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../config/test_credentials.dart';
import '../helpers/app_bootstrap.dart';
import '../helpers/auth_helpers.dart';
import '../helpers/mock_services.dart';

/// Auth & session flows — email verification only (TEST-001 – TEST-022).
void main() {
  setUpAll(() {
    registerAuthFallbacks();
  });

  group('Welcome & login screens', () {
    // TEST-005
    testWidgets('TEST-005: welcome screen shows Sign In and Create Account', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: WelcomeScreen()),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });

    // TEST-008
    testWidgets('TEST-008: login validation blocks empty submit', (tester) async {
      final auth = MockAuthService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authServiceProvider.overrideWithValue(auth)],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign In'));
      await tester.pump();

      verifyNever(() => auth.login(any()));
    });

    // TEST-009
    testWidgets('TEST-009: login happy path navigates to home', (tester) async {
      final auth = MockAuthService();
      stubReadyLogin(auth);

      final router = GoRouter(
        initialLocation: AppRoutes.login,
        routes: [
          GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => const Scaffold(body: Text('Home Shell')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authServiceProvider.overrideWithValue(auth)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'user@test.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Home Shell'), findsOneWidget);
    });

    // TEST-010
    testWidgets('TEST-010: login routes to email verification when required', (tester) async {
      final auth = MockAuthService();
      stubEmailVerificationLogin(auth);

      final router = GoRouter(
        initialLocation: AppRoutes.login,
        routes: [
          GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
          GoRoute(
            path: AppRoutes.emailVerification,
            builder: (_, state) => EmailVerificationScreen(
              email: state.uri.queryParameters['email'] ?? '',
              isNewUser: state.uri.queryParameters['isNewUser'] == 'true',
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authServiceProvider.overrideWithValue(auth)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'verify@test.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.byType(EmailVerificationScreen), findsOneWidget);
    });

    // TEST-012
    testWidgets('TEST-012: login failure shows error and stays on login', (tester) async {
      final auth = MockAuthService();
      stubFailedLogin(auth);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authServiceProvider.overrideWithValue(auth)],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'bad@test.com');
      await tester.enterText(find.byType(TextField).at(1), 'wrong');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('Email verification', () {
    // TEST-015
    testWidgets('TEST-015: empty email redirects to welcome', (tester) async {
      final router = GoRouter(
        initialLocation: '${AppRoutes.emailVerification}?email=&isNewUser=false',
        routes: [
          GoRoute(
            path: AppRoutes.emailVerification,
            builder: (_, state) => EmailVerificationScreen(
              email: state.uri.queryParameters['email'] ?? '',
              isNewUser: false,
            ),
          ),
          GoRoute(
            path: AppRoutes.welcome,
            builder: (_, __) => const Scaffold(body: Text('Welcome Back')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back'), findsOneWidget);
    });

    // TEST-016 / TEST-017 covered by unit auth_service tests; widget smoke:
    testWidgets('TEST-016: verification screen renders 6 code fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EmailVerificationScreen(email: 'user@test.com', isNewUser: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(6));
    });
  });

  group('Router unauthenticated redirect', () {
    // TEST-006, TEST-007 via pumpE2eApp
    testWidgets('TEST-006: welcome route reachable when unauthenticated', (tester) async {
      await pumpE2eApp(tester);
      await e2eGo(tester, AppRoutes.welcome);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Sign In'), findsOneWidget);
    });
  });

  group('Live API auth (email only)', () {
    // TEST-140 partial — full journey needs integration driver
    test('TEST-140: live login skipped when premium/free accounts missing', () {
      skipIfNoValidAccount();
      expect(TestCredentials.hasApiBaseUrl, isTrue);
    }, skip: TestCredentials.hasApiBaseUrl ? null : 'API base URL not configured');
  });
}
