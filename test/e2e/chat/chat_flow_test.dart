import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/pages/chat_list_page.dart';
import 'package:lgbtindernew/pages/chat_page.dart';
import 'package:lgbtindernew/routes/app_router.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/app_bootstrap.dart';
import '../helpers/mock_services.dart';
import 'package:lgbtindernew/features/chat/data/services/chat_service.dart';
import 'package:lgbtindernew/features/chat/providers/chat_providers.dart';

class MockChatService extends Mock implements ChatService {}

/// Chat messaging flows (TEST-053 – TEST-063).
void main() {
  group('Chat list', () {
    // TEST-053
    testWidgets('TEST-053: chat list page renders', (tester) async {
      final chat = MockChatService();
      when(() => chat.getChats()).thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [chatServiceProvider.overrideWithValue(chat)],
          child: const MaterialApp(home: ChatListPage()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ChatListPage), findsOneWidget);
    });
  });

  group('Chat thread', () {
    // TEST-055
    testWidgets('TEST-055: chat page renders with user header', (tester) async {
      final chat = MockChatService();
      when(
        () => chat.getChatHistory(
          receiverId: any(named: 'receiverId'),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => []);
      when(() => chat.markAsRead(any())).thenAnswer((_) async {});
      when(() => chat.getPinnedMessagesCount(any())).thenAnswer((_) async => 0);
      when(() => chat.getPinnedMessages(any())).thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [chatServiceProvider.overrideWithValue(chat)],
          child: const MaterialApp(
            home: ChatPage(userId: 1, userName: 'Alex'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ChatPage), findsOneWidget);
      expect(find.text('Alex'), findsWidgets);
    });

    // TEST-063
    testWidgets('TEST-063: /chat without userId shows chat list via router', (tester) async {
      final storage = InMemoryTokenStorage()..seedAuthenticated();
      final chat = MockChatService();
      when(() => chat.getChats()).thenAnswer((_) async => []);

      await pumpE2eApp(
        tester,
        tokenStorage: storage,
        overrides: [chatServiceProvider.overrideWithValue(chat)],
      );
      await e2eGo(tester, AppRoutes.chat);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.byType(ChatListPage), findsOneWidget);
    });
  });
}
