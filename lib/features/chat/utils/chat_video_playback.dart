import '../data/models/message_delivery_status.dart';
import 'chat_local_media.dart';

/// Whether a chat video thumbnail may open the full-screen player (CHAT-UX-007).
class ChatVideoPlayback {
  ChatVideoPlayback._();

  static bool canOpen({
    required String? mediaUrl,
    MessageDeliveryStatus deliveryStatus = MessageDeliveryStatus.sent,
  }) {
    if (mediaUrl == null) return false;
    final url = mediaUrl.trim();
    if (url.isEmpty) return false;
    if (deliveryStatus == MessageDeliveryStatus.sending ||
        deliveryStatus == MessageDeliveryStatus.failed) {
      return false;
    }
    if (ChatLocalMedia.isLocalPath(url)) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }
}
