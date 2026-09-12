import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lgbtindernew/features/auth/presentation/widgets/login_form.dart';
import 'package:lgbtindernew/routes/app_router.dart';
import 'package:lgbtindernew/screens/auth/login_screen.dart';

import '../../helpers/test_helpers.dart';

Widget _loginApp(ProviderContainer container) {
  final router = GoRouter(
    initialLocation: AppRoutes.login,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const Scaffold(body: Text('Register')),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const Scaffold(body: Text('Forgot')),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (_, __) => const Scaffold(body: Text('Welcome')),
      ),
    ],
  );

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('shows extracted form widgets and Sign In', (tester) async {
    final container = createTestContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(_loginApp(container));
    await waitForAsync(tester);

    expect(find.byType(LoginCredentialsFields), findsOneWidget);
    expect(find.byType(LoginRememberForgotRow), findsOneWidget);
    expect(find.byType(LoginSignUpFooter), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsWidgets);
  });

  testWidgets('remember-me toggle stays inside LoginRememberForgotRow',
      (tester) async {
    var parentBuilds = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              parentBuilds++;
              return const LoginRememberForgotRow();
            },
          ),
        ),
      ),
    );

    final buildsAfterFirstFrame = parentBuilds;
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    expect(parentBuilds, buildsAfterFirstFrame);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
  });

  testWidgets('typing in email does not rebuild the credentials parent',
      (tester) async {
    var parentBuilds = 0;
    final email = TextEditingController();
    final password = TextEditingController();
    addTearDown(email.dispose);
    addTearDown(password.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              parentBuilds++;
              return LoginCredentialsFields(
                emailController: email,
                passwordController: password,
              );
            },
          ),
        ),
      ),
    );

    final buildsAfterFirstFrame = parentBuilds;
    await tester.enterText(find.byType(TextField).first, 'a@b.com');
    await tester.pump();

    expect(email.text, 'a@b.com');
    expect(parentBuilds, buildsAfterFirstFrame);
  });
}
