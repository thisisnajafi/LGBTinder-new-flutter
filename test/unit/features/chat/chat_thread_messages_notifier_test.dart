import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lgbtindernew/features/chat/providers/chat_thread_providers.dart';

void main() {
  test('setRows and replaceAt update rows without rebuilding the index twice', () {
    final notifier = ChatThreadMessagesNotifier();
    notifier.setRows([
      {'id': 1, 'client_id': 'a', 'text': 'hi'},
      {'id': 2, 'client_id': 'b', 'text': 'yo'},
    ]);
    notifier.ensureIndex();
    expect(notifier.index.byServerId(2), 1);

    notifier.replaceAt(1, {'id': 2, 'client_id': 'b', 'text': 'yo!', 'is_edited': true});
    expect(notifier.state.rows[1]['text'], 'yo!');
    expect(notifier.index.byServerId(2), 1);

    notifier.patch(isLoading: true);
    expect(notifier.state.isLoading, isTrue);
    expect(notifier.state.rows.length, 2);

    notifier.mapRows((row) {
      if (row['id'] == 1) return {...row, 'is_read': true};
      return row;
    });
    expect(notifier.state.rows[0]['is_read'], isTrue);
  });

  test('chatMessageProvider returns the matching row map', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(chatThreadMessagesProvider(7).notifier).setRows([
      {'id': 1, 'client_id': 'c1', 'text': 'hi'},
      {'id': 2, 'client_id': 'c2', 'text': 'yo'},
    ]);
    expect(
      container.read(chatMessageProvider(const ChatThreadRowId(7, 'c-c1')))?['text'],
      'hi',
    );
    expect(
      container.read(chatMessageProvider(const ChatThreadRowId(7, 'c-c2')))?['id'],
      2,
    );
  });

  test('composer reply and edit are exclusive', () {
    final composer = ChatComposerNotifier();
    composer.beginReply(
      messageId: 9,
      text: 'hello',
      type: 'text',
      name: 'Sam',
    );
    expect(composer.state.replyMessageId, 9);
    expect(composer.state.isEditing, isFalse);

    composer.beginEdit(messageId: 4, preview: 'edit me');
    expect(composer.state.isEditing, isTrue);
    expect(composer.state.replyMessageId, isNull);
    expect(composer.state.editingPreview, 'edit me');
    expect(composer.state.editingCreatedAt, isNull);

    composer.beginEdit(
      messageId: 4,
      preview: 'edit me',
      createdAt: DateTime.utc(2026, 9, 12, 8),
    );
    expect(composer.state.editingCreatedAt, DateTime.utc(2026, 9, 12, 8));

    composer.clear();
    expect(composer.state.isEditing, isFalse);
    expect(composer.state.replyMessageId, isNull);
  });
}
