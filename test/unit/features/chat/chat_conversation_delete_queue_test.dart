import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/providers/chat_conversation_delete_queue.dart';

void main() {
  test('undo within 5 seconds cancels the delete', () {
    fakeAsync((async) {
      final queue = _RecordingDeleteQueue();
      final container = ProviderContainer(
        overrides: [
          chatConversationDeleteQueueProvider.overrideWith(() => queue),
        ],
      );
      addTearDown(container.dispose);

      container.read(chatConversationDeleteQueueProvider.notifier).schedule(9);
      async.elapse(const Duration(seconds: 4));
      expect(queue.commits, isEmpty);

      final undone =
          container.read(chatConversationDeleteQueueProvider.notifier).undo(9);
      expect(undone, isTrue);
      async.elapse(const Duration(seconds: 2));
      expect(queue.commits, isEmpty);
    });
  });

  test('delete commits after 5 seconds', () {
    fakeAsync((async) {
      final queue = _RecordingDeleteQueue();
      final container = ProviderContainer(
        overrides: [
          chatConversationDeleteQueueProvider.overrideWith(() => queue),
        ],
      );
      addTearDown(container.dispose);

      container.read(chatConversationDeleteQueueProvider.notifier).schedule(9);
      async.elapse(const Duration(seconds: 5));
      async.flushMicrotasks();
      expect(queue.commits, [9]);
    });
  });
}

class _RecordingDeleteQueue extends ChatConversationDeleteQueue {
  final List<int> commits = [];

  @override
  Future<void> commit(int userId) async {
    commits.add(userId);
    state = {
      for (final id in state)
        if (id != userId) id,
    };
  }
}
