import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lgbtindernew/core/auth/unauthorized_handler.dart';
import 'package:lgbtindernew/core/providers/api_providers.dart';
import 'package:lgbtindernew/features/auth/providers/auth_provider.dart';
import 'package:lgbtindernew/features/auth/providers/auth_service_provider.dart';
import 'package:lgbtindernew/pages/onboarding_page.dart';
import 'package:lgbtindernew/pages/splash_page.dart';
import 'package:lgbtindernew/routes/app_router.dart';
import 'package:lgbtindernew/screens/auth/email_verification_screen.dart';
import 'package:lgbtindernew/screens/auth/login_screen.dart';
import 'package:lgbtindernew/screens/auth/register_screen.dart';
import 'package:lgbtindernew/screens/auth/welcome_screen.dart';
import 'package:lgbtindernew/widgets/buttons/scale_tap_feedback.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/analytics_override.dart';
import '../helpers/app_bootstrap.dart';
import '../helpers/auth_helpers.dart';
import '../helpers/dio_splash_mock.dart';
import '../helpers/mock_services.dart';

/// Splash, register, session, and verification flows (TEST-001 – TEST-022).
void main() {
  setUpAll(() {
    registerAuthFallbacks();
    registerDioFallbacks();
  });

  group('Splash routing', () {
    Future<void> pumpSplash(
      WidgetTester tester, {
      required InMemoryTokenStorage storage,
      bool introSeen = true,
      int? checkTokenStatus,
    }) async {
      SharedPreferences.setMockInitialValues({
        'intro_onboarding_seen': introSeen,
      });

      final mockDio = MockDio();
      final mockClient = MockDioClient();
      if (checkTokenStatus != null) {
        stubCheckToken(mockClient, mockDio, statusCode: checkTokenStatus);
      }

      final router = GoRouter(
        initialLocation: AppRoutes.splash,
        routes: [
          GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashPage()),
          GoRoute(path: AppRoutes.welcome, builder: (_, __) => const WelcomeScreen()),
          GoRoute(path: AppRoutes.onboarding, builder: (_, __) => const OnboardingPage()),
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => const Scaffold(body: Text('Home Shell')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageServiceProvider.overrideWithValue(storage),
            dioClientProvider.overrideWithValue(mockClient),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();
      await e2ePumpFrames(tester, frames: 4);
      // Drain splash guard timer (5s) so tests do not leak pending timers.
      if (checkTokenStatus != null) {
        await tester.pump(const Duration(seconds: 6));
      }
    }

    // TEST-001
    testWidgets('TEST-001: splash without token routes to welcome', (tester) async {
      e2eSetPhoneViewport(tester);
      addTearDown(() => e2eResetViewport(tester));

      final storage = InMemoryTokenStorage()..seedUnauthenticated();
      await pumpSplash(tester, storage: storage);

      expect(find.text('Sign In'), findsWidgets);
    });

    // TEST-002
    testWidgets('TEST-002: first launch routes to intro onboarding', (tester) async {
      e2eSetPhoneViewport(tester);
      addTearDown(() => e2eResetViewport(tester));

      final storage = InMemoryTokenStorage()..seedUnauthenticated();
      await pumpSplash(tester, storage: storage, introSeen: false);

      expect(find.text('Welcome to LGBTFinder'), findsOneWidget);
    });

    // TEST-003
    testWidgets('TEST-003: valid token and check-token routes to home', (tester) async {
      e2eSetPhoneViewport(tester);
      addTearDown(() => e2eResetViewport(tester));

      final storage = InMemoryTokenStorage()..seedAuthenticated();
      await pumpSplash(tester, storage: storage, checkTokenStatus: 200);

      expect(find.text('Home Shell'), findsOneWidget);
    });

    // TEST-004
    testWidgets('TEST-004: invalid check-token clears session and routes to welcome', (tester) async {
      e2eSetPhoneViewport(tester);
      addTearDown(() => e2eResetViewport(tester));

      final storage = InMemoryTokenStorage()..seedAuthenticated();
      await pumpSplash(tester, storage: storage, checkTokenStatus: 401);

      expect(find.text('Sign In'), findsWidgets);
      expect(await storage.isAuthenticated(), isFalse);
    });

    // TEST-021
    testWidgets('TEST-021: session restore with valid token opens home', (tester) async {
      e2eSetPhoneViewport(tester);
      addTearDown(() => e2eResetViewport(tester));

      final storage = InMemoryTokenStorage()..seedAuthenticated(token: 'persisted-token');
      await pumpSplash(tester, storage: storage, checkTokenStatus: 200);

      expect(find.text('Home Shell'), findsOneWidget);
      expect(await storage.getAuthToken(), 'persisted-token');
    });
  });

  group('Welcome navigation', () {
    // TEST-007
    testWidgets('TEST-007: welcome navigates to register and login', (tester) async {
      e2eSetPhoneViewport(tester);
      addTearDown(() => e2eResetViewport(tester));

      final router = GoRouter(
        initialLocation: AppRoutes.welcome,
        routes: [
          GoRoute(path: AppRoutes.welcome, builder: (_, __) => const WelcomeScreen()),
          GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),
          GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
        ],
      );

      final auth = MockAuthService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(auth),
            ...noopAnalyticsOverrides(),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await e2ePumpFrames(tester, frames: 8);

      await tester.tap(find.text('Create Account'));
      await e2ePumpFrames(tester, frames: 4);
      expect(find.byType(RegisterScreen), findsOneWidget);

      router.go(AppRoutes.welcome);
      await e2ePumpFrames(tester, frames: 4);

      await tester.tap(find.text('Sign In').last);
      await e2ePumpFrames(tester, frames: 4);
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('Login profile completion', () {
    // TEST-011
    testWidgets('TEST-011: login routes to profile wizard when required', (tester) async {
      e2eSetPhoneViewport(tester);
      addTearDown(() => e2eResetViewport(tester));

      final auth = MockAuthService();
      stubProfileCompletionLogin(auth);

      final router = GoRouter(
        initialLocation: AppRoutes.login,
        routes: [
          GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
          GoRoute(
            path: AppRoutes.profileWizard,
            builder: (_, __) => const Scaffold(body: Text('Profile Wizard')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(auth),
            ...noopAnalyticsOverrides(),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await e2ePumpFrames(tester, frames: 5);

      await tester.enterText(find.byType(TextField).at(0), 'new@test.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tapAuthSubmitButton(tester);
      await e2ePumpFrames(tester, frames: 8);

      expect(find.text('Profile Wizard'), findsOneWidget);
    });
  });

  group('Register', () {
    // TEST-013
    testWidgets('TEST-013: register navigates to email verification', (tester) async {
      e2eSetPhoneViewport(tester);
      addTearDown(() => e2eResetViewport(tester));
      await tester.binding.setSurfaceSize(const Size(1080, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final auth = MockAuthService();
      stubRegister(auth, email: 'newuser@test.com');

      final router = GoRouter(
        initialLocation: AppRoutes.register,
        routes: [
          GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),
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
      await e2ePumpFrames(tester, frames: 5);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Alex');
      await tester.enterText(fields.at(1), 'User');
      await tester.enterText(fields.at(2), 'newuser@test.com');
      await tester.enterText(fields.at(3), 'Password123!');
      await tester.enterText(fields.at(4), 'Password123!');
      await tester.tap(find.byType(Checkbox));
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -400));
      await e2ePumpFrames(tester, frames: 2);
      await tapAuthSubmitButton(tester);
      await e2ePumpFrames(tester, frames: 8);

      expect(find.byType(EmailVerificationScreen), findsOneWidget);
      expect(find.text('newuser@test.com'), findsWidgets);
      verify(() => auth.register(any())).called(1);
    });

    // TEST-014
    testWidgets('TEST-014: register validation blocks empty submit', (tester) async {
      e2eSetPhoneViewport(tester);
      addTearDown(() => e2eResetViewport(tester));

      final auth = MockAuthService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authServiceProvider.overrideWithValue(auth)],
          child: const MaterialApp(home: RegisterScreen()),
        ),
      );
      await e2ePumpFrames(tester, frames: 5);

      await tester.drag(find.byType(Scrollable).last, const Offset(0, -400));
      await e2ePumpFrames(tester, frames: 2);
      await tapAuthSubmitButton(tester);
      verifyNever(() => auth.register(any()));
    });
  });

  group('Email verification', () {
    // TEST-017
    testWidgets('TEST-017: invalid verification code stays on screen', (tester) async {
      final auth = MockAuthService();
      stubVerifyEmailFailure(auth);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authServiceProvider.overrideWithValue(auth)],
          child: const MaterialApp(
            home: EmailVerificationScreen(email: 'user@test.com', isNewUser: true),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      for (var i = 0; i < 6; i++) {
        await tester.enterText(find.byType(TextField).at(i), '9');
      }
      await tapAuthSubmitButton(tester);
      await e2ePumpFrames(tester, frames: 6);

      expect(find.byType(EmailVerificationScreen), findsOneWidget);
      verify(() => auth.verifyEmail(any())).called(1);
    });

    // TEST-018
    testWidgets('TEST-018: resend disabled during countdown then enabled', (tester) async {
      final auth = MockAuthService();
      stubResendVerification(auth);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authServiceProvider.overrideWithValue(auth)],
          child: const MaterialApp(
            home: EmailVerificationScreen(email: 'user@test.com', isNewUser: true),
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Resend in'), findsOneWidget);

      await tester.pump(const Duration(seconds: 121));

      expect(find.text('Resend Code'), findsOneWidget);
      await tester.tap(find.text('Resend Code'));
      await e2ePumpFrames(tester, frames: 4);

      verify(() => auth.resendVerificationCode('user@test.com')).called(1);
    });

    // TEST-019
    testWidgets('TEST-019: verification back goes to register for new users', (tester) async {
      final router = GoRouter(
        initialLocation: '${AppRoutes.emailVerification}?email=new@test.com&isNewUser=true',
        routes: [
          GoRoute(
            path: AppRoutes.emailVerification,
            builder: (_, state) => EmailVerificationScreen(
              email: state.uri.queryParameters['email'] ?? '',
              isNewUser: true,
            ),
          ),
          GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await e2ePumpFrames(tester, frames: 5);

      await tester.tap(find.byType(ScaleTapFeedback));
      await e2ePumpFrames(tester, frames: 4);

      expect(find.byType(RegisterScreen), findsOneWidget);
    });
  });

  group('Logout and unauthorized', () {
    // TEST-020
    testWidgets('TEST-020: logout clears tokens via auth provider', (tester) async {
      final storage = InMemoryTokenStorage()..seedAuthenticated();
      final auth = MockAuthService();
      stubLogout(auth, storage);

      final container = ProviderContainer(
        overrides: [
          tokenStorageServiceProvider.overrideWithValue(storage),
          authServiceProvider.overrideWithValue(auth),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).logout();

      expect(await storage.isAuthenticated(), isFalse);
      verify(() => auth.logout()).called(1);
    });

    // TEST-022
    test('TEST-022: unauthorized handler invokes registered callback', () {
      var invoked = false;
      UnauthorizedHandler.setCallback(() => invoked = true);
      UnauthorizedHandler.invoke();
      expect(invoked, isTrue);
    });
  });
}
