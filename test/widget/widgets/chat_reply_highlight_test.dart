import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/features/chat/providers/chat_thread_providers.dart';
import 'package:lgbtindernew/widgets/chat/chat_reply_highlight.dart';

void main() {
  test('highlight hold is 800ms', () {
    expect(
      AppAnimations.chatReplyHighlightHold,
      const Duration(milliseconds: 800),
    );
  });

  testWidgets('flash clears after the hold duration', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              final id = ref.watch(chatReplyHighlightProvider(3));
              return Text('id ${id ?? 'none'}');
            },
          ),
        ),
      ),
    );

    container.read(chatReplyHighlightProvider(3).notifier).flash(
          42,
          hold: AppAnimations.chatReplyHighlightHold,
        );
    await tester.pump();
    expect(container.read(chatReplyHighlightProvider(3)), 42);

    await tester.pump(const Duration(milliseconds: 799));
    expect(container.read(chatReplyHighlightProvider(3)), 42);

    await tester.pump(const Duration(milliseconds: 1));
    expect(container.read(chatReplyHighlightProvider(3)), isNull);
  });

  testWidgets('select only rebuilds the matching row', (tester) async {
    var hit42 = 0;
    var miss = 0;
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Column(
            children: [
              Consumer(
                builder: (context, ref, _) {
                  final on = ref.watch(
                    chatReplyHighlightProvider(3).select((id) => id == 42),
                  );
                  hit42++;
                  return Text('hit $on');
                },
              ),
              Consumer(
                builder: (context, ref, _) {
                  final on = ref.watch(
                    chatReplyHighlightProvider(3).select((id) => id == 7),
                  );
                  miss++;
                  return Text('miss $on');
                },
              ),
            ],
          ),
        ),
      ),
    );

    expect(hit42, 1);
    expect(miss, 1);

    container.read(chatReplyHighlightProvider(3).notifier).flash(
          42,
          hold: AppAnimations.chatReplyHighlightHold,
        );
    await tester.pump();
    expect(hit42, 2);
    expect(miss, 1);

    await tester.pump(AppAnimations.chatReplyHighlightHold);
    expect(container.read(chatReplyHighlightProvider(3)), isNull);
  });

  testWidgets('Reduce Motion skips the highlight fade', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          );
        },
        home: const ChatReplyHighlight(
          highlighted: true,
          child: SizedBox(width: 24, height: 24),
        ),
      ),
    );

    final box = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('chat-reply-highlight')),
    );
    expect(box.duration, Duration.zero);
  });
}
