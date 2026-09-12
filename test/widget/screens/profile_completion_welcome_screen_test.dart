import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lgbtindernew/routes/app_router.dart';
import 'package:lgbtindernew/screens/auth/profile_completion_welcome_screen.dart';
import 'package:lgbtindernew/widgets/avatar/animated_avatar.dart';

import '../../helpers/test_helpers.dart';

const _welcomePath = '/profile-completion-welcome';

Widget _welcomeApp(
  ProviderContainer container, {
  bool disableAnimations = false,
}) {
  final router = GoRouter(
    initialLocation: _welcomePath,
    routes: [
      GoRoute(
        path: _welcomePath,
        builder: (_, __) => const ProfileCompletionWelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileWizard,
        builder: (_, __) => const Scaffold(body: Text('Wizard')),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const Scaffold(body: Text('Home')),
      ),
    ],
  );

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router,
      builder: disableAnimations
          ? (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              );
            }
          : null,
    ),
  );
}

AnimatedAvatar _avatar(WidgetTester tester) {
  return tester.widget<AnimatedAvatar>(
    find.byKey(const ValueKey('profile_completion_welcome_avatar')),
  );
}

void _tallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('first paint is static; pulse starts after interaction',
      (tester) async {
    _tallSurface(tester);
    final container = createTestContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(_welcomeApp(container));
    await waitForAsync(tester);

    expect(find.text('Complete Your Profile'), findsOneWidget);
    expect(_avatar(tester).showPulse, isFalse);
    expect(_avatar(tester).animate, isFalse);

    await tester.tap(find.text('Complete Your Profile'));
    await tester.pump();

    expect(_avatar(tester).showPulse, isTrue);
    expect(_avatar(tester).animate, isTrue);
  });

  testWidgets('reduce motion never starts avatar pulse', (tester) async {
    _tallSurface(tester);
    final container = createTestContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(_welcomeApp(container, disableAnimations: true));
    await waitForAsync(tester);

    await tester.tap(find.text('Complete Your Profile'));
    await tester.pump();

    expect(_avatar(tester).showPulse, isFalse);
    expect(_avatar(tester).animate, isFalse);
  });

  testWidgets('Get Started opens the profile wizard', (tester) async {
    _tallSurface(tester);
    final container = createTestContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(_welcomeApp(container));
    await waitForAsync(tester);

    await tester.tap(find.text('Get Started'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Wizard'), findsOneWidget);
  });
}
