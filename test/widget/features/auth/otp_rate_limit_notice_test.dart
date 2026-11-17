import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/auth/presentation/widgets/otp_rate_limit_notice.dart';

void main() {
  testWidgets('burned code: countdown then offers resend', (tester) async {
    var resent = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OtpRateLimitNotice(
            retryAfterSeconds: 2,
            codeInvalidated: true,
            onResend: () async {
              resent = true;
              return true;
            },
          ),
        ),
      ),
    );

    expect(
      find.text(
        'Too many attempts. Please wait 0:02, then request a new code.',
      ),
      findsOneWidget,
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

    await tester.tap(find.text('Resend Code'));
    await tester.pump();
    expect(resent, isTrue);
  });

  testWidgets('IP wait: countdown then unlocks without Resend', (tester) async {
    var ended = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OtpRateLimitNotice(
            retryAfterSeconds: 2,
            codeInvalidated: false,
            onWaitEnded: () => ended = true,
          ),
        ),
      ),
    );

    expect(find.text('Too many requests. Please wait 0:02.'), findsOneWidget);
    expect(find.text('Resend Code'), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('You can try again now.'), findsOneWidget);
    expect(find.text('Resend Code'), findsNothing);
    expect(ended, isTrue);
  });
}
