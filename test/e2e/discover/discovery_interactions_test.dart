import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/matching/data/models/like.dart';
import 'package:lgbtindernew/features/profile/data/models/user_profile.dart';
import 'package:lgbtindernew/features/profile/providers/profile_providers.dart';
import 'package:lgbtindernew/screens/discovery/filter_screen.dart';
import 'package:lgbtindernew/screens/discovery/profile_detail_screen.dart';
import 'package:lgbtindernew/shared/utils/plan_guard.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/app_bootstrap.dart';
import '../helpers/mock_services.dart';
import 'discovery_test_helpers.dart';

/// Discovery interactions (TEST-036 – TEST-044).
void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(Duration.zero);
    registerFallbackValue(false);

    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (message.contains('overflowed') ||
          message.contains('RenderFlex') ||
          message.contains('TextEditingController was used after being disposed') ||
          message.contains('_dependents.isEmpty')) {
        return;
      }
      previousOnError?.call(details);
    };
  });

  group('Plan limits', () {
    // TEST-044
    testWidgets('TEST-044: swipe limit shows upgrade dialog and blocks like', (tester) async {
      final likes = MockLikesService();
      final planLimits = MockPlanLimitsService();
      stubPlanLimitsService(planLimits, tier: 'basid');
      when(() => planLimits.hasReachedSwipeLimit()).thenAnswer((_) async => true);
      when(() => planLimits.hasReachedSuperlikeLimit()).thenAnswer((_) async => false);
      when(() => planLimits.incrementUsage(any())).thenReturn(null);

      await pumpDiscoveryPage(
        tester,
        discovery: MockDiscoveryService(),
        planLimits: planLimits,
        likes: likes,
        profiles: [sampleDiscoveryProfile()],
      );

      await tapDiscoveryLike(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Daily Swipe Limit Reached'), findsOneWidget);
      expect(find.text('Alex'), findsOneWidget);
      verifyNever(() => likes.likeUser(any()));
    });
  });

  group('Swipe actions', () {
    // TEST-036
    testWidgets('TEST-036: like removes card and calls likes service', (tester) async {
      final discovery = MockDiscoveryService();
      final likes = MockLikesService();
      final planLimits = MockPlanLimitsService();
      stubDiscoveryPlanLimits(planLimits);

      when(() => likes.likeUser(101)).thenAnswer((_) async => sampleLikeResponse());

      await pumpDiscoveryPage(
        tester,
        discovery: discovery,
        planLimits: planLimits,
        likes: likes,
        profiles: [
          sampleDiscoveryProfile(id: 101, firstName: 'Alex'),
          sampleDiscoveryProfile(id: 102, firstName: 'Sam'),
        ],
      );

      expect(find.text('Alex'), findsOneWidget);
      await tapDiscoveryLike(tester);

      expect(find.text('Alex'), findsNothing);
      expect(find.text('Sam'), findsOneWidget);
      verify(() => likes.likeUser(101)).called(1);
    });

    // TEST-037
    testWidgets('TEST-037: dislike advances deck via likes service', (tester) async {
      final discovery = MockDiscoveryService();
      final likes = MockLikesService();
      final planLimits = MockPlanLimitsService();
      stubDiscoveryPlanLimits(planLimits);

      when(() => likes.dislikeUser(101)).thenAnswer(
        (_) async => DislikeResponse(theyLikedYou: false),
      );

      await pumpDiscoveryPage(
        tester,
        discovery: discovery,
        planLimits: planLimits,
        likes: likes,
        profiles: [sampleDiscoveryProfile(id: 101, firstName: 'Alex')],
      );

      await tapDiscoveryDislike(tester);

      expect(find.text('Alex'), findsNothing);
      verify(() => likes.dislikeUser(101)).called(1);
    });
  });

  group('Empty deck', () {
    // TEST-038
    testWidgets('TEST-038: empty discovery deck shows empty state CTAs', (tester) async {
      final discovery = MockDiscoveryService();
      final planLimits = MockPlanLimitsService();
      stubDiscoveryPlanLimits(planLimits);

      await pumpDiscoveryPage(
        tester,
        discovery: discovery,
        planLimits: planLimits,
        profiles: [],
        waitForCard: false,
      );

      expect(find.text('No more profiles'), findsOneWidget);
      expect(
        find.text('Try widening filters or expanding distance to find more people.'),
        findsOneWidget,
      );
      expect(find.text('Adjust filters'), findsOneWidget);
      expect(find.text('Increase distance + retry'), findsOneWidget);

      await e2ePumpFrames(tester, frames: 5);
    });

    // TEST-039
    testWidgets('TEST-039: increase distance retries with expanded radius', (tester) async {
      final discovery = MockDiscoveryService();
      final planLimits = MockPlanLimitsService();
      stubDiscoveryPlanLimits(planLimits);

      await pumpDiscoveryPage(
        tester,
        discovery: discovery,
        planLimits: planLimits,
        profiles: [],
        waitForCard: false,
      );

      await tester.tap(find.text('Increase distance + retry'));
      await e2ePumpFrames(tester, frames: 6);

      expect(find.textContaining('Expanded distance to 50 km'), findsOneWidget);
      verify(
        () => discovery.fetchNearbySuggestionsFromApi(
          page: 1,
          limit: any(named: 'limit'),
          filters: any(
            named: 'filters',
            that: predicate<Map<String, dynamic>?>(
              (f) => f != null && f!['max_distance'] == 50,
            ),
          ),
        ),
      ).called(greaterThanOrEqualTo(1));

      await e2ePumpFrames(tester, frames: 5);
    });
  });

  group('Filters', () {
    // TEST-040
    testWidgets('TEST-040: filter button opens FilterScreen', (tester) async {
      final planLimits = MockPlanLimitsService();
      stubDiscoveryPlanLimits(planLimits);

      await pumpDiscoveryPage(
        tester,
        discovery: MockDiscoveryService(),
        planLimits: planLimits,
        profiles: [],
        waitForCard: false,
      );

      await openDiscoveryFilters(tester);

      expect(find.byType(FilterScreen), findsOneWidget);
      expect(find.text('Filters'), findsOneWidget);
    });

    // TEST-041
    test('TEST-041: basid plan guard denies advanced filters', () async {
      final planLimits = MockPlanLimitsService();
      stubPlanLimitsService(planLimits, tier: 'basid');
      final guard = PlanGuard(planLimits);
      final result = await guard.canUseAdvancedFilters();
      expect(result.isAllowed, isFalse);
      expect(result.upgradeRequired, isTrue);
    });
  });

  group('Superlike & profile detail', () {
    // TEST-042
    testWidgets('TEST-042: superlike opens required-message sheet', (tester) async {
      final planLimits = MockPlanLimitsService();
      stubDiscoveryPlanLimits(planLimits);

      await pumpDiscoveryPage(
        tester,
        discovery: MockDiscoveryService(),
        planLimits: planLimits,
        profiles: [sampleDiscoveryProfile()],
      );

      await tapDiscoverySuperlike(tester);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Send a Super Like'), findsOneWidget);
      expect(find.text('Add a message to stand out (required)'), findsOneWidget);
    });

    // TEST-043
    testWidgets('TEST-043: profile detail screen loads for routed user', (tester) async {
      final profileService = MockProfileService();
      when(() => profileService.getUserProfile(101)).thenAnswer(
        (_) async => UserProfile(
          id: 101,
          firstName: 'Alex',
          lastName: 'Test',
          email: 'alex@test.com',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileServiceProvider.overrideWithValue(profileService),
          ],
          child: const MaterialApp(
            home: ProfileDetailScreen(userId: 101),
          ),
        ),
      );
      await e2ePumpFrames(tester, frames: 8);

      expect(find.byType(ProfileDetailScreen), findsOneWidget);
    });
  });
}
