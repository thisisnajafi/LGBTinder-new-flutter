import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lgbtindernew/features/auth/presentation/widgets/email_verification_form.dart';
import 'package:lgbtindernew/routes/app_router.dart';
import 'package:lgbtindernew/screens/auth/email_verification_screen.dart';

import '../../helpers/test_helpers.dart';

Widget _verificationApp(ProviderContainer container) {
  final router = GoRouter(
    initialLocation: '/verify',
    routes: [
      GoRoute(
        path: '/verify',
        builder: (_, __) => const EmailVerificationScreen(
          email: 'test@example.com',
          isNewUser: true,
        ),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (_, __) => const Scaffold(body: Text('Welcome')),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const Scaffold(body: Text('Register')),
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
  testWidgets('shows OTP fields, email, and isolated countdown', (tester) async {
    final container = createTestContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(_verificationApp(container));
    await waitForAsync(tester);

    expect(find.byType(EmailOtpFields), findsOneWidget);
    expect(find.byType(EmailResendRow), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(6));
    expect(find.text('test@example.com'), findsOneWidget);
    expect(find.text('Verify Email'), findsWidgets);
    expect(find.textContaining('Resend in'), findsOneWidget);
  });

  testWidgets('countdown ticks without rebuilding the parent', (tester) async {
    var parentBuilds = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              parentBuilds++;
              return EmailResendRow(
                cooldown: const Duration(seconds: 5),
                onResend: () async => false,
              );
            },
          ),
        ),
      ),
    );

    final buildsAfterFirstFrame = parentBuilds;
    expect(find.text('Resend in 0:05'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Resend in 0:04'), findsOneWidget);
    expect(parentBuilds, buildsAfterFirstFrame);
  });

  testWidgets('debounce ignores a second resend tap while in flight',
      (tester) async {
    var calls = 0;
    final gate = Completer<bool>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmailResendRow(
            cooldown: Duration.zero,
            onResend: () {
              calls++;
              return gate.future;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Resend Code'));
    await tester.pump();
    await tester.tap(find.text('Sending...'));
    await tester.pump();

    expect(calls, 1);
    gate.complete(false);
    await tester.pump();
  });
}
