import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/providers/chat_thread_providers.dart';

void main() {
  testWidgets('typing and viewport do not rebuild the message list',
      (tester) async {
    var listBuilds = 0;
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    final rows = ref.watch(
                      chatThreadMessagesProvider(7).select((s) => s.rows),
                    );
                    listBuilds++;
                    return Text('rows ${rows.length}');
                  },
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final typing = ref.watch(chatTypingUsersProvider);
                    return Text('typing ${typing.length}');
                  },
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final atBottom = ref.watch(isAtBottomProvider(7));
                    return Text('bottom $atBottom');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(listBuilds, 1);
    expect(find.text('rows 0'), findsOneWidget);

    container.read(chatTypingUsersProvider.notifier).setTyping(7, true);
    await tester.pump();
    expect(listBuilds, 1);
    expect(find.text('typing 1'), findsOneWidget);

    container.read(chatThreadViewportProvider(7).notifier).applyScroll(
          showFab: true,
          atBottom: false,
        );
    await tester.pump();
    expect(listBuilds, 1);
    expect(find.text('bottom false'), findsOneWidget);

    container.read(conversationReadStateProvider(7).notifier).markNow();
    await tester.pump();
    expect(listBuilds, 1);

    container.read(chatThreadMessagesProvider(7).notifier).setRows([
      {'id': 1, 'text': 'hi'},
    ]);
    await tester.pump();
    expect(listBuilds, 2);
    expect(find.text('rows 1'), findsOneWidget);

    container.read(chatThreadMessagesProvider(7).notifier).patch(isLoading: true);
    await tester.pump();
    expect(listBuilds, 2);

    container.read(chatComposerProvider(7).notifier).beginReply(
          messageId: 1,
          text: 'hi',
          type: 'text',
          name: 'Sam',
        );
    await tester.pump();
    expect(listBuilds, 2);
  });

  test('typingUsersProvider is the split map, not ChatState', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(typingUsersProvider), isEmpty);
    container.read(chatTypingUsersProvider.notifier).setTyping(3, true);
    expect(container.read(typingUsersProvider)[3], isTrue);
    container.read(chatTypingUsersProvider.notifier).setTyping(3, false);
    expect(container.read(typingUsersProvider).containsKey(3), isFalse);
  });
}
