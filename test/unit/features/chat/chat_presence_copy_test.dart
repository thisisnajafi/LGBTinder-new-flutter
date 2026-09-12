import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/utils/chat_presence_copy.dart';

void main() {
  final now = DateTime(2026, 9, 12, 14, 0);

  test('online empty preview is Active recently', () {
    expect(
      ChatPresenceCopy.emptyPreview(isOnline: true, now: now),
      ChatPresenceCopy.activeRecently,
    );
  });

  test('offline empty preview is Active recently within an hour', () {
    expect(
      ChatPresenceCopy.emptyPreview(
        isOnline: false,
        lastSeenAt: now.subtract(const Duration(minutes: 12)),
        now: now,
      ),
      ChatPresenceCopy.activeRecently,
    );
  });

  test('offline empty preview uses last seen via intl after a week', () {
    final label = ChatPresenceCopy.emptyPreview(
      isOnline: false,
      lastSeenAt: DateTime(2026, 8, 1, 9),
      now: now,
    );
    expect(label.startsWith('Last seen '), isTrue);
    expect(label.contains('m ago'), isFalse);
    expect(label.contains('h ago'), isFalse);
    expect(label.contains('d ago'), isFalse);
  });

  test('minutes-ago last seen has no extra package', () {
    expect(
      ChatPresenceCopy.lastSeenLabel(
        now.subtract(const Duration(minutes: 5)),
        now: now,
      ),
      'Last seen 5m ago',
    );
  });

  test('blank last message is treated as empty', () {
    expect(ChatPresenceCopy.hasLastMessage(null), isFalse);
    expect(ChatPresenceCopy.hasLastMessage('  '), isFalse);
    expect(ChatPresenceCopy.hasLastMessage('hey'), isTrue);
  });
}
