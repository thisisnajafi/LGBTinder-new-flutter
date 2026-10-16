import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/core/subscription/subscription_access.dart';
import 'package:lgbtindernew/core/location/data/models/user_location.dart';
import 'package:lgbtindernew/core/location/location_providers.dart';
import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/features/auth/presentation/widgets/login_form.dart';
import 'package:lgbtindernew/features/calls/presentation/widgets/call_live_chrome.dart';
import 'package:lgbtindernew/features/discover/widgets/discover_empty_state.dart';
import 'package:lgbtindernew/features/payments/data/services/payment_service.dart';
import 'package:lgbtindernew/features/payments/data/services/plan_limits_service.dart';
import 'package:lgbtindernew/features/payments/presentation/screens/subscription_plans_screen.dart';
import 'package:lgbtindernew/features/payments/providers/payment_providers.dart';
import 'package:lgbtindernew/features/reference_data/data/models/reference_item.dart';
import 'package:lgbtindernew/features/reference_data/providers/reference_data_providers.dart';
import 'package:lgbtindernew/features/settings/data/models/matching_preferences.dart';
import 'package:lgbtindernew/features/settings/pages/settings_page.dart';
import 'package:lgbtindernew/features/settings/providers/settings_provider.dart';
import 'package:lgbtindernew/screens/discovery/filter_screen.dart';
import 'package:lgbtindernew/widgets/cards/swipeable_card.dart';
import 'package:lgbtindernew/widgets/chat/chat_list_item.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sizes = <Size>[
    Size(320, 568),
    Size(360, 640),
    Size(411, 891),
    Size(800, 1280),
  ];
  const scales = <double>[1.0, 1.3];

  Future<void> pumpSurface(
    WidgetTester tester, {
    required Size size,
    required double textScale,
    required Widget child,
    List<Override> overrides = const [],
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(textScale),
              disableAnimations: true,
            ),
            child: child,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  }

  for (final size in sizes) {
    for (final scale in scales) {
      final label = '${size.width.toInt()}x${size.height.toInt()} @ $scale';

      testWidgets('discover empty state has no overflow ($label)', (tester) async {
        await pumpSurface(
          tester,
          size: size,
          textScale: scale,
          child: const DiscoverEmptyState(
            title: 'Turn on location for nearby matches',
            subtitle:
                'Enable location so we can find people near you, or expand your search radius.',
            primaryActionLabel: 'Enable location',
            onPrimaryAction: _noop,
            secondaryActionLabel: 'Increase distance + retry',
            onSecondaryAction: _noop,
            tertiaryActionLabel: 'Adjust filters',
            onTertiaryAction: _noop,
          ),
        );
        expect(find.text('Turn on location for nearby matches'), findsOneWidget);
      });

      testWidgets('chat list tile keeps the name readable ($label)', (tester) async {
        await pumpSurface(
          tester,
          size: size,
          textScale: scale,
          child: ChatListItem(
            userId: 9,
            name: 'Pamela Carter',
            lastMessage: 'See you tonight',
            lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
            hasPlan: true,
            isOfficial: true,
            isPinned: true,
          ),
        );
        final name = find.text('Pamela Carter');
        expect(name, findsOneWidget);
        expect(
          tester.renderObject<RenderParagraph>(name).didExceedMaxLines,
          isFalse,
        );
      });

      testWidgets('login remember row has no overflow ($label)', (tester) async {
        await pumpSurface(
          tester,
          size: size,
          textScale: scale,
          child: const Scaffold(body: LoginRememberForgotRow()),
        );
        expect(find.text('Remember me'), findsOneWidget);
        expect(find.text('Forgot Password?'), findsOneWidget);
      });

      testWidgets('call controls wrap without overflow ($label)', (tester) async {
        await pumpSurface(
          tester,
          size: size,
          textScale: scale,
          child: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: 12,
                runSpacing: 12,
                children: [
                  CallMuteButton(onTap: _noop),
                  CallFlipButton(onTap: _noop),
                  CallEndButton(onTap: _noop),
                ],
              ),
            ),
          ),
        );
        expect(find.text('mute'), findsOneWidget);
      });
    }
  }

  testWidgets('text scale 1.5 does not crash the empty state or chat tile', (tester) async {
    await pumpSurface(
      tester,
      size: const Size(320, 568),
      textScale: 1.5,
      child: const DiscoverEmptyState(
        title: 'Turn on location for nearby matches',
        subtitle:
            'Enable location so we can find people near you, or expand your search radius.',
        primaryActionLabel: 'Enable location',
        onPrimaryAction: _noop,
        secondaryActionLabel: 'Increase distance + retry',
        onSecondaryAction: _noop,
        tertiaryActionLabel: 'Adjust filters',
        onTertiaryAction: _noop,
      ),
    );
    await pumpSurface(
      tester,
      size: const Size(360, 640),
      textScale: 1.5,
      child: ChatListItem(
        userId: 9,
        name: 'Pamela Carter',
        lastMessage: 'See you tonight',
        lastMessageTime: DateTime.now(),
        hasPlan: true,
        isOfficial: true,
      ),
    );
  });

  testWidgets('settings, filters, and paywall build at 320 and 800', (tester) async {
    final payment = _MockPaymentService();
    when(() => payment.getPlans()).thenAnswer((_) async => []);
    when(() => payment.getSubPlans()).thenAnswer((_) async => []);
    final planLimits = _MockPlanLimitsService();
    when(() => planLimits.isCacheValid()).thenReturn(false);
    when(() => planLimits.getCachedLimits()).thenReturn(null);
    when(
      () => planLimits.getPlanLimits(
        forceRefresh: any(named: 'forceRefresh'),
      ),
    ).thenAnswer((_) async => throw Exception('offline'));

    final screenOverrides = <Override>[
      paymentServiceProvider.overrideWithValue(payment),
      hasAdvancedFiltersProvider.overrideWithValue(false),
      planLimitsServiceProvider.overrideWithValue(planLimits),
      gendersProvider.overrideWith((ref) async => const <ReferenceItem>[]),
      interestsProvider.overrideWith((ref) async => const <ReferenceItem>[]),
      jobsProvider.overrideWith((ref) async => const <ReferenceItem>[]),
      educationLevelsProvider.overrideWith((ref) async => const <ReferenceItem>[]),
      languagesProvider.overrideWith((ref) async => const <ReferenceItem>[]),
      musicGenresProvider.overrideWith((ref) async => const <ReferenceItem>[]),
      relationshipGoalsProvider.overrideWith((ref) async => const <ReferenceItem>[]),
      matchingPreferencesProvider.overrideWith(
        (ref) async => const MatchingPreferences(),
      ),
      userLocationProvider.overrideWith((ref) async => const UserLocation()),
    ];

    for (final size in const [Size(320, 568), Size(800, 1280)]) {
      for (final scale in const [1.0, 1.3]) {
        await pumpSurface(
          tester,
          size: size,
          textScale: scale,
          overrides: screenOverrides,
          child: const SettingsPage(),
        );
        await pumpSurface(
          tester,
          size: size,
          textScale: scale,
          overrides: screenOverrides,
          child: const FilterScreen(),
        );
        await pumpSurface(
          tester,
          size: size,
          textScale: scale,
          overrides: screenOverrides,
          child: const SubscriptionPlansScreen(),
        );
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);
      }
    }
  });

  test('swipe card keeps its aspect ratio when height is tight', () {
    final size = SwipeableCard.fitSize(maxWidth: 800, maxHeight: 420);
    expect(size.height, lessThanOrEqualTo(420));
    expect(size.width / size.height, closeTo(SwipeableCard.cardAspectRatio, 0.02));
    expect(size.width, lessThan(800));
  });
}

void _noop() {}

class _MockPaymentService extends Mock implements PaymentService {}

class _MockPlanLimitsService extends Mock implements PlanLimitsService {}
