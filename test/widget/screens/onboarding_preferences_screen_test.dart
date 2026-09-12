import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lgbtindernew/core/widgets/app_list_view.dart';
import 'package:lgbtindernew/features/onboarding/presentation/widgets/onboarding_preferences_form.dart';
import 'package:lgbtindernew/features/profile/data/models/update_profile_request.dart';
import 'package:lgbtindernew/features/profile/data/models/user_profile.dart';
import 'package:lgbtindernew/features/profile/data/services/profile_service.dart';
import 'package:lgbtindernew/features/profile/providers/profile_providers.dart';
import 'package:lgbtindernew/features/reference_data/data/models/reference_item.dart';
import 'package:lgbtindernew/features/reference_data/providers/reference_data_providers.dart';
import 'package:lgbtindernew/routes/app_router.dart';
import 'package:lgbtindernew/screens/onboarding/onboarding_preferences_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';

class _MockProfileService extends Mock implements ProfileService {}

void _tallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

List<Override> _overrides(_MockProfileService profile) {
  return [
    profileServiceProvider.overrideWithValue(profile),
    preferredGendersProvider.overrideWith(
      (ref) async => [
        ReferenceItem(id: 10, title: 'Women'),
        ReferenceItem(id: 11, title: 'Men'),
      ],
    ),
    relationshipGoalsProvider.overrideWith(
      (ref) async => [ReferenceItem(id: 9, title: 'Long-term')],
    ),
    interestsProvider.overrideWith(
      (ref) async => [
        ReferenceItem(id: 6, title: 'Music'),
        ReferenceItem(id: 7, title: 'Travel'),
        ReferenceItem(id: 8, title: 'Art'),
      ],
    ),
  ];
}

Widget _app(ProviderContainer container) {
  final router = GoRouter(
    initialLocation: AppRoutes.onboardingPreferences,
    routes: [
      GoRoute(
        path: AppRoutes.onboardingPreferences,
        builder: (_, __) => const OnboardingPreferencesScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const Scaffold(body: Text('Home')),
      ),
    ],
  );

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(UpdateProfileRequest());
  });

  testWidgets('uses AppListView.builder and isolated chip sections',
      (tester) async {
    _tallSurface(tester);
    final profile = _MockProfileService();
    when(() => profile.updateProfile(any())).thenAnswer(
      (_) async => const UserProfile(
        id: 1,
        firstName: 'A',
        lastName: 'B',
        email: 'a@b.com',
      ),
    );
    final container = createTestContainer(overrides: _overrides(profile));
    addTearDown(container.dispose);

    await tester.pumpWidget(_app(container));
    await waitForAsync(tester);
    await tester.pump();

    expect(find.byType(AppListView), findsOneWidget);
    expect(find.byType(OnboardingChipSection), findsNWidgets(3));
    expect(find.byType(OnboardingAgeRangeSection), findsOneWidget);
    expect(find.byType(OnboardingDistanceSection), findsOneWidget);
    expect(find.text('Looking For'), findsOneWidget);
    expect(find.text('Save Preferences'), findsOneWidget);
  });

  testWidgets('chip taps stay local; Save sends one batched updateProfile',
      (tester) async {
    _tallSurface(tester);
    final profile = _MockProfileService();
    final requests = <UpdateProfileRequest>[];
    when(() => profile.updateProfile(any())).thenAnswer((invocation) async {
      requests.add(invocation.positionalArguments.first as UpdateProfileRequest);
      return const UserProfile(
        id: 1,
        firstName: 'A',
        lastName: 'B',
        email: 'a@b.com',
      );
    });
    final container = createTestContainer(overrides: _overrides(profile));
    addTearDown(container.dispose);

    await tester.pumpWidget(_app(container));
    await waitForAsync(tester);
    await tester.pump();

    await tester.tap(find.text('Women'));
    await tester.tap(find.text('Music'));
    await tester.tap(find.text('Travel'));
    await tester.tap(find.text('Art'));
    await tester.pump();

    expect(requests, isEmpty);

    await tester.tap(find.text('Save Preferences'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(requests, hasLength(1));
    expect(requests.single.preferredGenders, [10]);
    expect(requests.single.interests, [6, 7, 8]);
    expect(requests.single.minAgePreference, 18);
    expect(requests.single.maxAgePreference, 100);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('Save with fewer than 3 interests does not call the API',
      (tester) async {
    _tallSurface(tester);
    final profile = _MockProfileService();
    when(() => profile.updateProfile(any())).thenAnswer(
      (_) async => const UserProfile(
        id: 1,
        firstName: 'A',
        lastName: 'B',
        email: 'a@b.com',
      ),
    );
    final container = createTestContainer(overrides: _overrides(profile));
    addTearDown(container.dispose);

    await tester.pumpWidget(_app(container));
    await waitForAsync(tester);
    await tester.pump();

    await tester.tap(find.text('Music'));
    await tester.pump();
    await tester.tap(find.text('Save Preferences'));
    await tester.pump();

    verifyNever(() => profile.updateProfile(any()));
    expect(find.text('Please select at least 3 interests'), findsOneWidget);
  });
}
