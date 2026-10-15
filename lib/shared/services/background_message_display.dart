/// One row already in the status-bar shade.
class BackgroundTrayItem {
  final int? id;
  final String? tag;
  final String? title;
  final String? body;

  const BackgroundTrayItem({this.id, this.tag, this.title, this.body});
}

/// Tray display rules for the FCM background isolate.
///
/// The isolate runs only while the app is backgrounded or terminated, so the
/// conversation that was open before Home is not "currently open in the
/// foreground" and must still produce a notification (RT-009).
///
/// A background chat push that includes an OS notification is already in the
/// shade. Posting a local copy as well shows the same title and body twice
/// (RT-017).
class BackgroundMessageDisplay {
  BackgroundMessageDisplay._();

  /// Post a local notification for a data-only message.
  ///
  /// An OS `notification` payload is already shown by Android/iOS. Call
  /// payloads are handled by CallKit, not the message tray. A shade row that
  /// already has this title and body is the same message.
  static bool shouldPostLocalNotification({
    required bool hasOsNotificationPayload,
    required bool isCallPayload,
    bool trayAlreadyShowsMessage = false,
  }) {
    if (isCallPayload) return false;
    if (hasOsNotificationPayload) return false;
    if (trayAlreadyShowsMessage) return false;
    return true;
  }

  static bool trayAlreadyShowsMessage({
    required String title,
    required String body,
    required List<BackgroundTrayItem> active,
  }) {
    return active.any((item) => item.title == title && item.body == body);
  }

  /// Stable tag so a second local post for the same chat message replaces
  /// the first instead of adding a row.
  static String trayTagForMessage(Object? messageId) {
    final id = messageId?.toString().trim() ?? '';
    if (id.isEmpty) return 'lgbtfinder-message';
    return 'lgbtfinder-message-$id';
  }

  /// Extra shade rows for this title and body. One row stays.
  ///
  /// Prefer [keepTag] (the local post). When that tag is absent, the first
  /// matching row stays — that is the FCM notification Android already showed.
  static List<BackgroundTrayItem> extrasToCancel({
    required String title,
    required String body,
    required String keepTag,
    required List<BackgroundTrayItem> active,
  }) {
    final same = active
        .where((item) => item.title == title && item.body == body)
        .toList();
    if (same.length <= 1) return const [];
    final ours = same.where((item) => item.tag == keepTag);
    if (ours.isEmpty) return same.skip(1).toList();
    return same.where((item) => item.tag != keepTag).toList();
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
