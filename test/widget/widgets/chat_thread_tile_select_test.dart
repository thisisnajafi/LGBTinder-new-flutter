import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/providers/chat_thread_providers.dart';
import 'package:lgbtindernew/features/chat/utils/chat_timeline_slots.dart';
import 'package:lgbtindernew/features/chat/utils/chat_unread_separator.dart';
import 'package:lgbtindernew/widgets/chat/chat_date_badge.dart';

void main() {
  test('delivery patch keeps the same structural slots', () {
    final original = [
      {'id': 1, 'client_id': 'c1', 'text': 'hi', 'is_sent': true},
      {'id': 2, 'client_id': 'c2', 'text': 'yo', 'is_sent': false},
    ];
    final patched = [
      original[0],
      {...original[1], 'is_read': true, 'is_delivered': true},
    ];
    List<ChatTimelineSlot> slotsOf(List<Map<String, dynamic>> rows) {
      return ChatTimelineSlots.build(
        decoratedRows: ChatUnreadSeparator.insert(
          items: ChatDateBadgeInserter.wrap(rows),
          unreadCount: 0,
        ),
      );
    }

    expect(slotsOf(patched), slotsOf(original));
    expect(ChatTimelineSlots.rowKey(original[0]), 'c-c1');
    expect(ChatTimelineSlots.rowKey(original[1]), 'c-c2');
  });

  testWidgets('row select rebuilds only the patched tile', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final firstBuilds = ValueNotifier<int>(0);
    final secondBuilds = ValueNotifier<int>(0);
    addTearDown(firstBuilds.dispose);
    addTearDown(secondBuilds.dispose);

    final first = {'id': 1, 'client_id': 'c1', 'text': 'hi', 'is_sent': true};
    final second = {'id': 2, 'client_id': 'c2', 'text': 'yo', 'is_sent': false};

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Column(
            children: [
              _RowProbe(
                peerUserId: 7,
                rowKey: 'c-c1',
                builds: firstBuilds,
              ),
              _RowProbe(
                peerUserId: 7,
                rowKey: 'c-c2',
                builds: secondBuilds,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(firstBuilds.value, 1);
    expect(secondBuilds.value, 1);

    container.read(chatThreadMessagesProvider(7).notifier).setRows([
      first,
      second,
    ]);
    await tester.pump();
    expect(firstBuilds.value, 2);
    expect(secondBuilds.value, 2);

    container.read(chatTypingUsersProvider.notifier).setTyping(7, true);
    await tester.pump();
    expect(firstBuilds.value, 2);
    expect(secondBuilds.value, 2);

    container.read(chatComposerProvider(7).notifier).beginReply(
          messageId: 1,
          text: 'hi',
          type: 'text',
          name: 'Sam',
        );
    await tester.pump();
    expect(firstBuilds.value, 2);
    expect(secondBuilds.value, 2);

    container.read(chatThreadMessagesProvider(7).notifier).replaceAt(
          1,
          {...second, 'is_read': true},
        );
    await tester.pump();
    expect(firstBuilds.value, 2);
    expect(secondBuilds.value, 3);
  });

  testWidgets('chrome select ignores a row body patch', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    var chromeBuilds = 0;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              final chrome = ref.watch(
                chatThreadMessagesProvider(7).select(
                  (s) => ChatThreadChrome(
                    isLoading: s.isLoading,
                    hasError: s.hasError,
                    errorMessage: s.errorMessage,
                    isEmpty: s.rows.isEmpty,
                    isLoadingMore: s.isLoadingMore,
                    loadMoreFailed: s.loadMoreFailed,
                  ),
                ),
              );
              chromeBuilds++;
              return Text('empty ${chrome.isEmpty} loading ${chrome.isLoading}');
            },
          ),
        ),
      ),
    );
    await tester.pump();
    expect(chromeBuilds, 1);

    container.read(chatThreadMessagesProvider(7).notifier).setRows([
      {'id': 1, 'client_id': 'c1', 'text': 'hi'},
    ]);
    await tester.pump();
    expect(chromeBuilds, 2);

    container.read(chatThreadMessagesProvider(7).notifier).replaceAt(
          0,
          {'id': 1, 'client_id': 'c1', 'text': 'hi', 'is_read': true},
        );
    await tester.pump();
    expect(chromeBuilds, 2);

    container.read(chatThreadMessagesProvider(7).notifier).patch(isLoading: true);
    await tester.pump();
    expect(chromeBuilds, 3);
  });
}

class _RowProbe extends ConsumerWidget {
  final int peerUserId;
  final String rowKey;
  final ValueNotifier<int> builds;

  const _RowProbe({
    required this.peerUserId,
    required this.rowKey,
    required this.builds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(chatMessageProvider(ChatThreadRowId(peerUserId, rowKey)));
    builds.value++;
    return const SizedBox(height: 1);
  }
}
