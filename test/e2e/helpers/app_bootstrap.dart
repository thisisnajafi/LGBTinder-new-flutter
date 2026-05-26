import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lgbtindernew/core/providers/api_providers.dart';
import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/features/auth/providers/auth_service_provider.dart';
import 'package:lgbtindernew/features/payments/data/services/plan_limits_service.dart';
import 'package:lgbtindernew/routes/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mocktail/mocktail.dart';

import 'mock_services.dart';

/// Result of [pumpE2eApp] — container + router for navigation in tests.
typedef E2eAppHandle = ({ProviderContainer container, GoRouter router});

/// Pumps the app shell with [GoRouter] and optional provider overrides.
Future<E2eAppHandle> pumpE2eApp(
  WidgetTester tester, {
  List<Override> overrides = const [],
  InMemoryTokenStorage? tokenStorage,
}) async {
  SharedPreferences.setMockInitialValues({
    'intro_onboarding_seen': true,
  });
  final storage = tokenStorage ?? InMemoryTokenStorage();
  if (tokenStorage == null) {
    storage.seedUnauthenticated();
  }

  final container = ProviderContainer(
    overrides: [
      tokenStorageServiceProvider.overrideWithValue(storage),
      ...overrides,
    ],
  );

  final router = container.read(appRouterProvider);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        routerConfig: router,
      ),
    ),
  );

  return (container: container, router: router);
}

/// Pumps full app with an authenticated session and waits past splash redirect.
Future<E2eAppHandle> pumpAuthenticatedE2eApp(
  WidgetTester tester, {
  List<Override> overrides = const [],
  InMemoryTokenStorage? tokenStorage,
}) async {
  e2eSetPhoneViewport(tester);
  final storage = tokenStorage ?? InMemoryTokenStorage()..seedAuthenticated();

  final app = await pumpE2eApp(
    tester,
    tokenStorage: storage,
    overrides: overrides,
  );

  // Splash delay + skip network check-token (not available in widget tests).
  markStartupFlowLeft();
  app.router.go(AppRoutes.home);
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pump(const Duration(milliseconds: 500));

  return app;
}

/// Bounded pumps — avoids pumpAndSettle timeout on animated screens.
Future<void> e2ePumpFrames(
  WidgetTester tester, {
  int frames = 3,
  Duration step = const Duration(milliseconds: 200),
}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(step);
  }
}

/// Navigate via the app [GoRouter] instance (not BuildContext — MaterialApp.router differs).
Future<void> e2eGo(
  WidgetTester tester,
  GoRouter router,
  String location,
) async {
  router.go(location);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Use a tall phone viewport so welcome/login layouts do not overflow in tests.
void e2eSetPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
}

void e2eResetViewport(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

/// Tap the primary gradient submit button on auth screens (avoids duplicate "Sign In" title text).
Future<void> tapAuthSubmitButton(WidgetTester tester) async {
  final button = find.byWidgetPredicate(
    (widget) => widget.runtimeType.toString().contains('GradientButton'),
  );
  expect(button, findsWidgets);
  await tester.tap(button.last);
  await tester.pump();
}

Future<void> e2ePumpSettle(WidgetTester tester, {Duration? duration}) async {
  await tester.pump();
  if (duration != null) {
    await tester.pump(duration);
  }
  await tester.pump(const Duration(milliseconds: 100));
}

/// Overrides for authenticated router tests.
List<Override> authenticatedOverrides({
  InMemoryTokenStorage? storage,
  MockAuthService? auth,
  MockPlanLimitsService? planLimits,
}) {
  final tokenStorage = storage ?? InMemoryTokenStorage()..seedAuthenticated();
  final authService = auth ?? MockAuthService();
  final planService = planLimits ?? MockPlanLimitsService();

  when(() => planService.getPlanLimits(forceRefresh: any(named: 'forceRefresh')))
      .thenAnswer((_) async => planLimitsForTier('basid'));

  return [
    tokenStorageServiceProvider.overrideWithValue(tokenStorage),
    authServiceProvider.overrideWithValue(authService),
    planLimitsServiceProvider.overrideWithValue(planService),
  ];
}
