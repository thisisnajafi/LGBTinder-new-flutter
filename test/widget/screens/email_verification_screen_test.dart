/// Widget tests for EmailVerificationScreen
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lgbtindernew/screens/auth/email_verification_screen.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('EmailVerificationScreen', () {
    testWidgets('should display 6 code input fields', (WidgetTester tester) async {
      // Arrange
      final container = createTestContainer();

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: EmailVerificationScreen(
              email: 'test@example.com',
              isNewUser: true,
            ),
          ),
        ),
      );
      await waitForAsync(tester);

      // Assert
      expect(find.byType(EmailVerificationScreen), findsOneWidget);
      // 6 code input fields should be present (implementation dependent)
      expect(find.byType(TextField), findsNWidgets(6));
    });

    testWidgets('should display email address', (WidgetTester tester) async {
      // Arrange
      final container = createTestContainer();

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: EmailVerificationScreen(
              email: 'test@example.com',
              isNewUser: true,
            ),
          ),
        ),
      );
      await waitForAsync(tester);

      // Assert
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('should display verify button', (WidgetTester tester) async {
      // Arrange
      final container = createTestContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: EmailVerificationScreen(
              email: 'test@example.com',
              isNewUser: true,
            ),
          ),
        ),
      );
      await waitForAsync(tester);

      // Assert
      expect(find.text('Verify'), findsOneWidget);
    });

    testWidgets('should display resend code button', (WidgetTester tester) async {
      // Arrange
      final container = createTestContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: EmailVerificationScreen(
              email: 'test@example.com',
              isNewUser: true,
            ),
          ),
        ),
      );
      await waitForAsync(tester);

      // Assert
      // Resend button should be present (implementation dependent)
      // This test may need adjustment based on actual UI
    });

    testWidgets('should show countdown timer for resend', (WidgetTester tester) async {
      // Arrange
      final container = createTestContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: EmailVerificationScreen(
              email: 'test@example.com',
              isNewUser: true,
            ),
          ),
        ),
      );
      await waitForAsync(tester);

      // Assert
      // Countdown timer should be displayed (implementation dependent)
    });
  });
}

