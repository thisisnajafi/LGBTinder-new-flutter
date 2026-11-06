import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lgbtindernew/features/auth/data/models/otp_request.dart';
import 'package:lgbtindernew/features/auth/data/models/otp_response.dart';
import 'package:lgbtindernew/features/auth/presentation/widgets/email_verification_form.dart';
import 'package:lgbtindernew/features/auth/presentation/widgets/otp_rate_limit_notice.dart';
import 'package:lgbtindernew/features/auth/presentation/widgets/password_reset_steps.dart';
import 'package:lgbtindernew/features/auth/providers/auth_service_provider.dart';
import 'package:lgbtindernew/features/auth/utils/otp_rate_limit.dart';
import 'package:lgbtindernew/routes/app_router.dart';
import 'package:lgbtindernew/screens/auth/password_reset_flow_screen.dart';
import 'package:lgbtindernew/shared/models/api_error.dart';
import 'package:mocktail/mocktail.dart';

import '../../e2e/helpers/mock_services.dart';

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

void main() {
  setUpAll(() {
    registerFallbackValue(SendOtpRequest(email: 'a@b.com'));
    registerFallbackValue(VerifyOtpRequest(email: 'a@b.com', code: '000000'));
  });

  testWidgets('password reset OTP lockout shows countdown then resend', (
    tester,
  ) async {
    final auth = MockAuthService();
    when(
      () => auth.sendOtp(any()),
    ).thenAnswer((_) async => OtpResponse(status: true, message: 'sent'));
    when(() => auth.verifyOtp(any())).thenThrow(_otpLockout(retryAfter: 2));

    final router = GoRouter(
      initialLocation: AppRoutes.forgotPassword,
      routes: [
        GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (_, __) => const PasswordResetFlowScreen(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (_, __) => const Scaffold(body: Text('Login')),
        ),
        GoRoute(
          path: AppRoutes.welcome,
          builder: (_, __) => const Scaffold(body: Text('Welcome')),
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(auth)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'user@test.com');
    await tester.tap(find.text('Send Verification Code'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(ResetOtpStep), findsOneWidget);

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

    verify(() => auth.verifyOtp(any())).called(greaterThanOrEqualTo(1));
    await tester.pump();

    expect(find.byType(OtpRateLimitNotice), findsOneWidget);
    expect(
      find.textContaining('Too many attempts. Please wait 0:02'),
      findsWidgets,
    );
    expect(find.text('Resend Code'), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('You can request a new code now.'), findsOneWidget);
    expect(find.text('Resend Code'), findsOneWidget);

    await tester.ensureVisible(find.text('Resend Code'));
    await tester.pump();
    await tester.tap(find.text('Resend Code'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    verify(() => auth.sendOtp(any())).called(2);
    expect(find.byType(OtpRateLimitNotice), findsNothing);
  });
}
