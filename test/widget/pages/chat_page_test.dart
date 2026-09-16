/// Widget tests for ChatPage
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lgbtindernew/features/chat/providers/chat_list_preview_provider.dart';
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
      await _unmountChat(tester);
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

      expect(find.byType(MessageInput), findsOneWidget);
      expect(
        find.textContaining('Say hi to Test User'),
        findsOneWidget,
      );
      await _unmountChat(tester);
    });

    testWidgets('opening a thread with unread does not crash the tree', (
      WidgetTester tester,
    ) async {
      final container = createTestContainer();
      container.read(chatListPreviewProvider.notifier).seedFromMaps([
        {
          'id': 123,
          'chat_id': 123,
          'name': 'Test User',
          'unread_count': 3,
        },
      ]);

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
      await tester.pump();
      await waitForAsync(tester);

      expect(find.text('Something went wrong'), findsNothing);
      expect(find.byType(ChatPage), findsOneWidget);
      expect(
        container.read(chatListPreviewProvider).items.single.unreadCount,
        0,
      );
      await _unmountChat(tester);
      container.dispose();
    });
  });
}

Future<void> _unmountChat(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  // CHAT-PERF-005: conversation close is debounced 900ms.
  await tester.pump(const Duration(milliseconds: 950));
}
