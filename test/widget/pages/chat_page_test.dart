/// Widget tests for ChatPage
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lgbtindernew/pages/chat_page.dart';
import 'package:lgbtindernew/widgets/chat/message_input.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('ChatPage', () {
    testWidgets('renders header, message input, and chat shell', (WidgetTester tester) async {
      final container = createTestContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: ChatPage(
              userId: 123,
              userName: 'Test User',
            ),
          ),
        ),
      );
      await waitForAsync(tester);

      expect(find.byType(ChatPage), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
      expect(find.byType(MessageInput), findsOneWidget);
    });

    testWidgets('shows empty messages state after load', (WidgetTester tester) async {
      final container = createTestContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: ChatPage(
              userId: 123,
              userName: 'Test User',
            ),
          ),
        ),
      );
      await waitForAsync(tester);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('No messages yet'), findsOneWidget);
    });
  });
}

