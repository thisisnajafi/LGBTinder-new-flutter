import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/core/widgets/session_side_effects_host.dart';
import 'package:lgbtindernew/features/auth/data/services/auth_service.dart';
import 'package:lgbtindernew/features/auth/providers/auth_provider.dart';
import 'package:lgbtindernew/routes/app_router.dart';
import 'package:lgbtindernew/shared/services/onboarding_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../e2e/helpers/mock_services.dart';

class _FakeAuthService extends Fake implements AuthService {
  @override
  void clearInMemoryAuthHeader() {}

  @override
  Future<void> logout({String? bearerToken, String? deviceToken}) async {}
}

class _NoOnboarding extends OnboardingService {
  @override
  Future<bool> isOnboardingCompleted() async => true;
}

/// What the router guard answers when something opens the welcome screen.
String? _welcomeRedirectFor(AuthStage stage) {
  return evaluateGuardDecision(
    location: AppRoutes.welcome,
    hasLeftStartupFlow: true,
    authStage: stage,
    isPublicRoute: true,
    isAuthEntryRoute: true,
    isProtectedRoute: false,
    hasPendingProtectedRoute: false,
  ).redirectTo;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetAuthStageCache();
  });

  group('session expiry (401) → welcome', () {
    test('welcome is bounced to home while the session is still stored', () {
      // The reason logout must come first.
      expect(_welcomeRedirectFor(AuthStage.authenticated), AppRoutes.home);
      expect(_welcomeRedirectFor(AuthStage.unauthenticated), isNull);
    });

    test('ends the session before navigating', () async {
      final order = <String>[];
      await endSessionThenOpenWelcome(
        logout: () async {
          await Future<void>.delayed(const Duration(milliseconds: 5));
          order.add('logout');
        },
        openWelcome: () => order.add('welcome'),
      );

      expect(order, ['logout', 'welcome']);
    });

    test('still opens welcome when the local logout throws', () async {
      var opened = false;
      await endSessionThenOpenWelcome(
        logout: () async => throw StateError('storage unavailable'),
        openWelcome: () => opened = true,
      );

      expect(opened, isTrue);
    });

    test('a navigation error is contained', () async {
      await expectLater(
        endSessionThenOpenWelcome(
          logout: () async {},
          openWelcome: () => throw StateError('router gone'),
        ),
        completes,
      );
    });

    test('after logout the guard lets welcome through', () async {
      final storage = InMemoryTokenStorage()
        ..seedCompletedProfile(token: 'expired-token');
      final notifier = AuthProviderNotifier(
        _FakeAuthService(),
        storage,
        _NoOnboarding(),
        () async {},
        () {},
      );
      addTearDown(notifier.dispose);
      await Future<void>.delayed(Duration.zero);

      // Guard already cached "signed in" for this storage revision.
      final before = await resolveAuthStageCached(storage);
      expect(_welcomeRedirectFor(before), AppRoutes.home);

      String? redirectSeenByNavigation;
      await endSessionThenOpenWelcome(
        logout: () => notifier.logout(silent: true),
        openWelcome: () {},
      );
      redirectSeenByNavigation =
          _welcomeRedirectFor(await resolveAuthStageCached(storage));

      expect(redirectSeenByNavigation, isNull);
      expect(notifier.state.isAuthenticated, isFalse);
      await notifier.pendingBackgroundLogout;
    });
  });
}
