import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/core/providers/api_providers.dart';
import 'package:lgbtindernew/features/discover/data/models/discovery_profile.dart';
import 'package:lgbtindernew/features/discover/data/services/discovery_service.dart';
import 'package:lgbtindernew/features/discover/providers/discovery_providers.dart';
import 'package:lgbtindernew/features/matching/data/models/like.dart';
import 'package:lgbtindernew/features/matching/data/services/likes_service.dart';
import 'package:lgbtindernew/features/matching/providers/likes_providers.dart';
import 'package:lgbtindernew/features/notifications/providers/notification_providers.dart';
import 'package:lgbtindernew/features/payments/data/services/plan_limits_service.dart';
import 'package:lgbtindernew/features/profile/data/models/user_profile.dart';
import 'package:lgbtindernew/features/profile/data/services/profile_service.dart';
import 'package:lgbtindernew/features/profile/providers/profile_providers.dart';
import 'package:lgbtindernew/pages/discovery_page.dart';
import 'package:lgbtindernew/shared/services/cache_service.dart';
import 'package:lgbtindernew/widgets/buttons/scale_tap_feedback.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/app_bootstrap.dart';
import '../helpers/mock_services.dart';

class MockDiscoveryService extends Mock implements DiscoveryService {}

class MockCacheService extends Mock implements CacheService {}

class MockLikesService extends Mock implements LikesService {}

class MockProfileService extends Mock implements ProfileService {}

DiscoveryProfile sampleDiscoveryProfile({
  int id = 101,
  String firstName = 'Alex',
}) {
  return DiscoveryProfile(
    id: id,
    firstName: firstName,
    age: 28,
    city: 'Berlin',
    country: 'DE',
    primaryImageUrl: 'https://example.com/photo.jpg',
  );
}

LikeResponse sampleLikeResponse({bool isMatch = false}) =>
    LikeResponse(isMatch: isMatch);

bool _isDiscoveryActionButton(Widget widget) {
  if (widget is! ScaleTapFeedback) return false;
  final child = widget.child;
  if (child is! Container) return false;
  return child.constraints?.maxWidth == 56 && child.constraints?.maxHeight == 56;
}

Finder discoveryActionButtons() => find.byWidgetPredicate(_isDiscoveryActionButton);

List<Override> discoveryTestOverrides({
  required MockPlanLimitsService planLimits,
  required MockDiscoveryService discovery,
  required MockCacheService cache,
  MockLikesService? likes,
  MockProfileService? profile,
  List<DiscoveryProfile> profiles = const [],
}) {
  final likesService = likes ?? MockLikesService();
  final profileService = profile ?? MockProfileService();

  when(() => profileService.getMyProfile()).thenAnswer(
    (_) async => UserProfile(
      id: 1,
      firstName: 'Tester',
      lastName: 'User',
      email: 'tester@test.com',
    ),
  );
  when(() => profileService.getUserProfile(any())).thenThrow(Exception('not stubbed'));

  when(
    () => discovery.fetchNearbySuggestionsFromApi(
      page: any(named: 'page'),
      limit: any(named: 'limit'),
      filters: any(named: 'filters'),
    ),
  ).thenAnswer((_) async => profiles);

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

  when(() => likesService.likeUser(any())).thenAnswer((_) async => sampleLikeResponse());
  when(() => likesService.dislikeUser(any())).thenAnswer(
    (_) async => DislikeResponse(theyLikedYou: false),
  );
  when(
    () => likesService.superlikeUser(any(), message: any(named: 'message')),
  ).thenAnswer((_) async => sampleLikeResponse());

  return [
    planLimitsServiceProvider.overrideWithValue(planLimits),
    discoveryServiceProvider.overrideWithValue(discovery),
    cacheServiceProvider.overrideWithValue(cache),
    likesServiceProvider.overrideWithValue(likesService),
    profileServiceProvider.overrideWithValue(profileService),
    unreadNotificationCountProvider.overrideWith((_) async => 0),
  ];
}

void stubDiscoveryPlanLimits(MockPlanLimitsService planLimits) {
  stubPlanLimitsService(planLimits, tier: 'basid');
  when(() => planLimits.hasReachedSwipeLimit()).thenAnswer((_) async => false);
  when(() => planLimits.hasReachedSuperlikeLimit()).thenAnswer((_) async => false);
  when(() => planLimits.incrementUsage(any())).thenReturn(null);
}

Future<void> pumpDiscoveryPage(
  WidgetTester tester, {
  required MockDiscoveryService discovery,
  required MockPlanLimitsService planLimits,
  MockCacheService? cache,
  MockLikesService? likes,
  MockProfileService? profile,
  List<DiscoveryProfile> profiles = const [],
  List<Override> extraOverrides = const [],
  Widget? home,
  bool waitForCard = true,
  String cardName = 'Alex',
}) async {
  e2eSetPhoneViewport(tester);
  addTearDown(() => e2eResetViewport(tester));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...discoveryTestOverrides(
          planLimits: planLimits,
          discovery: discovery,
          cache: cache ?? MockCacheService(),
          likes: likes,
          profile: profile,
          profiles: profiles,
        ),
        ...extraOverrides,
      ],
      child: MaterialApp(
        home: home ??
            const Scaffold(
              body: DiscoveryPage(selectedTabIndex: 0, discoveryTabIndex: 0),
            ),
      ),
    ),
  );
  if (waitForCard) {
    await waitForDiscoveryCard(tester, name: cardName);
  } else {
    await waitForDiscoveryEmpty(tester);
  }
}

Future<void> waitForDiscoveryEmpty(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.text('No more profiles').evaluate().isNotEmpty) return;
  }
  fail('Discovery empty state did not appear');
}

Future<void> waitForDiscoveryCard(WidgetTester tester, {String name = 'Alex'}) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.text(name).evaluate().isNotEmpty &&
        discoveryActionButtons().evaluate().length >= 3) {
      return;
    }
  }
  fail('Discovery card "$name" did not appear');
}

Future<void> openDiscoveryFilters(WidgetTester tester) async {
  if (find.text('Adjust filters').evaluate().isNotEmpty) {
    await tester.tap(find.text('Adjust filters'));
  } else {
    await tester.tap(find.byType(ScaleTapFeedback).at(1));
  }
  await e2ePumpFrames(tester, frames: 8);
}

Future<void> tapDiscoveryDislike(WidgetTester tester) async {
  await tester.tap(discoveryActionButtons().at(0));
  await e2ePumpFrames(tester, frames: 6);
}

Future<void> tapDiscoverySuperlike(WidgetTester tester) async {
  await tester.tap(discoveryActionButtons().at(1));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> tapDiscoveryLike(WidgetTester tester) async {
  await tester.tap(discoveryActionButtons().at(2));
  await e2ePumpFrames(tester, frames: 6);
}
