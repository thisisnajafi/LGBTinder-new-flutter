import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/utils/chat_edited_apply.dart';

void main() {
  test('edit patch keeps the row and marks edited_at in place', () {
    final editedAt = DateTime.utc(2026, 9, 12, 12);
    final rows = ChatEditedApply.apply(
      messages: [
        {'id': 1, 'text': 'old', 'is_edited': false},
        {'id': 2, 'text': 'keep', 'is_edited': false},
      ],
      messageId: 1,
      content: 'new hello',
      editedAt: editedAt,
    );

    expect(rows, hasLength(2));
    expect(rows[0]['id'], 1);
    expect(rows[0]['text'], 'new hello');
    expect(rows[0]['is_edited'], isTrue);
    expect(rows[0]['edited_at'], editedAt);
    expect(rows[1]['text'], 'keep');
    expect(rows[1]['is_edited'], isFalse);
  });
}
