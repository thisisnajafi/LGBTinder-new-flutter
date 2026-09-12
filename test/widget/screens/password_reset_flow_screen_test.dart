import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lgbtindernew/features/auth/presentation/widgets/password_reset_steps.dart';
import 'package:lgbtindernew/routes/app_router.dart';
import 'package:lgbtindernew/screens/auth/password_reset_flow_screen.dart';

import '../../helpers/test_helpers.dart';

Widget _resetApp(ProviderContainer container) {
  final router = GoRouter(
    initialLocation: AppRoutes.forgotPassword,
    routes: [
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const PasswordResetFlowScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (_, __) => const Scaffold(body: Text('Welcome')),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const Scaffold(body: Text('Login')),
      ),
    ],
  );

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('shows isolated email step and progress', (tester) async {
    final container = createTestContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(_resetApp(container));
    await waitForAsync(tester);

    expect(find.byType(PasswordResetProgress), findsOneWidget);
    expect(find.byType(ResetEmailStep), findsOneWidget);
    expect(find.byType(ResetOtpStep), findsNothing);
    expect(find.byType(ResetPasswordStep), findsNothing);
    expect(find.text('Reset Your Password'), findsOneWidget);
    expect(find.text('Email'), findsWidgets);
    expect(find.text('Send Verification Code'), findsOneWidget);
  });

  testWidgets('typing email does not rebuild the email-step parent',
      (tester) async {
    var parentBuilds = 0;
    final email = TextEditingController();
    final sending = ValueNotifier(false);
    addTearDown(email.dispose);
    addTearDown(sending.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              parentBuilds++;
              return ResetEmailStep(
                emailController: email,
                isSending: sending,
                onSend: () {},
              );
            },
          ),
        ),
      ),
    );

    final buildsAfterFirstFrame = parentBuilds;
    await tester.enterText(find.byType(TextField), 'a@b.com');
    await tester.pump();

    expect(email.text, 'a@b.com');
    expect(parentBuilds, buildsAfterFirstFrame);
  });

  testWidgets('progress highlights the current step only', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PasswordResetProgress(currentStep: 1),
        ),
      ),
    );

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Verify'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
  });
}
