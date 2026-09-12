import '../../../core/utils/app_date_time.dart';
import '../data/models/message.dart';
import 'chat_gallery_items.dart';
import 'chat_optimistic.dart';
import 'chat_visual_media.dart';

/// Maps a persisted [Message] to the thread row map used by the live list.
class ChatThreadRowMap {
  ChatThreadRowMap._();

  static Map<String, dynamic> fromMessage(
    Message message, {
    required int peerUserId,
    int? currentUserId,
    String? Function(int? replyToId)? replyPreview,
  }) {
    final isSent = currentUserId != null
        ? message.senderId == currentUserId
        : message.senderId != peerUserId;
    return {
      'id': message.id,
      'client_id': message.clientId,
      'text': message.message,
      'is_sent': isSent,
      'sender_id': message.senderId,
      'timestamp': AppDateTime.toLocal(message.createdAt),
      'is_read': message.isRead,
      'is_delivered': message.isDelivered || message.isRead,
      'is_edited': message.isEdited,
      'edited_at': message.editedAt,
      'type': message.messageType,
      'attachment_url':
          ChatVisualMedia.displayUrl(message) ??
          message.attachmentUrl ??
          message.mediaThumbnailUrl,
      'is_locked': message.isLocked,
      'is_blurred': message.isBlurred,
      'profile_card': message.profileCard,
      'hero_tag': ChatGalleryItem.heroTagFor(
        messageId: message.id,
        clientId: message.clientId,
      ),
      'delivery_status': message.deliveryStatus,
      'remaining_seconds': message.remainingSeconds,
      'is_expired': message.isExpired,
      'viewed_at': message.viewedAt,
      'secure_media_url': message.secureMediaUrl,
      'media_duration': message.mediaDuration,
      'conversation_id': message.conversationId,
      'expires_in_seconds': message.expiresInSeconds,
      'reply_to_message_id': message.replyToMessageId,
      'reply_to_text':
          message.replyToText ?? replyPreview?.call(message.replyToMessageId),
      'reply_to_name': message.replyToName,
      'forwarded_from_message_id': message.forwardedFromMessageId,
      'forwarded_from_user_id': message.forwardedFromUserId,
      'forwarded_from_name': message.forwardedFromName,
      'is_forwarded': message.isForwarded,
      'reactions': message.reactions,
      'my_reaction': message.myReaction,
      'is_deleted': message.isDeleted,
      'media_thumbnail_url': message.mediaThumbnailUrl,
      'media_width': message.mediaWidth,
      'media_height': message.mediaHeight,
    };
  }

  static String? replyPreviewIn(List<Map<String, dynamic>> rows, int? id) {
    if (id == null || id <= 0) return null;
    for (final msg in rows) {
      if (!ChatOptimistic.sameMessageId(msg['id'], id)) continue;
      final text = msg['text']?.toString() ?? '';
      if (text.isNotEmpty) return text;
      final type = msg['type']?.toString() ?? 'text';
      if (type == 'image') return 'Photo';
      if (type == 'voice') return 'Voice message';
      if (type == 'video') return 'Video';
    }
    return null;
  }
}
