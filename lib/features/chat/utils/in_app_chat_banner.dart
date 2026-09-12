import '../data/models/message.dart';
import 'chat_fcm_suppress.dart';
import 'chat_message_preview.dart';

class InAppChatBannerItem {
  const InAppChatBannerItem({
    required this.id,
    required this.peerUserId,
    required this.title,
    required this.body,
    this.avatarUrl,
    this.type = 'message',
    this.routeData = const <String, dynamic>{},
  });

  final String id;
  final int peerUserId;
  final String title;
  final String body;
  final String? avatarUrl;
  final String type;
  final Map<String, dynamic> routeData;

  bool get isChat => type == 'message';
}

/// Pure helpers for Telegram-style in-app chat banners (CHAT-NOTIF-004).
class InAppChatBannerPolicy {
  InAppChatBannerPolicy._();

  static const int maxStacked = 2;

  static bool shouldPresent({
    required bool isChatPayload,
    required bool suppressedOpenOrMuted,
    required bool isOwnMessage,
    required bool appForeground,
    bool isGenericPayload = false,
  }) {
    if (!appForeground) return false;
    if (isOwnMessage) return false;
    if (suppressedOpenOrMuted) return false;
    if (!isChatPayload && !isGenericPayload) return false;
    return true;
  }

  /// Newest last. Same peer is replaced. Cap at [maxStacked].
  static List<InAppChatBannerItem> push(
    List<InAppChatBannerItem> current,
    InAppChatBannerItem incoming,
  ) {
    final withoutPeer =
        current.where((item) => item.peerUserId != incoming.peerUserId).toList();
    final next = [...withoutPeer, incoming];
    if (next.length <= maxStacked) return next;
    return next.sublist(next.length - maxStacked);
  }

  static InAppChatBannerItem? fromFcm(
    Map<String, dynamic> data, {
    String? notificationTitle,
    String? notificationBody,
  }) {
    if (!ChatFcmSuppress.isChatPayload(data)) {
      return fromGenericFcm(
        data,
        notificationTitle: notificationTitle,
        notificationBody: notificationBody,
      );
    }
    final peer = ChatFcmSuppress.senderId(data);
    if (peer == null) return null;

    final messageId = data['message_id']?.toString().trim();
    final id = (messageId != null && messageId.isNotEmpty)
        ? messageId
        : 'peer_$peer';

    final hideSender = data['hide_sender']?.toString() == '1';
    final title = hideSender
        ? 'Someone'
        : _firstNonEmpty([
              data['user_name'],
              data['sender_name'],
              data['title'],
              data['headings'],
              notificationTitle,
            ]) ??
            'Someone';

    final redacted = data['content_redacted']?.toString() == '1';
    final body = redacted
        ? 'Sent you a message'
        : _firstNonEmpty([
              data['message_preview'],
              data['body'],
              data['message'],
              notificationBody,
            ]) ??
            'Message';

    final avatar = hideSender
        ? null
        : _firstNonEmpty([
            data['sender_avatar'],
            data['avatar_url'],
            data['user_avatar'],
            data['image'],
          ]);

    return InAppChatBannerItem(
      id: id,
      peerUserId: peer,
      title: title,
      body: body,
      avatarUrl: avatar,
    );
  }

  static InAppChatBannerItem fromMessage(
    Message message, {
    String? fallbackName,
    String? fallbackAvatarUrl,
  }) {
    final id = message.id > 0
        ? '${message.id}'
        : 'local_${message.clientId ?? message.createdAt.millisecondsSinceEpoch}';
    return InAppChatBannerItem(
      id: id,
      peerUserId: message.senderId,
      title: _nameFromMessage(message) ??
          (fallbackName != null && fallbackName.trim().isNotEmpty
              ? fallbackName.trim()
              : 'Someone'),
      body: chatMessagePreviewText(
        message: message.message,
        messageType: message.messageType,
        mediaDuration: message.mediaDuration,
        isExpired: message.isExpired,
      ),
      avatarUrl: _avatarFromMessage(message) ?? fallbackAvatarUrl,
    );
  }

  static const Set<String> genericBannerTypes = {
    'like',
    'new_like',
    'match',
    'new_match',
    'superlike',
    'superlike_received',
    'plan',
    'plan_updated',
    'plan_granted',
    'plan_upgraded',
    'subscription',
    'premium',
  };

  static InAppChatBannerItem? fromGenericFcm(
    Map<String, dynamic> data, {
    String? notificationTitle,
    String? notificationBody,
  }) {
    final type = (data['type']?.toString() ?? 'general').toLowerCase();
    if (!genericBannerTypes.contains(type)) return null;

    final peer = int.tryParse(data['user_id']?.toString() ?? '') ??
        int.tryParse(data['from_user_id']?.toString() ?? '') ??
        int.tryParse(data['sender_id']?.toString() ?? '') ??
        0;
    final id = _firstNonEmpty([
          data['notification_id'],
          data['like_id'],
          data['match_id'],
          type,
        ]) ??
        'generic_$type';

    return InAppChatBannerItem(
      id: id,
      peerUserId: peer,
      title: _firstNonEmpty([
            data['title'],
            data['headings'],
            notificationTitle,
          ]) ??
          'LGBTFinder',
      body: _firstNonEmpty([
            data['body'],
            data['message'],
            notificationBody,
          ]) ??
          'New notification',
      avatarUrl: _firstNonEmpty([
        data['avatar_url'],
        data['user_avatar'],
        data['image'],
      ]),
      type: type,
      routeData: {
        'type': type,
        if (peer > 0) 'user_id': peer,
        if (data['match_id'] != null) 'match_id': data['match_id'],
      },
    );
  }

  static Map<String, dynamic> suppressPayloadForMessage(Message message) {
    return {
      'type': 'message',
      'sender_id': message.senderId,
      'conversation_id': message.conversationId,
    };
  }

  static String? _nameFromMessage(Message message) {
    final meta = message.metadata;
    if (meta == null) return null;
    for (final key in ['sender_name', 'user_name', 'name', 'display_name']) {
      final value = meta[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static String? _avatarFromMessage(Message message) {
    final meta = message.metadata;
    if (meta == null) return null;
    for (final key in ['sender_avatar_url', 'sender_avatar', 'avatar_url']) {
      final value = meta[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static String? _firstNonEmpty(List<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }
}
