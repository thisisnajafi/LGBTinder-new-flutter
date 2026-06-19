import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/routes/app_router.dart';
import 'package:lgbtindernew/routes/route_redirector.dart';

void main() {
  group('RouteRedirector.resolveLegacyRoute', () {
    test('maps simple legacy paths', () {
      final r = RouteRedirector();
      expect(r.resolveLegacyRoute(Uri.parse('/help')), AppRoutes.helpSupport);
      expect(r.resolveLegacyRoute(Uri.parse('/discover')), '${AppRoutes.home}/discovery');
      expect(r.resolveLegacyRoute(Uri.parse('/likes')), '${AppRoutes.home}/matches');
      expect(r.resolveLegacyRoute(Uri.parse('/chats')), AppRoutes.chat);
      expect(r.resolveLegacyRoute(Uri.parse('/plans')), AppRoutes.subscriptionPlans);
      expect(r.resolveLegacyRoute(Uri.parse('/subscription')), AppRoutes.subscriptionPlans);
    });

    test('maps profile and chat id paths into query-based routes', () {
      final r = RouteRedirector();
      expect(
        r.resolveLegacyRoute(Uri.parse('/profile/123')),
        Uri(path: AppRoutes.profileDetail, queryParameters: {'userId': '123'}).toString(),
      );
      expect(
        r.resolveLegacyRoute(Uri.parse('/chat/55')),
        Uri(path: AppRoutes.chat, queryParameters: {'userId': '55'}).toString(),
      );
    });

    test('maps matches/:id to matches list (current router)', () {
      final r = RouteRedirector();
      expect(r.resolveLegacyRoute(Uri.parse('/matches/999')), '${AppRoutes.home}/matches');
      expect(r.resolveLegacyRoute(Uri.parse('/matches')), '${AppRoutes.home}/matches');
    });

    test('returns null for non-legacy paths', () {
      final r = RouteRedirector();
      expect(r.resolveLegacyRoute(Uri.parse('/home/discovery')), isNull);
      expect(r.resolveLegacyRoute(Uri.parse('/profile-detail?userId=1')), isNull);
      expect(r.resolveLegacyRoute(Uri.parse('/profile/edit')), isNull);
      expect(r.resolveLegacyRoute(Uri.parse(AppRoutes.profileEdit)), isNull);
    });

    test('does not treat reserved profile slugs as user ids', () {
      final r = RouteRedirector();
      expect(r.resolveLegacyRoute(Uri.parse('/profile/edit')), isNull);
      expect(r.resolveLegacyRoute(Uri.parse('/profile/verification')), isNull);
    });
  });

  group('RouteRedirector pending protected route', () {
    test('stores only first pending and consumes once', () {
      final r = RouteRedirector();
      expect(r.pendingProtectedRoute, isNull);

      r.setPendingIfEmpty('/chat?userId=1');
      r.setPendingIfEmpty('/chat?userId=2');
      expect(r.pendingProtectedRoute, '/chat?userId=1');

      expect(r.consumePending(), '/chat?userId=1');
      expect(r.pendingProtectedRoute, isNull);
      expect(r.consumePending(), isNull);
    });
  });
}

