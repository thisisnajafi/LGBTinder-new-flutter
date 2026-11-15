import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lgbtindernew/core/location/location_providers.dart';
import 'package:lgbtindernew/core/location/location_service.dart';
import 'package:lgbtindernew/core/location/location_sync_service.dart';
import 'package:lgbtindernew/core/providers/feature_flags_provider.dart';
import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/features/discover/utils/discovery_image_prefetch.dart';
import 'package:lgbtindernew/features/discover/widgets/discover_action_bar.dart';
import 'package:lgbtindernew/features/discover/widgets/discover_empty_state.dart';
import 'package:lgbtindernew/features/discover/widgets/discover_header.dart';
import 'package:lgbtindernew/features/discover/widgets/discover_swipe_notice.dart';
import 'package:lgbtindernew/features/profile/data/models/user_image.dart';
import 'package:lgbtindernew/pages/discovery_page.dart';
import 'package:lgbtindernew/shared/models/api_error.dart';
import 'package:lgbtindernew/widgets/cards/card_stack_manager.dart';
import 'package:lgbtindernew/widgets/cards/swipeable_card.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../e2e/discover/discovery_test_helpers.dart';
import '../../../e2e/helpers/mock_services.dart';
import 'discover_test_host.dart';

class _GrantedLocationService extends Fake implements LocationService {
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.whileInUse;
}

class _SyncedLocationService extends Fake implements LocationSyncService {
  @override
  Future<LocationSyncResult> syncForDiscover() async =>
      LocationSyncResult.skippedRecent;

  @override
  Future<LocationSyncResult> syncIfStale() async =>
      LocationSyncResult.skippedRecent;
}

