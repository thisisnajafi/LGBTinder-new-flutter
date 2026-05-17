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

import 'mock_services.dart';

/// Pumps the app shell with [GoRouter] and optional provider overrides.
Future<ProviderContainer> pumpE2eApp(
  WidgetTester tester, {
  List<Override> overrides = const [],
  InMemoryTokenStorage? tokenStorage,
}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = tokenStorage ?? InMemoryTokenStorage();
  storage.seedUnauthenticated();

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

  return container;
}

/// Navigate and settle frames.
Future<void> e2eGo(WidgetTester tester, String location) async {
  final context = tester.element(find.byType(MaterialApp));
  GoRouter.of(context).go(location);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> e2ePump settle(WidgetTester tester, {Duration? duration}) async {
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
