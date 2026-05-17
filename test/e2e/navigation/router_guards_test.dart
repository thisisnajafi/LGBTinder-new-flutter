import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/routes/app_router.dart';
import 'package:lgbtindernew/routes/route_redirector.dart';

/// Navigation guards and deep-link normalization (TEST-122 – TEST-140).
void main() {
  group('evaluateGuardDecision — protected routes', () {
    // TEST-122
    test('TEST-122: unauthenticated /home redirects to welcome with pending', () {
      final decision = evaluateGuardDecision(
        location: AppRoutes.home,
        hasLeftStartupFlow: false,
        authStage: AuthStage.unauthenticated,
        isPublicRoute: false,
        isAuthEntryRoute: false,
        isProtectedRoute: true,
        hasPendingProtectedRoute: false,
      );
      expect(decision.redirectTo, AppRoutes.welcome);
      expect(decision.storePending, isTrue);
    });

    // TEST-123
    test('TEST-123: unauthenticated /chat redirects to welcome with pending', () {
      final decision = evaluateGuardDecision(
        location: AppRoutes.chat,
        hasLeftStartupFlow: false,
        authStage: AuthStage.unauthenticated,
        isPublicRoute: false,
        isAuthEntryRoute: false,
        isProtectedRoute: true,
        hasPendingProtectedRoute: false,
      );
      expect(decision.redirectTo, AppRoutes.welcome);
      expect(decision.storePending, isTrue);
    });

    // TEST-124
    test('TEST-124: unauthenticated /subscription-plans redirects to welcome', () {
      final decision = evaluateGuardDecision(
        location: AppRoutes.subscriptionPlans,
        hasLeftStartupFlow: false,
        authStage: AuthStage.unauthenticated,
        isPublicRoute: false,
        isAuthEntryRoute: false,
        isProtectedRoute: true,
        hasPendingProtectedRoute: false,
      );
      expect(decision.redirectTo, AppRoutes.welcome);
    });

    // TEST-125
    test('TEST-125: unauthenticated /feature-locked redirects to welcome', () {
      final decision = evaluateGuardDecision(
        location: AppRoutes.featureLocked,
        hasLeftStartupFlow: false,
        authStage: AuthStage.unauthenticated,
        isPublicRoute: false,
        isAuthEntryRoute: false,
        isProtectedRoute: true,
        hasPendingProtectedRoute: false,
      );
      expect(decision.redirectTo, AppRoutes.welcome);
    });

    // TEST-126
    test('TEST-126: authenticated auth entry consumes pending route', () {
      final decision = evaluateGuardDecision(
        location: AppRoutes.login,
        hasLeftStartupFlow: false,
        authStage: AuthStage.authenticated,
        isPublicRoute: true,
        isAuthEntryRoute: true,
        isProtectedRoute: false,
        hasPendingProtectedRoute: true,
      );
      expect(decision.consumePending, isTrue);
      expect(decision.redirectTo, isNull);
    });

    // TEST-127
    test('TEST-127: authenticated user at welcome redirects to home', () {
      final decision = evaluateGuardDecision(
        location: AppRoutes.welcome,
        hasLeftStartupFlow: false,
        authStage: AuthStage.authenticated,
        isPublicRoute: true,
        isAuthEntryRoute: true,
        isProtectedRoute: false,
        hasPendingProtectedRoute: false,
      );
      expect(decision.redirectTo, AppRoutes.home);
    });

    // TEST-128
    test('TEST-128: profile-completion user blocked from discovery', () {
      final decision = evaluateGuardDecision(
        location: '${AppRoutes.home}/discovery',
        hasLeftStartupFlow: false,
        authStage: AuthStage.profileCompletion,
        isPublicRoute: false,
        isAuthEntryRoute: false,
        isProtectedRoute: true,
        hasPendingProtectedRoute: false,
      );
      expect(decision.redirectTo, AppRoutes.profileWizard);
    });

    // TEST-129
    test('TEST-129: profile-completion user allowed on wizard', () {
      final decision = evaluateGuardDecision(
        location: AppRoutes.profileWizard,
        hasLeftStartupFlow: false,
        authStage: AuthStage.profileCompletion,
        isPublicRoute: false,
        isAuthEntryRoute: false,
        isProtectedRoute: true,
        hasPendingProtectedRoute: false,
      );
      expect(decision.redirectTo, isNull);
    });

    // TEST-130
    test('TEST-130: splash re-entry after startup redirects to welcome', () {
      final decision = evaluateGuardDecision(
        location: AppRoutes.splash,
        hasLeftStartupFlow: true,
        authStage: AuthStage.unauthenticated,
        isPublicRoute: true,
        isAuthEntryRoute: false,
        isProtectedRoute: false,
        hasPendingProtectedRoute: false,
      );
      expect(decision.redirectTo, AppRoutes.welcome);
    });
  });

  group('RouteRedirector — legacy deep links', () {
    final redirector = RouteRedirector();

    // TEST-131
    test('TEST-131: /help → /help-support', () {
      expect(redirector.resolveLegacyRoute(Uri.parse('/help')), AppRoutes.helpSupport);
    });

    // TEST-132
    test('TEST-132: /discover → /home/discovery', () {
      expect(
        redirector.resolveLegacyRoute(Uri.parse('/discover')),
        '${AppRoutes.home}/discovery',
      );
    });

    // TEST-133
    test('TEST-133: /profile/:id → profile-detail query', () {
      expect(
        redirector.resolveLegacyRoute(Uri.parse('/profile/123')),
        Uri(path: AppRoutes.profileDetail, queryParameters: {'userId': '123'}).toString(),
      );
    });

    // TEST-134
    test('TEST-134: /chat/:id → chat query', () {
      expect(
        redirector.resolveLegacyRoute(Uri.parse('/chat/55')),
        Uri(path: AppRoutes.chat, queryParameters: {'userId': '55'}).toString(),
      );
    });

    // TEST-135
    test('TEST-135: /likes and /matches → matches list', () {
      expect(
        redirector.resolveLegacyRoute(Uri.parse('/likes')),
        '${AppRoutes.home}/matches',
      );
      expect(
        redirector.resolveLegacyRoute(Uri.parse('/matches')),
        '${AppRoutes.home}/matches',
      );
    });

    // TEST-136
    test('TEST-136: /plans → subscription-plans', () {
      expect(
        redirector.resolveLegacyRoute(Uri.parse('/plans')),
        AppRoutes.subscriptionPlans,
      );
    });

    // TEST-137 – widget-level 404 covered in auth_flow_test
    // TEST-138 – back behaviour covered in auth_flow_test
    // TEST-139 – profile detail fallback covered in discovery tests
    // TEST-140 – live deep link journey skipped without API (see auth_flow_test)
  });
}
