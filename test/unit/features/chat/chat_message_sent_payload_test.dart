import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/data/models/message.dart';
import 'package:lgbtindernew/features/chat/utils/chat_message_sent_payload.dart';
import 'package:lgbtindernew/features/chat/utils/chat_optimistic.dart';

void main() {
  group('ChatMessageSentPayload', () {
    test('merges event sender into message json', () {
      final json = ChatMessageSentPayload.messageJson({
        'conversation_id': 9,
        'sender': {
          'id': 12,
          'display_name': 'Alex',
          'name': 'Alex',
          'avatar_url': 'https://cdn.example/alex.jpg',
        },
        'message': {
          'id': 44,
          'sender_id': 12,
          'receiver_id': 99,
          'message': 'Hi',
          'message_type': 'text',
          'client_id': '550e8400-e29b-41d4-a716-446655440000',
          'created_at': '2026-09-11T10:00:00Z',
        },
      });

      expect(json, isNotNull);
      expect(json!['conversation_id'], 9);
      expect(json['sender_name'], 'Alex');
      expect(json['sender_avatar_url'], 'https://cdn.example/alex.jpg');

      final message = Message.fromJson(json);
      expect(message.clientId, '550e8400-e29b-41d4-a716-446655440000');
      expect(message.metadata?['sender_name'], 'Alex');
      expect(message.metadata?['sender_avatar_url'], 'https://cdn.example/alex.jpg');
    });

    test('parses media reply and expiry fields used by Flutter bubbles', () {
      final message = Message.fromJson({
        'id': 50,
        'conversation_id': 3,
        'sender_id': 12,
        'receiver_id': 99,
        'message': '',
        'message_type': 'image',
        'media_url': 'https://cdn.example/photo.jpg',
        'media_thumbnail_url': 'https://cdn.example/thumb.jpg',
        'reply_to_message_id': 10,
        'reply_to_text': 'earlier',
        'reply_to_name': 'Sam',
        'expires_in_seconds': 15,
        'expires_at': '2026-09-11T10:00:15Z',
        'client_id': 'temp-1',
        'created_at': '2026-09-11T10:00:00Z',
      });

      expect(message.attachmentUrl, 'https://cdn.example/photo.jpg');
      expect(message.mediaThumbnailUrl, 'https://cdn.example/thumb.jpg');
      expect(message.replyToMessageId, 10);
      expect(message.replyToText, 'earlier');
      expect(message.replyToName, 'Sam');
      expect(message.expiresInSeconds, 15);
      expect(message.clientId, 'temp-1');
    });
  });

  group('duplicate ingest', () {
    test('same server id is not a second row', () {
      expect(ChatOptimistic.sameMessageId(42, 42), isTrue);
      expect(ChatOptimistic.sameMessageId('42', 42), isTrue);
      expect(ChatOptimistic.sameMessageId(41, 42), isFalse);
    });
  });
}
