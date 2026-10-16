import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_endpoints.dart';
import '../../core/services/app_logger.dart';
import 'notification_navigation.dart';
import 'token_storage_service.dart';

const String kNotificationActionReply = 'reply';
const String kNotificationActionMarkRead = 'mark_read';
const String kNotificationActionCallBack = 'call_back';

/// Reply and mark-read from a message notification, including a background isolate.
@pragma('vm:entry-point')
void onBackgroundNotificationAction(NotificationResponse response) {
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
      final token = await TokenStorageService().getAuthToken();
      if (token == null || token.isEmpty) return;
      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}$path'),
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

List<AndroidNotificationAction> messageTrayActions() {
  return [
    const AndroidNotificationAction(
      kNotificationActionReply,
      'Reply',
      showsUserInterface: true,
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
}) {
  if (!chat) {
    return BigTextStyleInformation(body);
  }
  final person = Person(name: title, key: senderKey);
  return MessagingStyleInformation(
    person,
    conversationTitle: title,
    groupConversation: false,
    messages: [Message(body, DateTime.now(), person)],
  );
}
