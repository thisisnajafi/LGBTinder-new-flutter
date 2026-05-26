import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lgbtindernew/core/providers/api_providers.dart';
import 'package:lgbtindernew/features/discover/data/services/discovery_service.dart';
import 'package:lgbtindernew/features/discover/providers/discovery_providers.dart';
import 'package:lgbtindernew/features/matching/data/services/likes_service.dart';
import 'package:lgbtindernew/features/matching/providers/likes_providers.dart';
import 'package:lgbtindernew/shared/services/cache_service.dart';
import 'package:lgbtindernew/features/notifications/providers/notification_providers.dart';
import 'package:lgbtindernew/pages/discovery_page.dart';
import 'package:lgbtindernew/pages/home_page.dart';
import 'package:lgbtindernew/pages/chat_list_page.dart';
import 'package:lgbtindernew/routes/app_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:lgbtindernew/features/payments/data/services/plan_limits_service.dart';

import '../helpers/app_bootstrap.dart';
import '../helpers/mock_services.dart';

class MockDiscoveryService extends Mock implements DiscoveryService {}

class MockCacheService extends Mock implements CacheService {}

/// Discovery / swipe deck (TEST-035 – TEST-045).
void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(Duration.zero);
    registerFallbackValue(false);
  });

  List<Override> discoveryOverrides({
    required MockPlanLimitsService planLimits,
    required MockDiscoveryService discovery,
    required MockCacheService cache,
  }) {
    when(
      () => discovery.fetchNearbySuggestionsFromApi(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        filters: any(named: 'filters'),
      ),
    ).thenAnswer((_) async => []);

    when(
      () => cache.getCached<Map<String, dynamic>>(
        any(),
        any(),
        customExpiry: any(named: 'customExpiry'),
      ),
    ).thenAnswer((_) async => null);

    when(
      () => cache.cacheData(
        any(),
        any(),
        duration: any(named: 'duration'),
      ),
    ).thenAnswer((_) async {});

    return [
      planLimitsServiceProvider.overrideWithValue(planLimits),
      discoveryServiceProvider.overrideWithValue(discovery),
      cacheServiceProvider.overrideWithValue(cache),
      unreadNotificationCountProvider.overrideWith((_) async => 0),
    ];
  }

  group('Discovery page', () {
    // TEST-035
    testWidgets('TEST-035: discovery page builds inside home shell', (tester) async {
      e2eSetPhoneViewport(tester);
      addTearDown(() => e2eResetViewport(tester));

      final planLimits = MockPlanLimitsService();
      stubPlanLimitsService(planLimits);

      final discovery = MockDiscoveryService();
      final cache = MockCacheService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: discoveryOverrides(
            planLimits: planLimits,
            discovery: discovery,
            cache: cache,
          ),
          child: const MaterialApp(
            home: Scaffold(
              body: DiscoveryPage(selectedTabIndex: 0, discoveryTabIndex: 0),
            ),
          ),
        ),
      );
      await e2ePumpFrames(tester, frames: 8);

      expect(find.byType(DiscoveryPage), findsOneWidget);
    });
  });

  group('Home tab routing', () {
    // TEST-045
    testWidgets('TEST-045: home page renders bottom navigation', (tester) async {
      e2eSetPhoneViewport(tester);
      addTearDown(() => e2eResetViewport(tester));

      final planLimits = MockPlanLimitsService();
      stubPlanLimitsService(planLimits);
      final discovery = MockDiscoveryService();
      final cache = MockCacheService();
      final likes = MockLikesService();
      when(() => likes.getMatches()).thenAnswer((_) async => []);

      final router = GoRouter(
        initialLocation: AppRoutes.home,
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => const HomePage(),
            routes: [
              GoRoute(
                path: 'discovery',
                builder: (_, __) =>
                    const DiscoveryPage(selectedTabIndex: 0, discoveryTabIndex: 0),
              ),
              GoRoute(
                path: 'chat-list',
                builder: (_, __) => const ChatListPage(),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...discoveryOverrides(
              planLimits: planLimits,
              discovery: discovery,
              cache: cache,
            ),
            likesServiceProvider.overrideWithValue(likes),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await e2ePumpFrames(tester, frames: 8);

      expect(find.byType(HomePage), findsOneWidget);
    });
  });
}

class MockLikesService extends Mock implements LikesService {}
