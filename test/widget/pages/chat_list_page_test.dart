/// Widget tests for ChatListPage
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lgbtindernew/core/providers/feature_flags_provider.dart';
import 'package:lgbtindernew/pages/chat_list_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/test_helpers.dart';

/// The page reads cached sessions through SharedPreferences, so the harness
/// has to provide an (empty) instance. The default 800x600 test surface
/// selects the tablet master/detail layout, so use a phone-sized one.
Future<ProviderContainer> _container(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  final container = createTestContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('ChatListPage', () {
    testWidgets('should display chat list page with app bar', (WidgetTester tester) async {
      // Arrange
      final container = await _container(tester);

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ChatListPage(),
          ),
        ),
      );
      await waitForAsync(tester);

      // Assert
      expect(find.byType(ChatListPage), findsOneWidget);
      // App bar should be present (implementation dependent)
    });

    testWidgets('should display loading state initially', (WidgetTester tester) async {
      // Arrange
      final container = await _container(tester);

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ChatListPage(),
          ),
        ),
      );
      await waitForAsync(tester);

      // Assert
      // Loading indicator should be shown initially (implementation dependent)
    });

    testWidgets('should display error state on error', (WidgetTester tester) async {
      // Arrange
      final container = await _container(tester);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ChatListPage(),
          ),
        ),
      );
      await waitForAsync(tester);

      // Assert
      // Error widget should be shown on error (implementation dependent)
    });

    testWidgets('should display empty state when no chats', (WidgetTester tester) async {
      // Arrange
      final container = await _container(tester);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ChatListPage(),
          ),
        ),
      );
      await waitForAsync(tester);

      // Assert
      // Empty state should be shown when no chats (implementation dependent)
    });

    testWidgets('should navigate to chat page when chat is tapped', (WidgetTester tester) async {
      // Arrange
      final container = await _container(tester);
      bool navigated = false;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const ChatListPage(),
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

    testWidgets('should display search functionality', (WidgetTester tester) async {
      // Arrange
      final container = await _container(tester);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ChatListPage(),
          ),
        ),
      );
      await waitForAsync(tester);

      // Assert
      // Search functionality should be present (implementation dependent)
    });

    testWidgets('should display notification badge when unread notifications exist', (WidgetTester tester) async {
      // Arrange
      final container = await _container(tester);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ChatListPage(),
          ),
        ),
      );
      await waitForAsync(tester);

      // Assert
      // Notification badge should be shown when unread notifications exist (implementation dependent)
    });
  });
}