/// Whole-page smoke tests: the real [DiscoveryPage] with mocked services.
void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(Duration.zero);
    registerFallbackValue(false);
  });

  // Photos count as already on disk, so the front card is shown at once.
  setUp(() => DiscoveryImagePrefetch.debugFetch = (_) async {});
  tearDown(() => DiscoveryImagePrefetch.debugFetch = null);

  Future<void> pumpPage(
    WidgetTester tester, {
    required List<Override> overrides,
    Size surface = kSmallPhone,
    double textScale = 1.0,
    TextDirection direction = TextDirection.ltr,
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode:
              brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: Directionality(textDirection: direction, child: child!),
          ),
          home: const Scaffold(
            body: DiscoveryPage(selectedTabIndex: 0, discoveryTabIndex: 0),
          ),
        ),
      ),
    );
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<List<Override>> overridesFor({
    int profileCount = 3,
    MockLikesService? likes,
  }) async {
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();
    final planLimits = MockPlanLimitsService();
    stubDiscoveryPlanLimits(planLimits);
    final profile = MockProfileService();
    when(profile.getProfileImages).thenAnswer((_) async => <UserImage>[]);
    return [
      sharedPreferencesProvider.overrideWithValue(prefs),
      locationServiceProvider.overrideWithValue(_GrantedLocationService()),
      locationSyncServiceProvider.overrideWithValue(_SyncedLocationService()),
      ...discoveryTestOverrides(
        planLimits: planLimits,
        discovery: MockDiscoveryService(),
        cache: MockCacheService(),
        profile: profile,
        likes: likes,
        profiles: [
          for (var i = 0; i < profileCount; i++)
            sampleDiscoveryProfile(id: 101 + i, firstName: 'Person$i'),
        ],
      ),
    ];
  }

  testWidgets('page shows the header, the card stack and the action bar',
      (tester) async {
    await pumpPage(tester, overrides: await overridesFor());

    expect(find.byType(DiscoverHeader), findsOneWidget);
    expect(find.byType(CardStackManager), findsOneWidget);
    expect(find.byType(DiscoverActionBar), findsOneWidget);
    expect(
      tester.widget<SwipeableCard>(find.byType(SwipeableCard).last).userId,
      101,
      reason: 'the front card is the real card, not its skeleton',
    );
    // The passport button is plan-gated (free plan here); its label is
    // covered in discover_layout_test.dart.
    for (final label in const [
      'Open filters',
      'Notifications',
      'View my profile',
      'Like profile',
      'Dislike profile',
      'Super like profile',
      'Rewind last swipe',
    ]) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
    expectNoLayoutErrors(tester);
  });

  testWidgets('page lays out in RTL at 1.3x text scale on a small phone',
      (tester) async {
    await pumpPage(
      tester,
      overrides: await overridesFor(),
      textScale: 1.3,
      direction: TextDirection.rtl,
    );

    expect(find.byType(CardStackManager), findsOneWidget);
    expect(find.byType(DiscoverActionBar), findsOneWidget);
    expect(find.byType(SwipeableCard), findsNWidgets(3));
    expectNoLayoutErrors(tester);
  });

  testWidgets('page lays out in dark mode on a 320 dp wide phone',
      (tester) async {
    await pumpPage(
      tester,
      overrides: await overridesFor(),
      surface: const Size(320, 568),
      textScale: 1.3,
      brightness: Brightness.dark,
    );

    expect(find.byType(DiscoverActionBar), findsOneWidget);
    expect(find.byType(SwipeableCard), findsNWidgets(3));
    expectNoLayoutErrors(tester);
  });

  int topCardId(WidgetTester tester) {
    final stack = tester.widget<CardStackManager>(
      find.byType(CardStackManager),
    );
    return stack.cards.first['id'] as int;
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('like button moves on to the next profile straight away',
      (tester) async {
    final likes = MockLikesService();
    await pumpPage(tester, overrides: await overridesFor(likes: likes));
    expect(topCardId(tester), 101);

    await tester.tap(find.bySemanticsLabel('Like profile'));
    await tester.pump();
    // Optimistic: the deck has already advanced, before any server answer.
    expect(topCardId(tester), 102);

    await settle(tester);
    verify(() => likes.likeUser(101)).called(1);
    expect(topCardId(tester), 102);
    expect(find.byKey(DiscoverSwipeNotice.pillKey), findsNothing);
    expectNoLayoutErrors(tester);
  });

  testWidgets('a like the server fails brings the profile back with a toast',
      (tester) async {
    final likes = MockLikesService();
    final overrides = await overridesFor(likes: likes);
    when(() => likes.likeUser(any())).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      throw ApiError(code: 500, message: 'server down');
    });
    await pumpPage(tester, overrides: overrides);
    expect(topCardId(tester), 101);

    await tester.tap(find.bySemanticsLabel('Like profile'));
    await tester.pump();
    expect(topCardId(tester), 102);

    await settle(tester);
    expect(topCardId(tester), 101, reason: 'the failed like is undone');
    expect(
      find.text("Couldn't send your like. The profile is back, try again."),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsNothing);

    // Non-blocking: the notice sits on the card and takes no touches, so
    // the bar works straight away.
    final notice = tester.getRect(find.byKey(DiscoverSwipeNotice.pillKey));
    final bar = tester.getRect(find.byType(DiscoverActionBar));
    expect(notice.bottom, lessThan(bar.top));
    await tester.tap(find.bySemanticsLabel('Dislike profile'));
    await tester.pump();
    expect(topCardId(tester), 102);

    // And it goes away by itself.
    await tester.pump(DiscoverSwipeNotice.hold);
    await settle(tester);
    expect(find.byKey(DiscoverSwipeNotice.pillKey), findsNothing);
    expectNoLayoutErrors(tester);
  });

  testWidgets('dragging the card past the threshold likes it', (tester) async {
    final likes = MockLikesService();
    await pumpPage(tester, overrides: await overridesFor(likes: likes));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(SwipeableCard).last),
    );
    // First move only wins the gesture arena, then in steps like a finger.
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await gesture.moveBy(const Offset(55, 0));
      await tester.pump();
    }
    await gesture.up();
    await settle(tester);

    verify(() => likes.likeUser(101)).called(1);
    expect(topCardId(tester), 102);
    expectNoLayoutErrors(tester);
  });

  testWidgets('empty deck keeps three actions and hides the action bar',
      (tester) async {
    await pumpPage(
      tester,
      overrides: await overridesFor(profileCount: 0),
      textScale: 1.3,
      direction: TextDirection.rtl,
    );

    expect(find.byType(DiscoverActionBar), findsNothing);
    expect(find.byType(DiscoverHeader), findsOneWidget);
    expect(find.byType(DiscoverEmptyState), findsOneWidget);
    expect(find.byKey(DiscoverEmptyState.primaryActionKey), findsOneWidget);
    expect(find.byKey(DiscoverEmptyState.secondaryActionKey), findsOneWidget);
    expect(find.byKey(DiscoverEmptyState.tertiaryActionKey), findsOneWidget);
    expectNoLayoutErrors(tester);
  });
}
