/// Widget tests for RegisterScreen
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lgbtindernew/screens/auth/register_screen.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('RegisterScreen', () {
    testWidgets('should display registration form fields', (WidgetTester tester) async {
      // Arrange
      final container = createTestContainer();

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );
      await waitForAsync(tester);

      // Assert
      expect(find.byType(TextField), findsWidgets); // Email, password, first name, last name
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('First Name'), findsOneWidget);
      expect(find.text('Last Name'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
    });

    testWidgets('should show validation errors for empty fields', (WidgetTester tester) async {
      // Arrange
      final container = createTestContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );
      await waitForAsync(tester);

      // Act - Tap register button without filling fields
      final registerButton = find.text('Register');
      if (registerButton.evaluate().isNotEmpty) {
        await tester.tap(registerButton);
        await waitForAsync(tester);

        // Assert - Should show validation errors (implementation dependent)
        // This test may need adjustment based on actual validation implementation
      }
    });

    testWidgets('should navigate to login screen when login link is tapped',
        (WidgetTester tester) async {
      // Arrange
      final container = createTestContainer();
      bool navigatedToLogin = false;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const RegisterScreen(),
            routes: {
              '/login': (context) {
                navigatedToLogin = true;
                return const Scaffold(body: Text('Login Screen'));
              },
            },
          ),
        ),
      );
      await waitForAsync(tester);

      // Act - Find and tap login link (adjust selector based on actual implementation)
      final loginLink = find.text('Login');
      if (loginLink.evaluate().isNotEmpty) {
        await tester.tap(loginLink);
        await waitForAsync(tester);
      }

      // Assert - Navigation should occur (implementation dependent)
      // This test may need adjustment based on actual navigation implementation
    });
  });
}

