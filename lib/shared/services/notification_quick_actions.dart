import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_endpoints.dart';
import '../../core/services/app_logger.dart';
import 'background_auth_store.dart';
import 'background_message_display.dart';
import 'notification_navigation.dart';
import 'token_storage_service.dart';

const String kNotificationActionReply = 'reply';
const String kNotificationActionMarkRead = 'mark_read';
const String kNotificationActionCallBack = 'call_back';

/// Reply and mark-read from a message notification, including a background isolate.
@pragma('vm:entry-point')
void onBackgroundNotificationAction(NotificationResponse response) {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  unawaited(NotificationQuickActions.handle(response));
}

class NotificationQuickActions {
  NotificationQuickActions._();

  static Future<void> handle(NotificationResponse response) async {
    final action = response.actionId;
    if (action != kNotificationActionReply &&
        action != kNotificationActionMarkRead) {
      return;
    }
    final data = NotificationNavigation.parseLocalNotificationPayload(
      response.payload,
    );
    if (data == null) return;
    final peerId = NotificationNavigation.resolvePeerUserId(data);
    if (peerId == null) return;

    if (action == kNotificationActionMarkRead) {
      await _post(ApiEndpoints.chatRead, {'sender_id': peerId});
      return;
    }

    final text = response.input?.trim() ?? '';
    if (text.isEmpty) return;
    await _post(ApiEndpoints.chatSend, {
      'receiver_id': peerId,
      'message': text,
      'message_type': 'text',
    });
  }

  static Future<void> _post(String path, Map<String, dynamic> body) async {
    try {
      final backgroundToken = await BackgroundAuthStore.readToken();
      final secureToken = await TokenStorageService().getAuthToken();
      final token = preferStoredAuthToken(backgroundToken, secureToken);
      if (token == null) return;
      final origin = await BackgroundAuthStore.readApiOrigin();
      final base = (origin == null || origin.isEmpty)
          ? ApiEndpoints.baseUrl
          : '$origin/api';
      final response = await http.post(
        Uri.parse('$base$path'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      if (response.statusCode >= 400) {
        AppLogger.warning(
          'Notification action $path failed (${response.statusCode})',
          tag: 'Notifications',
        );
      }
    } catch (e) {
      AppLogger.warning(
        'Notification action $path failed',
        tag: 'Notifications',
        error: e,
      );
    }
  }
}

/// One group for every missed-call row so the shade summary keeps Call back.
const String kMissedCallGroupKey = 'missed_calls';

const List<AndroidNotificationAction> kMissedCallActions = [
  AndroidNotificationAction(
    kNotificationActionCallBack,
    'Call back',
    showsUserInterface: true,
    cancelNotification: false,
    contextual: false,
  ),
];

List<AndroidNotificationAction>? trayActionsFor(String type) {
  if (type == 'message' || type == 'chat' || type == 'new_message') {
    return messageTrayActions();
  }
  if (type == 'missed_call') {
    return kMissedCallActions;
  }
  return null;
}

/// Missed-call shade row. The group summary uses the same action so expanding
/// the stack does not drop Call back.
AndroidNotificationDetails missedCallAndroidDetails({
  required String title,
  required String body,
  required String tag,
  AndroidBitmap<Object>? largeIcon,
  bool summary = false,
}) {
  return AndroidNotificationDetails(
    kLgbtfinderCallsChannelId,
    notificationChannelLabel(kLgbtfinderCallsChannelId),
    channelDescription: notificationChannelDescription(kLgbtfinderCallsChannelId),
    importance: Importance.max,
    priority: Priority.max,
    category: AndroidNotificationCategory.missedCall,
    icon: '@drawable/ic_stat_lgbtfinder',
    color: const Color(0xFFEC4899),
    largeIcon: summary ? null : largeIcon,
    tag: summary ? null : tag,
    groupKey: kMissedCallGroupKey,
    setAsGroupSummary: summary,
    playSound: !summary,
    enableVibration: !summary,
    onlyAlertOnce: false,
    autoCancel: true,
    styleInformation: summary
        ? InboxStyleInformation(
            [body],
            contentTitle: title,
            summaryText: 'Missed calls',
          )
        : BigTextStyleInformation(body),
    actions: kMissedCallActions,
  );
}

/// Group header that still carries Call back for the latest missed call.
Future<void> showMissedCallGroupSummary({
  required FlutterLocalNotificationsPlugin plugin,
  required String title,
  required String body,
  required String payload,
}) async {
  await plugin.show(
    kMissedCallGroupKey.hashCode,
    title,
    body,
    NotificationDetails(
      android: missedCallAndroidDetails(
        title: title,
        body: body,
        tag: kMissedCallGroupKey,
        summary: true,
      ),
    ),
    payload: payload,
  );
}

List<AndroidNotificationAction> messageTrayActions() {
  return [
    const AndroidNotificationAction(
      kNotificationActionReply,
      'Reply',
      showsUserInterface: false,
      allowGeneratedReplies: true,
      cancelNotification: false,
      inputs: [AndroidNotificationActionInput(label: 'Message')],
    ),
    const AndroidNotificationAction(
      kNotificationActionMarkRead,
      'Mark as read',
      showsUserInterface: false,
      cancelNotification: true,
    ),
  ];
}

StyleInformation messageTrayStyle({
  required bool chat,
  required String title,
  required String body,
  String? senderKey,
  Uint8List? avatarPng,
}) {
  if (!chat) {
    return BigTextStyleInformation(body);
  }
  final person = Person(
    name: title,
    key: senderKey,
    icon: avatarPng == null ? null : ByteArrayAndroidIcon(avatarPng),
  );
  return MessagingStyleInformation(
    person,
    conversationTitle: title,
    groupConversation: false,
    messages: [Message(body, DateTime.now(), person)],
  );
}
