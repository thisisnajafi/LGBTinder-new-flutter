import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lgbtindernew/features/auth/presentation/widgets/register_form.dart';
import 'package:lgbtindernew/routes/app_router.dart';
import 'package:lgbtindernew/screens/auth/register_screen.dart';

import '../../helpers/test_helpers.dart';

Widget _registerApp(ProviderContainer container) {
  final router = GoRouter(
    initialLocation: AppRoutes.register,
    routes: [
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const Scaffold(body: Text('Login')),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (_, __) => const Scaffold(body: Text('Welcome')),
      ),
      GoRoute(
        path: AppRoutes.termsOfService,
        builder: (_, __) => const Scaffold(body: Text('Terms')),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (_, __) => const Scaffold(body: Text('Privacy')),
      ),
    ],
  );

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('shows extracted register form widgets', (tester) async {
    final container = createTestContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(_registerApp(container));
    await waitForAsync(tester);

    expect(find.byType(RegisterCredentialsFields), findsOneWidget);
    expect(find.byType(RegisterTermsBlock), findsOneWidget);
    expect(find.byType(RegisterSignInFooter), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(5));
    expect(find.text('First Name'), findsOneWidget);
    expect(find.text('Last Name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.text('Create Account'), findsWidgets);
  });

  testWidgets('terms toggle does not rebuild the terms parent', (tester) async {
    var parentBuilds = 0;
    final agreed = ValueNotifier(false);
    addTearDown(agreed.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              parentBuilds++;
              return RegisterTermsBlock(agreed: agreed);
            },
          ),
        ),
      ),
    );

    final buildsAfterFirstFrame = parentBuilds;
    await tester.tap(find.bySemanticsLabel('Agree to terms and privacy policy'));
    await tester.pump();

    expect(parentBuilds, buildsAfterFirstFrame);
    expect(agreed.value, isTrue);
  });

  testWidgets('typing in first name does not rebuild the credentials parent',
      (tester) async {
    var parentBuilds = 0;
    final firstName = TextEditingController();
    final lastName = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    final confirm = TextEditingController();
    addTearDown(firstName.dispose);
    addTearDown(lastName.dispose);
    addTearDown(email.dispose);
    addTearDown(password.dispose);
    addTearDown(confirm.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              parentBuilds++;
              return RegisterCredentialsFields(
                firstNameController: firstName,
                lastNameController: lastName,
                emailController: email,
                passwordController: password,
                confirmPasswordController: confirm,
              );
            },
          ),
        ),
      ),
    );

    final buildsAfterFirstFrame = parentBuilds;
    await tester.enterText(find.byType(TextField).first, 'Ada');
    await tester.pump();

    expect(firstName.text, 'Ada');
    expect(parentBuilds, buildsAfterFirstFrame);
  });
}
