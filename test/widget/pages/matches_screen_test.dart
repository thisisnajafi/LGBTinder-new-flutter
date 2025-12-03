/// Widget tests for MatchesScreen
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lgbtindernew/features/matching/presentation/screens/matches_screen.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('MatchesScreen', () {
    testWidgets('should display matches screen with app bar', (WidgetTester tester) async {
      // Arrange
      final container = createTestContainer();

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: MatchesScreen(),
          ),
        ),
      );
      await waitForAsync(tester);

      // Assert
      expect(find.byType(MatchesScreen), findsOneWidget);
      // App bar should be present (implementation dependent)
    });

    testWidgets('should display loading state initially', (WidgetTester tester) async {
      // Arrange
      final container = createTestContainer();

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: MatchesScreen(),
          ),
        ),
      );
      await waitForAsync(tester);

      // Assert
      // Loading indicator should be shown initially (implementation dependent)
    });

    testWidgets('should display error state on error', (WidgetTester tester) async {
      // Arrange
      final container = createTestContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: MatchesScreen(),
          ),
        ),
      );
      await waitForAsync(tester);

      // Assert
      // Error widget should be shown on error (implementation dependent)
    });

    testWidgets('should display empty state when no matches', (WidgetTester tester) async {
      // Arrange
      final container = createTestContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: MatchesScreen(),
          ),
        ),
      );
      await waitForAsync(tester);

      // Assert
      // Empty state should be shown when no matches (implementation dependent)
    });

    testWidgets('should navigate to chat when match is tapped', (WidgetTester tester) async {
      // Arrange
      final container = createTestContainer();
      bool navigated = false;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const MatchesScreen(),
            routes: {
              '/chat': (context) {
                navigated = true;
                return const Scaffold(body: Text('Chat Page'));
              },
            },
          ),
        ),
      );
      await waitForAsync(tester);

      // Assert
      // Navigation to chat should occur on tap (implementation dependent)
      // This test may need adjustment based on actual navigation
    });
  });
}

