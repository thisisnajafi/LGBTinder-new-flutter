import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lgbtindernew/screens/profile/profile_analytics_screen.dart';
import 'package:lgbtindernew/screens/profile/profile_completion_incentives_screen.dart';

import '../../helpers/test_helpers.dart';

Widget _hosted(Widget child) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => child),
    ],
  );
  return UncontrolledProviderScope(
    container: createTestContainer(),
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('incentives screen is static and shows catalog copy',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _hosted(const ProfileCompletionIncentivesScreen()),
    );
    await tester.pump();

    expect(find.text('Add Profile Photo'), findsOneWidget);
    expect(find.text('3x More Matches'), findsOneWidget);
    expect(find.byType(ProfileCompletionIncentivesScreen), findsOneWidget);
  });

  testWidgets('analytics first paint shows period row before chart data',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_hosted(const ProfileAnalyticsScreen()));

    expect(find.text('Week'), findsOneWidget);
    expect(find.text('Profile Views'), findsNothing);

    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('analytics_overview_chart')), findsOneWidget);
    expect(find.text('Profile Views'), findsOneWidget);
  });
}
