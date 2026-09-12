import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/utils/chat_message_sheet_actions.dart';

void main() {
  test('Copy is offered only on text messages', () {
    expect(ChatMessageSheetActions.canCopy('hello'), isTrue);
    expect(ChatMessageSheetActions.canCopy('  caption  '), isTrue);
    expect(ChatMessageSheetActions.canCopy(''), isFalse);
    expect(ChatMessageSheetActions.canCopy('   '), isFalse);
    expect(ChatMessageSheetActions.canCopy(null), isFalse);
    expect(
      ChatMessageSheetActions.canCopy('photo note', type: 'image'),
      isFalse,
    );
    expect(ChatMessageSheetActions.canCopy('', type: 'image'), isFalse);
    expect(ChatMessageSheetActions.canCopy(null, type: 'voice'), isFalse);
    expect(ChatMessageSheetActions.canCopy('ignored', type: 'voice'), isFalse);
    expect(ChatMessageSheetActions.canCopy('clip', type: 'sticker'), isFalse);
    expect(ChatMessageSheetActions.canCopy('note', type: 'video'), isFalse);
    expect(
      ChatMessageSheetActions.canCopy('card', type: 'profile_link'),
      isFalse,
    );
  });

  test('Report is offered only on others’ messages', () {
    expect(ChatMessageSheetActions.canReport(isSent: false), isTrue);
    expect(ChatMessageSheetActions.canReport(isSent: true), isFalse);
  });

  test('Delete is offered only on own persisted messages', () {
    expect(
      ChatMessageSheetActions.canDelete(
        isSent: true,
        messageId: 12,
        isDeleted: false,
      ),
      isTrue,
    );
    expect(
      ChatMessageSheetActions.canDelete(
        isSent: false,
        messageId: 12,
        isDeleted: false,
      ),
      isFalse,
    );
    expect(
      ChatMessageSheetActions.canDelete(isSent: true, messageId: 0),
      isFalse,
    );
    expect(
      ChatMessageSheetActions.canDelete(
        isSent: true,
        messageId: 12,
        isDeleted: true,
      ),
      isFalse,
    );
  });

  test('Delete for everyone is only own messages inside 24h', () {
    final now = DateTime.utc(2026, 9, 12, 12);
    expect(
      ChatMessageSheetActions.canDeleteForEveryone(
        isSent: true,
        createdAt: now.subtract(const Duration(hours: 23)),
        now: now,
      ),
      isTrue,
    );
    expect(
      ChatMessageSheetActions.canDeleteForEveryone(
        isSent: true,
        createdAt: now.subtract(const Duration(hours: 25)),
        now: now,
      ),
      isFalse,
    );
    expect(
      ChatMessageSheetActions.canDeleteForEveryone(
        isSent: false,
        createdAt: now,
        now: now,
      ),
      isFalse,
    );
  });

  test('Forward is offered on persisted non-secret messages', () {
    expect(
      ChatMessageSheetActions.canForward(messageId: 12, type: 'text'),
      isTrue,
    );
    expect(
      ChatMessageSheetActions.canForward(messageId: 12, type: 'image'),
      isTrue,
    );
    expect(
      ChatMessageSheetActions.canForward(messageId: 12, type: 'voice'),
      isTrue,
    );
    expect(
      ChatMessageSheetActions.canForward(messageId: 0, type: 'text'),
      isFalse,
    );
    expect(
      ChatMessageSheetActions.canForward(
        messageId: 12,
        type: 'text',
        isDeleted: true,
      ),
      isFalse,
    );
    expect(
      ChatMessageSheetActions.canForward(
        messageId: 12,
        type: 'text',
        isExpired: true,
      ),
      isFalse,
    );
    expect(
      ChatMessageSheetActions.canForward(
        messageId: 12,
        type: 'disappearing_image',
      ),
      isFalse,
    );
    expect(
      ChatMessageSheetActions.canForward(messageId: 12, type: 'system'),
      isFalse,
    );
    expect(
      ChatMessageSheetActions.canForward(
        messageId: 12,
        type: 'text',
        isLocked: true,
      ),
      isFalse,
    );
  });

  test('React is offered only on persisted unexpired messages', () {
    expect(
      ChatMessageSheetActions.canReact(messageId: 12, isExpired: false),
      isTrue,
    );
    expect(
      ChatMessageSheetActions.canReact(messageId: 0, isExpired: false),
      isFalse,
    );
    expect(
      ChatMessageSheetActions.canReact(messageId: 12, isExpired: true),
      isFalse,
    );
  });

  test('Pin is offered on persisted non-secret messages', () {
    expect(
      ChatMessageSheetActions.canPin(messageId: 12, type: 'text'),
      isTrue,
    );
    expect(
      ChatMessageSheetActions.canPin(messageId: 12, type: 'image'),
      isTrue,
    );
    expect(
      ChatMessageSheetActions.canPin(messageId: 0, type: 'text'),
      isFalse,
    );
    expect(
      ChatMessageSheetActions.canPin(
        messageId: 12,
        type: 'text',
        isDeleted: true,
      ),
      isFalse,
    );
    expect(
      ChatMessageSheetActions.canPin(messageId: 12, type: 'system'),
      isFalse,
    );
    expect(
      ChatMessageSheetActions.canPin(
        messageId: 12,
        type: 'disappearing_image',
      ),
      isFalse,
    );
  });

  test('Quick-react row is the six spec emojis', () {
    expect(ChatMessageSheetActions.reactEmojis, [
      '❤️',
      '😂',
      '😮',
      '😢',
      '😡',
      '👍',
    ]);
  });

  test('Edit stays limited to own unexpired persisted text', () {
    expect(
      ChatMessageSheetActions.canEdit(
        isSent: true,
        type: 'text',
        isExpired: false,
        messageId: 12,
      ),
      isTrue,
    );
    expect(
      ChatMessageSheetActions.canEdit(
        isSent: false,
        type: 'text',
        isExpired: false,
        messageId: 12,
      ),
      isFalse,
    );
    expect(
      ChatMessageSheetActions.canEdit(
        isSent: true,
        type: 'image',
        isExpired: false,
        messageId: 12,
      ),
      isFalse,
    );
    expect(
      ChatMessageSheetActions.canEdit(
        isSent: true,
        type: 'text',
        isExpired: true,
        messageId: 12,
      ),
      isFalse,
    );
    expect(
      ChatMessageSheetActions.canEdit(
        isSent: true,
        type: 'text',
        isExpired: false,
        messageId: 0,
      ),
      isFalse,
    );
  });

  test('Edit is rejected after 24 hours and shows remaining time', () {
    final sentAt = DateTime.utc(2026, 9, 12, 12);
    expect(ChatMessageSheetActions.editWindow, const Duration(hours: 24));
    expect(
      ChatMessageSheetActions.canEdit(
        isSent: true,
        type: 'text',
        isExpired: false,
        messageId: 12,
        createdAt: sentAt,
        now: sentAt.add(const Duration(hours: 23)),
      ),
      isTrue,
    );
    expect(
      ChatMessageSheetActions.editActionSubtitle(
        createdAt: sentAt,
        now: sentAt.add(const Duration(hours: 5)),
      ),
      '19h left',
    );
    expect(
      ChatMessageSheetActions.editRemainingLabel(
        createdAt: sentAt,
        now: sentAt.add(const Duration(hours: 5)),
      ),
      '19h left',
    );
    expect(
      ChatMessageSheetActions.editingBarTitle(
        createdAt: sentAt,
        now: sentAt.add(const Duration(hours: 5)),
      ),
      'Editing · 19h left',
    );
    expect(
      ChatMessageSheetActions.canEdit(
        isSent: true,
        type: 'text',
        isExpired: false,
        messageId: 12,
        createdAt: sentAt,
        now: sentAt.add(const Duration(hours: 25)),
      ),
      isFalse,
    );
    expect(
      ChatMessageSheetActions.editActionSubtitle(
        createdAt: sentAt,
        now: sentAt.add(const Duration(hours: 25)),
      ),
      isNull,
    );
    expect(
      ChatMessageSheetActions.formatEditRemaining(const Duration(minutes: 40)),
      '40m left',
    );
    expect(
      ChatMessageSheetActions.formatEditRemaining(const Duration(seconds: 20)),
      '<1m left',
    );
  });
}
