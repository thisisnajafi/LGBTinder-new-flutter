// TESTING (Task 10.2.1): Flutter Unit Tests - Message Model
//
// Tests for:
// - JSON serialization/deserialization
// - Type safety
// - Edge cases (null values, invalid data)

import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/chat/data/models/message.dart';

void main() {
  group('Message Model Tests', () {
    test('fromJson creates Message from valid JSON', () {
      final json = {
        'id': 1,
        'sender_id': 100,
        'receiver_id': 200,
        'message': 'Hello, world!',
        'message_type': 'text',
        'created_at': '2025-12-13T10:00:00Z',
        'is_read': false,
        'is_deleted': false,
      };

      final message = Message.fromJson(json);

      expect(message.id, 1);
      expect(message.senderId, 100);
      expect(message.receiverId, 200);
      expect(message.message, 'Hello, world!');
      expect(message.messageType, 'text');
      expect(message.isRead, false);
      expect(message.isDeleted, false);
    });

    test('fromJson handles null values gracefully', () {
      final json = {
        'id': null,
        'sender_id': null,
        'receiver_id': null,
        'message': null,
        'created_at': null,
      };

      final message = Message.fromJson(json);

      // Should use defaults instead of crashing
      expect(message.id, 0);
      expect(message.senderId, 0);
      expect(message.receiverId, 0);
      expect(message.message, '');
    });

    test('fromJson handles string IDs (type conversion)', () {
      final json = {
        'id': '123',
        'sender_id': '100',
        'receiver_id': '200',
        'message': 'Test',
        'created_at': '2025-12-13T10:00:00Z',
      };

      final message = Message.fromJson(json);

      expect(message.id, 123);
      expect(message.senderId, 100);
      expect(message.receiverId, 200);
    });

    test('fromJson handles boolean as int (0/1)', () {
      final json = {
        'id': 1,
        'sender_id': 100,
        'receiver_id': 200,
        'message': 'Test',
        'created_at': '2025-12-13T10:00:00Z',
        'is_read': 1, // Backend sends 1 instead of true
        'is_deleted': 0, // Backend sends 0 instead of false
      };

      final message = Message.fromJson(json);

      expect(message.isRead, true);
      expect(message.isDeleted, false);
    });

    test('toJson converts Message to JSON', () {
      final message = Message(
        id: 1,
        senderId: 100,
        receiverId: 200,
        message: 'Hello',
        messageType: 'text',
        createdAt: DateTime.parse('2025-12-13T10:00:00Z'),
        isRead: true,
        isDeleted: false,
      );

      final json = message.toJson();

      expect(json['id'], 1);
      expect(json['sender_id'], 100);
      expect(json['receiver_id'], 200);
      expect(json['message'], 'Hello');
      expect(json['message_type'], 'text');
      expect(json['is_read'], true);
      expect(json['is_deleted'], false);
    });

    test('isValid returns true for valid message', () {
      final message = Message(
        id: 1,
        senderId: 100,
        receiverId: 200,
        message: 'Hello',
        createdAt: DateTime.now(),
      );

      expect(message.isValid, true);
    });

    test('isValid returns false for invalid message', () {
      final message = Message(
        id: 0, // Invalid ID
        senderId: 0, // Invalid sender
        receiverId: 0, // Invalid receiver
        message: '', // Empty message
        createdAt: DateTime.now(),
      );

      expect(message.isValid, false);
    });
  });
}

