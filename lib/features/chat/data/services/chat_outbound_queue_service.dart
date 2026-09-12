import 'package:lgbtindernew/core/services/app_logger.dart';
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
  static const String logTag = 'ChatOutbox';
  static const int defaultMaxQueueSize = 50;

  ChatOutboundQueueService(
    this._localRepo, {
    this.maxQueueSize = defaultMaxQueueSize,
  });

  final ChatLocalRepository _localRepo;
  final int maxQueueSize;

  Future<List<QueuedChatMessage>> getPending() async {
    try {
      return await _localRepo.getOutboxEntries();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to read chat outbound queue',
        tag: logTag,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  Future<void> enqueue(QueuedChatMessage message) async {
    try {
      final queue = await getPending();
      final isNew = queue.every((item) => item.clientId != message.clientId);
      if (isNew && queue.length >= maxQueueSize) {
        final oldest = queue.first;
        await _localRepo.removeOutboxEntry(oldest.clientId);
        AppLogger.warning(
          'Chat outbox full; dropped oldest ${oldest.clientId}',
          tag: logTag,
        );
      }

      await _localRepo.enqueueOutbox(message);
      await _localRepo.trimOutboxToMax(maxQueueSize);
      AppLogger.info(
        'Queued chat message for user ${message.receiverId}',
        tag: logTag,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to enqueue chat outbox',
        tag: logTag,
        error: e,
        stackTrace: stackTrace,
      );
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
