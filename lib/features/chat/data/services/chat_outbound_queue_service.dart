import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../local/chat_local_repository.dart';

/// A text message waiting to be sent when connectivity returns.
class QueuedChatMessage {
  final String clientId;
  final int receiverId;
  final int senderId;
  final String message;
  final String messageType;
  final DateTime createdAt;

  const QueuedChatMessage({
    required this.clientId,
    required this.receiverId,
    required this.senderId,
    required this.message,
    this.messageType = 'text',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'clientId': clientId,
        'receiverId': receiverId,
        'senderId': senderId,
        'message': message,
        'messageType': messageType,
        'createdAt': createdAt.toIso8601String(),
      };

  factory QueuedChatMessage.fromJson(Map<String, dynamic> json) {
    return QueuedChatMessage(
      clientId: json['clientId'] as String,
      receiverId: json['receiverId'] as int,
      senderId: json['senderId'] as int,
      message: json['message'] as String,
      messageType: json['messageType'] as String? ?? 'text',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Persists outbound chat messages in SQLite until they can be sent.
class ChatOutboundQueueService {
  static const int _maxQueueSize = 50;

  ChatOutboundQueueService(this._localRepo);

  final ChatLocalRepository _localRepo;

  Future<List<QueuedChatMessage>> getPending() async {
    try {
      return await _localRepo.getOutboxEntries();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to read chat outbound queue: $e');
      }
      return [];
    }
  }

  Future<void> enqueue(QueuedChatMessage message) async {
    final queue = await getPending();
    queue.removeWhere((m) => m.clientId == message.clientId);
    queue.add(message);

    while (queue.length > _maxQueueSize) {
      queue.removeAt(0);
    }

    await _localRepo.clearOutbox();
    for (final item in queue) {
      await _localRepo.enqueueOutbox(item);
    }

    if (kDebugMode) {
      debugPrint('📦 Queued chat message for user ${message.receiverId}');
    }
  }

  Future<void> remove(String clientId) async {
    await _localRepo.removeOutboxEntry(clientId);
  }

  Future<void> clear() async {
    await _localRepo.clearOutbox();
  }
}

/// Legacy SharedPreferences key kept for one-time migration only.
const chatOutboundLegacyStorageKey = 'chat_outbound_message_queue';

String encodeOutboundQueueForMigration(List<QueuedChatMessage> queue) {
  return jsonEncode(queue.map((m) => m.toJson()).toList());
}
