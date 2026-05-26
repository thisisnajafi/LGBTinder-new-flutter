import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/routes/app_router.dart';

void main() {
  group('evaluateGuardDecision', () {
    test('redirects splash to welcome after startup already left', () {
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

    test('stores pending and redirects unauthenticated protected route', () {
      final decision = evaluateGuardDecision(
        location: AppRoutes.chat,
        hasLeftStartupFlow: false,
        authStage: AuthStage.unauthenticated,
        isPublicRoute: false,
        isAuthEntryRoute: false,
        isProtectedRoute: true,
        hasPendingProtectedRoute: false,
      );
      expect(decision.redirectTo, AppRoutes.login);
      expect(decision.storePending, isTrue);
    });

    test('consumes pending route when authenticated user visits auth entry', () {
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

    test('redirects authenticated user from auth entry to home', () {
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

    test('redirects profile-completion user from protected app route', () {
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

    test('allows profile-wizard for profile-completion user', () {
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
  });
}
