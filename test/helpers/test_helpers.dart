/// Test helpers and utilities for testing
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Helper to create a ProviderContainer for testing
ProviderContainer createTestContainer({
  List<Override>? overrides,
}) {
  return ProviderContainer(
    overrides: overrides ?? [],
  );
}

/// Helper to create a WidgetTester with Riverpod support
Future<void> pumpWidgetWithProviders(
  WidgetTester tester,
  Widget widget, {
  List<Override>? overrides,
}) async {
  final container = createTestContainer(overrides: overrides);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: widget,
    ),
  );
}

/// Helper to wait for async operations
Future<void> waitForAsync(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

