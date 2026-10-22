import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/auth/data/services/apple_auth_service.dart';
import 'package:lgbtindernew/features/auth/presentation/widgets/apple_login_button.dart';
import 'package:lgbtindernew/features/auth/presentation/widgets/social_login_button.dart';

Widget _host() => const ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: Center(child: SocialLoginButton())),
      ),
    );

void main() {
  testWidgets('iOS shows Sign in with Apple and hides Google', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await tester.pumpWidget(_host());
      expect(find.byType(AppleLoginButton), findsOneWidget);
      expect(find.text('Continue with Google'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Android shows Google and no Apple button', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await tester.pumpWidget(_host());
      expect(find.byType(AppleLoginButton), findsNothing);
      expect(find.text('Continue with Google'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  test('Apple nonce: random raw value, SHA-256 hex sent to Apple', () {
    final a = AppleAuthService.generateNonce();
    final b = AppleAuthService.generateNonce();
    expect(a.length, 32);
    expect(a, isNot(b));
    expect(
      AppleAuthService.sha256OfString('abc'),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });
}
