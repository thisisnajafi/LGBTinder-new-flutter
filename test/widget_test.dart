/// Basic smoke test for the app
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lgbtindernew/main.dart';
import 'helpers/test_helpers.dart';

void main() {
  testWidgets('App should build without errors', (WidgetTester tester) async {
    // Arrange
    final container = createTestContainer();

    // Act
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MyApp(),
      ),
    );
    await waitForAsync(tester);

    // Assert
    // If we get here without errors, the app built successfully
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
