import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/providers/subscription_provider.dart';
import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/features/chat/providers/user_presence_cache_provider.dart';
import 'package:lgbtindernew/features/chat/providers/chat_thread_providers.dart';
import 'package:lgbtindernew/features/chat/utils/chat_presence_copy.dart';
import 'package:lgbtindernew/shared/services/pusher_websocket_service.dart';
import 'package:lgbtindernew/widgets/chat/chat_list_item.dart';
import 'package:lgbtindernew/widgets/chat/chat_online_dot.dart';
import 'package:lgbtindernew/widgets/chat/typing_indicator.dart';

void main() {
  test('online pip uses the documented 10px #22C55E fill', () {
    expect(ChatOnlineDot.fill, const Color(0xFF22C55E));
    expect(ChatOnlineDot.diameter, 10);
    expect(ChatOnlineDot.ringWidth, 2);
  });

  testWidgets('online row shows the green pip', (tester) async {
    await tester.pumpWidget(_harness(isOnline: true, lastMessage: 'hey'));
    await tester.pump();

    expect(find.byType(ChatOnlineDot), findsOneWidget);
    expect(find.byKey(ChatOnlineDot.dotKey), findsOneWidget);
  });

  testWidgets('offline empty row shows last-seen copy without a pip',
      (tester) async {
    await tester.pumpWidget(
      _harness(
        isOnline: false,
        lastMessage: '',
        lastSeenAt: DateTime.now().subtract(const Duration(minutes: 8)),
      ),
    );
    await tester.pump();

    expect(find.byType(ChatOnlineDot), findsNothing);
    expect(find.text(ChatPresenceCopy.activeRecently), findsOneWidget);
    expect(find.text(ChatPresenceCopy.noMessagesYet), findsNothing);
  });

  testWidgets('presence cache turns the pip on without a list refresh',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        isPremiumProvider.overrideWith((ref) => true),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _app(
          const ChatListItem(
            userId: 42,
            name: 'Alex',
            lastMessage: 'hey',
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(ChatOnlineDot), findsNothing);

    container.read(userPresenceCacheProvider.notifier).apply(
          UserPresenceEvent(
            userId: 42,
            isOnline: true,
            timestamp: DateTime(2026, 9, 12, 15),
          ),
        );
    await tester.pump();

    expect(find.byType(ChatOnlineDot), findsOneWidget);
  });

  testWidgets('pinned row shows a bookmark', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isPremiumProvider.overrideWith((ref) => true),
        ],
        child: _app(
          const ChatListItem(
            userId: 7,
            name: 'Alex',
            lastMessage: 'hey',
            isPinned: true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(ChatListItem.pinIconKey), findsOneWidget);
  });

  testWidgets('typing cache updates the row without a parent refresh',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        isPremiumProvider.overrideWith((ref) => true),
      ],
    );
    addTearDown(container.dispose);
    var parentBuilds = 0;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _app(
          Consumer(
            builder: (context, ref, _) {
              parentBuilds++;
              return const ChatListItem(
                userId: 42,
                name: 'Alex',
                lastMessage: 'hey',
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(TypingIndicator), findsNothing);
    expect(parentBuilds, 1);

    container.read(chatTypingUsersProvider.notifier).setTyping(42, true);
    await tester.pump();

    expect(find.byType(TypingIndicator), findsOneWidget);
    expect(parentBuilds, 1);
  });
}

Widget _harness({
  required bool isOnline,
  String? lastMessage,
  DateTime? lastSeenAt,
}) {
  return ProviderScope(
    overrides: [
      isPremiumProvider.overrideWith((ref) => true),
    ],
    child: _app(
      ChatListItem(
        userId: 7,
        name: 'Alex',
        isOnline: isOnline,
        lastMessage: lastMessage,
        lastSeenAt: lastSeenAt,
      ),
    ),
  );
}

Widget _app(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    builder: (context, nested) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: nested!,
      );
    },
    home: Scaffold(body: child),
  );
}
