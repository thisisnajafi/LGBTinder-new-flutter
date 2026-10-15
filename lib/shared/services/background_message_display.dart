/// Tray display rules for the FCM background isolate.
///
/// The isolate runs only while the app is backgrounded or terminated, so the
/// conversation that was open before Home is not "currently open in the
/// foreground" and must still produce a notification (RT-009).
class BackgroundMessageDisplay {
  BackgroundMessageDisplay._();

  /// Post a local notification for a data-only message.
  ///
  /// An OS `notification` payload is already shown by Android/iOS. Call
  /// payloads are handled by CallKit, not the message tray.
  static bool shouldPostLocalNotification({
    required bool hasOsNotificationPayload,
    required bool isCallPayload,
  }) {
    if (isCallPayload) return false;
    if (hasOsNotificationPayload) return false;
    return true;
  }

  /// Title and body for a local tray item. Data-only chat pushes put these
  /// in the FCM data map; [message_preview] covers a payload that omitted them.
  static ({String title, String body})? resolveText({
    String? notificationTitle,
    String? notificationBody,
    Map<String, dynamic> data = const {},
  }) {
    final title =
        _nonEmpty(notificationTitle) ??
        _nonEmpty(data['title']) ??
        _nonEmpty(data['headings']) ??
        _nonEmpty(data['user_name']);
    final body =
        _nonEmpty(notificationBody) ??
        _nonEmpty(data['body']) ??
        _nonEmpty(data['message']) ??
        _nonEmpty(data['message_preview']);
    if (title == null || body == null) return null;
    return (title: title, body: body);
  }

  static String? _nonEmpty(Object? raw) {
    if (raw == null) return null;
    final value = raw.toString().trim();
    if (value.isEmpty) return null;
    return value;
  }
}

/// Must match FCM `android.notification.channel_id` for non-chat alerts.
const String kLgbtfinderFcmChannelId = 'lgbtfinder_channel';

/// High-importance chat channel. Distinct from [kLgbtfinderFcmChannelId],
/// which production devices already have stuck at DEFAULT importance.
const String kLgbtfinderMessagesChannelId = 'lgbtfinder_messages';
