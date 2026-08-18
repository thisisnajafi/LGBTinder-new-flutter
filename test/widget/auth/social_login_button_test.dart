import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/auth/presentation/widgets/social_login_button.dart';

void main() {
  testWidgets('renders Continue with Google', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SocialLoginButton(),
          ),
        ),
      ),
    );

    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
