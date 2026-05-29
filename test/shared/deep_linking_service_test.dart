import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/routes/app_router.dart';
import 'package:lgbtindernew/shared/services/deep_linking_service.dart';

void main() {
  group('resolveUrlSchemeRoute', () {
    test('returns null for unsupported scheme', () {
      final route = resolveUrlSchemeRoute(Uri.parse('https://example.com/match/1'));
      expect(route, isNull);
    });

    test('maps match route with user id to chat thread', () {
      expect(
        resolveUrlSchemeRoute(Uri.parse('lgbtfinder://match/123')),
        Uri(path: AppRoutes.chat, queryParameters: {'userId': '123'}).toString(),
      );
    });

    test('maps match route without user id to matches list', () {
      expect(
        resolveUrlSchemeRoute(Uri.parse('lgbtfinder://match')),
        '${AppRoutes.home}/matches',
      );
    });

    test('maps superlike route with user id to chat', () {
      expect(
        resolveUrlSchemeRoute(Uri.parse('lgbtfinder://superlike/42')),
        Uri(path: AppRoutes.chat, queryParameters: {'userId': '42'}).toString(),
      );
    });

    test('maps chat route with user id', () {
      expect(
        resolveUrlSchemeRoute(Uri.parse('lgbtfinder://chat/42')),
        Uri(path: AppRoutes.chat, queryParameters: {'userId': '42'}).toString(),
      );
    });

    test('maps chat route without user id', () {
      expect(
        resolveUrlSchemeRoute(Uri.parse('lgbtfinder://chat')),
        '${AppRoutes.home}/chat-list',
      );
    });

    test('maps profile route with user id', () {
      expect(
        resolveUrlSchemeRoute(Uri.parse('lgbtfinder://profile/9')),
        Uri(path: AppRoutes.profileDetail, queryParameters: {'userId': '9'}).toString(),
      );
    });

    test('maps discover and notifications routes', () {
      expect(
        resolveUrlSchemeRoute(Uri.parse('lgbtfinder://discover')),
        '${AppRoutes.home}/discovery',
      );
      expect(
        resolveUrlSchemeRoute(Uri.parse('lgbtfinder://notifications')),
        '${AppRoutes.home}/notifications',
      );
    });
  });
}
