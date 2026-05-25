import 'package:flutter/material.dart';

import '../../features/chat/data/models/message_delivery_status.dart';
import 'message_bubble.dart';

/// Single chat row with repaint isolation (PERF-PAGE-CHAT-004).
class ChatMessageListTile extends StatelessWidget {
  final Map<String, dynamic> message;
  final MessageDeliveryStatus? deliveryStatus;
  final VoidCallback? onRetry;
  final VoidCallback? onSelfDestructTap;

  const ChatMessageListTile({
    super.key,
    required this.message,
    this.deliveryStatus,
    this.onRetry,
    this.onSelfDestructTap,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: MessageBubble(
        key: ValueKey(
          message['client_id'] ??
              message['id'] ??
              message['timestamp']?.toString(),
        ),
        message: message['text'] ?? '',
        isSent: message['is_sent'] ?? false,
        timestamp: message['timestamp'],
        isRead: message['is_read'] ?? false,
        deliveryStatus: deliveryStatus ?? MessageDeliveryStatus.sent,
        onRetry: onRetry,
        messageType: message['type'] ?? 'text',
        remainingSeconds: message['remaining_seconds'],
        mediaUrl: message['attachment_url']?.toString(),
        mediaDuration: message['media_duration'] is int
            ? message['media_duration'] as int
            : int.tryParse(message['media_duration']?.toString() ?? ''),
        isLocked: message['is_locked'] == true,
        isBlurred: message['is_blurred'] == true,
        profileCard: message['profile_card'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(message['profile_card'] as Map)
            : null,
        heroTag: message['hero_tag']?.toString(),
        messageId: message['id'] is int ? message['id'] as int : 0,
        isExpired: message['is_expired'] == true,
        viewedAt: message['viewed_at'] is DateTime
            ? message['viewed_at'] as DateTime
            : null,
        onSelfDestructTap: onSelfDestructTap,
      ),
    );
  }
}
