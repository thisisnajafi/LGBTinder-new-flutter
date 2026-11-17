import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lgbtindernew/features/auth/data/models/verify_email_request.dart';
import 'package:lgbtindernew/features/auth/presentation/widgets/email_verification_form.dart';
import 'package:lgbtindernew/features/auth/presentation/widgets/otp_rate_limit_notice.dart';
import 'package:lgbtindernew/features/auth/providers/auth_service_provider.dart';
import 'package:lgbtindernew/features/auth/utils/otp_rate_limit.dart';
import 'package:lgbtindernew/routes/app_router.dart';
import 'package:lgbtindernew/screens/auth/email_verification_screen.dart';
import 'package:lgbtindernew/shared/models/api_error.dart';
import 'package:mocktail/mocktail.dart';

import '../../e2e/helpers/mock_services.dart';
import '../../helpers/test_helpers.dart';

ApiError _otpLockout({int retryAfter = 2}) => ApiError(
  code: 429,
  message: 'Too many incorrect codes.',
  errorCode: OtpRateLimit.errorCode,
  responseData: {
    'error_code': OtpRateLimit.errorCode,
    'retry_after': retryAfter,
    'message': 'Too many incorrect codes.',
  },
);

Widget _app(ProviderContainer container) {
  final router = GoRouter(
    initialLocation: '/verify',
    routes: [
      GoRoute(
        path: '/verify',
        builder: (_, __) => const EmailVerificationScreen(
          email: 'user@test.com',
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
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const Scaffold(body: Text('Home')),
      ),
      GoRoute(
        path: AppRoutes.profileWizard,
        builder: (_, __) => const Scaffold(body: Text('Wizard')),
      ),
    ],
  );
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _enterOtpDigits(WidgetTester tester) async {
  final fields = find.descendant(
    of: find.byType(EmailOtpFields),
    matching: find.byType(TextField),
  );
  expect(fields, findsNWidgets(6));
  for (var i = 0; i < 6; i++) {
    await tester.enterText(fields.at(i), '${i + 1}');
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUpAll(() {
    registerFallbackValue(VerifyEmailRequest(email: 'a@b.com', code: '000000'));
  });

  testWidgets('shows lockout notice, countdown, then resend after 429', (
    tester,
  ) async {
    final auth = MockAuthService();
    when(() => auth.verifyEmail(any())).thenThrow(_otpLockout(retryAfter: 2));
    when(() => auth.resendVerificationCode(any())).thenAnswer((_) async {});

    final container = createTestContainer(
      overrides: [authServiceProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_app(container));
    await waitForAsync(tester);

    await _enterOtpDigits(tester);
    verify(() => auth.verifyEmail(any())).called(greaterThanOrEqualTo(1));
    await tester.pump();

    expect(find.byType(OtpRateLimitNotice), findsOneWidget);
    expect(
      find.text(
        'Too many attempts. Please wait 0:02, then request a new code.',
      ),
      findsWidgets,
    );
    expect(find.text('Resend Code'), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    expect(
      find.text(
        'Too many attempts. Please wait 0:01, then request a new code.',
      ),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('You can request a new code now.'), findsOneWidget);
    expect(find.text('Resend Code'), findsOneWidget);

    await tester.ensureVisible(find.text('Resend Code'));
    await tester.pump();
    await tester.tap(find.text('Resend Code'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    verify(() => auth.resendVerificationCode('user@test.com')).called(1);
    expect(find.byType(OtpRateLimitNotice), findsNothing);
  });
}
