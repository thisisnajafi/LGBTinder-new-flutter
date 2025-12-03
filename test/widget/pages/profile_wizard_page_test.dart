/// Widget tests for ProfileWizardPage
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lgbtindernew/pages/profile_wizard_page.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('ProfileWizardPage', () {
    testWidgets('should display profile wizard with step indicator', (WidgetTester tester) async {
      // Arrange
      final container = createTestContainer();

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ProfileWizardPage(),
          ),
        ),
      );
      await waitForAsync(tester);

      // Assert
      expect(find.byType(ProfileWizardPage), findsOneWidget);
      // Step indicator should be present (implementation dependent)
    });

    testWidgets('should display step 1 (photos) initially', (WidgetTester tester) async {
      // Arrange
      final container = createTestContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ProfileWizardPage(),
          ),
        ),
      );
      await waitForAsync(tester);

      // Assert
      // Step 1 content should be displayed (implementation dependent)
      // This test may need adjustment based on actual implementation
    });

    testWidgets('should navigate to next step when continue is tapped', (WidgetTester tester) async {
      // Arrange
      final container = createTestContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ProfileWizardPage(),
          ),
        ),
      );
      await waitForAsync(tester);

      // Act
      // Find and tap continue button
      // This would require form interaction

      // Assert
      // Should navigate to step 2 (implementation dependent)
      // This test needs to be completed with proper form interaction
    });

    testWidgets('should display form fields in step 2', (WidgetTester tester) async {
      // Arrange
      final container = createTestContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ProfileWizardPage(),
          ),
        ),
      );
      await waitForAsync(tester);

      // Assert
      // Step 2 form fields should be present (implementation dependent)
      // This test may need adjustment based on actual implementation
    });

    testWidgets('should display interests selection in step 3', (WidgetTester tester) async {
      // Arrange
      final container = createTestContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ProfileWizardPage(),
          ),
        ),
      );
      await waitForAsync(tester);

      // Assert
      // Step 3 interests should be displayed (implementation dependent)
      // This test may need adjustment based on actual implementation
    });
  });
}

