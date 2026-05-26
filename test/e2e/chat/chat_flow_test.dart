import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lgbtindernew/pages/chat_list_page.dart';
import 'package:lgbtindernew/pages/chat_page.dart';
import 'package:lgbtindernew/routes/app_router.dart';
import '../helpers/app_bootstrap.dart';
import 'chat_test_helpers.dart';

/// Chat messaging flows (TEST-053 – TEST-063).
void main() {
  setUpAll(registerChatFallbacks);

  group('Chat list', () {
    // TEST-053
    testWidgets('TEST-053: chat list page renders', (tester) async {
      final chat = MockChatService();
      stubChatList(chat);

      await tester.pumpWidget(
        ProviderScope(
          overrides: chatListOverrides(chat: chat),
          child: const MaterialApp(home: ChatListPage()),
        ),
      );
      await waitForChatListLoaded(tester);

      expect(find.byType(ChatListPage), findsOneWidget);
    });
  });

  group('Chat thread', () {
    // TEST-055
    testWidgets('TEST-055: chat page renders with user header', (tester) async {
      final chat = MockChatService();
      stubChatThread(chat, peerUserId: 1);

      await pumpChatPage(
        tester,
        chat: chat,
        userId: 1,
        userName: 'Alex',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ChatPage), findsOneWidget);
      expect(find.text('Alex'), findsWidgets);
    });

    // TEST-063
    testWidgets('TEST-063: /chat without userId shows chat list via router', (tester) async {
      final chat = MockChatService();
      stubChatList(chat);

      final router = GoRouter(
        initialLocation: AppRoutes.chat,
        routes: [
          GoRoute(
            path: AppRoutes.chat,
            builder: (context, state) {
              final userId = state.uri.queryParameters['userId'];
              if (userId == null) {
                return const ChatListPage();
              }
              return ChatPage(
                userId: int.parse(userId),
                userName: state.uri.queryParameters['userName'],
              );
            },
          ),
        ],
      );

      await pumpChatRouter(
        tester,
        router: router,
        overrides: chatListOverrides(chat: chat),
      );

      expect(find.byType(ChatListPage), findsOneWidget);
    });
  });
}
