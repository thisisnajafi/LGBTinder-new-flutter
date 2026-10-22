import 'background_message_display.dart';
import 'notification_quick_actions.dart';

enum TrayStyleKind { messaging, bigText }

/// Tray fields derived from an FCM data map.
///
/// Android message, like, super like, match, and missed-call pushes are
/// data-only. Both the background isolate and the foreground handler build
/// the local notification from this mapping so title, channel, avatar, and
/// actions stay the same in background and terminated states.
class MappedTrayNotification {
  final String type;
  final String channelId;
  final String title;
  final String body;
  final String? avatarUrl;
  final String? groupKey;
  final String tag;
  final TrayStyleKind style;
  final bool reply;
  final bool markRead;
  final bool callBack;
  final Map<String, dynamic> data;

  const MappedTrayNotification({
    required this.type,
    required this.channelId,
    required this.title,
    required this.body,
    required this.avatarUrl,
    required this.groupKey,
    required this.tag,
    required this.style,
    required this.reply,
    required this.markRead,
    required this.callBack,
    required this.data,
  });

  /// Only the privacy-safe [avatar_url] is used. Clear profile URLs under
  /// other keys are ignored.
  static MappedTrayNotification? from({
    String? notificationTitle,
    String? notificationBody,
    required Map<String, dynamic> data,
    Object? fallbackId,
  }) {
    final copy = Map<String, dynamic>.from(data);
    final rawType = copy['type']?.toString() ?? '';
    if (rawType == 'super_like') {
      copy['type'] = 'superlike';
    } else if (rawType == 'chat' || rawType == 'new_message') {
      copy['type'] = 'message';
    }

    final resolved = BackgroundMessageDisplay.resolveText(
      notificationTitle: notificationTitle,
      notificationBody: notificationBody,
      data: copy,
    );
    if (resolved == null) return null;

    final text = BackgroundMessageDisplay.chatTrayCopy(
      title: resolved.title,
      body: resolved.body,
      data: copy,
    );
    final type = copy['type']?.toString() ?? '';
    final isChat = type == 'message';
    final channelId = notificationChannelIdFor(type);

    return MappedTrayNotification(
      type: type,
      channelId: channelId,
      title: text.title,
      body: text.body,
      avatarUrl: _avatarUrl(copy['avatar_url']) ??
          _avatarUrl(copy['sender_avatar_url']),
      groupKey: type == 'missed_call'
          ? kMissedCallGroupKey
          : BackgroundMessageDisplay.messageGroupKey(copy),
      tag: isChat
          ? BackgroundMessageDisplay.trayTagForMessage(
              copy['message_id'] ?? fallbackId,
            )
          : _tag(type, copy, fallbackId),
      style: isChat ? TrayStyleKind.messaging : TrayStyleKind.bigText,
      reply: isChat,
      markRead: isChat,
      callBack: type == 'missed_call',
      data: copy,
    );
  }

  static String? _avatarUrl(Object? raw) {
    if (raw == null) return null;
    final value = raw.toString().trim();
    if (value.isEmpty) return null;
    return value;
  }

  static String _tag(
    String type,
    Map<String, dynamic> data,
    Object? fallbackId,
  ) {
    final id =
        _avatarUrl(data['call_id']) ??
        _avatarUrl(data['message_id']) ??
        _avatarUrl(fallbackId) ??
        _avatarUrl(data['user_id']) ??
        _avatarUrl(data['sender_id']) ??
        '';
    if (id.isEmpty) return 'lgbtfinder-$type';
    return 'lgbtfinder-$type-$id';
  }
}
